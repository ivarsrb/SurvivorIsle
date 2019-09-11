//
//  MainMenuScene.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "MainMenuScene.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation MainMenuScene

@synthesize menuMesh, menuObjs;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        menuObjs = [[NSMutableArray alloc] init];
        
        //menu vertical beginning
        menuBeginningY = 0.14; //[[SingleGraph sharedSingleGraph] screen].relative.size.height / 3.0;
        
        [self InitMenuArray];
        [self InitGeometry];
        [self SetupRendering];

    }
    return self;
}

//fill vertex data
- (void) InitGeometry
{
    [CommonHelpers Log: @"Debug mode is ON"];
    
    justEntered = NO;
    
    menuMesh = [[GeometryShape alloc] init];
    menuMesh.dataSetType = VERTEX_SET;
    menuMesh.vertStructType = VERTEX_TEX_STR;
    
    //number of vertices in total mesh
    menuMesh.vertexCount = [self GetNumberOfTotalVertices];
    
    [menuMesh CreateVertexIndexArrays];        

    int vrtCnt = 0;
    //write geometry into global mesh
    for(Button *obj in menuObjs)
    {
        vrtCnt = [obj InitGeometry:menuMesh:vrtCnt];
    }
    
    [self StartLaunchSlide];
}


- (void) SetupRendering
{
    [menuMesh InitGeometryBeffers];
  
    //load teztures icons/buttons
    for(Button *obj in menuObjs)
    {
        [obj LoadTextures];
    }
}


- (void) Update: (float) dt
{
    if(!justEntered)
    {
        //use this "if", because we can not control entering into menu scene from app delegate
        //....put any first-time execution here, that is only performed once
        //NOTE: Render function may draw before update function
        //NOTE: don't put visibility modifiers in this function outside this block, because slide actions may override it
        
        [[SingleSound sharedSingleSound]  StopAllSoundsButOne: SOUND_CLICK]; //mute all game sounds, except click from puse butt
        
        //continue button is visible only when we came into menu from game
        if([[SingleDirector sharedSingleDirector] gameScene] == SC_MAIN_MENU_PAUSE)
        {
            Button *continueButt = [menuObjs objectAtIndex : MO_CONTINUE_BUTTON];
            continueButt->visible = YES;
            
            //determine position of play button depending on game state
            /*
            Button *playButt = [menuObjs objectAtIndex : MO_PLAY_BUTTON];
            playButt->rect.relative.origin.y = menuBeginningY + playButt->rect.relative.size.height * 1.3;
            [playButt CalcScrPointsFromRelative: [[SingleGraph sharedSingleGraph] screen].points.size];
            */
        }else
        if([[SingleDirector sharedSingleDirector] gameScene] == SC_MAIN_MENU)
        {
            Button *continueButt = [menuObjs objectAtIndex : MO_CONTINUE_BUTTON];
            continueButt->visible = NO;
            
            //determine position of play button depending on game state
            /*
            Button *playButt = [menuObjs objectAtIndex : MO_PLAY_BUTTON];
            playButt->rect.relative.origin.y = menuBeginningY;
            [playButt CalcScrPointsFromRelative: [[SingleGraph sharedSingleGraph] screen].points.size];
            */
        }
        
        justEntered = YES;
    }
    
    //what button to update is checked inside
    for(Button *obj in menuObjs)
    {
        [obj Update: dt];
    }
}

- (void) Render
{
    glBindVertexArrayOES(menuMesh.vertexArray);
    
    //draw interface elements
    for(Button *obj in menuObjs)
    {
        [obj Draw];
    }
}

- (void) ResourceCleanUp
{
    for(Button *obj in menuObjs)
    {
        [obj ResourceCleanUp];
    }
    [menuMesh ResourceCleanUp];
}

#pragma mark - Menu objects

//NOTE: for performance group transaperent and opaque objects
- (void) InitMenuArray
{
    ///////////////
    // Background
    ///////////////
    Button *backgroundIcon = [[Button alloc] init];
    backgroundIcon->type = BT_ICON;
    backgroundIcon->rect.relative.origin = CGPointMake(0.0, 0.0);
    backgroundIcon->rect.relative.size.width = [[SingleGraph sharedSingleGraph] screen].relative.size.width;
    backgroundIcon->rect.relative.size.height = [[SingleGraph sharedSingleGraph] screen].relative.size.height;
    //size depends on devoce
    [backgroundIcon AssignTextureNamesFull: @"Default.png" : @"Default@2x.png" : @"Default-568h@2x.png" :
                                            @"Default-Landscape.png" : @"Default-Landscape@2x.png"  : @"Default-667h@2x.png"  : @"Default-Landscape-736h@3x.png"];
    
    if(!isIpad && [[SingleDirector sharedSingleDirector] deviceType] != DEVICE_IPHONE_6_PLUS)
    {
        //because iphone,ipod launch images are in portrait, rotate them
        backgroundIcon->rotatedTexturing = YES;
    }
    backgroundIcon->blendNeeded = NO;
    [menuObjs insertObject: backgroundIcon atIndex: MO_MENU_BACKGROUND];
    
    ///////////////
    // Play button
    ///////////////
    Button *playButt = [[Button alloc] init];
    playButt->type = BT_BUTTON;
    if(isIpad)
    {
        //230x115 points
        playButt->rect.relative.size.width = 0.30;
        playButt->rect.relative.size.height = 0.15;
    }else
    {
        //112x56 points
        playButt->rect.relative.size.width = 0.35;
        playButt->rect.relative.size.height = 0.175;
    }
    
    //determine position of play button depending on game state
    /*
    float playButtY = menuBeginningY;
    if([[SingleDirector sharedSingleDirector] gameScene] == SC_MAIN_MENU_PAUSE)
    {
        playButtY += playButt->rect.relative.size.height * 1.3;
    }
    */
    float playButtY = menuBeginningY + playButt->rect.relative.size.height * 1.05;
    playButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - playButt->rect.relative.size.width / 2.0,
                                                 playButtY );
    //iphone - 128x64, ipad - 256x128
    [playButt AssignTextureDouble : @"play_butt.png" : @"play_butt-ipad.png"];
    [playButt AssignSelectedTextureDouble : @"play_sel_butt.png" : @"play_sel_butt-ipad.png"];
    playButt->blendNeeded = YES;
    [menuObjs insertObject: playButt atIndex: MO_PLAY_BUTTON];

    ///////////////
    // Continue button
    ///////////////
    Button *continueButt = [[Button alloc] init];
    continueButt->type = BT_BUTTON;
    if(isIpad)
    {
        //230x115 points
        continueButt->rect.relative.size.width = 0.30;
        continueButt->rect.relative.size.height = 0.15;
    }else
    {
        //112x56 points
        continueButt->rect.relative.size.width = 0.35;
        continueButt->rect.relative.size.height = 0.175;
    }
    continueButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - playButt->rect.relative.size.width / 2.0,
                                                      menuBeginningY);
    //iphone  - 128x64, ipad - 256x128
    [continueButt AssignTextureDouble : @"continue_butt.png" : @"continue_butt-ipad.png"];
    [continueButt AssignSelectedTextureDouble : @"continue_sel_butt.png" : @"continue_sel_butt-ipad.png"];
    continueButt->blendNeeded = YES;
    continueButt->visible = NO;
    [menuObjs insertObject: continueButt atIndex: MO_CONTINUE_BUTTON];
    
    ///////////////
    // Info button
    ///////////////
    Button *infoButt = [[Button alloc] init];
    infoButt->type = BT_BUTTON_AUTO;
    if(isIpad)
    {
        //76x76 points
        infoButt->rect.relative.size.width = 0.10;
        infoButt->rect.relative.size.height = 0.10;
    }else
    {
        //44.8x44.8 points
        infoButt->rect.relative.size.width = 0.14;
        infoButt->rect.relative.size.height = 0.14;
    }
    float originGap = infoButt->rect.relative.size.width / 2.0;
    infoButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width - infoButt->rect.relative.size.width - originGap,
                                                 [[SingleGraph sharedSingleGraph] screen].relative.size.height - infoButt->rect.relative.size.height - originGap);
    //64x64, 128x128
    [infoButt AssignTextureDouble:  @"info_butt.png" : @"info_butt-ipad.png"];
    [infoButt AssignSelectedTextureDouble : @"info_sel_butt.png" : @"info_sel_butt-ipad.png"];
    infoButt->blendNeeded = YES;
    [menuObjs insertObject: infoButt atIndex: MO_INFO_BUTTON];
    
    ///////////////
    // Sound button
    ///////////////
    Button *soundButt = [[Button alloc] init];
    soundButt->type = BT_BUTTON_CUSTOM; //selection managed in code in this module
    if(isIpad)
    {
        //76x76 points
        soundButt->rect.relative.size.width = 0.10;
        soundButt->rect.relative.size.height = 0.10;
    }else
    {
        //44.8x44.8 points
        soundButt->rect.relative.size.width = 0.14;
        soundButt->rect.relative.size.height = 0.14;
    }
    float originGapS = soundButt->rect.relative.size.width / 2.0;
    soundButt->rect.relative.origin = CGPointMake(originGapS,
                                                 [[SingleGraph sharedSingleGraph] screen].relative.size.height - infoButt->rect.relative.size.height - originGapS);
    //iphone - 64x64, ipad - 128x128
    [soundButt AssignTextureDouble:  @"sound_butt.png" : @"sound_butt-ipad.png"];
    [soundButt AssignSelectedTextureDouble : @"sound_sel_butt.png" : @"sound_sel_butt-ipad.png"];
    soundButt->blendNeeded = YES;
    soundButt->selected = [[SingleSound sharedSingleSound]  muted];
    [menuObjs insertObject: soundButt atIndex: MO_SOUND_BUTTON];
    
    ///////////////
    // Difficulty options
    ///////////////
    //-- difficulty panel
    Button *diffPanelIcon = [[Button alloc] init];
    diffPanelIcon->type = BT_ICON;
    if(isIpad)
    {
        //460.8x115.2 points
        diffPanelIcon->rect.relative.size.width = 0.60;
        diffPanelIcon->rect.relative.size.height = 0.15;
    }else
    {
        //256x64 points
        diffPanelIcon->rect.relative.size.width = 0.80;
        diffPanelIcon->rect.relative.size.height = 0.20;
    }
    //in middle between play buttond and lower bound
    float diffPanelY = (playButt->rect.relative.origin.y + playButt->rect.relative.size.height + [[SingleGraph sharedSingleGraph] screen].relative.size.height) / 2.0
                        - diffPanelIcon->rect.relative.size.height / 2.0;
    diffPanelIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - diffPanelIcon->rect.relative.size.width / 2.0,
                                                      diffPanelY);
    //iphone - 256x64, ipad - 512x128
    [diffPanelIcon AssignTextureDouble:  @"difficulty_panel.png" : @"difficulty_panel-ipad.png"];
    diffPanelIcon->blendNeeded = YES;
    [menuObjs insertObject: diffPanelIcon atIndex: MO_DIFFICULTY_PANEL];
    
    //-- easy
    Button *diff1OptButt = [[Button alloc] init];
    diff1OptButt->type = BT_BUTTON_CUSTOM;//selection managed in code in this module
    if(isIpad)
    {
        //153.6x76.8 points
        diff1OptButt->rect.relative.size.width = 0.20;
        diff1OptButt->rect.relative.size.height = 0.10;
    }else
    {
        //89.6x44.8 points
        diff1OptButt->rect.relative.size.width = 0.28;
        diff1OptButt->rect.relative.size.height = 0.14;
    }
    diff1OptButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - diff1OptButt->rect.relative.size.width * 1.20,  // 1.25
                                                     diffPanelIcon->rect.relative.origin.y +
                                                     diffPanelIcon->rect.relative.size.height / 2.0 -
                                                     diff1OptButt->rect.relative.size.height / 2.0);
    //128x64, 258x128
    [diff1OptButt AssignTextureDouble:  @"diff_1_opt_butt.png" : @"diff_1_opt_butt-ipad.png"];
    [diff1OptButt AssignSelectedTextureDouble: @"diff_1_opt_sel_butt.png" : @"diff_1_opt_sel_butt-ipad.png"];
    diff1OptButt->selected = ([[SingleDirector sharedSingleDirector] difficulty] == GD_EASY);
    diff1OptButt->blendNeeded = YES;
    [menuObjs insertObject: diff1OptButt atIndex: MO_DIFFICULTY_SWITCH_1];
    
    //-- hard
    Button *diff2OptButt = [[Button alloc] init];
    diff2OptButt->type = BT_BUTTON_CUSTOM; //selection managed in code in this module
    if(isIpad)
    {
        //153.6x76.8 points
        diff2OptButt->rect.relative.size.width = 0.20;
        diff2OptButt->rect.relative.size.height = 0.10;
    }else
    {
        //89.6x44.8 points
        diff2OptButt->rect.relative.size.width = 0.28;
        diff2OptButt->rect.relative.size.height = 0.14;
    }
    diff2OptButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 + diff2OptButt->rect.relative.size.width / 5.4, //4.0/
                                                     diff1OptButt->rect.relative.origin.y);
    //iphone - 128x64, ipad - 258x128
    [diff2OptButt AssignTextureDouble: @"diff_2_opt_butt.png" : @"diff_2_opt_butt-ipad.png"];
    [diff2OptButt AssignSelectedTextureDouble: @"diff_2_opt_sel_butt.png" : @"diff_2_opt_sel_butt-ipad.png"];
    diff2OptButt->selected =  ([[SingleDirector sharedSingleDirector] difficulty] == GD_HARD);
    diff2OptButt->blendNeeded = YES;
    [menuObjs insertObject: diff2OptButt atIndex: MO_DIFFICULTY_SWITCH_2];
    
    //------------------------------------ Help/Info
    ///////////////
    // General help panel
    ///////////////
    Button *genHelpPanelIcon = [[Button alloc] init];
    genHelpPanelIcon->type = BT_ICON;
    genHelpPanelIcon->rect.relative.size.width = [[SingleGraph sharedSingleGraph] screen].relative.size.width;
    genHelpPanelIcon->rect.relative.size.height = [[SingleGraph sharedSingleGraph] screen].relative.size.width * 2;
    genHelpPanelIcon->rect.relative.origin = CGPointMake(0,0);
    
    //ipad, iphone long - 1024 x 2048
    //iphone retina and low -  512 x 1024
    /*
    [genHelpPanelIcon AssignTextureNames: @"help_general.png" : @"help_general.png" : @"help_general-ipad.png" :
                                           @"help_general-ipad.png" : @"help_general-ipad.png"];
     */
    
    [genHelpPanelIcon AssignTextureNamesFull: @"help_general.png" : @"help_general.png" : @"help_general-ipad.png" :
                                              @"help_general-ipad.png" : @"help_general-ipad.png" : @"help_general-ipad.png" :
                                              @"help_general-ipad.png"];

    genHelpPanelIcon->blendNeeded = YES;
    genHelpPanelIcon->visible = NO;
    [menuObjs insertObject: genHelpPanelIcon atIndex: MO_HELP_GENERAL_PANEL];
    
    ///////////////
    // Back from Help to menu button
    ///////////////
    Button *backButt = [[Button alloc] init];
    backButt->type = BT_BUTTON_AUTO;
    if(isIpad)
    {
        //76x76 points
        backButt->rect.relative.size.width = 0.10;
        backButt->rect.relative.size.height = 0.10;
    }else
    {
        //44.8x44.8 points
        backButt->rect.relative.size.width = 0.14;
        backButt->rect.relative.size.height = 0.14;
    }
    float originGapB = backButt->rect.relative.size.width / 2.0;
    backButt->rect.relative.origin = CGPointMake(originGapB,
                                                 [[SingleGraph sharedSingleGraph] screen].relative.size.height - backButt->rect.relative.size.height - originGapB);
    //iphone - 64x64, ipad - 128x128
    [backButt AssignTextureDouble:  @"back_butt.png" : @"back_butt-ipad.png"];
    [backButt AssignSelectedTextureDouble : @"back_sel_butt.png" : @"back_sel_butt-ipad.png"];
    backButt->blendNeeded = YES;
    backButt->visible = NO;
    [menuObjs insertObject: backButt atIndex: MO_BACK_BUTTON];
    
    //post processing
    //calculate screen points
    for(Button *obj in menuObjs)
    {
        [obj CalcScrPointsFromRelative: [[SingleGraph sharedSingleGraph] screen].points.size];
       
        /*
        NSLog(@"%@ - %f %f ; %f %f",obj->iconFile,  obj->rect.relative.size.width, obj->rect.relative.size.height,
                                    obj->rect.points.size.width, obj->rect.points.size.height);
        */
    }
}
#pragma mark - Additional functions

//how many vertices needed for all menu objects
- (int) GetNumberOfTotalVertices
{
    int menuObjCount = 0;
    for(Button *obj in menuObjs)
    {
        //use only the ones we need to draw
        if(obj->type != BT_AREA)
        {
            menuObjCount++;
        }
    }
    
    return menuObjCount * 4;
}


#pragma mark - Movement start functions


//first time game enters main menu
- (void) StartLaunchSlide
{
    float actionTime = 0.5; //seconds
    //whenever game start slide menu from top, dont move background
    for(Button *obj in menuObjs)
    {
        NSUInteger index = [menuObjs indexOfObject:obj];
        //list of buttons to slide
        if(index == MO_PLAY_BUTTON || index == MO_INFO_BUTTON || index == MO_SOUND_BUTTON ||
           index == MO_DIFFICULTY_PANEL || index == MO_DIFFICULTY_SWITCH_1 || index == MO_DIFFICULTY_SWITCH_2)
        {
            [obj StartSlide: BS_TOP_DOWN_TO_VISIBLE: actionTime];
        }
    }
}

//slide to info/help screen
- (void) StartInfoSlide
{
    float actionTime = 0.5; //seconds
    for(Button *obj in menuObjs)
    {
        NSUInteger index = [menuObjs indexOfObject:obj];
        //OFF
        //list of buttons to slide off
        if(index == MO_PLAY_BUTTON || index == MO_CONTINUE_BUTTON || index == MO_INFO_BUTTON || index == MO_SOUND_BUTTON ||
           index == MO_DIFFICULTY_PANEL || index == MO_DIFFICULTY_SWITCH_1 || index == MO_DIFFICULTY_SWITCH_2)
        {
            [obj StartSlide: BS_RIGHT_LEFT_TO_HIDE: actionTime];
        }
        
        //ON
        //list of button to slide on
        if(index == MO_BACK_BUTTON || index == MO_HELP_GENERAL_PANEL)
        {
            [obj StartSlide: BS_RIGHT_LEFT_TO_VISIBLE: actionTime];
        }
    }
}

//slide from info/help screen to menu
- (void) StartInfoBackSlide
{
    float actionTime = 0.5; //seconds
    for(Button *obj in menuObjs)
    {
        NSUInteger index = [menuObjs indexOfObject:obj];
        
        //OFF
        //list of button to slide off
        if(index == MO_BACK_BUTTON || index == MO_HELP_GENERAL_PANEL)
        {
            [obj StartSlide: BS_LEFT_RIGHT_TO_HIDE: actionTime];
        }
        
        //ON
        //list of buttons to slide on
        if(index == MO_PLAY_BUTTON || index == MO_INFO_BUTTON || index == MO_SOUND_BUTTON ||
           index == MO_DIFFICULTY_PANEL || index == MO_DIFFICULTY_SWITCH_1 || index == MO_DIFFICULTY_SWITCH_2)
        {
            [obj StartSlide: BS_LEFT_RIGHT_TO_VISIBLE: actionTime];
        }
        //slide on also continue butt if we are in pause mode
        if(index == MO_CONTINUE_BUTTON && [[SingleDirector sharedSingleDirector] gameScene] == SC_MAIN_MENU_PAUSE)
        {
            [obj StartSlide: BS_LEFT_RIGHT_TO_VISIBLE: actionTime];
        }
    }
}

#pragma mark - Touche functions

- (void) TouchesBegin: (NSSet *)touches
{
    //get current touch coordinates
    for (UITouch* touch in touches)
    {   
        CGPoint touchLocation = [touch locationInView: [touch view]];

        //Start new game
        Button *playButt = [menuObjs objectAtIndex: MO_PLAY_BUTTON];
        if([playButt IsButtonPressed:touchLocation])
        {
            [playButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            break;
        }
        
        //continue existing game
        Button *continueButt = [menuObjs objectAtIndex: MO_CONTINUE_BUTTON];
        if([continueButt IsButtonPressed:touchLocation])
        {
            [continueButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            break;
        }
        
        //info button (auto)
        Button *infoButt = [menuObjs objectAtIndex: MO_INFO_BUTTON];
        if([infoButt IsButtonPressed:touchLocation])
        {
            [infoButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            
            [self StartInfoSlide];
            
            break;
        }
        
        //sound button
        Button *soundButt = [menuObjs objectAtIndex: MO_SOUND_BUTTON];
        if([soundButt IsButtonPressed:touchLocation])
        {
            [soundButt PressBegin: touch];
            //sound is played only when touch ends happens onturning sound on
            break;
        }
        
        //options (works only  when starting new game)
        //easy
        Button *diff1OptButt = [menuObjs objectAtIndex: MO_DIFFICULTY_SWITCH_1];
        if([diff1OptButt IsButtonPressed:touchLocation])
        {
            [diff1OptButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            break;
        }
        //hard
        Button *diff2OptButt = [menuObjs objectAtIndex: MO_DIFFICULTY_SWITCH_2];
        if([diff2OptButt IsButtonPressed:touchLocation])
        {
            [diff2OptButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            break;
        }
        
        //back button (auto)
        Button *backButt = [menuObjs objectAtIndex: MO_BACK_BUTTON];
        if([backButt IsButtonPressed:touchLocation])
        {
            [backButt PressBegin: touch];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            
            [self StartInfoBackSlide];
            Button *helpIcon = [menuObjs objectAtIndex: MO_HELP_GENERAL_PANEL];
            [helpIcon StopScrolling];
            
            break;
        }
        
        //help scroll
        Button *helpIcon = [menuObjs objectAtIndex: MO_HELP_GENERAL_PANEL];
        if([helpIcon IsButtonPressed:touchLocation])
        {
            [helpIcon PressBegin: touch];
            [helpIcon StartScrolling];
            touchLastLocation = touchLocation;
            break;
        }
    }
}

- (void) TouchesMove: (NSSet *)touches : (GLKViewController*) vc
{
    //float dt = vc.timeSinceLastUpdate;
    
    for (UITouch* touch in touches)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        
        //scroll help
        Button *helpIcon = [menuObjs objectAtIndex: MO_HELP_GENERAL_PANEL];
        if([helpIcon IsPressedByTouch: touch])
        {
            //float speedKoef = 0.1;
            //float deltY = (touchLastLocation.y - touchLocation.y) * dt * speedKoef;
            float deltY = (touchLocation.y - touchLastLocation.y);
            
            deltY = [CommonHelpers ConvertToRelative: deltY];
            
           // NSLog(@"deltaY %f", deltY);
            
            [helpIcon UpdateScrolling: deltY];
            
            touchLastLocation = touchLocation;
            break;
        }
    }
}

- (void) TouchesEnd: (NSSet *) touches : (PlayScene*) plSc
{
    //get current touch coordinates
    for (UITouch* touch in touches)
    {
        //because we need earlier these
        Button *diff1OptButt = [menuObjs objectAtIndex: MO_DIFFICULTY_SWITCH_1];
        Button *diff2OptButt = [menuObjs objectAtIndex: MO_DIFFICULTY_SWITCH_2];
        
        //Play button
        Button *playButt = [menuObjs objectAtIndex: MO_PLAY_BUTTON];
        if([playButt IsPressedByTouch: touch])
        {
            //nill all touches when enetring game
            for(Button *obj in menuObjs)
            {
                [obj PressEnd];
            }
            [plSc ResetData];
            [[SingleDirector sharedSingleDirector] setGameScene: SC_PLAY];
            justEntered = NO;
            break;
        }
        
        //continue existing game
        Button *continueButt = [menuObjs objectAtIndex: MO_CONTINUE_BUTTON];
        if([continueButt IsPressedByTouch:touch])
        {
            //nill all touches when enetring game
            for(Button *obj in menuObjs)
            {
                [obj PressEnd];
            }
            [plSc NillData];
            [[SingleDirector sharedSingleDirector] setGameScene: SC_PLAY];
            justEntered = NO;
            break;
        }
        
        //sound switch
        Button *soundButt = [menuObjs objectAtIndex: MO_SOUND_BUTTON];
        if([soundButt IsPressedByTouch:touch])
        {
            soundButt->selected = !soundButt->selected;
            //mute, unmute
            if(soundButt->selected)
            {
                [[SingleSound sharedSingleSound]  setMuted: YES];
                [[SingleSound sharedSingleSound]  StopAllSounds];
            }else
            {
                [[SingleSound sharedSingleSound]  setMuted: NO];
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
            }
            
            [soundButt PressEnd];
            break;
        }
        
        //options (works only  when starting new game)
        //easy
        if([diff1OptButt IsPressedByTouch:touch])
        {
            diff1OptButt->selected = true;
            diff2OptButt->selected = false;
            
            //easy
            [[SingleDirector sharedSingleDirector] setDifficulty:GD_EASY];

            [diff1OptButt PressEnd];
            break;
        }
        
        //hard
        if([diff2OptButt IsPressedByTouch:touch])
        {
            diff1OptButt->selected = false;
            diff2OptButt->selected = true;
            
            //hard
            [[SingleDirector sharedSingleDirector] setDifficulty:GD_HARD];
            
            [diff2OptButt PressEnd];
            break;
        }
        
        //end scrolling
        Button *helpIcon = [menuObjs objectAtIndex: MO_HELP_GENERAL_PANEL];
        if([helpIcon IsPressedByTouch:touch])
        {
            [helpIcon StopScrolling];
            [helpIcon PressEnd];
            break;
        }
        
    }
}

//if touche is canceled for some reason (toucheend is not called)
- (void) TouchesCancel:(NSSet *)touches : (PlayScene*) plSc
{
    //NSLog(@"cancel");
    [self TouchesEnd: touches : plSc];
}


@end
