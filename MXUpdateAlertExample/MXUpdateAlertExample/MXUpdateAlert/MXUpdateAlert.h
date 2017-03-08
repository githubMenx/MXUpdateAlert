//
//  MXUpdateAlert.h
//  MXUpdateAlertExample
//
//  Created by Meng on 17/3/8.
//  Copyright © 2017年 MX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXSingle.h"

@interface MXUpdateAlert : NSObject

singletonInterface(UpdateAlert)

- (void)checkUpdate;

@end
