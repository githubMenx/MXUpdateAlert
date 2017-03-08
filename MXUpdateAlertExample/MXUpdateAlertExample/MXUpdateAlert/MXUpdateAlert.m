//
//  MXUpdateAlert.m
//  MXUpdateAlertExample
//
//  Created by Meng on 17/3/8.
//  Copyright © 2017年 MX. All rights reserved.
//  支持更新提示类型(0、强制更新 1、非强制更新仅提醒一次 2、非强制更新每次打开app都进行提醒 3、不显示更新)

#import "MXUpdateAlert.h"
#import <UIKit/UIKit.h>

// updateType=1 YES:已提醒 NO:未提醒
#define kUpdateType1UserDefaultsKey @"kUpdateType1UserDefaultsKey"
// 存储最新版本号
#define kLastVersionUserDefaultsKey @"kLastVersionUserDefaultsKey"
// iTunes链接地址
#define kiTunesURL @"https://www.baidu.com"

@interface MXUpdateAlert ()

/** 最新版本数据 */
@property (nonatomic, strong) NSDictionary *bestNewVersionData;
/** 有无新版本 */
@property (nonatomic, assign, getter=isHasVersion) BOOL hasVersion;
/** updateType=2已提醒过 */
@property (nonatomic, assign, getter=isShowingUpdateType2) BOOL showingUpdateType2;

@end

@implementation MXUpdateAlert

singletonImplementation(UpdateAlert)

- (void)checkUpdate {
    
    /*
     * 如果rootViewController没有值return
     * 没有新版本return
     * 根据updateType展示alert
     */
    
    // 0.如果rootViewController没有值return
    if (![UIApplication sharedApplication].keyWindow.rootViewController) {
        return;
    }
    if (self.bestNewVersionData) {
        // 没有新版本return
        if (!self.isHasVersion) {
            return;
        }
        // 根据updateType展示alert
        [self showAlert];
    } else { // 获取最新版本信息
        // 模拟获取新版本信息
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary *result = @{
                                     @"data" : @{
                                             @"versionCode" : @"2",
                                             @"versionInfo" : @"1.更新了XXXXXXXXXXXXXXXXX;\n2.优化了XXXXXXXXXXXXXXXXX;\n3.修复了XXXXXXXXXXXXXXXXX;",
                                             @"updateType" : @"2"
                                             }
                                     };
            NSDictionary *data = result[@"data"];
            if (![data isKindOfClass:[NSDictionary class]]) {
                return;
            }
            // 版本比较
            NSString *serviceVersion = [NSString stringWithFormat:@"%@", data[@"versionCode"]];
            if (!serviceVersion.length) {
                return;
            }
            
            // 更新内容
            NSString *explain = data[@"versionInfo"];
            // 更新提示类型(0、强制更新 1、非强制更新仅提醒一次 2、非强制更新每次打开app都进行提醒 3、不显示更新)
            NSString *updateType = [NSString stringWithFormat:@"%@", data[@"updateType"]];
            if (!explain.length || !updateType.length) {
                return;
            }
            
            // 保存新版本信息
            self.bestNewVersionData = data;
            // 版本比较
            NSString *localVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
            if ([localVersion caseInsensitiveCompare:serviceVersion] == NSOrderedAscending) {
                self.hasVersion = YES;
                // 弹出更新提示框
                [self showAlert];
            } else {
                self.hasVersion = NO;
            }
            
        });
    }
    
}

/**
 弹出提示框
 */
- (void)showAlert {
    
    NSString *type = self.bestNewVersionData[@"updateType"];
    NSString *message = self.bestNewVersionData[@"versionInfo"];
    
    // 如果不是0/1/2/3 return
    if (![type isEqualToString:@"0"] && ![type isEqualToString:@"1"] && ![type isEqualToString:@"2"] && ![type isEqualToString:@"3"]) {
        return;
    }
    if ([type isEqualToString:@"3"]) { // 不显示更新
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUpdateType1UserDefaultsKey];
        return;
    }
    // 如果type是1, 版本号未升级, 且提醒过了 return
    BOOL bType = [type isEqualToString:@"1"];
    NSString *serviceVersion = [NSString stringWithFormat:@"%@", self.bestNewVersionData[@"versionCode"]];
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:kLastVersionUserDefaultsKey];
    BOOL bVersion = [lastVersion isEqualToString:serviceVersion];
    BOOL bUpdateType1 = [[NSUserDefaults standardUserDefaults] boolForKey:kUpdateType1UserDefaultsKey];
    if (bType && bVersion && bUpdateType1) {
        return;
    }
    // 如果type是2, 且提醒过return
    if ([type isEqualToString:@"2"] && self.isShowingUpdateType2) {
        return;
    }
    // alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"有新版本更新啦~" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if ([type isEqualToString:@"0"]) { // 强制更新
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUpdateType1UserDefaultsKey];
        [alert addAction:[UIAlertAction actionWithTitle:@"立即更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kiTunesURL]];
        }]];
    } else if ([type isEqualToString:@"1"] || [type isEqualToString:@"2"]) { // 非强制更新 1仅提醒一次 2每次打开app都进行提醒
        if ([type isEqualToString:@"1"]) {
            [[NSUserDefaults standardUserDefaults] setObject:serviceVersion forKey:kLastVersionUserDefaultsKey];
        } else {
            self.showingUpdateType2 = YES;
        }
        [[NSUserDefaults standardUserDefaults] setBool:[type isEqualToString:@"1"] forKey:kUpdateType1UserDefaultsKey];
        [alert addAction:[UIAlertAction actionWithTitle:@"下次再说" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"立即更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kiTunesURL]];
        }]];
    }
    
    // 下面是取title和message的父视图的代码：
    UIView *subView1 = alert.view.subviews[0];
    UIView *subView2 = subView1.subviews[0];
    UIView *subView3 = subView2.subviews[0];
    UIView *subView4 = subView3.subviews[0];
    UIView *subView5 = subView4.subviews[0];
    // 取title和message：
    //UILabel *titleLabel = subView5.subviews[0];
    UILabel *messageLabel = subView5.subviews[1];
    // 然后设置message内容居左：
    messageLabel.textAlignment = NSTextAlignmentLeft;
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
    
}

@end
