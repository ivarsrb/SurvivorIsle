//
//  Interface.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: -

#import "Interface.h"
#import "Character.h"
#import "Objects.h"

@implementation Interface
@synthesize  extCharacter, slotCoordinates, handCoordinates, mouthCoordinates, overlays;


- (id) initWithParams: (Character*) chr
{
    self = [super init];
    if (self != nil) 
    {
        extCharacter = chr;
        //interface lements
        overlays = [[Overlays alloc] initWithParams:chr];
        
        slotCoordinates = malloc(chr.inventory.slotCount * sizeof(SScreenCoordinates));
        
        [self DetermineInventorySlotCoords];
    }
    return self;
}

//data that chages from game to game (only new game)
- (void) ResetData: (Character*) chr
{
    [[SingleDirector sharedSingleDirector] setInterfaceType: IT_NONE]; //set to NONE here because BASIC will be set in SetBasicInterface
    //init interface state
    [self SetBasicInterface];
    [self NillData:chr];
    
    [overlays ResetData:chr];
    
    //show start instructions icon every time game neters from main menu, will be hidden aftr tapping
    [overlays SetInterfaceVisibility: INT_START_ICON: YES];
}

//data that should be nilled every time game is eneterd from menu screen (no mater new or continued)
- (void) NillData: (Character*) chr
{
    [overlays NillData:chr];
}

- (void) InitGeometry
{
    [overlays InitGeometry];
}

- (void) SetupRendering
{
    [overlays SetupRendering];
}

- (void) Update:(float)dt: (float)curTime
{
    //change energy indicators color depending on their value
    Button *nutritionIndcIcon = [overlays.interfaceObjs objectAtIndex: INT_NUTRITION_IND];
    Button *hydrationIndcIcon = [overlays.interfaceObjs objectAtIndex: INT_HYDRATION_IND];
    Button *injuryIndcIcon = [overlays.interfaceObjs objectAtIndex: INT_INJURY_IND];
    
    if(extCharacter.nutrition > 0.0 && extCharacter.hydration > 0.0 && extCharacter.health > 0.0)
    {
        //indicator color turns red when levels approach dangerous level
        //NUTRITION
        nutritionIndcIcon->backColor.r = 1.0;
        nutritionIndcIcon->backColor.g = nutritionIndcIcon->backColor.b = extCharacter.nutrition;
        //HYDRATION
        hydrationIndcIcon->backColor.r = 1.0;
        hydrationIndcIcon->backColor.g = hydrationIndcIcon->backColor.b = extCharacter.hydration;
        //INJURY HEALTH
        injuryIndcIcon->backColor.r = 1.0;
        injuryIndcIcon->backColor.g = injuryIndcIcon->backColor.b = extCharacter.health;
        
        
        //blink indicator if it is about to die
        //NUTRITION
        if(extCharacter.nutrition < ENERGY_SAFE_LIMIT && extCharacter.state != CS_RAFT)
        {
            [nutritionIndcIcon StartFlicker];
        }else
        {
            [nutritionIndcIcon EndFlicker];
        }
        //HYDRATION
        if(extCharacter.hydration < ENERGY_SAFE_LIMIT  && extCharacter.state != CS_RAFT)
        {
            [hydrationIndcIcon StartFlicker];
        }else
        {
            [hydrationIndcIcon EndFlicker];
        }
        //INJURY HEALTH
        if(extCharacter.health < INJURY_SAFE_LIMIT && extCharacter.state != CS_RAFT)
        {
            [injuryIndcIcon StartFlicker];
        }else
        {
            [injuryIndcIcon EndFlicker];
        }
        
        //if started floating hide in case it flickered after
        if(extCharacter.state == CS_RAFT)
        {
            [overlays SetInterfaceVisibility: INT_NUTRITION_IND: NO];
            [overlays SetInterfaceVisibility: INT_HYDRATION_IND: NO];
            [overlays SetInterfaceVisibility: INT_INJURY_IND: NO];
        }
    }else
    {
        //died
        [nutritionIndcIcon EndFlicker];
        [hydrationIndcIcon EndFlicker];
        [injuryIndcIcon EndFlicker];
        
        //if indicator is minimal turn it black
        if(extCharacter.nutrition <= 0)
        {
            nutritionIndcIcon->backColor = GLKVector4Make(0, 0, 0, nutritionIndcIcon->backColor.a);
        }
        if(extCharacter.hydration <= 0)
        {
            hydrationIndcIcon->backColor = GLKVector4Make(0, 0, 0, hydrationIndcIcon->backColor.a);
        }
        if(extCharacter.health <= 0)
        {
            injuryIndcIcon->backColor = GLKVector4Make(0, 0, 0, injuryIndcIcon->backColor.a);
        }
    }

    [overlays Update: extCharacter: dt];
}

- (void) Render: (Environment*) env
{
    [overlays Render: extCharacter : slotCoordinates : handCoordinates : mouthCoordinates: env];
}

- (void) ResourceCleanUp
{
    free(slotCoordinates);
    self.extCharacter = nil;
    [overlays ResourceCleanUp];
}


#pragma mark -  Inventory items


//determine inventory slot coordinates in relative and screen space
//for standard iphone, ipad, all slots follow eac other [][][][m][h][][][]
//for long iphone - hand and moputh are seprated from inventory slots by half a slot [][][] [m][h] [][][]
- (void) DetermineInventorySlotCoords
{
    float itemGap = overlays.itemSize.relative.size.width;
    
    int column = 0;
    for(int i = 0; i < extCharacter.inventory.slotCount; i++) 
    {
        if(i == extCharacter.inventory.slotCount / 2)
        {
            float extraHandMouthGap = 0;
            //for long iphone add extra gaps between slots and hand/ mouth
            if([[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_5 ||
               [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6 ||
               [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6_PLUS)
            {
                extraHandMouthGap = itemGap / 2.0;
            }
            //hand
            //relative
            mouthCoordinates.relative.origin = CGPointMake(column * itemGap + extraHandMouthGap, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemGap);
            mouthCoordinates.relative.size = CGSizeMake(itemGap, itemGap);
            //screen
            mouthCoordinates.points = [CommonHelpers CGRRelativeToPoints: mouthCoordinates.relative : [[SingleGraph sharedSingleGraph] screen].points.size];
            
            column++;
            
            //mouth
            //relative
            handCoordinates.relative.origin  = CGPointMake(column * itemGap + extraHandMouthGap, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemGap);
            handCoordinates.relative.size = CGSizeMake(itemGap, itemGap);
            //screen
            handCoordinates.points = [CommonHelpers CGRRelativeToPoints: handCoordinates.relative : [[SingleGraph sharedSingleGraph] screen].points.size];

            column++;
            
            //for long iphone skip extra colums
            if([[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_5 ||
               [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6 ||
               [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6_PLUS)
            {
                column++;
            }
        }
        
        //relative
        slotCoordinates[i].relative.origin  = CGPointMake(column * itemGap, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemGap);
        slotCoordinates[i].relative.size = CGSizeMake(itemGap, itemGap); //NOTE make sure to not chanmge this
        //screen
        slotCoordinates[i].points = [CommonHelpers CGRRelativeToPoints: slotCoordinates[i].relative : [[SingleGraph sharedSingleGraph] screen].points.size];
        
        column++;
    }
}

#pragma mark - Inteface touche conditions
/////////////////
// Naming:
// ....Touched - located in TouchBegin and checks if button is just touched
// ....Pressed - located in ToucheMove or ToucheEnd and checks if button is already pressed and held down
/////////////////

//start instructions icon
- (BOOL) IsStartIconTouched: (CGPoint) tpos
{
    Button *startIcon = [overlays.interfaceObjs objectAtIndex: INT_START_ICON];
    return  startIcon.visible && [startIcon  RectContains:tpos];
}

//touche begin check
- (BOOL) IsJoystickTouched: (CGPoint) tpos
{
    Button *itemJoy = [overlays.interfaceObjs objectAtIndex: INT_MOV_JOYSTICK];
    Button *itemJoyStick = [overlays.interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
    return extCharacter.state != CS_RAFT && extCharacter.state != CS_DEAD && !itemJoyStick.flag && [itemJoy IsButtonPressed:tpos];
}

//touche end check
- (BOOL) IsJoystickPressed: (UITouch*) touch
{
    Button *itemJoyStick = [overlays.interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
    return [itemJoyStick IsPressedByTouch: touch] && itemJoyStick.flag;
}

//weather inventry board and items can be touched 
- (BOOL) IsInventoryBoardTouched: (CGPoint) tpos
{
    Button *itemInvB = [overlays.interfaceObjs objectAtIndex: INT_INVENTORY_BOARD];
    return extCharacter.state != CS_RAFT && extCharacter.state != CS_DEAD && [itemInvB  RectContains:tpos];
}

//weather is spear strike is pressed
- (BOOL) IsStrikeButtTouched: (CGPoint) tpos
{
    Button *spearFireButt = [overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
    return extCharacter.state == CS_BASIC  && extCharacter.handItem.ID == ITEM_SPEAR && [spearFireButt  IsButtonPressed:tpos];
}

//weather is stone throw is pressed
- (BOOL) IsStoneThrowButtTouched: (CGPoint) tpos
{
    Button *actionButt = [overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
    return extCharacter.state == CS_BASIC  && extCharacter.handItem.ID == ITEM_STONE && [actionButt  IsButtonPressed:tpos];
}

//weather  knife is pressed
- (BOOL) IsKnifeButtTouched: (CGPoint) tpos
{
    Button *actionButt = [overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
    return extCharacter.state == CS_BASIC  && extCharacter.handItem.ID == ITEM_KNIFE && [actionButt  IsButtonPressed:tpos];
}

//weather is leaf blowing
- (BOOL) IsLeafBlowButtTouched: (CGPoint) tpos
{
    Button *actionButt = [overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
    return extCharacter.state == CS_BASIC  && extCharacter.handItem.ID == ITEM_SMALLPALM_LEAF && [actionButt  IsButtonPressed:tpos];
}

//weather hand  is touched, remove spear
- (BOOL) IsHandItemRemoveTouched: (CGPoint) tpos : (Objects*) objects
{
    //check not to remove spear when striking
    BOOL spearInStrike = (extCharacter.handItem.ID == ITEM_SPEAR && objects.handSpear.striking);
    BOOL knifeInCut = (extCharacter.handItem.ID == ITEM_KNIFE && objects.knife.knife.enabled);
    BOOL leafInSwing = (extCharacter.handItem.ID == ITEM_SMALLPALM_LEAF && [objects.handLeaf IsLeafInSwing]);
    
    return extCharacter.state == CS_BASIC && CGRectContainsPoint(handCoordinates.points, tpos) &&  extCharacter.inventory.grabbedItem.type == kItemEmpty &&
           extCharacter.handItem.ID != kItemEmpty && !spearInStrike && !knifeInCut && !leafInSwing;
}

//weather something can be placed in hand
- (BOOL) IsHandPlaceTouched: (CGPoint) tpos
{
    return extCharacter.state == CS_BASIC  && CGRectContainsPoint(handCoordinates.points, tpos);
}

//if freelook allowed
- (BOOL) IsFreeLookAllowed
{
    return extCharacter.state != CS_FIRE_DRILL;
}

//eating allowed
- (BOOL) IsMouthUsingTouched: (CGPoint) tpos
{
    return extCharacter.state != CS_RAFT && CGRectContainsPoint(mouthCoordinates.points, tpos) ;
}

//weathr item can be dropped here and now
- (BOOL) IsItemDroppingAllowed: (CGPoint) tpos
{
    Button *itemViewS = [overlays.interfaceObjs objectAtIndex: INT_VIEW_SPACE];
    return extCharacter.state == CS_BASIC && [itemViewS RectContains:tpos];
}

//weather items can be picked in inventory
- (BOOL) IsItemPickingAllowed: (CGPoint) tpos
{
    Button *itemInvB = [overlays.interfaceObjs objectAtIndex: INT_INVENTORY_BOARD];
    Button *itemJoy = [overlays.interfaceObjs objectAtIndex: INT_MOV_JOYSTICK];
    Button *actionButt = [overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
    
    return extCharacter.state != CS_DEAD && extCharacter.state != CS_RAFT && extCharacter.state != CS_SHELTER_RESTING &&
           extCharacter.state != CS_FIRE_DRILL && extCharacter.inventory.grabbedItem.type == kItemEmpty &&
           ![itemInvB RectContains: tpos] && ![itemJoy RectContains: tpos] && !(actionButt.visible && [actionButt RectContains: tpos]);
}

//drill board
- (BOOL) IsDrillBoardTouched: (CGPoint) tpos
{
    Button *drillBoardIcon = [overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
    return extCharacter.state == CS_FIRE_DRILL && [drillBoardIcon IsButtonPressed:tpos];
}
- (BOOL) IsDrillBoardPressed: (UITouch*) touch
{
    Button *drillBoardIcon = [overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
    return [drillBoardIcon IsPressedByTouch: touch];
}


//start building raft
- (BOOL) IsBeginRaftButtTouched: (CGPoint) tpos
{
    Button *startRaftButt = [overlays.interfaceObjs objectAtIndex: INT_RAFT_BEGIN_BUTT];
    return  extCharacter.state == CS_BASIC && extCharacter.handItem.ID == ITEM_RAFT_LOG &&  [startRaftButt  IsButtonPressed:tpos];
}

//start floating
- (BOOL) IsFloatRaftButtTouched: (CGPoint) tpos
{
    Button *floatRaftButt = [overlays.interfaceObjs objectAtIndex: INT_RAFT_FLOAT_BUTT];
    return  extCharacter.state == CS_BASIC  &&  [floatRaftButt  IsButtonPressed:tpos];
}


//start building shelter
- (BOOL) IsBeginShelterButtTouched: (CGPoint) tpos
{
    Button *startShelterButt = [overlays.interfaceObjs objectAtIndex: INT_SHELTER_BEGIN_BUTT];
    return  extCharacter.state == CS_BASIC /*&& extCharacter.handItem.ID == ITEM_RAFT_LOG*/ &&  [startShelterButt  IsButtonPressed:tpos];
}

#pragma mark -  Inteface state management

//make visible / hidden elemnts entering BASIC state
- (void) SetBasicInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_BASIC)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_BASIC];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetBasicInterface"];
    }
}

//make visible / hidden elemnts entering SPEARING state
- (void) SetSpearingInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_SPEAR)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        [overlays SetInterfaceVisibility: INT_ACTION_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_CROSSHAIR : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_SPEAR];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetSpearingInterface"];
    }
}

//make visible / hidden elemnts entering STONE THROWING state
- (void) SetStoneThrowInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_STONE)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        [overlays SetInterfaceVisibility: INT_ACTION_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_CROSSHAIR : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_STONE];
    }
    else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetStoneThrowInterface"];
    }
}

//make visible / hidden elemnts entering KNIFE state
- (void) SetKnifeInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_KNIFE)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        [overlays SetInterfaceVisibility: INT_ACTION_BUTT : YES];
        //[overlays SetInterfaceVisibility: INT_CROSSHAIR : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_KNIFE];
    }
    else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetKnifeInterface"];
    }
}

//make visible / hidden elemnts entering LEAF BLOWING state
- (void) SetLeafBlowInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_LEAF)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        [overlays SetInterfaceVisibility: INT_ACTION_BUTT : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_LEAF];
    }
    else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetLeafBlowInterface"];
    }
}

//make visible / hidden elemnts entering FIRE DRILL state
- (void) SetFireDrillInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_FIRE_DRILL)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        [overlays SetInterfaceVisibility: INT_DRILLBOARD_ICON : YES];
        [overlays SetInterfaceVisibility: INT_DRILL_STICK_ICON : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_FIRE_DRILL];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetFireDrillInterface"];
    }
}

//make visible / hidden elemnts entering RESTING state
- (void) SetRestingInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_RESTING)
    {
        [overlays HideAllOverlays];
        
        //on
        [overlays SetInterfaceVisibility: INT_INVENTORY_BOARD : YES];
        [overlays SetInterfaceVisibility: INT_MOV_JOYSTICK : YES];
        [overlays SetInterfaceVisibility: INT_JOYSTICK_STICK : YES];
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_DAY_ICON: YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_RESTING];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetRestingInterface"];
    }
}

//interface when character step into raft
- (void) SetRaftInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_RAFT)
    {
        [overlays HideAllOverlays];
        //on
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_WIN_ICON : YES];
        //make this button vivisble because we need to show that it is selected after raft state is set
        [overlays SetInterfaceVisibility: INT_RAFT_FLOAT_BUTT : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_RAFT];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetRaftInterface"];
    }
}

//interface when characterstate is DEAD and no action can be performed
- (void) SetDeathInterface
{
    if([[SingleDirector sharedSingleDirector] interfaceType] != IT_DEATH)
    {
        [overlays HideAllOverlays];
        //on
        [overlays SetInterfaceVisibility: INT_PAUSE_BUTT : YES];
        [overlays SetInterfaceVisibility: INT_NUTRITION_IND : YES];
        [overlays SetInterfaceVisibility: INT_HYDRATION_IND : YES];
        [overlays SetInterfaceVisibility: INT_INJURY_IND : YES];
        [overlays SetInterfaceVisibility: INT_LOOSE_ICON : YES];
        
        [[SingleDirector sharedSingleDirector] setInterfaceType: IT_DEATH];
    }else
    {
        [CommonHelpers Log: @"Trying to reset in Interface in SetDeathInterface"];
    }
}

#pragma mark -  Inteface animations

//invenotry boards is filled, blink 
- (void) InvenotryFullBlink
{
    Button *inventoryFullIcon = [overlays.interfaceObjs objectAtIndex: INT_INVNTORY_FULL];
    [inventoryFullIcon StartFlicker];
}

//hand full icon blinks
- (void) HandFullBlink
{
    Button *itemHandFull = [overlays.interfaceObjs objectAtIndex: INT_HAND_FULL];
    itemHandFull.rePosition = GLKVector2Make(handCoordinates.relative.origin.x, 0);  //we could not set this in intioalization
    itemHandFull.modelviewMat = GLKMatrix4MakeTranslation(itemHandFull.rePosition.x, 0, 0);
    [itemHandFull StartFlicker];
}

//start indicator splash scaling above given indicator
//charging - weather indicator signals charge (increase) or not (decrease)
- (void) StartIndicatorSplashAt: (int) indicatorIndex : (BOOL) charging
{
    Button *indSplashIcon = [overlays.interfaceObjs objectAtIndex: indicatorIndex];
    [indSplashIcon StartScaling];
    
    //turn red when decreasing
    if(!charging)
    {
        //red
        indSplashIcon->backColor.b = 0.0;
        indSplashIcon->backColor.g = 0.0;
    }else
    {
        //white
        indSplashIcon->backColor.b = 1.0;
        indSplashIcon->backColor.g = 1.0;
    }
}


#pragma mark -  Touch functions

- (void) TouchMove: (UITouch*) touch : (CGPoint) tpos : (GLKVector3) spacePoint3D : (Objects*) objs : (Terrain*) terr  : (Interaction*) intrct
{
    //check item marker visibility when item is dragged
    //BOOL isDroppingAllowed = [self IsItemDroppingAllowed: tpos];
    
    switch (extCharacter.inventory.grabbedItem.type)
    {
        //dissalowed item visibility determinantion
        case ITEM_COCONUT:
        {
            //BOOL val = (isDroppingAllowed && ![objs.cocos IsPlaceAllowed: spacePoint3D : terr : intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.cocos IsPlaceAllowed: spacePoint3D : terr : intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_SHELL:
        {
            //BOOL val = (isDroppingAllowed && ![objs.shells IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.shells IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_ROCK_FLAT:
        {
            //BOOL val = (isDroppingAllowed && ![objs.flatRocks IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.flatRocks IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_STICK:
        case ITEM_SPEAR:
        {
            //put on shelter check
            BOOL valR = [self IsItemDroppingAllowed: tpos] && [objs.shelter PuttingSticksAllowed: spacePoint3D];
            [overlays SetInterfaceVisibility: INT_ITEM_ON_SHELTER : valR];
            
            BOOL val = (!valR && ![objs.sticks IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC ;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        //put on shelter check
        case ITEM_SMALLPALM_LEAF:
        {
            BOOL valR =  [self IsItemDroppingAllowed: tpos] && [objs.shelter PuttingLeavesAllowed: spacePoint3D];
            [overlays SetInterfaceVisibility: INT_ITEM_ON_SHELTER : valR];
            
            BOOL val = (!valR && ![objs.handLeaf IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC ;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_FISH_2_RAW:
        case ITEM_FISH_RAW:
        {
            //BOOL val = (isDroppingAllowed && ![objs.fishes IsPlaceAllowed:spacePoint3 :terr]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.fishes IsPlaceAllowed:spacePoint3D :terr] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_RAINCATCH:
        {
            //BOOL val = (isDroppingAllowed && ![objs.rainCatch IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.rainCatch IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_DEADFALL_TRAP:
        {
            //BOOL val = (isDroppingAllowed && ![objs.deadfallTraps IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.deadfallTraps IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_SHARP_WOOD:
        {
            //BOOL val = (isDroppingAllowed && ![objs.stickTraps IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.stickTraps IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_KINDLING:
        {
            //BOOL val = (isDroppingAllowed && ![objs.campFire IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.campFire IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_RAFT_LOG:
        {
            //put on raft check
            BOOL valR = [self IsItemDroppingAllowed: tpos]  && [objs.raft PuttingLogsAllowed:spacePoint3D];
            [overlays SetInterfaceVisibility: INT_ITEM_ON_RAFT : valR];
            
            //disabled check
            BOOL val = (!valR && ![objs.logs IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_RAG:
        {
            //BOOL val = (isDroppingAllowed && ![objs.rags IsPlaceAllowed:spacePoint3D :terr :intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.rags IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
            
        //put on fire icon visibility check
        case ITEM_WOOD:
        {
            BOOL valR = ([self IsItemDroppingAllowed: tpos] && [objs.campFire WoodItemAllowed: spacePoint3D : extCharacter.inventory.grabbedItem.type]);
            [overlays SetInterfaceVisibility: INT_ITEM_ON_FIRE: valR];
            
            BOOL val = extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        //put on raft check
        case ITEM_SAIL:
        {
            BOOL val = ([self IsItemDroppingAllowed: tpos] && [objs.raft PuttingSailAllowed:spacePoint3D]);// || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_ON_RAFT : val];
        }
        break;
        //
        case ITEM_FISH_CLEANED:
        case ITEM_RAT_CLEANED:
       // case ITEM_CRAB_RAW:
        {
            //cooking mark
            BOOL val = [self IsItemDroppingAllowed: tpos] && extCharacter.inventory.items[extCharacter.inventory.grabbedItem.type].cookable  &&
                       [objs.campFire CookingItemAllowed: spacePoint3D : extCharacter.inventory.grabbedItem.type];
            [overlays SetInterfaceVisibility: INT_ITEM_ON_FIRE: val];
            
            //dissalowed mark
            //NOTE: fishes module is used to check IsPlaceAllowed. Because this function is equal for all edible coocable items
            BOOL vald = (!val && ![objs.fishes IsPlaceAllowedRawFish: spacePoint3D : terr : intrct]) || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : vald];
        }
        break;
        case ITEM_STONE:
        {
            //BOOL val = (isDroppingAllowed && ![objs.stone IsPlaceAllowed: spacePoint3D : terr : intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.stone IsPlaceAllowed: spacePoint3D : terr : intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_TINDER:
        {
            BOOL val = extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_LEAF:
        {
            BOOL val = extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_KNIFE:
        {
            //BOOL val = (isDroppingAllowed && ![objs.stone IsPlaceAllowed: spacePoint3D : terr : intrct]) || extCharacter.state != CS_BASIC;
            BOOL val = ![objs.knife IsPlaceAllowed: spacePoint3D : terr : intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
        case ITEM_SEA_URCHIN:
        {
            BOOL val = ![objs.seaUrchin IsPlaceAllowed:spacePoint3D :terr :intrct] || extCharacter.state != CS_BASIC;
            [overlays SetInterfaceVisibility: INT_ITEM_DISALLOWED : val];
        }
        break;
    }

    
    //NSLog(@"---   %d", extCharacter.inventory.grabbedItem.type);
    
    //highlight mouth and hand icons when usable item is dragged over
    if(extCharacter.inventory.items[extCharacter.inventory.grabbedItem.type].edible ||
       extCharacter.inventory.items[extCharacter.inventory.grabbedItem.type].holdable)
    {
        //check against middle of grabbed icon
        CGPoint iconMiddleCoords = CGPointMake(extCharacter.inventory.grabbedItem.position.x + slotCoordinates[0].points.size.width / 2.0 ,
                                               extCharacter.inventory.grabbedItem.position.y + slotCoordinates[0].points.size.width / 2.0);
        
        Button *itemPlaceMark = [overlays.interfaceObjs objectAtIndex: INT_ITEM_PLACEMARK];
        if(//mouth
           ([self IsMouthUsingTouched: iconMiddleCoords] && extCharacter.inventory.items[extCharacter.inventory.grabbedItem.type].edible)
           ||
           //hand
           ([self IsHandPlaceTouched: iconMiddleCoords] && extCharacter.inventory.items[extCharacter.inventory.grabbedItem.type].holdable && extCharacter.handItem.ID == kItemEmpty))
        {
            itemPlaceMark->visible = YES;
        }else
        {
            itemPlaceMark->visible = NO; //hide any other time
        }
    }
    
    
    /*
    //check against middle of grabbed icon
    CGPoint iconMiddleCoords = CGPointMake(extCharacter.inventory.grabbedItem.position.x + slotCoordinates[0].points.size.width / 2.0 ,
                                           extCharacter.inventory.grabbedItem.position.y + slotCoordinates[0].points.size.width / 2.0);
    
    Button *itemPlaceMark = [overlays.interfaceObjs objectAtIndex: INT_ITEM_PLACEMARK];
    
    if([self IsInventoryBoardTouched: iconMiddleCoords])
    {
        
        
        
    }
     */
}

@end
