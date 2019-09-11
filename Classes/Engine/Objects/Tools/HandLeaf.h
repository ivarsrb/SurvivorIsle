//
//  HandLeaf.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 20/06/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Solid interactive object
// Used to display small palm leaves that are dropped on ground after picking and holding in hand

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "ObjectHelpers.h"
#import "ObjectPhysics.h"
#import "Character.h"
#import "Interface.h"
#import "Terrain.h"
#import "Interaction.h"
#import "Particles.h"
#import "CampFire.h"
#import "Beehive.h"

@interface HandLeaf : NSObject
{
    int count;
    SModelRepresentation *collection;
    
    ModelLoader *model;
    
    GLKBaseEffect *effect;
    
    //index and vertex rray attributes
    SIndVertAttribs bufferAttribs;
    
    //parameters
    BOOL waved; //hold value of weather already waved in this wave (to check particles etc)
    float smokeEffect; //0.0-1.0 curent effect of smoke from one to maximum 
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;
@property (readonly, nonatomic) int count;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Terrain*) terr : (Interaction*) inter : (Particles*) particles : (CampFire*) campfire : (Beehive*) beehive;
- (void) Render;
- (void) ResourceCleanUp;

- (BOOL) IsLeafInHand;
- (BOOL) IsLeafInSwing;

- (void) StartBlow: (SModelRepresentation*) c;
- (void) UpdateBlow: (SModelRepresentation*) c : (float) dt : (Particles*) particles : (Character*) character : (Terrain*) terr : (CampFire*) campfire;
- (GLKVector3) GetParticlePosition: (Character*) character;

- (void) StartBlowDustParticles: (SModelRepresentation*) c : (Terrain*) terr : (Particles*) particles : (Character*) character;
- (void) StartBlowSmokeParticles: (Terrain*) terr : (Particles*) particles : (Character*) character : (CampFire*) campfire;
- (void) ResetSmokeBlow: (Particles*) particles : (Character*) character : (CampFire*) campfire;
- (void) UpdateSmoke: (float) dt : (Particles*) particles : (CampFire*) campfire;

- (BOOL) IsObjectSmoked: (GLKVector3) objPosition : (Particles*) particles;

- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter;
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*)intct  : (Interface*) inter;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct;
- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character;
@end
