//
//  Stone.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 30/03/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Solid, interactive objects for throwing
// v.1.1.

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "ObjectHelpers.h"
#import "Character.h"
#import "Interface.h"
#import "Terrain.h"
#import "Cocos.h"
#import "PalmTree.h"
#import "ObjectPhysics.h"
#import "Interaction.h"
#import "Particles.h"
#import "Ocean.h"

@interface Stone : NSObject
{
    int count;
    SModelRepresentation *collection;

    ModelLoader *model;
    
    GLKBaseEffect *effect;
    
    //index and vertex rray attributes
    SIndVertAttribs bufferAttribs;
    
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;

- (void) PresetData;
- (void) ResetData:(Terrain*) terr: (Interaction*) intr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Terrain*) terr : (Interaction*) inter : (Particles*) particles : (Ocean*) ocean;
- (void) Render;
- (void) ResourceCleanUp;

- (void) Throw: (SModelRepresentation*) c : (Character*) character;
- (void) CollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (Interaction*) inter : (Particles*) particles : (Ocean*) ocean : (Character*) character;

- (BOOL) IsStoneInHand;
- (void) PlaceOnBeach: (SModelRepresentation*) c : (Terrain*) terr : (Interaction*) intr;

- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter;
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*) intct : (Interface*) inter;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct;
- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character;
@end
