//
//  DryGrass.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Transparent, interactive, dynamic object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"

@interface DryGrass : NSObject
{
    int count;
    SModelRepresentation *collection;
    SBranchAnimation *branches;
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int firstVertex;
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    
    //parameters
    int brachesPerGrass;
    int bracheCount;
    int vertexPerBranch;
    float swingTime; //branch swing time
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int firstVertex;
@property (readonly, nonatomic) int count;

- (void) PresetData;
- (void) ResetData: (GeometryShape*) mesh: (Terrain*) terr: (Interaction*) intr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) UpdateVertexArray:(GeometryShape*) mesh: (BOOL) start;
- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (GeometryShape*) mesh;
- (void) RenderDynamic;
- (void) ResourceCleanUp;
- (void) UpdateBranches:(float) dt;

- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
@end
