//
//  Stick.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Stick object that lays on ground randomly
// Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleSound.h"
#import "SingleGraph.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "Character.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"
#import "Environment.h"
#import "ObjectHelpers.h"

@interface Stick : NSObject
{
    int count;
    int countSpear; //only for spear that is on ground
    SModelRepresentation *collection;
    SModelRepresentation *collectionSpear;
    ModelLoader *model;
    ModelLoader *modelSpear;
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for stick  object
    int firstIndexSpear; //start of global index array for spear object
    
    //for collision detection
    int numberOfSpheres;
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) ModelLoader *modelSpear;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SModelRepresentation *collectionSpear;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) int firstIndex;

- (void) PresetData;
- (void) ResetData:(Terrain*) terr: (Interaction*) intr: (Environment*) env;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter;
- (void) Render;
- (void) ResourceCleanUp;

- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (int) PickObjectSpear: (GLKVector3) charPos: (GLKVector3) pickedPos : (Character*) character : (Interface*) inter;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct;
- (void) PlaceObjectSpear: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct  : (Interface*) inter;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

@end
