//
//  Ocean.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Water system
//---------
// v.1.1. - distant water splash
//---------

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "SingleGraph.h"
#import "Environment.h"
#import "Terrain.h"
#import "SkyDome.h"
#import "Character.h"
#import "Particles.h"

@class Raft;
@class Wildlife;

@interface Ocean : NSObject
{
    GeometryShape *oceanMesh;
    
    //shader
    GLKBaseEffect *effectOcean;
    
    //parameters
    GLKVector3 oceanBase;
    
    //parameters
    int vertexCount,indexCount;
    float scaleFactor;
    int side;
    int oceanWidth;
    int *verticesPerRow;
    GLKVector3 shiftBack;
    GLKVector2 *textureCoords;
    float waveTime;
    float waveDirAngle; 
    float **waveHeightMap; //store wave height in2d array to easier get ocean height at some poin
    float waterBaseHeight;
    
    //coloring
    GLKVector4 *distanceShading;
    
    //day/night coloring
    SDaytimeColors coloring;
    
}

@property (strong, nonatomic) GeometryShape *oceanMesh;
@property (strong, nonatomic) GLKBaseEffect *effectOcean;
@property (readonly, nonatomic) GLKVector3 oceanBase;
@property (readonly, nonatomic) float waterBaseHeight;
@property (readonly, nonatomic) int oceanWidth;
@property (readonly, nonatomic) float scaleFactor;
@property (readonly, nonatomic) SDaytimeColors coloring;

- (id) initWithObjects: (Terrain*) terr;
- (void) ResetData: (Environment*) env;
- (void) InitGeometry: (Terrain*) terr;
- (void) SetupRendering;
- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (SkyDome*) sky : (Character*) character;
- (void) Render;
- (void) ResourceCleanUp;

- (void) GetVertexIndexCount:(int*) vCount : (int*) iCount;
- (void) InitVertexIndexArray:(Terrain*) terr;
- (void) RotateOceanField:(Environment*) env;
- (void) UpdateVertices:(float) dt : (float) curTime : (GLKVector4) dtColor : (SkyDome*) sky : (Character*) character;
- (void) MixWithSunlight:(GLKVector4*) color : (GLKVector3) sunPosition : (GLKVector3) vertex;
- (void) MixWithWaveHeight:(GLKVector4*) color : (GLKVector3) vertex;
- (float) GetHeightByPoint: (GLKVector3) pos;
- (float) GetWaveHeight: (float) x : (float) y : (float) baseH;

@end
