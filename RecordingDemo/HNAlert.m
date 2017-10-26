//
//  HNAlert.m
//  Mall
//
//  Created by xukun on 2017/6/29.
//  Copyright © 2017年 huanniu. All rights reserved.
//

#define KEY_MAINWINDOW [UIApplication sharedApplication].keyWindow

#import "HNAlert.h"

@implementation HNAlert

+ (void)alert:(NSString *)title message:(NSString *)message item:(NSArray *)items style:(HNAlertStyle)style Callback:(AlertCallback)callback {
    
    if (style == HNAlertViewStyleActionAlert) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

        for (int i = 0; i < items.count; i++) {
            UIAlertAction *alertAction;
            NSString *itemTitle = items[i];
            if ([itemTitle isEqualToString:@"取消"]) {
                alertAction = [UIAlertAction actionWithTitle:itemTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    if (callback) {
                        callback(HNAlertCallbackStyleCancel);
                    }
                }];
            } else {
                alertAction = [UIAlertAction actionWithTitle:itemTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if (callback) {
                        callback(HNAlertCallbackStyleDone);
                    }
                    
                }];
            }
            [alertController addAction:alertAction];
        }
        
        [KEY_MAINWINDOW.rootViewController presentViewController:alertController animated:YES completion:nil];
    } else if (style == HNAlertViewStyleActionAlertOK){
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (callback) {
              callback(HNAlertCallbackStyleOK);
            }
            
        }];
        [alertController addAction:alertAction];
        [KEY_MAINWINDOW.rootViewController presentViewController:alertController animated:YES completion:nil];
        
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (int i = 0; i < items.count; i++) {
            UIAlertAction *alertAction;
            NSString *itemTitle = items[i];
            if ([itemTitle isEqualToString:@"取消"]) {
                alertAction = [UIAlertAction actionWithTitle:itemTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    if (callback) {
                        callback(HNAlertCallbackStyleCancel);
                    }
                    
                }];
            } else if ([itemTitle isEqualToString:@"确定"]) {
                alertAction = [UIAlertAction actionWithTitle:itemTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    if (callback) {
                        callback(HNAlertCallbackStyleDone);
                    }
                }];
            } else {
                alertAction = [UIAlertAction actionWithTitle:itemTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    callback(i);
                }];
            }
            [alertController addAction:alertAction];
        }
        
        [KEY_MAINWINDOW.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

@end
