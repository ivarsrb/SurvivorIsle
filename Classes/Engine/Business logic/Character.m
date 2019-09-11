//
//  Character.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "Character.h"
#import "Objects.h"
#import "SingleSound.h"
#import "Particles.h"

@implementation Character

@synthesize camera,inventory,nutrition,hydration,movementV,health,
            height,state,freeLookTouch, handItem, prevHandItem, sitHeight,prevStateInformative;

//initialize with character initioal position and eye direction
- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        //constant data
        height = 1.8; // meters height
        sitHeight = height / 2;
        //init camera
        camera = [[Camera alloc] init];
        //init inventory
        inventory = [[Inventory alloc] init];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData: (Terrain*) terr: (Environment*) env
{
    //position initially caharcter like washed from ship, rotate randomly view
   // GLKVector3 pos = [CommonHelpers RandomOnCircleLine:terr.oceanLineCircle];
    float windAngle = -env.windAngle - M_PI_2; //PointOnCircle is -x based
    GLKVector3 pos = [CommonHelpers PointOnCircle:terr.oceanLineCircle :windAngle];
    GLKVector3 eyeV = GLKVector3Make(0.0, 0.0, 1.0); //eyes initially look at positive z angle
    float rotAngle = [CommonHelpers RandomInRange:0 :M_PI :10]; //step 0.1
    [CommonHelpers RotateY: &eyeV: rotAngle];
    GLKVector3 up = GLKVector3Make(0, 1, 0);
    pos.y = [terr GetHeightByPoint:&pos] + height;
    //position camera
    [camera PositionCamera: pos :eyeV :up];
    
    stepImitation = 0;
    state = CS_BASIC;
    prevState = state; //in order to back-track
    prevStateInformative = state; //to always be able to see previous state, prevState doest always show us that because it is ment to backtrack
    //set life parameters
    //------------------
    // Death is determined if any of these parameters - health, nutrition, hydration -
    // go 0.0 or lower!
    // health - affected by injuries, restored in shelter
    // nutrition, hydration - affected by by time, restored by food and drink
    //------------------
    [self RestoreHealth];
    nutrition = 1.0;
    hydration = 1.0;
    
    //character movement speed 
    movementMultiplierY = 10; //relativ speed in Y direction
    movementMultiplierX = 3; //relativ speed in X direction
    
    [inventory ResetData];
    handItem.ID = kItemEmpty;
    prevHandItem.ID = kItemEmpty;
    
    [self NillData:env];
}

//data that should be nilled every time game is entered from menu screen (no mater new or continued)
- (void) NillData: (Environment*) env
{
    //touch related parameters
    freeLookTouch = nil;
    
    [self NillMovement];
    
    //interace related nilling
    [inventory FinalizeItemGrab: YES]; //put back grabbed item
    
    //difficulty related, changes with difficulty change
    float daysToHunger;  //how long without food (days)
    float daysToDehydrate;  //how long without water
    
    //difficulty related
    //easy
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_EASY)
    {
        daysToHunger = 20; //1.0;  //how long without food (days)
        daysToDehydrate = 20; //0.7;  //how long without water
    }
    //hard
    else
    {
        daysToHunger = 0.7;  //how long without food (days)
        daysToDehydrate = 0.5;  //how long without water
    }
    
    //NOTE: 1.0 is the same as full nutrition and hydration, if changed max value, change also here
    nutDecr = 1.0 / (daysToHunger * env.dayLength * 60);
    hydDecr = 1.0 / (daysToDehydrate * env.dayLength * 60);
}


//movement/strafe of character
- (void) Update: (float) dt: (Interaction*) interaction: (Interface*) intr
{
    if(state != CS_DEAD)
    {
        if(state != CS_RAFT)
        {
            //Movement
            if([self IsMoving])
            {
                //step imitation
                int stepFrequency = 8; //how often steps will occur
                float stepDivider = 8; //height of steps 1 / stepDivider
                stepImitation += stepFrequency * dt;
                //bound check
                if(stepImitation >= 2 * M_PI)
                {
                    stepImitation = stepImitation - 2 * M_PI;
                }
                
                //movement
                GLKVector3 movementRotated = GLKVector3MultiplyScalar(movementV, dt);
                [CommonHelpers RotateY:&movementRotated :camera.yAngle]; //to get correct vector, keep it always relative to view vector
                //move
                [camera AddVector:movementRotated];

                //colision detection
                GLKVector3 reboundPosition; //point where character should end up after colision
                if(![interaction MovementAllowed: self: movementRotated: &reboundPosition])
                {
                    [camera MoveToPosition:reboundPosition];
                }
                 
                //set charcter eye hight
                float eyeHeight = [interaction GetHeightByPoint:camera.position] + height + (sinf(stepImitation) / stepDivider);
                [camera LiftCamera: eyeHeight];
            }
            
            //restore injury health
            //in chelter
            if(state == CS_SHELTER_RESTING)
            {
                [self IncreaseHealth: dt : intr];
            }
            
            
            //DEATH CHECK
            BOOL isDead = (hydration <= 0.0 || nutrition <= 0.0 || health <= 0.0); //death expression
            //update indicators if stil alive
            //if(hydration > 0 && nutrition > 0)
            if(!isDead)
            {
                hydration -= hydDecr * dt;
                nutrition -= nutDecr * dt;
            }else
            {
                //DEATH
                [self Die: interaction : intr];
            }
            
        }else 
        //raft state
        {
            
        }
    }
    
    //update camera actions
    [camera UpdateActions: dt];
}

- (void) ResourceCleanUp
{
    [inventory ResourceCleanUp];
    freeLookTouch = nil;
}

#pragma mark -  Health management

//set to maximum health
- (void) RestoreHealth
{
    lastInjury = JT_NONE;
    health = 1.0;
}

//restore health in time
- (void) IncreaseHealth: (float) dt :  (Interface*) intr
{
    float increment = 0.1; //increet of health in second
    health += increment * dt;
    if(health > 1.0)
    {
        health = 1.0;
    }else
    {
        [intr StartIndicatorSplashAt: INT_INJURY_SPLASH_ICON : true];
    }
}

//take off part of health
- (void) DecreaseHealth: (float) decrement :  (Interface*) intr : (int) injuryType
{
    if(health > 0.0)
    {
        lastInjury = injuryType; //assign injury type that just happened as a last (previous)
        
        health -= decrement;
        if(health < 0.0)
        {
            health = 0.0;
        }
        
        //scream only if there is some health left
        if (health > 0.0)
        {
            [intr StartIndicatorSplashAt: INT_INJURY_SPLASH_ICON : false];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_PAIN];
        }
    }
    //NSLog(@"health   %F", health);
}

//death procedure
- (void) Die: (Interaction*) interaction : (Interface*) intr
{
    //DEATH
    //ran out of nutritions or water
    [self setState: CS_DEAD];
    [intr SetDeathInterface];
    
    //imitate like character falls on ground/water
    float additHeight = 0.3; //how much above ground
    float timeOfAction = 0.5;
    GLKVector3 deathPosition = camera.position;
    deathPosition.y = [interaction GetHeightByPointAboveWater: camera.position] + additHeight;;
    [camera StartSlideAction: deathPosition : timeOfAction];
    
    [[SingleSound sharedSingleSound]  PlaySound: SOUND_SCREAM];
}


#pragma mark -  Motion

//freelok handling. X,Y = currently touched coordinates
- (void) Rotate: (CGPoint) tchStart : (float) X : (float) Y : (float) dt
{
    float downgrade = 6.0;
    
    if(tchStart.x < X) //look to the right
    {
        [camera RotateViewY:(tchStart.x - X) / downgrade * dt];
    }else
    if(tchStart.x > X) //look to the left
    {
        [camera RotateViewY:(tchStart.x - X) / downgrade * dt];
    }
    if(tchStart.y < Y) //look up
    {
        [camera RotateViewUpDown:(tchStart.y - Y) / downgrade * dt];
    }else
    if(tchStart.y > Y) //look down
    {
        [camera RotateViewUpDown:(tchStart.y - Y) / downgrade * dt];
    }
}

#pragma mark -  State management

//state management
- (void) setState: (enumCharacterStates) s
{
    if(state != CS_FIRE_DRILL && state != CS_SHELTER_RESTING) //if current state was not fire drill and shelter set prvious state
    {
        prevState = state;
    }
    
    prevStateInformative = state; //always see our previous state
    
    //when moving from BASIC state, if something is in hand store it and clear hand
    if(state == CS_BASIC && handItem.ID != kItemEmpty)
    {
        prevHandItem.ID = handItem.ID;
        handItem.ID = kItemEmpty;
    }
    
    
    
    state = s;
}

//set to state which was before current, works only in one level of depth (dont set twice in a row)
- (void) SetPreviousState: (Interface*) intr
{
    state = prevState;
    
    //set interface when changin view back
    switch (state) {
        case CS_BASIC:
            
            [intr SetBasicInterface];
            
            //restore hand item if was backed up
            if(prevHandItem.ID != kItemEmpty)
            {
                handItem.ID = prevHandItem.ID;
                prevHandItem.ID = kItemEmpty;
               
                [self SetInterfaceByHandItem: intr : handItem.ID];
                
            }
            
            break;
        default:
            break;
    }
   
}

//set approproate interface when given item is placed in hand #v.1.1.
- (void) SetInterfaceByHandItem: (Interface*) intr : (enumInventoryItems) type
{
    //for spear set spearing interface
    if(type == ITEM_SPEAR)
    {
        [intr SetSpearingInterface];
    }
    else
    //for stone set stone throwig interface
    if(type == ITEM_STONE)
    {
        [intr SetStoneThrowInterface];
    }
    else
    //for knife set knife interface
    if(type == ITEM_KNIFE)
    {
        [intr SetKnifeInterface];
    }
    else
    //for leaf set leaf blowing interface
    if(type == ITEM_SMALLPALM_LEAF)
    {
        [intr SetLeafBlowInterface];
    }
}



#pragma mark -  Hand management

//pick up items that can not be placed in inventory, only hand
- (BOOL) PickItemHand: (Interface*) intr : (enumInventoryItems) type
{
    BOOL retVal = NO;
    
    //only in empty hand
    if(handItem.ID == kItemEmpty)
    {
        handItem = inventory.items[type];
        [self SetInterfaceByHandItem: intr : handItem.ID];
        retVal = YES;
    }
    
   
    
    return retVal;
}

//remove item from hand
- (void) ClearHand
{
    handItem.ID = kItemEmpty;
}

#pragma mark -  Parameter management

//eat or drink passed item
- (void) EatDrinkItem: (enumInventoryItems) itemType :  (Interface*) intr
{
    nutrition += inventory.items[itemType].reNutrition;
    hydration += inventory.items[itemType].reHydration;
    
    if(nutrition > 1.0)
    {
        nutrition = 1.0;
    }
    if(hydration > 1.0)
    {
        hydration = 1.0;
    }
    
    //mark with splash indicators if something added
    if(inventory.items[itemType].reNutrition > 0.0)
    {
        [intr StartIndicatorSplashAt: INT_NUTRITION_SPLASH_ICON : true];
    }
    if(inventory.items[itemType].reHydration > 0.0)
    {
        [intr StartIndicatorSplashAt: INT_HYDRATION_SPLASH_ICON : true];
    }
    
    //sound
    [[SingleSound sharedSingleSound] PlaySound:SOUND_EATING];
}

//nill movement of character
- (void) NillMovement
{
    //nill movement flags
    movementV = GLKVector3Make(0, 0, 0);
}

//weather character is moving wight now
- (BOOL) IsMoving
{
    return (movementV.x != 0 || movementV.z != 0);
}

//weather character is running wight now
- (BOOL) IsRunning
{
    float sideRuddingKoef = 0.50; //running is % of max movement
    float frontRuddingKoef = 0.60;
    
    return (fabs(movementV.z) > movementMultiplierY * sideRuddingKoef ||
            fabs(movementV.x) > movementMultiplierX * frontRuddingKoef);
}


#pragma mark -  Functions used in touch functions

/////////////////////////
// Movement joystick
/////////////////////////

- (void) JoystickBegin: (UITouch*) touch : (Interface*) intr: (Objects*) objects : (Interaction*) interaction
{
    if(![camera IsInAction])
    {
        Button *itemJoyStick = [intr.overlays.interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
        //move joystick stick with finger
        [itemJoyStick PressBegin: touch];
        itemJoyStick.flag = YES; //here 'flag' means that joystick is in use and no other touch will have it

        //----- leave from fire if conditions inside are met
        [objects.campFire LeaveFirePlace: self : intr];
        [objects.shelter LeaveShelter: self : intr : interaction];
    }
}

- (void) JoystickMove: (CGPoint) touchLocation : (Interface*) intr
{
    if(state == CS_BASIC && ![camera IsInAction])
    {
        Button *itemJoyStick = [intr.overlays.interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
        Button *itemJoy = [intr.overlays.interfaceObjs objectAtIndex: INT_MOV_JOYSTICK];
        //------ move joystick stick with finger
        //how much joystick stick has to move to move together with finger
        float deltaX = [CommonHelpers ConvertToRelative: touchLocation.x - [itemJoyStick HalfWidthPoints]] - itemJoyStick.rect.relative.origin.x;
        float deltaY = [CommonHelpers ConvertToRelative: touchLocation.y - [itemJoyStick HalfHeightPoints]] - itemJoyStick.rect.relative.origin.y;
        //restrict joystick stick to not to go beyond joystick
        CGPoint joyHalfPoint = [itemJoy CenterPointPoints];
        float distance = [CommonHelpers DistanceCGP: joyHalfPoint : touchLocation]; //distanmce from center of joystick to touch
        float maxStickMovementDistance = [itemJoy HalfHeightPoints] - [itemJoyStick  HalfHeightPoints]; //maximum distance form joystick center to stick center
        if(distance > maxStickMovementDistance)
        {
            GLKVector3 point1 = GLKVector3Make(joyHalfPoint.x, joyHalfPoint.y, 0);
            GLKVector3 point2 = GLKVector3Make(touchLocation.x, touchLocation.y, 0);
            float holdDistance = distance - maxStickMovementDistance; //distance from joystic outer circle to touch position
            GLKVector3 pc = [CommonHelpers PointOnLine:point1 : point2 : -holdDistance];  //find point on joystick outer circle

            //offset from origin to place on joystick outer circle
            deltaX = [CommonHelpers ConvertToRelative: pc.x - [itemJoyStick HalfWidthPoints]] - itemJoyStick.rect.relative.origin.x;
            deltaY = [CommonHelpers ConvertToRelative: pc.y - [itemJoyStick HalfHeightPoints]] - itemJoyStick.rect.relative.origin.y;
        }
     
        //position joystick stick
        itemJoyStick.rePosition = GLKVector2Make(deltaX, deltaY);
        itemJoyStick.modelviewMat = GLKMatrix4MakeTranslation(itemJoyStick.rePosition.x, itemJoyStick.rePosition.y, 0);
        
        //------ character movement
        //touch distance from center of joystick
        float xDistance = touchLocation.x - joyHalfPoint.x;
        float yDistance = touchLocation.y - joyHalfPoint.y;
        
        //if fingers moves out of joystick are bounds, limit it to upper bound
        if(fabsf(xDistance) > [itemJoy HalfWidthPoints])
        {
            int sign = xDistance / fabsf(xDistance);
            xDistance = sign * [itemJoy HalfWidthPoints];
        }
        if(fabsf(yDistance) > [itemJoy HalfHeightPoints])
        {
            int sign = yDistance / fabsf(yDistance);
            yDistance = sign * [itemJoy HalfHeightPoints];
        }

        //x
        //multiplied by 2 because wee need to make relative across movement range (-movementMultiplierX to movementMultiplierX)
        float relMovementSpeedx = (-xDistance / itemJoy.rect.points.size.width) * movementMultiplierX * 2;
        movementV.x = relMovementSpeedx;
        
        //y
        float relMovementSpeedy = (-yDistance / itemJoy.rect.points.size.height) * movementMultiplierY * 2;
        movementV.z = relMovementSpeedy;
    }else
    {
        [self NillMovement];
    }
}

- (void) JoystickEnd: (UITouch*) touch : (Interface*) intr
{
    Button *itemJoyStick = [intr.overlays.interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
    //move joystick stick with finger
    [itemJoyStick SetMatrixToIdentity];
    itemJoyStick.flag = NO;
    [itemJoyStick PressEnd];
    
    //---- nill character movement
    [self NillMovement];
}

#pragma mark -  Touch related functions

- (void) TouchBegin: (UITouch*) touch : (Interface*) intr : (Objects*) objects : (Interaction*) interaction
{
    CGPoint touchLocation = [touch locationInView: [touch view]];
    
    //NSLog(@"%@", touch);
    
    //inventory
    if([inventory TouchBegin: touch : touchLocation : intr])
    {
        //hand icon touvh
        //remove item from hand if touched
        if([intr IsHandItemRemoveTouched: touchLocation : objects])
        {
            //grab item
            [inventory InitGrabbItem: handItem.ID : [inventory GetFirstFreeSlot] : touchLocation : intr.handCoordinates.points.origin : touch];
            handItem.ID = kItemEmpty;
            [intr SetBasicInterface];
        }
    }else
    //movement touch
    if([intr IsJoystickTouched:touchLocation] /*&& !objects.campFire.spindle.isDrilled*/)
    {
        [self JoystickBegin: touch : intr : objects : interaction];
    }else
    //freelok touch start
    if(freeLookTouch == nil && [intr IsFreeLookAllowed])
    {
        freeLookTouch = touch;
        freeLookTchStart = CGPointMake(FLT_MIN, FLT_MIN); //dont put here start location like before because ther is delay when moving at first touch //touchLocation;
        //NSLog(@"%@", touch);
    }
}

//movedType - comes in kEmpty, and if is assigned by something other than kMEpty, means something is dragged
- (void) TouchMove: (UITouch*) touch : (Interface*) intr : (float) dt : (int*) movedType
{
    CGPoint touchLocation = [touch locationInView:[touch view]];
    
    //movement touch
    if([intr IsJoystickPressed: touch])
    {
        [self JoystickMove: touchLocation : intr];
        //when moving character while holding item, assign, as it means the same  as item is being dragged
        *movedType = inventory.grabbedItem.type;
    }
    else
    //freelok touch
    if(freeLookTouch != nil && [touch isEqual:freeLookTouch])
    {
        if(!CGPointEqualToPoint(freeLookTchStart, CGPointMake(FLT_MIN, FLT_MIN))) //skip first touch move so first freeLookTchStart value comes from move func not start func
        {
            [self Rotate: freeLookTchStart: touchLocation.x: touchLocation.y: dt];
            //freeLookTchStart = touchLocation;
            //when rotating character while holding item, assign, as it means the same  as item is being dragged
            *movedType = inventory.grabbedItem.type;
        }
        freeLookTchStart = touchLocation;
    }else
    {
        [inventory TouchMove:touch :touchLocation :intr :dt];
        *movedType = inventory.grabbedItem.type;
    }
}

- (BOOL) TouchEnd:(UITouch*) touch :  (Interface*) intr : (Objects*) objects : (Particles*) particles : (int*) droppedType : (GLKVector3) spacePoint : (GLKVector3) spacePoint3D
{
    CGPoint touchLocation = [touch locationInView:[touch view]];
    BOOL retVal = NO;
    //NSLog(@"%@", touch);
    BOOL silentFinalization = NO;
    
    //inventory
    if([inventory TouchEnd: touch : touchLocation : intr : self])
    {
        //check against middle of grabbed icon
        CGPoint iconMiddleCoords = CGPointMake(inventory.grabbedItem.position.x + intr.slotCoordinates[0].points.size.width/2 ,
                                               inventory.grabbedItem.position.y + intr.slotCoordinates[0].points.size.width/2);
        
        if(inventory.grabbedItem.type > kItemEmpty)
        {
            //finalization from Inventory
            //check weather item is eddible and dragged over mouth
            if(inventory.items[inventory.grabbedItem.type].edible && [intr IsMouthUsingTouched: iconMiddleCoords])
            {
    
                [self EatDrinkItem: inventory.grabbedItem.type : intr];
                if(inventory.grabbedItem.type == ITEM_RAINCATCH_FULL)
                {
                    silentFinalization = YES;
                    [inventory AssignGrabbedItem: ITEM_RAINCATCH]; //drink and return empty rain cath
                }else
                {
                    [inventory ClearGrabbedItem];
                }
            }else
            //place item in hand
            if((inventory.items[inventory.grabbedItem.type].holdable && handItem.ID == kItemEmpty && [intr IsHandPlaceTouched:iconMiddleCoords])
               ||
               //case when only holdable item (like log) are dropped on inventory, put it back in hand
               (inventory.items[inventory.grabbedItem.type].onlyHold && handItem.ID == kItemEmpty &&  [intr IsInventoryBoardTouched:iconMiddleCoords])
               )
            {
                handItem = inventory.items[inventory.grabbedItem.type];

                [self SetInterfaceByHandItem: intr : handItem.ID];
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_INV_CLICK];
                [inventory ClearGrabbedItem];
            }else
            //dropping items on some game elemnts or 3d world
            if([intr IsItemDroppingAllowed:iconMiddleCoords])
            {
                //FIREPLACE
                //Wood placed in campfire
                if([objects.campFire WoodItemAllowed: spacePoint3D : inventory.grabbedItem.type])
                {
                    [objects.campFire AddWood];
                    [inventory ClearGrabbedItem];
                    [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                }
                //something coocable placed in fire
                if(inventory.items[inventory.grabbedItem.type].cookable && [objects.campFire CookingItemAllowed: spacePoint3D : inventory.grabbedItem.type])
                {
                    [objects.campFire StartCooking: inventory.grabbedItem.type];
                    [inventory ClearGrabbedItem];
                    [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                }
                 
                //RAFT
                //add logs
                if(inventory.grabbedItem.type == ITEM_RAFT_LOG && [objects.raft PuttingLogsAllowed: spacePoint3D])
                {
                    [objects.raft AddLog: objects.logs : particles];
                    [self ClearHand];
                    [inventory ClearGrabbedItem];
                }
                //add sail
                else
                if(inventory.grabbedItem.type == ITEM_SAIL && [objects.raft PuttingSailAllowed: spacePoint3D])
                {
                    [objects.raft AddSail : particles];
                    [inventory ClearGrabbedItem];
                }

                //SHELTER
                //add stick
                if((inventory.grabbedItem.type == ITEM_STICK || inventory.grabbedItem.type == ITEM_SPEAR)&& [objects.shelter PuttingSticksAllowed: spacePoint3D])
                {
                    [objects.shelter AddStick: particles];
                    [inventory ClearGrabbedItem];
                    
                }else
                //add leave
                if(inventory.grabbedItem.type == ITEM_SMALLPALM_LEAF && [objects.shelter PuttingLeavesAllowed: spacePoint3D])
                {
                    [objects.shelter AddLeave: particles];
                    [inventory ClearGrabbedItem];
                    
                }
                
                //3D WORLD
                //item dropped over 3D world
                if(inventory.grabbedItem.type > kItemEmpty && inventory.items[inventory.grabbedItem.type].droppable)
                {
                    //drop item
                    *droppedType = inventory.grabbedItem.type;
                    [inventory ClearGrabbedItem];
                }
            }
        }
            
        //if hand item  was put on full inventory board, put it back in hand when released
        if(inventory.grabbedItem.type > kItemEmpty && inventory.grabbedItem.previousSlot == -1 && inventory.items[inventory.grabbedItem.type].holdable && !inventory.items[inventory.grabbedItem.type].onlyHold)
        {
            [self PickItemHand: intr : inventory.grabbedItem.type];
            [inventory ClearGrabbedItem];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        }
        
        //finalization (puts item back, if not cleared)
        [inventory FinalizeItemGrab: silentFinalization];
        retVal = YES;
    }else
    //movement touch
    if([intr IsJoystickPressed: touch])
    {
        [self JoystickEnd: touch :  intr];
        retVal = YES;
    }else
    //freelok touch
    if([touch isEqual: freeLookTouch])
    {
        //NSLog(@"%@", touch);
        
        freeLookTouch = nil;
        retVal = YES;
    }
    
    return retVal;
}



@end
