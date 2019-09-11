//
//  SkyDome.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//  Sky system
//---------
// v.1.1. - meteor
//---------
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "GeometryShape.h"
#import "Character.h"
#import "CommonHelpers.h"

//object order numbers in lights mesh //#v1.1
enum _enumObjectOrder
{
    OO_SUN_OUTER,
    OO_SUN_INNER,
    OO_MOON,
    OO_STARS,
    OO_METEOR_LEFT,
    OO_METEOR_RIGHT,
    
    NUM_OBJECT_ORDERS
};
typedef enum _enumObjectOrder enumObjectOrder;


@interface SkyDome : NSObject
{    
    //geometry
    GeometryShape *skyMesh;
    GeometryShape *lightsMesh; //sun, moon etc
    
    //translation matrices
    GLKMatrix4 transMat, globalTransMat; //skydome
    
    //shaders
    GLKBaseEffect *effectSkyDome;
    GLKBaseEffect *effectSun;
    GLKBaseEffect *effectMiddSun;
    GLKBaseEffect *effectMoon;
    GLKBaseEffect *effectStar;
    GLKBaseEffect *effectMeteor; //#v1.1
    
    //sky
    int dtheta; //latitude pieces
    int dphi; //longitude pieces
    float radius; //radiuos of sky dome 
    //sky color palettes
    GLKVector4 middayPlt[10], eveningPlt[10], nightPlt[10], morningPlt[10]; 
    
    //sun
    SModelRepresentation sun;
    //GLKVector4 sunMiddayColor, sunEveningColor, sunMorningColor;
    SDaytimeColors sunColoring; //#v1.1.
    
    //moon
    SModelRepresentation moon;
    //stars
    int starCount;
    SModelRepresentation *starCollection;
    //meteor //#v1.1
    SModelRepresentation meteor;
    float meteorHalf;
}
@property (strong, nonatomic) GeometryShape *skyMesh;
@property (strong, nonatomic) GeometryShape *lightsMesh;
@property (strong, nonatomic) GLKBaseEffect *effectSkyDome;
@property (strong, nonatomic) GLKBaseEffect *effectSun;
@property (strong, nonatomic) GLKBaseEffect *effectMiddSun;
@property (strong, nonatomic) GLKBaseEffect *effectMoon;
@property (strong, nonatomic) GLKBaseEffect *effectStar;
@property (strong, nonatomic) GLKBaseEffect *effectMeteor;
@property (readonly, nonatomic) SModelRepresentation sun;


- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (Character*) character;
- (void) Render;
- (void) ResetData: (Environment*) env;

- (void) InitSkyGeometry;
- (void) InitSkyColors;
- (void) UpdateSky:(float) curTime;

- (void) InitLightsGeometry;
- (void) UpdateSun:(float) curTime;
- (void) UpdateMoon:(float) curTime;
- (void) UpdateStars:(float) dt;
- (void) UpdateMeteor: (float) curTime : (float) dt;

- (GLKVector4) ChangeColor:(GLKVector4) col :  (GLKVector4) change;
- (void) ResourceCleanUp;
- (GLKVector3) GetCharacterLightVector: (Character*) character;
- (void) ModifyColoringByViewVector: (GLKVector4*) coloring : (Character*) character;
@end
