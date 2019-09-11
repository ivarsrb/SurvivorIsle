//
//  PalmTree.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Palm tree
// solid, non-interactive, static/dynamic object (palm trunk is opaque)

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleDirector.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"


//number of joints in palm if palm trunk changes change this number
#define PALM_JOINT_COUNT 5
#define VERTEX_PER_JOINT 8
//palmtree collision bounds structure
struct _SPalmBounds
{
    //NOTE: values here are absolote in space for each palm, not relative
    GLKVector3 vertice[PALM_JOINT_COUNT]; //need to store one vertice to dermenie joint radius
    GLKVector3 center[PALM_JOINT_COUNT]; //center of palm joint
    float radius[PALM_JOINT_COUNT]; //radius of palm joint
};
typedef struct _SPalmBounds SPalmBounds;


@interface PalmTree : NSObject
{
    int count;
    int straightCount;
    int bendedCount;
    int brachesPerTree;
    int bracheCount;
    SModelRepresentation *collection;
    ModelLoader *modelTrunk;
    ModelLoader *modelTrunk2;
    ModelLoader *modelBranch;
    SBranchAnimation *branches;
    SPalmBounds *trunkBounds; //for collision detection
    //effect
    GLKBaseEffect *effectTrunk;
    GLKBaseEffect *effectBranch;
    
    //global index array flags
    //static
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    //dynamic
    int vertexDynamicCount; //how many vertixes are stored from this class into global array
    int indexDynamicCount;
    
    int firstIndexTrunk;
    int firstIndexBranch;
    
    int firstVertexTrunk;
    int firstVertexBranch;
    
    //parameters
    float palmHeight; //height from ground to trunk upper point
    float swingTime; //branch swing time
}

@property (strong, nonatomic) ModelLoader *modelTrunk;
@property (strong, nonatomic) ModelLoader *modelTrunk2;
@property (strong, nonatomic) ModelLoader *modelBranch;
@property (strong, nonatomic) GLKBaseEffect *effectTrunk;
@property (strong, nonatomic) GLKBaseEffect *effectBranch;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SPalmBounds *trunkBounds;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int vertexDynamicCount;
@property (readonly, nonatomic) int indexDynamicCount;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) float palmHeight; 

- (void) PresetData;
- (void) ResetData: (GeometryShape*) mesh:(GeometryShape*) meshDynamic: (Terrain*) terr: (Interaction*) intr;
- (void) InitGeometry;
- (void) UpdateVertexArray:(GeometryShape*) mesh;
- (void) UpdateDynamicVertexArray:(GeometryShape*) mesh: (BOOL) start;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor: (GeometryShape*) meshDynamic;
- (void) Render;
- (void) RenderDynamic;
- (void) ResourceCleanUp;
- (void) UpdateBranches:(float) dt;
- (void) PlaceOnPalmtree: (SModelRepresentation*) c;

- (void) AssignTrunkBounds;
- (float) GetLowestYInPalm: (int) palmIndex : (float) notLowerEqualThan;
//- (int) GetPalmJointIndexByY: (int) palmIndex : (float) height;
- (BOOL) GetUpDownJointsByY: (int) palmIndex : (float) height : (int*) lowerJoint : (int*) upperJoint;
@end
