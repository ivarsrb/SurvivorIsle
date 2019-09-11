//
//  Knife.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 02/06/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Solid interactive object, single entity

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "ObjectHelpers.h"
#import "GeometryShape.h"
#import "Character.h"
#import "Inventory.h"
#import "Particles.h"
#import "SmallPalm.h"
#import "Interaction.h"
#import "Terrain.h"

@interface Knife : NSObject
{
    SModelRepresentation knife;
    
    ModelLoader *modelBlade; //dynamic texture
    ModelLoader *modelHandle;
    
    //effect
    GLKBaseEffect *effectBlade;
    GLKBaseEffect *effectHandle;
    
    //index and vertex rray attributes
    SIndVertAttribs bufferAttribs;

    //parameters
    GLKVector3 initialDisplacePosition; //initial knife position displace (relative space) in hand
    GLKVector3 initialKnifeTip; //point against to check for cutting
    float initialExtraAngleX; //initial extra angle around X axis
    
    BOOL somethingCut; //used to allow to cut only one thing at a time
    
    //blade texture parameters
    GLKVector3 backupPosition; //knife position in previous step
}

@property (readonly, nonatomic) SModelRepresentation knife;
@property (strong, nonatomic) ModelLoader *modelBlade;
@property (strong, nonatomic) ModelLoader *modelHandle;
@property (strong, nonatomic) GLKBaseEffect *effectBlade;
@property (strong, nonatomic) GLKBaseEffect *effectHandle;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float) dt : (GLKMatrix4*) modelviewMat : (Character*) character : (GLKVector4) daytimeColor : (Particles*) particles : (SmallPalm*) smallpalms : (Interaction*) inter : (GeometryShape*) meshDynamic;
- (void) Render;
- (void) RenderDynamic;
- (void) ResourceCleanUp;

- (void) StartCut;
- (void) UpdateCut: (float) dt : (Character*) character : (GLKVector3*) displacePosition : (GLKVector3*) motionAngle;
- (void) UpdateDynamicVertexArray: (GeometryShape*) mesh;
- (GLKVector3) GetKnifeTip: (float) extraOrientationY;

- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter : (Particles*) particles ;
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*)intct  : (Interface*) inter;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct;
- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character;
@end
