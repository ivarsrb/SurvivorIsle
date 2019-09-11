//
//  ObjectHelpers.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/03/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// General commonly used functions that are game object related (not math or anything specific)

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"
#import "CommonHelpers.h"
#import "ObjectPhysics.h"
#import "Interaction.h"

@interface ObjectHelpers : NSObject

//object dropping
+ (void) StartDropping : (SModelRepresentation*) c;
//+ (void) UpdateDropping: (SModelRepresentation*) c : (float) dt;
+ (void) UpdateDropping: (SModelRepresentation*) c : (float) dt : (Interaction*) inter : (float) speedMinlimit : (float) groundSlowdownKoef;
+ (void) NillDropping: (SModelRepresentation*) c;
//+ (void) GroundCollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (float) speedMinlimit : (float) groundSlowdownKoef;
+ (BOOL) CheckMultipleSpheresCollision: (int) numberOfSpheres : (float) objLength : (SModelRepresentation*) c : (GLKVector3) charPos : (GLKVector3) pickedPos : (float) pickDistance;
@end
