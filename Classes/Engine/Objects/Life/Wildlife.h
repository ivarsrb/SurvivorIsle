//
//  Wildlife.h
//  The Survivor
//
//  Created by Ivars Rusbergs on 3/6/14.
//  Copyright (c) 2014 Ivars Rusbergs. All rights reserved.
//
// Decorative, non - interactive wildife elemnts
// - Butterflies
// - dolphin
// ------------
// #v1.1. From dolphin collection to single dolphin instance
// ------------
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Environment.h"
#import "Ocean.h"
#import "Particles.h"


@interface Wildlife : NSObject
{
    //butterfly
    int bflyCount;
    SModelRepresentation *bflyCollection;
    ModelLoader *bflyModel;
    
    //dolphin
    SModelRepresentation dolphin;
    ModelLoader *dolphinModel;
    
    //textures
    GLuint *bflyTexID;
    GLuint dolphinTexID;
    
    //effect
    GLKBaseEffect *bflyEffect;
    GLKBaseEffect *dolphinEffect;
    
    //mesh filling params
    //butterfly
    SIndVertAttribs bflyMeshParams;
    //dolphin
    SIndVertAttribs dolphinMeshParams;
    
    //params
    //butterfly
    float bflyEtalonWingsTime; //butterfly time counter to swing wings
    float bflyEtalonWingsAngle; //butterfly etalon wing flapping angle
   
    //dolphin
    float dolphinInitialY ;//initial / baseposition of dolphin
}

@property (strong, nonatomic) ModelLoader *bflyModel;
@property (strong, nonatomic) GLKBaseEffect *bflyEffect;
@property (readonly, nonatomic) SModelRepresentation *bflyCollection;
@property (readonly, nonatomic) SIndVertAttribs bflyMeshParams;

@property (strong, nonatomic) ModelLoader *dolphinModel;
@property (strong, nonatomic) GLKBaseEffect *dolphinEffect;
@property (readonly, nonatomic) SModelRepresentation dolphin;
@property (readonly, nonatomic) SIndVertAttribs dolphinMeshParams;

- (void) ResetData: (Terrain*) terr;
- (void) InitGeometry;
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) UpdateVertexArray:(GeometryShape*) mesh;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (GeometryShape*) meshDynamic : (Terrain*) terr : (Environment*) env : (Ocean*) ocean : (Particles*) particles;
- (void) RenderDynamic;
- (void) Render;

- (void) UpdateBflyEtalon: (float) dt;
- (void) ResetBfly: (SModelRepresentation*) c : (int) i : (Terrain*) terr;
- (void) InitNewBflyMove: (SModelRepresentation*) object :  (Terrain*) terr;

- (void)  ResetDolphin: (SModelRepresentation*) c : (Terrain*) terr;
- (void) UpdateDolphin: (SModelRepresentation*) object : (float) dt : (Terrain*) terr : (Ocean*) ocean;
- (void) InitNewDolphinMove: (SModelRepresentation*) object  : (Terrain*) terr;

- (void) ResourceCleanUp;


@end
