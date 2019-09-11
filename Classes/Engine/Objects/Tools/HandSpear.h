//
//  HandSpear.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
// Spear in hand
// Solid interactive object, animated

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Character.h"
#import "Inventory.h"
#import "Particles.h"
#import "Ocean.h"
         


@class Fish;
@class Shark;

@interface HandSpear : NSObject
{
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //transform matrices
    GLKMatrix4 prePositionMatrix;
    GLKMatrix4 mdvMatrix;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    
    //speac configuration
    GLKVector3 spearTip; //tip of spear
    float distanceFromChar; //how far away spear tip is located from char
    float downFromEyes; //how far lower spear tip will be below eyes
    float sideAngle; //spear is shifted to side
    float tiltAngleBase; //spear is tilted about x Axis in still positions
    float tiltAngleDest; //destination strike point tilt angle
    float tiltAngle; //tilt angle currently
    
    //strike parameters
    BOOL striking; //weather is in striking mode
    BOOL strikeDown; //spear moves down/up
    float strikeTime; //how long strink lasts
    float timeStruck; //how long current strike lasts
    float strikeDistance; ///strike distance from spear initial tip to strike pint
    GLKVector3 strikeMovement; //movement parameters of strike
    GLKVector3 strikePoint; //point to which spear strikes
    GLKVector3 distFromCharToStrike; //used only to help move speartip together with char movement while striking
    float angleYAtStrike; //used only to change striking point when rotating view about y axis
    BOOL fishStruck; //if fish is struck
}
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) GLKVector3 spearTip;
@property (readonly, nonatomic) BOOL striking;
@property (readonly, nonatomic) BOOL strikeDown;
@property (readonly, nonatomic) BOOL fishStruck;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt : (GLKMatrix4*) modelviewMat : (Character*) character : (Fish*) fishes :(GLKVector4) daytimeColor : (Particles*) particles : (Ocean*) ocean : (Shark*) shark;
- (void) Render: (Character*) character;
- (void) ResourceCleanUp;
- (void) Strike: (Character*) character : (GLKVector3) strikePos;
- (void) Stop;
- (BOOL) TranslateBetweenPoints:(GLKVector3) stPoint : (GLKVector3) endPoint : (float) actionTime : (float*) timeInAction : (float) dt : (bool) backWard :(GLKVector3*) result;

- (BOOL) TouchBegin:(UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (GLKMatrix4*) modvMat : (int*) viewpParams;
@end
