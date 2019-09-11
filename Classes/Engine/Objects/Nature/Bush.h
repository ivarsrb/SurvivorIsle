//
//  Bush.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Island bush management
// Transparent, interactive, static object

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

@interface Bush : NSObject
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

- (void) PresetData;
- (void) ResetData: (GeometryShape*) mesh: (Terrain*) terr: (Interaction*) intr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) UpdateVertexArray:(GeometryShape*) mesh;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor;
- (void) Render;
- (void) ResourceCleanUp;
//- (void) SetLocationRect: (SModelRepresentation*) coll;
//- (void) SetAABBRadius: (SModelRepresentation*) coll;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
@end
