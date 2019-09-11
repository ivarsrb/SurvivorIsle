//
//  Interaction.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Interaction among different game objects, mainly collision detection

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleGraph.h"
#import "MacrosAndStructures.h"
#import "ObjectPhysics.h"
#import "CommonHelpers.h"

@class Terrain, Objects, Ocean, Character;

@interface Interaction : NSObject
{
    Terrain *terrain;
    Objects *objects;
    Ocean *ocean;
}
@property (strong, nonatomic) Terrain *terrain;
@property (strong, nonatomic) Objects *objects;
@property (strong, nonatomic) Ocean *ocean;

- (id) initWithObjects: (Terrain*) terr : (Objects*) obj : (Ocean*) ocn;
- (void) ResourceCleanUp;

- (float) GetHeightByPoint: (GLKVector3) pos;
- (float) GetHeightByPointAboveWater : (GLKVector3) pos;
- (BOOL) MovementAllowed: (Character*) character : (GLKVector3) stepVector : (GLKVector3*) reboudnPoint;
- (BOOL) IsPlaceOccupiedOnStartup: (SModelRepresentation*) obj;
- (BOOL) PlaceOccupied: (GLKVector3) position : (float) radius;
- (BOOL) FreeToDrop: (GLKVector3) position;

- (int) ObjectVsGroundCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) speedMinlimit : (float) groundSlowdownKoef;
- (BOOL) ObjectVsPalmCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) slowdownKoef;
- (BOOL) ObjectVsCocosCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) slowdownKoef;
- (void) ObjectVsWildlifeInteraction: (SModelRepresentation*) c : (Character*) character;
- (BOOL) ObjectVsPalmCrownCollision: (SModelRepresentation*) c;

@end
