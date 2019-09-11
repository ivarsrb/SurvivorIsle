//
//  Rag.h
//  Island survival
//
//  Created by Ivars Rusbergs on 11/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Rag from ship sale management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"
#import "Environment.h"
#import "Shipwreck.h"
#import "Ocean.h"
#import "Character.h"

@interface Rag : NSObject
{
    SModelRepresentation rag;
    ModelLoader *model;

    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    
    //rag parameters
    SLimitedFloat release; //release of log structure
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKTextureInfo *texture;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation rag;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int firstIndex;

- (void) ResetData: (Shipwreck*) ship : (Environment*) env : (Terrain*) terr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor:(Environment*) env: (Ocean*) ocean:(Terrain*) terr;
- (void) Render;
- (void) ResourceCleanUp;

- (void) ReleaseRag:(float) dt: (Environment*) env;
- (void) MoveRags:(float) dt: (float) curTime: (Ocean*) ocean: (Terrain*) terr;

- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*) intct;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

@end
