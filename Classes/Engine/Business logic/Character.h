//
//  Character.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// User character properties un management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "CommonHelpers.h"
#import "Inventory.h"
#import "Camera.h"
#import "Interface.h"
#import "Interaction.h"
#import "Terrain.h"
#import "Environment.h"


@class Objects;
@class Particles;

@interface Character : NSObject
{
    //character states
    enumCharacterStates state;
    enumCharacterStates prevState; //in order to back-track
    enumCharacterStates prevStateInformative; //to always be able to see previous state, prevState doest always show us that because it is ment to backtrack
    
    //with properties
    Camera *camera;
    Inventory *inventory;
    SInventoryItem handItem; //item tht is currently in hand 
    SInventoryItem prevHandItem; //item that was in hand before state change, so we can turn back
    
    enumInjuryTypea lastInjury; //type of injury that was receved previous time
    /*
    int movementFlag;
    float movementSpeed;    
    int strafeFlag;
    float strafeSpeed;
    */
    GLKVector3 movementV; //used for character movement, controling movement by joystick
    float movementMultiplierY; //relativ speed in Y direction
    float movementMultiplierX; //relativ speed in X direction
    float stepImitation; //value for imitating up/down step movement while character moves
    float height;
    float sitHeight; //height while sitting
    
    //general health
    float health; //from 0.0 - 1.0, physical health of character (responds to injuries)
    
    //managable indicators
    float nutrition; //levels of nutrition 0 - 1
    float hydration; //levels of hydration 0 - 1
    float hydDecr,nutDecr; //hydration and food decr factor
    
    //touch related parameters
    //freelook
    CGPoint freeLookTchStart;
    UITouch *freeLookTouch;
}
@property (readonly, nonatomic) enumCharacterStates state;
@property (readonly, nonatomic) enumCharacterStates prevStateInformative;
@property (strong, nonatomic, readonly) Camera *camera;
@property (strong, nonatomic) Inventory *inventory;
@property (nonatomic) SInventoryItem handItem;
@property (nonatomic,readonly) SInventoryItem prevHandItem;
@property (nonatomic, readonly) GLKVector3 movementV;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) float sitHeight;
@property (nonatomic) float nutrition;
@property (nonatomic) float hydration;
@property (nonatomic, readonly) float health;
@property (strong, nonatomic) UITouch *freeLookTouch;

- (void) NillData: (Environment*) env; 
- (void) ResetData:(Terrain*) terr : (Environment*) env;
- (void) Rotate: (CGPoint) tchStart : (float)X : (float)Y : (float) dt;
- (void) Update: (float) dt : (Interaction*) interaction : (Interface*) intr;
- (void) ResourceCleanUp;
- (void) setState:(enumCharacterStates) s;
- (void) SetPreviousState: (Interface*) intr;

- (void) Die: (Interaction*) interaction : (Interface*) intr;

- (void) RestoreHealth;
- (void) IncreaseHealth: (float) dt : (Interface*) intr;
- (void) DecreaseHealth: (float) decrement :  (Interface*) intr : (int) injuryType;

- (void) EatDrinkItem: (enumInventoryItems) itemType :  (Interface*) intr;
- (BOOL) IsMoving;
- (BOOL) IsRunning;
- (void) NillMovement;
- (BOOL) PickItemHand: (Interface*) intr : (enumInventoryItems) type;
- (void) SetInterfaceByHandItem: (Interface*) intr : (enumInventoryItems) type;
- (void) ClearHand;

- (void) JoystickBegin: (UITouch*) touch : (Interface*) intr: (Objects*) objects : (Interaction*) interaction;
- (void) JoystickMove: (CGPoint) touchLocation : (Interface*) intr;
- (void) JoystickEnd: (UITouch*) touch : (Interface*) intr;

- (void) TouchBegin:(UITouch*) touch : (Interface*) intr :  (Objects*) objects : (Interaction*) interaction;
- (void) TouchMove:(UITouch*) touch : (Interface*) intr : (float) dt : (int*) movedType;
- (BOOL) TouchEnd:(UITouch*) touch : (Interface*) intr : (Objects*) objects : (Particles*) particles : (int*) droppedType : (GLKVector3) spacePoint : (GLKVector3) spacePoint3D ;
@end
