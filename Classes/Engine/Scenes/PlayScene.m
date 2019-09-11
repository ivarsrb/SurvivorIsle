//
//  PlayScene.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "PlayScene.h"

@implementation PlayScene

@synthesize environment, character, terrain, skyDome, ocean,
            objects, clouds, interface, rain, interaction, particles;


- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        //parameters
        vieportParams[0] = 0; vieportParams[1] = 0;
        vieportParams[2] = [[SingleGraph sharedSingleGraph] screen].points.size.width;
        vieportParams[3] = [[SingleGraph sharedSingleGraph] screen].points.size.height;
        
        //game objects
        environment = [[Environment alloc] init];
        character = [[Character alloc] init];
        terrain = [[Terrain alloc] init];
        skyDome = [[SkyDome alloc] init];
        ocean = [[Ocean alloc] initWithObjects: terrain];
        clouds = [[Clouds alloc] init];
        rain = [[Rain alloc] initWithParams: character];
        objects = [[Objects alloc] initWithObjects: terrain:ocean];
        particles = [[Particles alloc] init];
        interface = [[Interface alloc] initWithParams: character];
        interaction = [[Interaction alloc] initWithObjects: terrain: objects: ocean];
        
        //set up matrices, basic shaders
        [self SetupRendering];
    }
    return self;
}

//initialize all data, that should change from new game to new game, like random location of pbjects, user start pos etc
//this is called every time "new game" button is pressed
//NO MEMORY ALLOCATIONS ALLOWED IN THIS FUNC!
- (void) ResetData
{
    lastPickTouch = 0;
    
    [environment ResetData];
    
    [character ResetData: terrain: environment];
    [interface ResetData: character];
    [skyDome ResetData: environment];
    [clouds ResetData];
    [ocean ResetData: environment];
    [rain ResetData];
    [objects ResetData: terrain : interaction : environment];
    [particles ResetData];
    //nill data is also included here, but within each resetData functions
}

//data that should be nilled every time game is eneterd from menu screen (no mater new or continued)
- (void) NillData
{
    [environment NillData];
    [character NillData: environment];
    [interface NillData: character];
    [objects.rats  NillData];
    [objects.crabs  NillData];
}

//init resources and set up rendering states
- (void) SetupRendering
{    
    //set up object opengl buffers and shaders
    [terrain SetupRendering];
    [skyDome SetupRendering];
    [ocean SetupRendering];
    [clouds SetupRendering];
    [rain SetupRendering];
    [objects SetupRendering];
    [interface SetupRendering];
    [particles SetupRendering];
}



- (void) Update: (float) dt
{
    [character Update: dt : interaction : interface];

    //update matrices
    GLKVector3 lookAtPont = [character.camera GetLookAtPoint];//GLKVector3Add(character.camera.position, character.camera.viewVector);
    modelViewMatrix = GLKMatrix4MakeLookAt(
                                           character.camera.position.x, character.camera.position.y,character.camera.position.z,
                                           lookAtPont.x,     lookAtPont.y,     lookAtPont.z,
                                           character.camera.upVector.x, character.camera.upVector.y, character.camera.upVector.z);
    modelViewProjectionMatrix = GLKMatrix4Multiply([[SingleGraph sharedSingleGraph] projMatrix], modelViewMatrix);

    //update game objects
    [environment Update: dt];
    [skyDome Update: dt : environment.time : &modelViewMatrix : character];
    [terrain Update: dt : environment.time : &modelViewMatrix : clouds : character : skyDome];
    [ocean Update: dt : environment.time : &modelViewMatrix : skyDome : character];
    [clouds Update: dt: environment.time: &modelViewMatrix : character : environment];
    [rain Update: dt : environment.time : &modelViewMatrix : character : environment : objects.shelter];
    [objects Update: dt : environment.time : &modelViewMatrix : terrain : character : interface : environment : ocean : interaction : clouds : particles : skyDome];
    [particles Update: dt : environment.time : &modelViewMatrix : ocean : terrain];
    [interface Update: dt : environment.time];
    
    //playscene sound management
    //sound listener
    //NOTE: potential problem iif absolute sound is played in one of object update functions, because it is set sooner than listener
    //but we cant set listener right after character.update because ocean sound flickers, because there is gap between listener set up and source set up in ocean sound
    [[SingleSound sharedSingleSound] SetListenerPos:character.camera.position];
    
    [[SingleSound sharedSingleSound] UpdateOceanSound: terrain];
    [[SingleSound sharedSingleSound] UpdateFootstepSound: character : terrain];
    [[SingleSound sharedSingleSound] UpdateRainSound: environment];
    [[SingleSound sharedSingleSound] UpdateThunderSound: clouds];
    [[SingleSound sharedSingleSound] UpdateWindSound: dt];
    [[SingleSound sharedSingleSound] UpdateBirdSound: dt : environment];
    [[SingleSound sharedSingleSound] UpdateSpearSound: objects.handSpear];
    [[SingleSound sharedSingleSound] UpdateFireSound: objects.campFire : interface];
    [[SingleSound sharedSingleSound] UpdateHeartbeatSound: character];
    [[SingleSound sharedSingleSound] UpdateBeeSound: objects.beehive];
    
    //NOTE: if putting raft sound here, put construction also in raft module
}

- (void) Render
{
    [skyDome Render];
    
    [clouds Render];
    
    [terrain Render: modelViewProjectionMatrix.m];
    
    [objects RenderSolid: character];
    
    [objects RenderDynamicSolid];
    
    [ocean Render];
    
    [objects RenderTransparent: character];

    [objects RenderDynamicTransparent: environment];
    
    [particles Render];
    
    //[objects RenderSolidOnTop];
    
    [rain Render];
    
    [interface Render: environment];
    
    //always enable depth mask before end of frame so glClear work normally
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
}

- (void) ResourceCleanUp
{
    [character ResourceCleanUp];
    [interface ResourceCleanUp];
    [terrain ResourceCleanUp];
    [skyDome ResourceCleanUp];
    [ocean ResourceCleanUp];
    [clouds ResourceCleanUp];
    [rain ResourceCleanUp];
    [objects ResourceCleanUp];
    [particles ResourceCleanUp];
    [interaction ResourceCleanUp];
}

- (void) TouchesBegin:(NSSet *)touches
{
    NSUInteger numTaps = [[touches anyObject] tapCount];
    
    //get current touch coordinates
    for (UITouch* touch in touches)
    {
        //NSLog(@"BEGIN playscene");
        
        CGPoint touchLocation = [touch locationInView:[touch view]];
        int X = touchLocation.x;
        int Y = touchLocation.y;

        ////////////////////////////
        // Start instructions icon tapped to be closed
        ////////////////////////////
        if([interface IsStartIconTouched: touchLocation])
        {
            [interface.overlays SetInterfaceVisibility: INT_START_ICON : NO];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_INV_CLICK];
        }
        
        ////////////////////////////
        // Pause/main menu button pressed
        ////////////////////////////
        Button *pauseButt = [interface.overlays.interfaceObjs objectAtIndex: INT_PAUSE_BUTT];
        if([pauseButt IsButtonPressed: touchLocation])
        {
            [pauseButt PressBegin: touch];
            [[SingleSound sharedSingleSound] PlaySound: SOUND_CLICK];
            break;
        }

        //character touchings
        [character TouchBegin: touch : interface : objects : interaction];
        
        //campfire touch
        [objects.campFire TouchBegin: touch : touchLocation : interface];
        
        //raft 
        [objects.raft TouchBegin: touch : touchLocation : interface : character : terrain : objects.logs : particles];
        
        //shelter
        [objects.shelter TouchBegin: touch : touchLocation : interface : character : terrain : interaction : particles];
        
        //spearing
        [objects.handSpear TouchBegin: touch : touchLocation : interface : character : &modelViewMatrix : vieportParams];
        
        //stone
        [objects.stone TouchBegin: touch : touchLocation : interface : character];
        
        //knife
        [objects.knife TouchBegin: touch : touchLocation : interface : character];
        
        //smallpalm leaf in hand
        [objects.handLeaf TouchBegin: touch : touchLocation : interface : character];
        
        //Double tap, activate picking functions in freelok space (dont allow to pick one after another)
        float minTimeBetweenPicks = 0.3; //seconds
        if(numTaps >= 2 && (touch.timestamp - lastPickTouch) >= minTimeBetweenPicks  && [interface IsItemPickingAllowed: touchLocation] )
        {
            //touvh point
            GLKVector3 windowTouch = GLKVector3Make(X, [[SingleGraph sharedSingleGraph] screen].points.size.height - Y, 0);

            //point that is touched on Znear plane
            bool errorUP;
            GLKVector3 spacePoint = GLKMathUnproject(windowTouch,modelViewMatrix,[[SingleGraph sharedSingleGraph] projMatrix], vieportParams, &errorUP);
            
            //check object picking
            //checking is done inside, because is placed only in hand , if there are more these kind of pickings - put together here
            [objects.logs PickObject: character.camera.position : spacePoint : character : interface];
            
            int pickStatus;
            //only one item can be picked at a time
            //first need to be able to pick temporary items, than permanent
            
            //temporary objects (dissapars when picked)
            pickStatus = [objects.cocos PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.crabs PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.stickTraps PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.deadfallTraps PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.rats PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.shells PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.flatRocks PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.campFire PickObject: character.camera.position : spacePoint : character.inventory : particles];
            if(!pickStatus)
                pickStatus = [objects.rainCatch PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.rags PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.sticks PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.sticks PickObjectSpear: character.camera.position : spacePoint : character : interface];
            if(!pickStatus)
                pickStatus = [objects.stone PickObject: character.camera.position : spacePoint : character : interface];
            if(!pickStatus)
                pickStatus = [objects.smallPalm PickObject: character.camera.position : spacePoint : character : interface];
            if(!pickStatus)
                pickStatus = [objects.knife PickObject: character.camera.position : spacePoint : character : interface : particles];
            if(!pickStatus)
                pickStatus = [objects.handLeaf PickObject: character.camera.position : spacePoint : character : interface];
            if(!pickStatus)
                pickStatus = [objects.beehive PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.seaUrchin PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.egg PickObject: character.camera.position : spacePoint : character.inventory];
            
            //permanent objects (stays in place when picked)
            if(!pickStatus)
                pickStatus = [objects.dryGrass PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.berryBush PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.leaves PickObject: character.camera.position : spacePoint : character.inventory];
            if(!pickStatus)
                pickStatus = [objects.bushes PickObject: character.camera.position : spacePoint : character.inventory];
            
            switch (pickStatus) 
            {
                case 1: //item picked
                    [[SingleSound sharedSingleSound]  PlaySound:SOUND_PICK];
                    break;
                case 2: //did not pick becouse inventory was full
                    [[SingleSound sharedSingleSound]  PlaySound:SOUND_PICK_FAIL];
                    //blink 
                    [interface InvenotryFullBlink]; //graphically show that invenotry is full
                   
                    //NOTE: full invenotry check also in Fish - Update
                    
                    break;
            }
            
            lastPickTouch = touch.timestamp; //store last picked time
        }
    }
}

- (void) TouchesMove: (NSSet *)touches :  (GLKViewController*) vc
{
    float dt = vc.timeSinceLastUpdate;
    
    for (UITouch* touch in touches)
    {   
        CGPoint touchLocation = [touch locationInView:[touch view]];
        
        int movedItemType = kItemEmpty; //will store currently picked up and moved item
        
        //character
        [character TouchMove: touch : interface : dt : &movedItemType];
        
        //something is being dragged
        //NOTE: dragging also shpuld be checked when item is held in one spot, but camera is rotated/moved at the same time
        if(movedItemType > kItemEmpty && character.state != CS_DEAD && character.state != CS_RAFT)
        {
            //we use stored coordinates, because if touch comes from turning camera, it will use wrong coordinates
            int X = character.inventory.grabbedItem.position.x + character.inventory.grabbedItem.grabDistance.width;
            int Y = character.inventory.grabbedItem.position.y + character.inventory.grabbedItem.grabDistance.height;
            
            //touvh point on window
            GLKVector3 windowTouch = GLKVector3Make(X, [[SingleGraph sharedSingleGraph] screen].points.size.height - Y, 0);
            //point that is touched on Znear plane
            bool errorUP;
            GLKVector3 spacePoint = GLKMathUnproject(windowTouch, modelViewMatrix, [[SingleGraph sharedSingleGraph] projMatrix], vieportParams,  &errorUP);
            //determine touch position in 3d space given placeDistance from spacePoint
            GLKVector3 spacePoint3D = [CommonHelpers PointOnLine: character.camera.position :spacePoint :DROP_DISTANCE];
            //[terrain GetHeightByPointAssign: &spacePoint3D];
            if(![terrain HasCollided: spacePoint : spacePoint3D : &spacePoint3D]) //#v.1.1.
            {
                //colision did not appear because finger was pointed above ground, simply assign height here of last point
                [terrain GetHeightByPointAssign: &spacePoint3D]; //assign y position by terrain, any extra additions in related object code
            }
            
            //interface
            [interface TouchMove: touch : touchLocation : spacePoint3D : objects : terrain : interaction];
        }
        
        //campfire
        [objects.campFire TouchMove: touch : touchLocation : character : interface : dt];
    }
}


- (void) TouchesEnd: (NSSet *)touches
{
    for (UITouch* touch in touches)
    {
        //NSLog(@"END playscene");
        
        CGPoint touchLocation = [touch locationInView:[touch view]];
        int X = touchLocation.x;
        int Y = touchLocation.y;
        //NSLog(@"%d %d", X,Y);
        
        int droppedItemType = kItemEmpty; //if item is dropped in 3d world, this item stores its type
        
        //touvh point on window
        GLKVector3 windowTouch = GLKVector3Make(X, [[SingleGraph sharedSingleGraph] screen].points.size.height - Y, 0);
        //point that is touched on Znear plane
        bool errorUP;
        GLKVector3 spacePoint = GLKMathUnproject(windowTouch,modelViewMatrix,[[SingleGraph sharedSingleGraph] projMatrix], vieportParams, &errorUP);
        //determine touch position in 3d space given placeDistance from spacePoint
        GLKVector3 spacePoint3D = [CommonHelpers PointOnLine:character.camera.position :spacePoint :DROP_DISTANCE];
        //find collision point between znear plane and point under ground
        if(![terrain HasCollided: spacePoint : spacePoint3D : &spacePoint3D]) //#v.1.1.
        {
            //colision did not appear because finger was pointed above ground, simply assign height here of last point
            [terrain GetHeightByPointAssign: &spacePoint3D]; //assign y position by terrain, any extra additions in related object code
        }
        
        ////////////////////////////
        // Pause/main menu button pressed
        // NOTE: if changed here, change in app delegate also
        ////////////////////////////
        Button *pauseButt = [interface.overlays.interfaceObjs objectAtIndex: INT_PAUSE_BUTT];
        if([pauseButt IsPressedByTouch:touch])
        {
            //[[SingleSound sharedSingleSound]  StopAllSounds];
            if(character.state == CS_DEAD || character.state == CS_RAFT) //winning and loosing state
            {
                //if dead, no continue button is needed
                [[SingleDirector sharedSingleDirector] setGameScene: SC_MAIN_MENU];
            }else
            {
                //go tumain menuto be able to press "continue" there
                [[SingleDirector sharedSingleDirector] setGameScene: SC_MAIN_MENU_PAUSE];
            }
            
            [pauseButt PressEnd];
            break;
        }
        
        //character
        if([character TouchEnd: touch : interface : objects : particles : &droppedItemType : spacePoint : spacePoint3D])
        {
            //dropped item
            if(droppedItemType > kItemEmpty && character.state != CS_DEAD && character.state != CS_RAFT)
            {
                switch (droppedItemType) 
                {
                    case ITEM_COCONUT:
                    {
                        [objects.cocos PlaceObject : spacePoint3D  : terrain: character : interaction];
                    }
                    break;
                    case ITEM_SHELL:
                    {
                        [objects.shells PlaceObject : spacePoint3D  : terrain: character : interaction];
                    }
                    break;
                    case ITEM_KINDLING:
                    {
                        [objects.campFire PlaceObject : spacePoint3D  : terrain: character : interaction : interface : particles];
                    }
                    break;
                    case ITEM_RAINCATCH:
                    {
                        [objects.rainCatch PlaceObject : spacePoint3D  : terrain: character : interaction : droppedItemType];
                    }
                    break;
                    case ITEM_ROCK_FLAT:
                    {
                        [objects.flatRocks PlaceObject : spacePoint3D  : terrain: character : interaction];
                    }
                    break;
                    case ITEM_STICK:
                    {
                        [objects.sticks PlaceObject : spacePoint3D  : terrain: character : interaction];
                    }
                    break;
                    case ITEM_SPEAR:
                    {
                        [objects.sticks PlaceObjectSpear : spacePoint3D  : terrain: character : interaction : interface];
                    }
                    break;
                    case ITEM_DEADFALL_TRAP:
                    {
                        [objects.deadfallTraps PlaceObject : spacePoint3D  : terrain: character : interaction: droppedItemType];
                    }
                    break;
                    case ITEM_SHARP_WOOD:
                    {
                        [objects.stickTraps PlaceObject : spacePoint3D  : terrain: character : interaction: droppedItemType];
                    }
                    break;
                    case ITEM_RAFT_LOG:
                    {
                        [objects.logs PlaceObject : spacePoint3D  : terrain: character : interaction : interface];
                    }
                    break;
                    case ITEM_RAG:
                    {
                        [objects.rags PlaceObject : spacePoint3D  : terrain: character : interaction];
                    }
                    break;
                    case ITEM_FISH_RAW:
                    case ITEM_FISH_2_RAW:
                    {
                        [objects.fishes PlaceObject: spacePoint3D  : terrain : character : droppedItemType];
                    }
                    break;
                    case ITEM_FISH_CLEANED:
                    {
                        [objects.fishes PlaceObjectRawFish : spacePoint3D  : terrain: character : interaction : objects.campFire : droppedItemType];
                    }
                    break;
                    case ITEM_RAT_CLEANED:
                    {
                        [objects.rats PlaceObject : spacePoint3D  : terrain: character : interaction : objects.campFire : droppedItemType];
                    }
                    break;
                    case ITEM_STONE:
                    {
                        [objects.stone PlaceObject : spacePoint3D  : terrain : character : interaction : interface];
                    }
                    break;
                    case ITEM_KNIFE:
                    {
                        [objects.knife PlaceObject : spacePoint3D  : terrain : character : interaction : interface];
                    }
                    break;
                    case ITEM_SMALLPALM_LEAF:
                    {
                        [objects.handLeaf PlaceObject : spacePoint3D  : terrain : character : interaction : interface];
                    }
                    break;
                    case ITEM_SEA_URCHIN:
                    {
                        [objects.seaUrchin PlaceObject : spacePoint3D  : terrain : character : interaction];
                    }
                    break;
                }
            }
        }
        
        //camp fire touch end (camera position is altered here !!!)
        [objects.campFire TouchEnd: touch : touchLocation : character : interface : spacePoint];
    }
}


//if touche is canceled for some reason (toucheend is not called for begin)
- (void) TouchesCancel: (NSSet *) touches
{
    //NSLog(@"CANCEL playscene");
    //call as if all cancelend events end here
    [self TouchesEnd: touches];
}


@end
