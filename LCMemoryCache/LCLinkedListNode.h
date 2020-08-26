//
//  LCLinkedListNode.h
//  YYKitDemo
//
//  Created by 李畅 on 2020/7/20.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCLinkedListNode : NSObject

@property (nonatomic, strong, nullable) NSString *key;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, weak, nullable) LCLinkedListNode *next;
@property (nonatomic, weak, nullable) LCLinkedListNode *prev;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) NSTimeInterval updateTIme;

@end

NS_ASSUME_NONNULL_END
