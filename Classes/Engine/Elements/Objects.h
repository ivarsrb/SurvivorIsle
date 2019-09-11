//
//  Objects.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Interactive and non-interactive objects
// Objects are small graphicall enitites

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Character.h"
#import "Cocos.h"
#import "PalmTree.h"
#import "Bush.h"
#import "Grass.h"
#import "Leaves.h"
#import "DryGrass.h"
#import "BerryBush.h"
#import "CampFire.h"
#import "HandSpear.h"
#import "Fish.h"
#import "Stick.h"
#import "RainCatch.h"
#import "Shell.h"
#import "Crab.h"
#import "Shipwreck.h"
#import "FlatRock.h"
#import "DeadfallTrap.h"
#import "StickTrap.h"
#import "Rat.h"
#import "Environment.h"
#import "Interface.h"
#import "Ocean.h"
#import "Interaction.h"
#import "Log.h"
#import "Rag.h"
#import "Raft.h"
#import "Wildlife.h"
#import "Clouds.h"
#import "Stone.h"
#import "Particles.h"
#import "Shelter.h"
#import "SmallPalm.h"
#import "Knife.h"
#import "HandLeaf.h"
#import "SkyDome.h"
#import "Beehive.h"
#import "SeaUrchin.h"
#import "Egg.h"
#import "Bird.h"
#import "Shark.h"

@interface Objects : NSObject
{
    //geometry
    GeometryShape *objectMesh;
    GeometryShape *dynamicObjectMesh;
    
    //objects
    //solid
    HandSpear *handSpear;
    Cocos *cocos;
    Stick *sticks;
    Fish *fishes;
    Shell *shells;
    Crab *crabs;
    FlatRock *flatRocks;
    Shipwreck *shipwreck;
    DeadfallTrap *deadfallTraps;
    StickTrap *stickTraps;
    Rat *rats;
    Log *logs;
    Rag *rags;
    Raft *raft;
    Wildlife *wildlife;
    Stone *stone;
    Shelter *shelter;
    SmallPalm *smallPalm;
    Knife *knife;
    HandLeaf *handLeaf;
    Beehive *beehive;
    SeaUrchin *seaUrchin;
    Egg *egg;
    Bird *bird;
    Shark *shark;
    
    //transaprent
    PalmTree *palms;
    Bush *bushes;
    Grass *grass;
    DryGrass *dryGrass;
    BerryBush *berryBush;
    Leaves *leaves;
    CampFire *campFire;
    RainCatch *rainCatch;
    
    //day/night coloring
    SDaytimeColors coloring;
}
@property (strong, nonatomic) GeometryShape *objectMesh;
@property (strong, nonatomic) GeometryShape *dynamicObjectMesh;
@property (strong, nonatomic) HandSpear *handSpear;
@property (strong, nonatomic) Cocos *cocos;
@property (strong, nonatomic) Stick *sticks;
@property (strong, nonatomic) Fish *fishes;
@property (strong, nonatomic) PalmTree *palms;
@property (strong, nonatomic) Bush *bushes;
@property (strong, nonatomic) Grass *grass;
@property (strong, nonatomic) DryGrass *dryGrass;   
@property (strong, nonatomic) BerryBush *berryBush;
@property (strong, nonatomic) Leaves *leaves;
@property (strong, nonatomic) CampFire *campFire;
@property (strong, nonatomic) RainCatch *rainCatch;
@property (strong, nonatomic) Shell *shells;
@property (strong, nonatomic) Crab *crabs;
@property (strong, nonatomic) FlatRock *flatRocks;
@property (strong, nonatomic) Raft *raft;
@property (strong, nonatomic) Log *logs;
@property (strong, nonatomic) Rag *rags;
@property (strong, nonatomic) Shipwreck *shipwreck;
@property (strong, nonatomic) DeadfallTrap *deadfallTraps;
@property (strong, nonatomic) StickTrap *stickTraps;
@property (strong, nonatomic) Rat *rats;
@property (strong, nonatomic) Wildlife *wildlife;
@property (strong, nonatomic) Stone *stone;
@property (strong, nonatomic) Shelter *shelter;
@property (strong, nonatomic) SmallPalm *smallPalm;
@property (strong, nonatomic) Knife *knife;
@property (strong, nonatomic) HandLeaf *handLeaf;
@property (strong, nonatomic) Beehive *beehive;
@property (strong, nonatomic) SeaUrchin *seaUrchin;
@property (strong, nonatomic) Egg *egg;
@property (strong, nonatomic) Bird *bird;
@property (strong, nonatomic) Shark *shark;

- (id) initWithObjects: (Terrain*) terr: (Ocean*) ocean;
- (void) ResetData: (Terrain*) terr : (Interaction*) intr : (Environment*)env;
- (void) InitGeometry:  (Terrain*) terr: (Ocean*) ocean;
- (void) SetupRendering;
- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (Terrain*) terr : (Character*) character : (Interface*) intr : (Environment*) env :
                 (Ocean*) ocean : (Interaction*) interaction : (Clouds*) clouds : (Particles*) particles : (SkyDome*) sky;
- (void) RenderSolid:(Character*) character;
- (void) RenderTransparent : (Character*) character;
- (void) RenderDynamicSolid;
- (void) RenderDynamicTransparent:(Environment*) env;
- (void) ResourceCleanUp;

@end
