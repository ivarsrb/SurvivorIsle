//
//  DeadfallTrap.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Trap on game
//  Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "Terrain.h"
#import "Environment.h"
#import "Interface.h"
#import "Inventory.h"
#import "Interaction.h"
#import "ObjectHelpers.h"
#import "Particles.h"

@interface DeadfallTrap : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    //textures
    GLuint *texIDs;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Interaction*) inter;
- (void) Render;
- (void) ResourceCleanUp;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct: (int) droppedItem;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;
- (BOOL) CatchInTrap:(GLKVector3*) gamePosition  : (Particles*) particles;
@end
