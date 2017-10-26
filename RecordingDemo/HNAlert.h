//
//  HNAlert.h
//  Mall
//
//  Created by xukun on 2017/6/29.
//  Copyright © 2017年 huanniu. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,HNAlertStyle) {
    HNAlertViewStyleActionSheet = 0,  // ActionSheet样式
    HNAlertViewStyleActionAlert = 1,  // alert样式
    HNAlertViewStyleActionAlertOK = 2 // 只有一个按钮的alert
};

typedef NS_ENUM(NSInteger,HNAlertCallbackStyle) {
    HNAlertCallbackStyleDone = 99,    // 点击确定的回调
    HNAlertCallbackStyleCancel,        // 点击取消的回调
    HNAlertCallbackStyleOK              // 点击OK的回调
};


typedef void (^AlertCallback)(HNAlertCallbackStyle style);


@interface HNAlert : NSObject


/**
 警告框
 @param title 标题
 @param message 提示语
 @param items @[按钮]
 @param style 弹出框样式
 @param callback 点击按钮回掉
 */
+ (void)alert:(NSString *)title message:(NSString *)message item:(NSArray *)items style:(HNAlertStyle)style Callback:(AlertCallback)callback;
@end
