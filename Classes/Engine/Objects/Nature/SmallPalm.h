//
//  SmallPalm.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/05/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Static pickable object, ment for shelter

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"
#import "Environment.h"
#import "SingleSound.h"
#import "Character.h"
#import "Interface.h"

@interface SmallPalm : NSObject
{
    int count; //number of smallpalms
    int branchesPerPalm; //how many branches per palm
    int brancheCount; //number of smallpalm leafs in game, added together
    SModelRepresentation *collection; //trunk (smallpalm collection)
    SModelRepresentation *brancheCollection; //collection of individual branches
    //SBranchAnimation *brancheAnim; //branche animation
    
    //models
    ModelLoader *modelTrunk;
    ModelLoader *modelBranch;
    
    //effect
    GLKBaseEffect *effectTrunk;
    GLKBaseEffect *effectBranch;
    
    //index and vertex rray attributes
    SIndVertAttribs bufferAttribsTrunk;
    SIndVertAttribs bufferAttribsBranch;
    
    float swingTime;
}

@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SModelRepresentation *brancheCollection;
@property (strong, nonatomic) ModelLoader *modelTrunk;
@property (strong, nonatomic) ModelLoader *modelBranch;
@property (strong, nonatomic) GLKBaseEffect *effectTrunk;
@property (strong, nonatomic) GLKBaseEffect *effectBranch;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribsTrunk;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribsBranch;


- (void) PresetData;
- (void) ResetData: (Terrain*) terr : (Interaction*) intr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Environment*) env;
- (void) Render;
- (void) ResourceCleanUp;
- (void) UpdateBranchesSway: (float) dt : (BOOL) storm;
- (BOOL) CheckBranchCutting: (GLKVector3) knifePoint : (GLKVector3*) branchOrigin;
- (void) CutBranch: (int) branchInd;
- (void) UpdateBrancheFalling: (int) branchInd : (float) dt;
- (BOOL) IsTrunkEmpty: (int) trunkId;
- (GLKVector3) GetPointAboveLeafOrigin: (int) leafIndex : (float) aboveOrigin;

- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character  : (Interface*) inter;

@end
