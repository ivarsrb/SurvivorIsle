//
//  Shipwreck.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Shipwrck management
// Static, solid object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Environment.h"

@interface Shipwreck : NSObject
{
    SModelRepresentation ship;
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
@property (readonly, nonatomic) SModelRepresentation ship;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;

- (void) ResetData: (Terrain*) terr : (Environment*) env;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor;
- (void) Render;
- (void) ResourceCleanUp;
@end
