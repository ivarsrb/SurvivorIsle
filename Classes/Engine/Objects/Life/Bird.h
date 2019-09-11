//
//  Bird.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 28/09/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// Solid, moving object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Character.h"
#import "Egg.h"


@interface Bird : NSObject
{
    //crabs
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    //textures
    GLuint *texIDs;
    
    //effect
    GLKBaseEffect *effect;
    
    //index and vertex array attributes
    SIndVertAttribs bufferAttribs;
    
    //parameters
    float flightHeight;
    float flightRadius;
    float wingFlapSpeed;
}

@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;

- (void) ResetData: (Egg*) egg;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor: (Terrain*) terr : (Character*) character;
- (void) Render;
- (void) ResourceCleanUp;

- (void) ResetMovement: (SModelRepresentation*) c;
- (void) ScanForStartMovement: (SModelRepresentation*) c : (Character*) character;
- (void) StartMovement: (SModelRepresentation*) c : (Character*) character;
- (void) UpdateMovement: (float) dt : (SModelRepresentation*) c : (Terrain*) terr;
- (void) InitiateMove: (SModelRepresentation*) c : (GLKVector3) destPoint;

- (void) SetUpAnimation: (SModelRepresentation*) c;
- (void) StartAnimation: (SModelRepresentation*) c;
- (void) UpdateAnimation: (SModelRepresentation*) c : (float) dt;

@end
