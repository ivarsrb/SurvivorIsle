//
//  Cocos.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Object - cocos managament
// Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Character.h"
#import "Interaction.h"
#import "PalmTree.h"
#import "Environment.h"
#import "ObjectHelpers.h"
#import "Particles.h"

@interface Cocos : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    
    //parameters
    BOOL firstReleased; //first cocos is released on his won, others are need to be shot doen
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int count;

- (void) ResetData: (Terrain*) terr: (PalmTree*) palm;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor: (Terrain*) terr : (Interaction*) inter  : (Particles*) particles;
- (void) Render;
- (void) ResourceCleanUp;

- (void) Release: (SModelRepresentation*) c;
- (void) ReleaseAfterHit: (SModelRepresentation*) c : (SModelRepresentation*) hitterObj;
- (void) CollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (Interaction*) inter  : (Particles*) particles;

- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*)intct;

@end
