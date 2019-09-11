//
//  Environment.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Game world environment data management - time

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleDirector.h"
#import "CommonHelpers.h"

@interface Environment : NSObject
{
    //time management
	int dayLength; //number of real times minutes of game 24 hours
    float startTime; //time at which environment starts
    
    //with porperties
    float time;
    int dayNumber; //number of current day since beginning of game
    BOOL raining; //weather raining at the moment
    GLKVector3 wind; //direction and relative speed of wind
    float windAngle; //agle of wind (radians), relative to z
}
@property (nonatomic, readonly) float time;//current minutes from  00:00 midnight (gametime)
@property (nonatomic) BOOL raining;
@property (nonatomic) GLKVector3 wind; 
@property (nonatomic,readonly) int dayLength; 
@property (nonatomic,readonly) float windAngle;
@property (nonatomic,readonly) int dayNumber;

- (void) ResetData;
- (void) Update: (float) dt;
- (void) NillData;
@end
