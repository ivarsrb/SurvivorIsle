//
//  Interface.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// In-game interface management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleDirector.h"
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "Overlays.h"
#import "Terrain.h"
#import "Interaction.h"
#import "Environment.h"

@class Character;
@class Objects;

@interface Interface : NSObject
{
    Character *extCharacter;
    Overlays *overlays;
    
    //inventory slot coordinates
    SScreenCoordinates *slotCoordinates;
    SScreenCoordinates handCoordinates;
    SScreenCoordinates mouthCoordinates;
    
    //aditional parameters
    float itemIconS;
}

@property (strong, nonatomic) Character *extCharacter; //#DECIDE weak pointer here?
@property (strong, nonatomic) Overlays *overlays;
@property (nonatomic, readonly) SScreenCoordinates *slotCoordinates;
@property (nonatomic, readonly) SScreenCoordinates handCoordinates;
@property (nonatomic, readonly) SScreenCoordinates mouthCoordinates;


- (id) initWithParams: (Character*) chr;
- (void) ResetData: (Character*) chr;
- (void) NillData: (Character*) chr;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime;
- (void) Render: (Environment*) env;
- (void) ResourceCleanUp;

- (void) DetermineInventorySlotCoords;

- (BOOL) IsStartIconTouched: (CGPoint) tpos;
- (BOOL) IsJoystickTouched: (CGPoint) tpos;
- (BOOL) IsJoystickPressed: (UITouch*) touch;
- (BOOL) IsInventoryBoardTouched:(CGPoint) tpos;
- (BOOL) IsStrikeButtTouched: (CGPoint) tpos;
- (BOOL) IsStoneThrowButtTouched: (CGPoint) tpos;
- (BOOL) IsKnifeButtTouched: (CGPoint) tpos;
- (BOOL) IsLeafBlowButtTouched: (CGPoint) tpos;
- (BOOL) IsHandItemRemoveTouched:(CGPoint) tpos : (Objects*) objects;
- (BOOL) IsHandPlaceTouched:(CGPoint) tpos;
- (BOOL) IsFreeLookAllowed;
- (BOOL) IsMouthUsingTouched: (CGPoint) tpos;
- (BOOL) IsItemDroppingAllowed: (CGPoint) tpos;
- (BOOL) IsItemPickingAllowed: (CGPoint) tpos;;
- (BOOL) IsBeginRaftButtTouched: (CGPoint) tpos;
- (BOOL) IsFloatRaftButtTouched: (CGPoint) tpos;
- (BOOL) IsBeginShelterButtTouched: (CGPoint) tpos;
- (BOOL) IsDrillBoardTouched: (CGPoint) tpos;
- (BOOL) IsDrillBoardPressed: (UITouch*) touch;

- (void) SetBasicInterface;
- (void) SetFireDrillInterface;
- (void) SetSpearingInterface;
- (void) SetStoneThrowInterface;
- (void) SetLeafBlowInterface;
- (void) SetKnifeInterface;
- (void) SetRaftInterface;
- (void) SetDeathInterface;
- (void) SetRestingInterface;

- (void) HandFullBlink;
- (void) InvenotryFullBlink;
- (void) StartIndicatorSplashAt: (int) indicatorIndex : (BOOL) charging;

- (void) TouchMove: (UITouch*) touch : (CGPoint) tpos : (GLKVector3) spacePoint3D : (Objects*) objs : (Terrain*) terr  : (Interaction*) intrct;

@end
