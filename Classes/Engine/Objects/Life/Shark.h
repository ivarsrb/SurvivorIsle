//
//  Shark.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/10/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// Solid interactive object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Character.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "Terrain.h"
#import "Ocean.h"

@interface Shark : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //index and vertex array attributes
    SIndVertAttribs bufferAttribs;
    
    //attributes
    SCircle sharkCr;
    float floatHeight;
    
    float *rotationFactor; //for vertices
}
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;


- (id) initWithParams: (Terrain*) terr : (Ocean*) ocean;
- (void) ResetData;
- (void) InitGeometry: (Terrain*) terr : (Ocean*) ocean;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) UpdateVertexArray: (GeometryShape*) mesh;
- (void) SetupRendering;
- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (Character*) character : (GeometryShape*) mesh;
- (void) Render;
- (void) ResourceCleanUp;
- (BOOL) StrikeSharkCheck: (GLKVector3) spearPos;
- (void) CalculateTurnAngle: (SModelRepresentation*) c;
- (void) ResetShark: (SModelRepresentation*) c : (int) i;
- (void) UpdateShark: (SModelRepresentation*) c : (float) dt : (Terrain*) terr : (Character*) character;
- (void) ForceRunaway: (SModelRepresentation*) c;
@end
