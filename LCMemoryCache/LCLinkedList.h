//
//  LCLinkedList.h
//  YYKitDemo
//
//  Created by 李畅 on 2020/7/20.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCLinkedListNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCLinkedList : NSObject
{
    @package
    CFMutableDictionaryRef _searchDic;
}
@property (nonatomic, strong, nullable) LCLinkedListNode *headNode;
@property (nonatomic, strong, nullable) LCLinkedListNode *trailNode;
@property (nonatomic, assign) NSUInteger totalCount;
@property (nonatomic, assign) NSUInteger totalSize;


-(void)insertNodeAtHead:(LCLinkedListNode *)node;
-(void)bringNodeToHead:(LCLinkedListNode *)node;
-(void)removeFromSearchDicWithKey:(NSString *)key;
-(void)removeNode:(LCLinkedListNode *)node;
-(LCLinkedListNode *)removeTrailNode;
-(void)clearAllNodes;


@end

NS_ASSUME_NONNULL_END
