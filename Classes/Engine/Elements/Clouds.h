//
//  Clouds.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Cloud rendering and upper weathe effects

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "Character.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "Environment.h"

@interface Clouds : NSObject
{
    //geometry
    GeometryShape *cloudMesh;
    
    //cloud parameters
    int count;
    int cloudVertexCount;
    SModelRepresentation *collection;
    float cloudHeight; //maximal height of clouds (just above heads)
    float radius; //radius of cloud dome (except top, because top is defined by cloudHeight)
    STextureAtlas textureAtlas[4]; //texture coordinates in atlas
    
    //translation matrices
    GLKMatrix4 transMat, globalTransMat; 
    
    //effects
    GLKBaseEffect *effectClouds;
    
    //daytime coloring
    //GLKVector4 dayTimeColor;
    //GLKVector4 middayColor, eveningColor, nightColor, morningColor;
    SDaytimeColors coloring; //#v1.1.
    
    
    //lightning
    int lightningVertexCount;
    int iluminationVertexCount;
    SModelRepresentation lightning;
    SBasicAnimation lightningStrike;
    GLKBaseEffect *effectLightning;
    GLKBaseEffect *effectIlumination;
    SDaytimeColors lightningIllumination; //ambient (other objects) color that lightning produces
   // int visCounter;
}
@property (strong, nonatomic) GeometryShape *cloudMesh;
@property (strong, nonatomic) GLKBaseEffect *effectClouds;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (strong, nonatomic) GLKBaseEffect *effectLightning;
@property (strong, nonatomic) GLKBaseEffect *effectIlumination;
@property (readonly, nonatomic) SBasicAnimation lightningStrike;
@property (readonly, nonatomic) SModelRepresentation lightning;
@property (readonly, nonatomic) SDaytimeColors lightningIllumination;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) float radius;

- (void) ResetData;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (Character*) character : (Environment*) env;
- (void) Render;
- (void) ResourceCleanUp;

- (void) UpdateClouds:(float)dt :(Environment*) env;
- (void) UpdateVertexBuffer:(BOOL) firstTime;
- (void) HideOverLappedClouds: (int) currCloud;
- (void) ShowHiddenCloud: (SModelRepresentation*) c;
- (void) InitTeztureAtlas;
- (void) InitCloudParams;
- (float) GetHeightOnCloudSphere : (GLKVector3) pos : (float*) distance;

- (void) InitLightningParams;
- (void) InitLightningGeometry;
- (void) UpdateLightning: (float) dt;
- (BOOL) LightningInProximity: (float) dt;
@end
