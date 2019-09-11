//
//  Terrain.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Terrain management class, conserning relief

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "ShaderLoader.h"
#import "ModelLoader.h"

@class Clouds;
@class Character;
@class SkyDome;

@interface Terrain : NSObject
{
    //shader programm
    //take 2 textures and mixes them by vertex alpha
    GLuint programMixAlpha;
    //unifrm array
    GLint uniformsMixAlpha[NUM_UNIFORMS];
    
    //dimensions of terrain
    int hfWidth;
    float scaleFactor;
    float **heightField;
    CGRect islandRect;
    SCircle inlandCircle;
    SCircle grassCircle;
    SCircle islandCircle; 
    SCircle middleCircle; 
    SCircle oceanLineCircle; 
    SCircle majorCircle;
    float scaleDownFactor;
    
    //geometry
    GeometryShape *terrainMesh;
    
    //underplate geometry
    GeometryShape *underplateMesh;
    GLKBaseEffect *effectUnderplate;
    
    //texture IDs
    GLuint grassTexID;
    GLuint sandTexID;
    
    //day/night coloring
    //GLKVector4 dayTimeColor;
    //GLKVector4 middayColor, eveningColor, nightColor, morningColor;
    SDaytimeColors coloring; //#v1.1.
}
//textures
@property (strong, nonatomic) GeometryShape *terrainMesh;
@property (strong, nonatomic) GeometryShape *underplateMesh;
@property (readonly, nonatomic) int hfWidth;
@property (readonly, nonatomic) float scaleFactor;
@property (readonly, nonatomic) CGRect islandRect;
@property (readonly, nonatomic) SCircle islandCircle;
@property (readonly, nonatomic) SCircle inlandCircle;
@property (readonly, nonatomic) SCircle middleCircle; 
@property (readonly, nonatomic) SCircle oceanLineCircle;
@property (readonly, nonatomic) SCircle majorCircle;
@property (readonly, nonatomic) SCircle grassCircle;
@property (strong, nonatomic) GLKBaseEffect *effectUnderplate;
//@property (readonly, nonatomic) GLKVector4 dayTimeColor;
@property (readonly, nonatomic) SDaytimeColors coloring;

- (void) InitGeometry;
- (void) SetupRendering;
- (void) Render:(float*) mvpMat;
- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat  : (Clouds*) clouds : (Character*) character  : (SkyDome*) sky;
- (void) LoadHMFromFile: (NSString*) filename;
- (float) GetHeightByPoint: (GLKVector3 *) pos;
- (void) GetHeightByPointAssign: (GLKVector3 *) pos;
- (void) AdjustModelEndPoints: (SModelRepresentation*) m : (ModelLoader*) model;
- (BOOL) IsInland:(GLKVector3) position;
- (BOOL) IsBeach:(GLKVector3) position;
- (BOOL) IsOcean:(GLKVector3) position;
- (BOOL) IsBeachOcean:(GLKVector3) position;
- (void) ResourceCleanUp;

- (BOOL) PointHitsGround: (GLKVector3) p1;
- (BOOL) ObjectHitsGround: (GLKVector3) center : (float) radius;
- (GLKVector3) GetCollisionPoint: (GLKVector3) p1 : (GLKVector3) p2;
- (BOOL) HasCollided: (GLKVector3) p1 : (GLKVector3) p2 : (GLKVector3*) collisionPoint;
@end
