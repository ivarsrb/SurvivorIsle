//
//  Leaves.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Transparent, interactive, static object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleGraph.h"
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"

@interface Leaves : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int firstVertex;
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int firstVertex;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) int firstIndex;

- (void) PresetData;
- (void) ResetData: (GeometryShape*) mesh: (Terrain*) terr: (Interaction*) intr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor;
- (void) Render;
- (void) ResourceCleanUp;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
@end
