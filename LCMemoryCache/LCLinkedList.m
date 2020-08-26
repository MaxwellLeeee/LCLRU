//
//  LCLinkedList.m
//  YYKitDemo
//
//  Created by 李畅 on 2020/7/20.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "LCLinkedList.h"
#import <CoreFoundation/CoreFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface LCLinkedList()


@end

@implementation LCLinkedList

-(instancetype)init
{
    self = [super init];
    if (self) {
        _searchDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

-(void)removeFromSearchDicWithKey:(NSString *)key
{
    CFDictionaryRemoveValue(_searchDic, (__bridge const void *)(key));
}

//如果node就是尾节点，因为是环形链表，直接改变headNode和trailNode的指向就可以了
-(void)bringNodeToHead:(LCLinkedListNode *)node
{
    if(node == self.headNode){
        return;
    }
    if (node == self.trailNode) {
        self.headNode = self.trailNode;
        self.trailNode = self.trailNode.prev;
        CFDictionarySetValue(_searchDic, (__bridge const void *)(node.key), (__bridge const void *)(node));
        return;
    }
    /*
     1.将此节点的前节点的next指向此节点的后节点
     2.将此节点的后节点的prev指向此节点的前节点
     3.将此节点的prev指向原头节点的prev
     3.将原头节点的prev指向这个节点
     4.将此节点的next指向原头节点
    */
    
    node.prev.next = node.next;
    node.next.prev = node.prev;
    
    node.prev = self.headNode.prev;
    node.next = self.headNode;
    
    self.headNode.prev = node;
    self.headNode = node;
}

-(void)insertFirstNode:(LCLinkedListNode *)node
{
    node.prev = node;
    node.next = node;
    self.headNode = node;
    self.trailNode = node;
}

-(void)insertNodeAtHead:(LCLinkedListNode *)node
{
    if (self.totalCount == 0) { //空
        [self insertFirstNode:node];
    }else{
        node.prev = self.headNode.prev;
        node.next = self.headNode;
        
        self.headNode.prev = node;
        self.headNode = node;
    }
    CFDictionarySetValue(_searchDic, (__bridge const void *)(node.key), (__bridge const void *)(node));
    self.totalSize += node.size;
    self.totalCount ++;
}

-(LCLinkedListNode *)removeTrailNode
{
    /*
     1.链表为空，不处理
     2.链表未满之前，需要将尾节点的后节点指向前节点
     3.链表已满的话，不需要处理，直接替换掉key和value就好了,这种情况不应该调用这个方法
     */
    if(self.totalCount == 0){
        return nil;
    }
    if (!self.trailNode.key) {
        LCLinkedListNode *trail = self.trailNode;
        _totalCount --;
        _totalSize -= self.trailNode.size;
        if (self.headNode != self.trailNode) {
            self.trailNode = self.trailNode.prev;
            self.trailNode.next = self.headNode;
            self.headNode.prev = self.trailNode;
        }
        return trail;
    }
    LCLinkedListNode *trail = self.trailNode;
    CFDictionaryRemoveValue(_searchDic, (__bridge const void *)(self.trailNode.key));
    _totalCount --;
    _totalSize -= self.trailNode.size;
    if (self.headNode != self.trailNode) {
        self.trailNode = self.trailNode.prev;
        self.trailNode.next = self.headNode;
        self.headNode.prev = self.trailNode;
    }
    return trail;
}

-(void)removeNode
{
    
}

-(void)clearAllNodes
{
    self.totalSize = 0;
    self.totalCount = 0;
    self.headNode = nil;
    self.trailNode = nil;
    if (CFDictionaryGetCount(_searchDic) > 0) {
        CFMutableDictionaryRef holder = _searchDic;
        _searchDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        dispatch_async(dispatch_get_main_queue(), ^{
            CFRelease(holder);
        });
    }
}


@end
