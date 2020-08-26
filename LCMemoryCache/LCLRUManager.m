//
//  YYLRUManager.m
//  YYKitDemo
//
//  Created by 李畅 on 2020/7/22.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "LCLRUManager.h"
#import "LCLinkedListNode.h"
#import "LCLinkedList.h"
#import <pthread.h>
#import <QuartzCore/QuartzCore.h>


#define kUseReuseSet (1)

@implementation LCLRUManager{
    pthread_mutex_t _lock;
    LCLinkedList *_lru;
    dispatch_queue_t _queue;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _lru = [LCLinkedList new];
        _queue = dispatch_queue_create("com.tencent.cache.memory", DISPATCH_QUEUE_SERIAL);
        _countLimit = NSUIntegerMax;
        _sizeLimit = NSUIntegerMax;
        _ageLimit = DBL_MAX;
        _autoTrimInterval = 5.0;
        [self tryToFindNeedDeleteMemory];
    }
    return self;
}


- (void)dealloc {
    [_lru clearAllNodes];
    pthread_mutex_destroy(&_lock);
}

-(void)tryToFindNeedDeleteMemory
{
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self doSearchAction];
        [self tryToFindNeedDeleteMemory];
    });
}

-(void)doSearchAction
{
    dispatch_async(_queue, ^{
        [self checkAge];
        [self checkSize];
    });
}

-(void)checkSize
{
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if(_lru.totalSize < self.sizeLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) {
        return;
    }
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru.totalSize > self.sizeLimit) {
                LCLinkedListNode *node = [_lru removeTrailNode];
                if (node) {
                    [holder addObject:node];
                }
            }else{
                finish = YES;
            }
        }else{
            usleep(10 * 1000);
        }
#if kUseReuseSet
        if (holder.count > 0) {
            [self putIntoReuseWithNodeArr:holder];
        }
#endif
        pthread_mutex_unlock(&_lock);
#if kUseReuseSet
#else
        if (holder.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [holder count];
            });
        }
#endif
    }
}

-(void)checkAge
{
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    pthread_mutex_lock(&_lock);
    if (_lru.totalCount == 0 || (now - _lru.trailNode.updateTIme) < self.ageLimit) {
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) {
        return;
    }
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru.totalCount > 0 && (now - _lru.trailNode.updateTIme > self.ageLimit)) {
                LCLinkedListNode *node = [_lru removeTrailNode];
                if (node) {
                    [holder addObject:node];
                }
            }else{
                finish = YES;
            }
        }else{
            usleep(10 * 1000);
        }
#if kUseReuseSet
        if (holder.count > 0) {
            [self putIntoReuseWithNodeArr:holder];
        }
#endif
        pthread_mutex_unlock(&_lock);
#if kUseReuseSet
#else
        if (holder.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [holder count];
            });
        }
#endif
    }
}

-(BOOL)containsObjectForKey:(id)key
{
    if (!key) {
        return NO;
    }
    pthread_mutex_lock(&_lock);
    BOOL contains = CFDictionaryContainsKey(_lru->_searchDic, (__bridge const void *)(key));
    pthread_mutex_unlock(&_lock);
    return contains;
}

//取这个值就说明，用到了这个缓存，就需要把这个缓存移动到头节点
-(id)objectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    pthread_mutex_lock(&_lock);
    LCLinkedListNode *node = CFDictionaryGetValue(_lru->_searchDic, (__bridge const void *)(key));
    if (node) {
        node.updateTIme = CACurrentMediaTime();
        [_lru bringNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
    return node ? node.data: nil;
}


/*
链表为满的情况
1.key在searchDic中能找到值node，那么替换掉node的value，把原value释放，并把node移动到头节点
2.key在searchDic找不到对应的值，那么取最后一个node，替换key和value，把原value释放，把头节点和尾节点指向移动一位就可以了
链表未满的情况
1.key在searchDic中能找到值node，那么替换掉node的value，把原value释放，并把node移动到头节点
2.key在searchDic找不到对应的值，创建一个node，设置key和value，插入到头节点
*/
-(void)setObject:(id)object forKey:(id)key cost:(NSUInteger)cost
{
    if (!key) {
        return;
    }
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    pthread_mutex_lock(&_lock);
    LCLinkedListNode *node = CFDictionaryGetValue(_lru->_searchDic, (__bridge const void *)(key));
    NSTimeInterval now = CACurrentMediaTime();
    id needReleaseValue;
    if(node){ //找到了
        needReleaseValue = object;
        _lru.totalSize -= node.size;
        _lru.totalSize += cost;
        node.size = cost;
        node.updateTIme = now;
        node.data = object;
        [_lru bringNodeToHead:node];
    }else{ //没找到
        if(_lru.totalCount >= self.countLimit){ //受个数限制，链表已满
            _lru.totalSize -= _lru.trailNode.size;
            _lru.totalSize += cost;
            [_lru removeFromSearchDicWithKey:_lru.trailNode.key];
            node = _lru.trailNode;
            needReleaseValue = node.data;
            node.size = cost;
            node.updateTIme = now;
            node.key = key;
            node.data = object;
            [_lru bringNodeToHead:node];
        }else if(_lru.totalSize >= self.sizeLimit){ //受大小限制，链表已满
            _lru.totalSize -= _lru.trailNode.size;
            _lru.totalSize += cost;
            [_lru removeFromSearchDicWithKey:_lru.trailNode.key];
            node = _lru.trailNode;
            needReleaseValue = node.data;
            node.size = cost;
            node.updateTIme = now;
            node.key = key;
            node.data = object;
            [_lru bringNodeToHead:node];
        }else{ //链表未满
            //            node = [LCLinkedListNode new];
            node = [self makeNewNode];
            node.size = cost;
            node.updateTIme = now;
            node.key = key;
            node.data = object;
            [_lru insertNodeAtHead:node];
        }
    }
    if (needReleaseValue) {
        //TODO:
    }
    pthread_mutex_unlock(&_lock);
}

- (void)removeAllObjects {
    pthread_mutex_lock(&_lock);
    [_lru clearAllNodes];
    pthread_mutex_unlock(&_lock);
}

- (void)removeObjectForKey:(id)key {
    if (!key) {
        return;
    }
    pthread_mutex_lock(&_lock);
    LCLinkedListNode *node = CFDictionaryGetValue(_lru->_searchDic, (__bridge const void *)(key));
#if kUseReuseSet
    [self putIntoReuse:node];
#else
    if (node) {
        [_lru removeNode:node];
        dispatch_async(dispatch_get_main_queue(), ^{
            [node class];
        });
    }
#endif
    pthread_mutex_unlock(&_lock);
}

-(LCLinkedListNode *)makeNewNode
{
    if (self.reuseArr.count > 0) {
        LCLinkedListNode *firstNode = [self.reuseArr anyObject];
        [self.reuseArr removeObject:firstNode];
        return firstNode;
    }
    return [LCLinkedListNode new];
}

-(void)putIntoReuse:(LCLinkedListNode *)node
{
    //不删除node，只释放内容
    node.data = nil;
    [self.reuseArr addObject:node];
}

-(void)putIntoReuseWithNodeArr:(NSArray <LCLinkedListNode *> *) nodeArr
{
    //不删除node，只释放内容
    for (LCLinkedListNode *node in nodeArr) {
        node.data = nil;
    }
    [self.reuseArr addObjectsFromArray:nodeArr];
}

-(NSMutableSet *)reuseArr
{
    if (!_reuseArr) {
        _reuseArr = [[NSMutableSet alloc] initWithCapacity:0];
    }
    return _reuseArr;
}

@end
