//
//  SingleDirector.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Singleton for shared app states and settings

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"

@interface SingleDirector : NSObject

@property (nonatomic) BOOL initialized;
@property (nonatomic, readonly) enumDeviceTypes deviceType;
@property (nonatomic) enumGameScenes gameScene;
@property (nonatomic) enumInterfaceTypes interfaceType;

//options
@property (nonatomic) int difficulty;


+ (SingleDirector *) sharedSingleDirector;
- (void) GetCurrentDevice:(CGSize) scrSize;
@end
