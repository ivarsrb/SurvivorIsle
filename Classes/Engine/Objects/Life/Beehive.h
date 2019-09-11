//
//  Beehive.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 15/07/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Bee hive  - interactive solid object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "Terrain.h"
#import "PalmTree.h"
#import "ParticleEffect.h"
#import "Character.h"
#import "Interface.h"

@interface Beehive : NSObject
{
    SModelRepresentation hive; //insect house 
    SModelRepresentation beeswarm; //insect swarm as a whole (for position)
    SModelRepresentation *insects;//array to hold info about every bee
    ModelLoader *model;
    SBasicAnimation stingInterval; //varable to regulate bee sting frequencee
    
    //effect
    GLKBaseEffect *effect;
    
    //index and vertex array attributes
    SIndVertAttribs bufferAttribs;
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation hive;
@property (readonly, nonatomic) SModelRepresentation beeswarm;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;
@property (readonly, nonatomic) SModelRepresentation *insects;

- (void) ResetData: (Terrain*) terr : (PalmTree*) palms;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update :(float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Particles*) particles : (Character*) character :  (Interface*) intr;
- (void) Render;
- (void) ResourceCleanUp;
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Inventory*) inv;
- (void) SmokeBeehive;
- (void) InitBeeMovementVectors;
- (void) UpdateBeeMovement : (float) dt : (Particles*) particles : (Character*) character :  (Interface*) intr;
@end
