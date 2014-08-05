//
//  VKDynamicBinding.m
//  WiFinder
//
//  Created by youngsing on 14-7-10.
//  Copyright (c) 2014年 youngsing. All rights reserved.
//

#import "VKDynamicBinding.h"
@import ObjectiveC;

#define kJSPrefix @"VKJS://"

@implementation VKDynamicBinding

+ (void)parseRequestFromJS:(NSString *)requsetString completion:(void (^)(id))completion {
    [self parseJSString:requsetString completion:completion];
}

+ (void)parseJSString:(NSString *)jsString completion:(void (^)(id))completion {
    /**
     *  代码字符串格式： VKJS://class1.method1.parameter1;class2.method2.paramter2;
     *  class、method分别对应本地的class name、method name
     *  parameter为将参数数组JSON序列化并Base64编码后的字符串
     */
    
    
    // 是否为异步回调
    BOOL isCallback = NO;
    
    if ([jsString hasPrefix:kJSPrefix]) {
        
        NSString *parseString = [jsString substringFromIndex:7];
        NSArray *parseArray = [parseString componentsSeparatedByString:@";"];
        
        NSMutableArray *resultArray = [NSMutableArray array];
        
        // 遍历执行代码串
        for (NSString *invokeString in parseArray) {
            NSArray *invokeArray = [invokeString componentsSeparatedByString:@"."];
            
            Class class = NSClassFromString(invokeArray[0]);
            SEL selector = NSSelectorFromString(invokeArray[1]);
            // 类或者实例
            id instance = nil;
            
            // 获取方法签名
            NSMethodSignature *signature = [class instanceMethodSignatureForSelector:selector];
            if (!signature) {
                signature = [class methodSignatureForSelector:selector];
                instance = class;
            } else {
                instance = [class new];
            }
            
            if (!signature) {
                continue;
            }
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:instance];
            [invocation setSelector:selector];
            
            // 处理参数传递，首先处理带参数的调用
            if (invokeArray.count == 3) {
                
                NSString *jsonParams = invokeArray[2];
                // 参数需要进行Base64处理，此处忽略
                NSArray *params = [NSJSONSerialization JSONObjectWithData:[jsonParams dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
                
                NSUInteger paramsCount = [signature numberOfArguments];
                if (params.count != paramsCount - 2) {
                    // 参数数量不匹配直接跳过
                    continue;
                }
                
                // 处理各种类型的传入参数，不完备，根据实际使用情况添加
                for (int i = 0; i != params.count; ++i) {
                    id param = params[i];
                    const char * cType = [signature getArgumentTypeAtIndex:2 + i];
                    
                    if (!strcmp(cType, @encode(id))) {
                        
                        [invocation setArgument:&param atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(NSInteger))) {
                        
                        NSInteger value = [param integerValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(NSUInteger))) {
                        
                        NSUInteger value = [param unsignedIntegerValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(CGFloat))) {
                        
                        CGFloat value = [param floatValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(BOOL))) {
                        
                        BOOL value = [param boolValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(CGPoint))) {
                        
                        CGPoint value = [param CGPointValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(CGSize))) {
                        
                        CGSize value = [param CGSizeValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    } else if (!strcmp(cType, @encode(CGRect))) {
                        
                        CGRect value = [param CGRectValue];
                        [invocation setArgument:&value atIndex:2 + i];
                        
                    }
                }
                
            } else {
                // 不带参数，但需要异步回调
                BOOL shouldCallback = [invokeArray[1] hasSuffix:@":"];
                if (shouldCallback) {
                    isCallback = YES;
                    [invocation setArgument:&completion atIndex:2];
                }
                
            }
            [invocation invoke];
            
            if (isCallback) {
                break;
            }
            
            // 处理返回值
            const char * cType = [signature methodReturnType];
            NSUInteger length = [signature methodReturnLength];
            
            if (length) {
                
                void * buffer = malloc(length);
                id result;
                if (!strcmp(cType, @encode(id))) {
                    
                    __unsafe_unretained id ret = nil;
                    [invocation getReturnValue:&ret];
                    result = ret;
                    
                } else {
                    
                    [invocation getReturnValue:buffer];
                    
                    if (!strcmp(cType, @encode(NSInteger))) {
                        
                        result = [NSNumber numberWithInteger:*((NSInteger *)buffer)];
                        
                    } else if (!strcmp(cType, @encode(NSUInteger))) {
                        
                        result = [NSNumber numberWithUnsignedInteger:*((NSUInteger *)buffer)];
                        
                    } else if (!strcmp(cType, @encode(CGFloat))) {
                        
                        result = [NSNumber numberWithFloat:*((CGFloat *)buffer)];
                        
                    } else if (!strcmp(cType, @encode(BOOL))) {
                        
                        result = [NSNumber numberWithBool:*((BOOL *)buffer)];
                        
                    } else if (!strcmp(cType, @encode(CGPoint))) {
                        
                        result = NSStringFromCGPoint(*(CGPoint *)buffer);
                        
                    } else if (!strcmp(cType, @encode(CGSize))) {
                        
                        result = NSStringFromCGSize(*(CGSize *)buffer);
                        
                    } else if (!strcmp(cType, @encode(CGRect))) {
                        
                        result = NSStringFromCGRect(*(CGRect *)buffer);
                        
                    }
                }
                
                if (result) {
                    [resultArray addObject:result];
                }
                free(buffer);
            }
        }
        
        // 如果不是异步回调，就返回执行结果
        if (!isCallback && completion) {
            completion(resultArray.count ? resultArray : nil);
        }
    }
    
}

@end
