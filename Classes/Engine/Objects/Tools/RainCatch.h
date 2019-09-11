//
//  RainCatch.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Raincatching object that is placed on ground to collect rain
// Semi-Transparent, interactive, dynamic object

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

@interface RainCatch : NSObject
{
    int count;
    SModelRepresentation *collection;
    //raincatch model
    ModelLoader *model;
    ModelLoader *modelDrops;
    //effect
    GLKBaseEffect *effect;
    GLKBaseEffect *effectDrops;
    //textures
    GLuint *texIDs; 
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int vertexDynamicCount; //how many vertixes are stored from this class into global dynamic array
    int indexDynamicCount;
    
    int firstIndex; //start of global index array for this object
    int firstIndexDrops; //start of global index array for this object
    
    int firstVertexDrops;
    
    float catchTime; //seconds it take to collect rain water 
}
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) ModelLoader *modelDrops;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) GLKBaseEffect *effectDrops;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int vertexDynamicCount;
@property (readonly, nonatomic) int indexDynamicCount;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int count;

- (void) ResetData;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) UpdateDynamicVertexArray:(GeometryShape*) mesh:(float) dt;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor: (Environment*) env : (GeometryShape*) meshDynamic : (Interaction*) inter;
- (void) Render;
- (void) RenderDynamic :(BOOL) raining;
- (void) ResourceCleanUp;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct: (int) droppedItem;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;
@end
