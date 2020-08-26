//
//  YYLRUManager.h
//  YYKitDemo
//
//  Created by 李畅 on 2020/7/22.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCLRUManager : NSObject

@property NSUInteger countLimit;
@property NSUInteger sizeLimit;
@property NSTimeInterval ageLimit;
@property NSTimeInterval autoTrimInterval;
@property (nonatomic, strong) NSMutableSet *reuseArr;

- (BOOL)containsObjectForKey:(id)key;
- (nullable id)objectForKey:(id)key;
- (void)setObject:(nullable id)object forKey:(id)key cost:(NSUInteger)cost;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
