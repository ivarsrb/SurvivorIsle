//
//  Shelter.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 06/05/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
//  Shelter module, solid interactive objectt


#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleSound.h"
#import "SingleGraph.h"
#import "CommonHelpers.h"
#import "ModelLoader.h"
#import "GeometryShape.h"
#import "Character.h"
#import "Interface.h"
#import "Interaction.h"
#import "Particles.h"

//shelter states
enum _enumShelterStates
{
    SS_NONE, //not started building
    SS_BUILDING, //started building
    SS_DONE, //done
};
typedef enum _enumShelterStates enumShelterStates;


@interface Shelter : NSObject
{
    SModelRepresentation shelter;
    
    ModelLoader *model;
    
    GLKBaseEffect *effect;
    
    //texture
    GLuint *textures;
    GLuint ghostTex;
    //objects
    NSMutableArray *objectIDs; //store object names and their numbers (separated by _)
    
    //index and vertex rray attributes
    SIndVertAttribs bufferAttribs;
    
    //parameters
    enumShelterStates state;
    SLimitedInt leafCount; //how many leafs are attached to shelter at this moment and maximal value
    SLimitedInt stickCount; //how many sticks are attached to shelter at this moment and maximal value
    SCircle entranceCrircle; //circle where entrance to shelter will be
    GLKMatrix4 indicatorRotMat;
}

@property (readonly, nonatomic) SModelRepresentation shelter;
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;
@property (readonly, nonatomic) NSMutableArray *objectIDs;
@property (readonly, nonatomic) enumShelterStates state;
@property (readonly, nonatomic) SCircle entranceCrircle;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float)dt : (float)curTime : (GLKMatrix4*) modelviewMat  : (GLKVector4) daytimeColor : (GLKVector4) nonAffectedDaytimeColor : (Character*) character : (Terrain*) terr : (Interface*) intr : (Interaction*) interaction;
- (void) Render;
- (void) RenderTransparent : (Character*) character;
- (void) ResourceCleanUp;

- (BOOL) ObjectVisible: (int) i;
- (BOOL) ObjectVisibleAsGhost: (int) i;
- (BOOL) ObjectVisibleIndicator: (int) i;
- (GLKVector3) GetPotentialShelterPlace: (Character*) character;
- (void) EnterShelter: (Character*) character : (Interface*) intr;
- (void) LeaveShelter: (Character*) character : (Interface*) intr : (Interaction*) interaction;

- (BOOL) PuttingSticksAllowed: (GLKVector3) point;
- (BOOL) PuttingLeavesAllowed: (GLKVector3) point;
- (void) AddStick: (Particles*) particles;
- (void) AddLeave: (Particles*) particles;

- (void) UpdateShelterInterface:(Character*) character: (Interface*) intr: (Terrain*) terr : (Interaction*) interaction;
- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (Terrain*) terr : (Interaction*) interaction : (Particles*) particles;
@end

