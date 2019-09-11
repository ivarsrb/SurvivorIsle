//
//  ObjectPhysics.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 10/04/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// #v1.1.
//  Collection of function to help realize motion physics of objects - movement, inertion, collisions etc

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleDirector.h"
#import "CommonHelpers.h"
#import "Terrain.h"

@interface ObjectPhysics : NSObject

+ (void) ResetMotionByVector: (SModelRepresentation*) c : (float) speed : (GLKVector3) directionVect;
+ (void) ResetMotionByAngles: (SModelRepresentation*) c : (float) speed : (float) xAngle : (float) yAngle;
+ (void) UpdateMotion: (SModelRepresentation*) c : (float) dt;
+ (float) GetResultantVelocity: (SModelRepresentation*) c;
+ (float) GetYAngle: (SModelRepresentation*) c;
//+ (float) GetXAngle: (SModelRepresentation*) c;
+ (BOOL) IsInMotion: (SModelRepresentation*) c;
+ (void) HaltMotion: (SModelRepresentation*) c;
+ (GLKVector3) GetReflectionVector: (SModelRepresentation*) c : (GLKVector3) planeNormal;
@end
