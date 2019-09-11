//
//  Rat.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Animal - rat
// Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleGraph.h"
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Inventory.h"
#import "Terrain.h"
#import "Character.h"
#import "DeadfallTrap.h"
#import "Interaction.h"
#import "ObjectActions.h"
#import "CampFire.h"
#import "Particles.h"

@interface Rat : NSObject
{
    //crabs
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    ObjectActions *actions;
    //textures
    GLuint *texID;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic)  ObjectActions *actions;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int count;

- (void) NillData;
- (void) ResetData: (Terrain*) terr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor:(Terrain*) terr: (Character*) character: (DeadfallTrap*) traps: (Interaction*) intct  : (Particles*) particles;
- (void) Render;
- (void) ResourceCleanUp;

- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*) intct : (CampFire*) cmpFire : (int) droppedItemType;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

- (BOOL) IsPathBlocked: (SModelRepresentation*) c: (Terrain*) terr;//: (Interaction*) intct;
- (BOOL) IsTrapInArea: (GLKVector3) tposition: (Terrain*) terr;
- (BOOL) IsNearTrap: (SModelRepresentation*) c: (DeadfallTrap*) traps: (Terrain*) terr: (GLKVector3*) toPoint;

- (void) SetUpAnimation: (SModelRepresentation*) c;
- (void) StartAnimation: (SModelRepresentation*) c;
- (void) EndAnimation: (SModelRepresentation*) c;
- (void) UpdateAnimation:(SModelRepresentation*) c: (float) dt;
- (void) AnimateLegEtalon:(SModelRepresentation*) c: (SSceletalAnimation*) etalon: (float) dt;
- (void) AnimateLeg:(SModelRepresentation*) c: (SSceletalAnimation*) leg: (float) dt;

@end
