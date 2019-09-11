//
//  AppDelegate.h
//  The Survivor
//
//  Created by Ivars Rusbergs on 9/13/13.
//  Copyright (c) 2013 Ivars Rusbergs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SingleDirector.h"
#import "SingleSound.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
