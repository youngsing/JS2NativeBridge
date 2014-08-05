//
//  VKDynamicBinding.h
//  WiFinder
//
//  Created by youngsing on 14-7-10.
//  Copyright (c) 2014年 youngsing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VKDynamicBinding : NSObject

/**
 *  执行一段WebView通过JS传递给本地的代码字符串，并将结果返回给WebView
 *
 *  @param requsetString 需要本地执行的代码字符串
 *  @param completion    包含执行结果的回调
 */
+ (void)parseRequestFromJS:(NSString *)requsetString completion:(void(^)(id result))completion;

@end
