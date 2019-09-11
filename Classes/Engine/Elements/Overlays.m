//
//  Overlays.m
//  Island survival
//
//  Created by Ivars Rusbergs on 9/6/13.
//
// STATUS: - 

#import "Overlays.h"
#import "Character.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation Overlays
@synthesize overlayMesh, interfaceObjs, inventoryItems, dayNumbers, itemSize, itemSlotAnimation;

- (id) initWithParams: (Character*) chr
{
    self = [super init];
    if (self != nil)
    {
        //arrays
        //2 arrays, one for inventory items, other for all other interface objects
        //inventory array indexes are important to distinguish inventory items
        interfaceObjs = [[NSMutableArray alloc] init];
        inventoryItems = [[NSMutableArray alloc] init];
        //array to store day numbers, easier to draw in seperate loop
        dayNumbers = [[NSMutableArray alloc] init];
        
        //init overlay elemnts here
        [self InitInterfaceArray: chr];
        [self InitDayNumbersArray];
        [self InitInventoryArray];
        [self InitGeometry];
        
        //animation
        itemSlotAnimation = malloc(chr.inventory.slotCount * sizeof(SBasicAnimation));
    }
    return self;
}


//data that chages from game to game (only new game)
- (void) ResetData: (Character*) chr
{
    [self NillData:chr];
}

//data that should be nilled every time game is entered from menu screen (no matter new or continued)
- (void) NillData: (Character*) chr
{
    for(Button *obj in interfaceObjs)
    {
        [obj NillBUtton];
    }
    
    for(Button *obj in dayNumbers)
    {
        [obj NillBUtton];
    }
    
    for(Button *obj in inventoryItems)
    {
        [obj NillBUtton];
    }
    
    //nill movement joystick when entered into menu or phone ring
    Button *itemJoyStick = [interfaceObjs objectAtIndex: INT_JOYSTICK_STICK];
    //these are the same as in character module 'touch end'
    itemJoyStick.flag = NO;
    [itemJoyStick SetMatrixToIdentity];
    
    //inventory animation
    [self NillInventoryAnimation:chr];
}

- (void) InitGeometry
{
    overlayMesh = [[GeometryShape alloc] init];
    overlayMesh.dataSetType = VERTEX_SET;
    overlayMesh.vertStructType = VERTEX_TEX_STR;

    overlayMesh.vertexCount = [self GetNumberOfTotalVertices];
    
    [overlayMesh CreateVertexIndexArrays];
    
    int vrtCnt = 0;
    //write geometry into global mesh
    for(Button *obj in interfaceObjs)
    {
        vrtCnt = [obj InitGeometry: overlayMesh : vrtCnt];
    }
    //write geometry into global mesh
    for(Button *obj in dayNumbers)
    {
        vrtCnt = [obj InitGeometry: overlayMesh : vrtCnt];
    }

    //write geometry into global mesh
    for(Button *obj in inventoryItems)
    {
        vrtCnt = [obj InitGeometry: overlayMesh : vrtCnt];
    }
}

- (void) SetupRendering
{
    [overlayMesh InitGeometryBeffers];
    
    //load teztures icons/buttons
    for(Button *obj in interfaceObjs)
    {
        [obj LoadTextures];
    }
    
    //load teztures icons/buttons
    for(Button *obj in dayNumbers)
    {
        [obj LoadTextures];
    }
    
    //load teztures item
    for(Button *obj in inventoryItems)
    {
        [obj LoadTextures];
    }
}

- (void) Update: (Character*) character :(float) dt
{
    for(Button *obj in interfaceObjs)
    {
        [obj Update: dt];
    }

    [self UpdateSlotAnimation:character: dt];
}

- (void) Render: (Character*) character : (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates : (Environment*) env
{
    [[SingleGraph sharedSingleGraph] SetCullFace:YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest:NO];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:YES];
    [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
    
    glBindVertexArrayOES(overlayMesh.vertexArray);
    
    //draw interface elements
    for(Button *obj in interfaceObjs)
    {
        [obj Draw];
    }
    
    [self DrawDayNumbers: env];
    
    //inventory
    if(character.state != CS_RAFT && character.state != CS_DEAD)
    {
        [self DrawPlaceMark: character : handCoordinates : mouthCoordinates];
        [self DrawItemHighlighter: character : slotCoordinates : handCoordinates : mouthCoordinates];
        [self DrawInventory: character : slotCoordinates : handCoordinates];
        [self DrawPutOnFireIcon: character];
        [self DrawPutOnRaftIcon: character];
        [self DrawPutOnShelterIcon: character];
        [self DrawDisallowedIcon: character : slotCoordinates];
    }
}

- (void) ResourceCleanUp
{
    for(Button *obj in interfaceObjs)
    {
        [obj ResourceCleanUp];
    }
    
    for(Button *obj in dayNumbers)
    {
        [obj ResourceCleanUp];
    }
    
    for(Button *obj in inventoryItems)
    {
        [obj ResourceCleanUp];
    }
    
    [overlayMesh ResourceCleanUp];
    
    free(itemSlotAnimation);
}

#pragma mark - Interface objects

//NOTE: for performance group transaperent and opaque objects
- (void) InitInterfaceArray: (Character*) chr
{
    float relMargin = 0.01; //margin for icons from sides of screen
    
    //determine inventory board dimensions and item size
    //it depends on screen size, long screen will have inv. board as if it holds 9 slots , not 8 like normal screen,
    //  while actually 6 slots + mouth + hand and for long screen spaces will be wider between slots
    int extraSlotCount;
    if([[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_5 ||
       [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6 ||
       [[SingleDirector sharedSingleDirector] deviceType] == DEVICE_IPHONE_6_PLUS)
    {
        extraSlotCount = 3; //mouth + hand + extra_gap_for_spacing
    }else
    {
        extraSlotCount = 2; //mouth + hand
    }
    itemSize.relative.size.width = itemSize.relative.size.height = [[SingleGraph sharedSingleGraph] screen].relative.size.width / (chr.inventory.slotCount + extraSlotCount);
    
    //---
    //NSLog(@"%f %f", itemSize.relative.size.width, itemSize.relative.size.height);
    //---
    
    ////////////
    //view space
    ////////////
    Button *itemViewS = [[Button alloc] init];
    itemViewS->type = BT_AREA;
    itemViewS->rect.relative.origin = CGPointMake(0, 0);
    itemViewS->rect.relative.size.width = [[SingleGraph sharedSingleGraph] screen].relative.size.width;
    itemViewS->rect.relative.size.height = [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height;
    [interfaceObjs insertObject:itemViewS atIndex:INT_VIEW_SPACE];

    ////////////
    //inventory board 
    ////////////
    Button *itemInvB = [[Button alloc] init];
    itemInvB->type = BT_ICON;
    //heights is the same size as item
    itemInvB->rect.relative.origin = CGPointMake(0, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height);
    itemInvB->rect.relative.size.width = [[SingleGraph sharedSingleGraph] screen].relative.size.width;
    itemInvB->rect.relative.size.height = itemSize.relative.size.height;
    //ipad - 1024x128, iphone - 512x64,
    //iphone long - 1024x114 (NOTE: non power of 2 texture in order to fit correctly)
    //OPTI: could be possible to make smaller resolution
    [itemInvB AssignTextureNamesFull : @"inventory.png" : @"inventory.png" : @"inventory-long.png" :
                                       @"inventory-ipad.png" : @"inventory-ipad.png" : @"inventory-long.png" : @"inventory-long.png"];
    itemInvB->blendNeeded = YES;
    [interfaceObjs insertObject: itemInvB atIndex: INT_INVENTORY_BOARD];
 
    ////////////
    //movement joystick
    ////////////
    Button *itemJoy = [[Button alloc] init];
    itemJoy->type = BT_ICON;
    if(isIpad)
    {
        itemJoy->rect.relative.origin = CGPointMake(0.00, 0.50);
        //246x246
        itemJoy->rect.relative.size.width = 0.32;
        itemJoy->rect.relative.size.height = 0.32;
    }else
    {
        itemJoy->rect.relative.origin = CGPointMake(0.00, 0.40);
        //128x128
        itemJoy->rect.relative.size.width = 0.40;
        itemJoy->rect.relative.size.height = 0.40;
    }
    //ipad - 256x256, iphone - 128x128
    [itemJoy AssignTextureDouble : @"joystick.png" : @"joystick-ipad.png"];
    itemJoy->blendNeeded = YES;
    [interfaceObjs insertObject: itemJoy atIndex: INT_MOV_JOYSTICK];
    
    ////////////
    //movement joystick stick that helps t determine movement of joystick
    ////////////
    Button *itemJoyStick = [[Button alloc] init];
    itemJoyStick->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        itemJoyStick->rect.relative.size.width = 0.08;
        itemJoyStick->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        itemJoyStick->rect.relative.size.width = 0.10;
        itemJoyStick->rect.relative.size.height = 0.10;
    }
    itemJoyStick->rect.relative.origin = CGPointMake([itemJoy CenterPointRelative].x - [itemJoyStick HalfWidthRelative],
                                                     [itemJoy CenterPointRelative].y - [itemJoyStick HalfHeightRelative]);
    
    //ipad - 64x64, iphone - 64x64
    [itemJoyStick AssignTextureName: @"joystick_stick.png"];
    itemJoyStick->blendNeeded = YES;
    [interfaceObjs insertObject: itemJoyStick atIndex : INT_JOYSTICK_STICK];
    
    ////////////
    //pause button
    ////////////
    Button *pauseButt = [[Button alloc] init];
    pauseButt->type = BT_BUTTON;
    if(isIpad)
    {
        //62x62
        pauseButt->rect.relative.size.width = 0.08;
        pauseButt->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        pauseButt->rect.relative.size.width = 0.10;
        pauseButt->rect.relative.size.height = 0.10;
    }
    pauseButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width - relMargin - pauseButt->rect.relative.size.width, relMargin);
    //ipad - 64x64, iphone - 64x64
    [pauseButt AssignTextureName: @"pause_butt.png"];
    [pauseButt AssignSelectedTextureName: @"pause_sel_butt.png"];
    pauseButt->blendNeeded = YES;
    [interfaceObjs insertObject: pauseButt atIndex: INT_PAUSE_BUTT];
    
    ////////////
    //nutrition indicator
    ////////////
    Button *nutritionIndcIcon = [[Button alloc] init];
    nutritionIndcIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        nutritionIndcIcon->rect.relative.size.width = 0.08;
        nutritionIndcIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        nutritionIndcIcon->rect.relative.size.width = 0.10;
        nutritionIndcIcon->rect.relative.size.height = 0.10;
    }
    //for placement
    float midscreen = [[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0;
    float middgap = nutritionIndcIcon->rect.relative.size.width; //to place indictaors apart
    nutritionIndcIcon->rect.relative.origin = CGPointMake(midscreen - nutritionIndcIcon->rect.relative.size.width - middgap, relMargin);
    //ipad - 64x64, iphone - 64x64
    [nutritionIndcIcon AssignTextureName: @"nutrition_ind.png"];
    nutritionIndcIcon->blendNeeded = YES;
    nutritionIndcIcon->flicker.actionTime = 0.3;
    nutritionIndcIcon->flicker.direction = NO; //means that false  hides when flickering
    nutritionIndcIcon->flicker.type = BF_CONTINUOUS_BLINK;
    [interfaceObjs insertObject: nutritionIndcIcon atIndex: INT_NUTRITION_IND];
    
    ////////////
    //hydration indicator
    ////////////
    Button *hydrationIndcIcon = [[Button alloc] init];
    hydrationIndcIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        hydrationIndcIcon->rect.relative.size.width = 0.08;
        hydrationIndcIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        hydrationIndcIcon->rect.relative.size.width = 0.10;
        hydrationIndcIcon->rect.relative.size.height = 0.10;
    }
    hydrationIndcIcon->rect.relative.origin = CGPointMake(midscreen + middgap, relMargin);
    //ipad - 64x64, iphone - 64x64
    [hydrationIndcIcon AssignTextureName: @"hydration_ind.png"];
    hydrationIndcIcon->blendNeeded = YES;
    hydrationIndcIcon->flicker.actionTime = 0.3;
    hydrationIndcIcon->flicker.direction = NO; //means that false  hides when flickering
    hydrationIndcIcon->flicker.type = BF_CONTINUOUS_BLINK;
    [interfaceObjs insertObject: hydrationIndcIcon atIndex: INT_HYDRATION_IND];

    ////////////
    //injury indicator
    ////////////
    Button *injuryIndcIcon = [[Button alloc] init];
    injuryIndcIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        injuryIndcIcon->rect.relative.size.width = 0.08;
        injuryIndcIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        injuryIndcIcon->rect.relative.size.width = 0.10;
        injuryIndcIcon->rect.relative.size.height = 0.10;
    }
    injuryIndcIcon->rect.relative.origin = CGPointMake(midscreen - injuryIndcIcon->rect.relative.size.width / 2.0, relMargin);
    //ipad - 64x64, iphone - 64x64
    [injuryIndcIcon AssignTextureName: @"injury_ind.png"];
    injuryIndcIcon->blendNeeded = YES;
    injuryIndcIcon->flicker.actionTime = 0.3;
    injuryIndcIcon->flicker.direction = NO; //means that false  hides when flickering
    injuryIndcIcon->flicker.type = BF_CONTINUOUS_BLINK;
    [interfaceObjs insertObject: injuryIndcIcon atIndex: INT_INJURY_IND];
    
    ////////////
    //Nutrition splash icon (to signal changes in indicator)
    ////////////
    Button *nutritionSplashIcon = [[Button alloc] init];
    nutritionSplashIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        nutritionSplashIcon->rect.relative.size.width = 0.08;
        nutritionSplashIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        nutritionSplashIcon->rect.relative.size.width = 0.10;
        nutritionSplashIcon->rect.relative.size.height = 0.10;
    }
    nutritionSplashIcon->rect.relative.origin = nutritionIndcIcon->rect.relative.origin;
    //ipad - 64x64, iphone - 64x64
    [nutritionSplashIcon AssignTextureName: @"indicator_splash.png"];
    nutritionSplashIcon->blendNeeded = YES;
    nutritionSplashIcon->scaling.actionTime = 0.5;
    nutritionSplashIcon->scaling.maxScale = 1.5;
    [interfaceObjs insertObject: nutritionSplashIcon atIndex: INT_NUTRITION_SPLASH_ICON];
    
    ////////////
    //Hydration splash icon (to signal changes in indicator)
    ////////////
    Button *hydrationSplashIcon = [[Button alloc] init];
    hydrationSplashIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        hydrationSplashIcon->rect.relative.size.width = 0.08;
        hydrationSplashIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        hydrationSplashIcon->rect.relative.size.width = 0.10;
        hydrationSplashIcon->rect.relative.size.height = 0.10;
    }
    hydrationSplashIcon->rect.relative.origin = hydrationIndcIcon->rect.relative.origin;
    //ipad - 64x64, iphone - 64x64
    [hydrationSplashIcon AssignTextureName: @"indicator_splash.png"];
    hydrationSplashIcon->blendNeeded = YES;
    hydrationSplashIcon->scaling.actionTime = 0.5;
    hydrationSplashIcon->scaling.maxScale = 1.5;
    [interfaceObjs insertObject: hydrationSplashIcon atIndex: INT_HYDRATION_SPLASH_ICON];
    

    ////////////
    //Injury splash icon (to signal changes in indicator)
    ////////////
    Button *injurySplashIcon = [[Button alloc] init];
    injurySplashIcon->type = BT_ICON;
    if(isIpad)
    {
        //62x62
        injurySplashIcon->rect.relative.size.width = 0.08;
        injurySplashIcon->rect.relative.size.height = 0.08;
    }else
    {
        //32x32
        injurySplashIcon->rect.relative.size.width = 0.10;
        injurySplashIcon->rect.relative.size.height = 0.10;
    }
    injurySplashIcon->rect.relative.origin = injuryIndcIcon->rect.relative.origin;
    //ipad - 64x64, iphone - 64x64
    [injurySplashIcon AssignTextureName: @"indicator_splash.png"];
    injurySplashIcon->blendNeeded = YES;
    injurySplashIcon->scaling.actionTime = 0.5;
    injurySplashIcon->scaling.maxScale = 1.5;
    [interfaceObjs insertObject: injurySplashIcon atIndex: INT_INJURY_SPLASH_ICON];
    
    
    ////////////
    //day label (for day number)
    ////////////
    Button *dayIcon = [[Button alloc] init];
    dayIcon->type = BT_ICON;
    if(isIpad)
    {
        //124x62
        dayIcon->rect.relative.size.width = 0.16;
        dayIcon->rect.relative.size.height = 0.08;
    }else
    {
        //64x32
        dayIcon->rect.relative.size.width = 0.20;
        dayIcon->rect.relative.size.height = 0.10;
    }
    dayIcon->rect.relative.origin = CGPointMake(relMargin, relMargin);
    //ipad - 128x64, iphone - 128x64
    [dayIcon AssignTextureName: @"day.png"];
    dayIcon->blendNeeded = YES;
    [interfaceObjs insertObject: dayIcon atIndex: INT_DAY_ICON];
    
    ////////////
    //inventory full board
    ////////////
    Button *inventoryFullIcon = [[Button alloc] init];
    inventoryFullIcon->type = BT_ICON;
    //heights is the same size as item
    inventoryFullIcon->rect.relative.origin = CGPointMake(0, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height);
    inventoryFullIcon->rect.relative.size.width = [[SingleGraph sharedSingleGraph] screen].relative.size.width;
    inventoryFullIcon->rect.relative.size.height = itemSize.relative.size.height;
    //ipad - 1024x128, iphone - 512x64,
    //iphone long - 1024x114 (NOTE: non power of 2 texture in order to fit correctly)
    //OPTI: could be possible to make msaller and stretch if texture is simple
    [inventoryFullIcon AssignTextureNamesFull : @"inventory_full.png" : @"inventory_full.png" : @"inventory_full-long.png" :
                                                @"inventory_full-ipad.png" : @"inventory_full-ipad.png" : @"inventory_full-long.png" : @"inventory_full-long.png"];
    inventoryFullIcon->blendNeeded = YES;
    inventoryFullIcon->flicker.actionTime = 0.2; //second to blink
    inventoryFullIcon->flicker.type = BF_DOUBLE_BLINK;
    [interfaceObjs insertObject: inventoryFullIcon atIndex: INT_INVNTORY_FULL];
    
    ////////////
    //hand full
    ////////////
    Button *itemHandFull = [[Button alloc] init];
    itemHandFull->type = BT_ICON;
    //x origin will be set when blinking starts
    itemHandFull->rect.relative.origin = CGPointMake(0, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height);
    //ipad - 128x128 iphone - 60x60, iphone long 63.1x63.1
    itemHandFull->rect.relative.size.width = itemSize.relative.size.width;
    itemHandFull->rect.relative.size.height = itemSize.relative.size.height;
    //[itemHandFull AssignTextureName: @"hand_full.png" ];
    //ipad - 128x128, iphone - 64x64
    [itemHandFull AssignTextureDouble : @"hand_full.png" : @"hand_full-ipad.png"];
    itemHandFull->blendNeeded = YES;
    itemHandFull->flicker.actionTime = 0.2; //second to blink
    itemHandFull->flicker.type = BF_DOUBLE_BLINK;
    [interfaceObjs insertObject: itemHandFull atIndex: INT_HAND_FULL];
    
    ////////////
    //item highlighted
    ////////////
    Button *itemHighlighted = [[Button alloc] init];
    itemHighlighted->type = BT_ICON;
    itemHighlighted->rect.relative.origin = CGPointMake(0, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height);
    //ipad - 128x128 iphone - 60x60, iphone long 63.1x63.1
    itemHighlighted->rect.relative.size.width = itemSize.relative.size.width;
    itemHighlighted->rect.relative.size.height = itemSize.relative.size.height;
    //ipad - 128x128, iphone - 64x64
    [itemHighlighted AssignTextureDouble : @"item_highlighted.png" : @"item_highlighted-ipad.png"];
    //[itemHighlighted AssignTextureName: @"item_highlighted.png" ];
    itemHighlighted->blendNeeded = YES;
    //itemHighlighted->backColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    [interfaceObjs insertObject: itemHighlighted atIndex: INT_ITEM_HIGHLIGHT];
    
    ////////////
    //general action button, like spearing throwing stones  //#v.1.1.
    ////////////
    Button *actionButt = [[Button alloc] init];
    actionButt->type = BT_BUTTON_AUTO;
    if(isIpad)
    {
        //115x115
        actionButt->rect.relative.size.width = 0.15;
        actionButt->rect.relative.size.height = 0.15;
        actionButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width - 0.17, 0.47);
    }else
    {
        //55x55
        actionButt->rect.relative.size.width = 0.17;
        actionButt->rect.relative.size.height = 0.17;
        actionButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width - 0.19, 0.40);
    }
    //ipad - 128x128, iphone - 64x64
    [actionButt AssignTextureDouble: @"action_butt.png" :  @"action_butt-ipad.png"];
    [actionButt AssignSelectedTextureDouble: @"action_sel_butt.png" : @"action_sel_butt-ipad.png"];
    actionButt->blendNeeded = YES;
    [interfaceObjs insertObject: actionButt atIndex: INT_ACTION_BUTT];
    
    /////////////
    //spear cross hair
    /////////////
    Button *crossHairIcon = [[Button alloc] init];
    crossHairIcon->type = BT_ICON;
    //ipad - 61x61 iphone - 32x32
    if(isIpad)
    {
        crossHairIcon->rect.relative.size.width = 0.08;
        crossHairIcon->rect.relative.size.height = 0.08;
    }else
    {
        crossHairIcon->rect.relative.size.width = 0.10;
        crossHairIcon->rect.relative.size.height = 0.10;
    }
    crossHairIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - crossHairIcon->rect.relative.size.width / 2.0,
                                                      [[SingleGraph sharedSingleGraph] screen].relative.size.height / 2.0 - crossHairIcon->rect.relative.size.height /2.0);
    //64x64
    [crossHairIcon AssignTextureName: @"cross_hair.png" ];
    crossHairIcon->blendNeeded = YES;
    [interfaceObjs insertObject: crossHairIcon atIndex: INT_CROSSHAIR];
    
    
    /////////////
    //begin building raft
    /////////////
    Button *startRaftButt = [[Button alloc] init];
    startRaftButt->type = BT_BUTTON_AUTO;
    //ipad - 128x128, iphone - 60x60, iphone long 63.1x63.1
    startRaftButt->rect.relative.size.width = itemSize.relative.size.width;
    startRaftButt->rect.relative.size.height = itemSize.relative.size.height;
    startRaftButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - startRaftButt->rect.relative.size.width / 2.0,
                                                      [[SingleGraph sharedSingleGraph] screen].relative.size.height - 2 * startRaftButt->rect.relative.size.height);
    //ipad - 128x128, iphone - 64x64
    [startRaftButt AssignTextureDouble: @"raft_begin_butt.png" :  @"raft_begin_butt-ipad.png"];
    [startRaftButt AssignSelectedTextureDouble: @"raft_begin_sel_butt.png" : @"raft_begin_sel_butt-ipad.png"];
    startRaftButt->blendNeeded = YES;
    [interfaceObjs insertObject: startRaftButt atIndex: INT_RAFT_BEGIN_BUTT];
    
    /////////////
    //float raft
    /////////////
    Button *floatRaftButt = [[Button alloc] init];
    floatRaftButt->type = BT_BUTTON_AUTO;
    //ipad - 128x128, iphone - 60x60, iphone long 63.1x63.1
    floatRaftButt->rect.relative.size.width = itemSize.relative.size.width;
    floatRaftButt->rect.relative.size.height = itemSize.relative.size.height;
    floatRaftButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - floatRaftButt->rect.relative.size.width / 2.0,
                                                      [[SingleGraph sharedSingleGraph] screen].relative.size.height - 2 * floatRaftButt->rect.relative.size.height);
    //ipad - 128x128, iphone - 64x64
    [floatRaftButt AssignTextureDouble: @"raft_float_butt.png" :  @"raft_float_butt-ipad.png"];
    [floatRaftButt AssignSelectedTextureDouble: @"raft_float_sel_butt.png" : @"raft_float_sel_butt-ipad.png"];
    floatRaftButt->blendNeeded = YES;
    [interfaceObjs insertObject: floatRaftButt atIndex: INT_RAFT_FLOAT_BUTT];
    
    //////////////
    //game win icon
    //////////////
    Button *winIcon = [[Button alloc] init];
    winIcon->type = BT_ICON;
    if(isIpad)
    {
        /*
        //307x153
        winIcon->rect.relative.size.width = 0.40;
        winIcon->rect.relative.size.height = 0.20;
        */
        //307x307
        winIcon->rect.relative.size.width = 0.40;
        winIcon->rect.relative.size.height = 0.40;
    }else
    { 
        /*
        //160x80
        winIcon->rect.relative.size.width = 0.50;
        winIcon->rect.relative.size.height = 0.25;
        */

        winIcon->rect.relative.size.width = 0.55;
        winIcon->rect.relative.size.height = 0.55;
    }
    winIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - winIcon->rect.relative.size.width / 2.0,
                                                [[SingleGraph sharedSingleGraph] screen].relative.size.height / 2.0 - winIcon->rect.relative.size.height /2.0);
    //ipad - 256x256
    [winIcon AssignTextureName: @"win_icon.png"];
    winIcon->blendNeeded = YES;
    [interfaceObjs insertObject: winIcon atIndex: INT_WIN_ICON];

    //////////////
    //game start icon
    //////////////
    Button *startIcon = [[Button alloc] init];
    startIcon->type = BT_ICON;
    if(isIpad)
    {
        //307x307
        startIcon->rect.relative.size.width = 0.40;
        startIcon->rect.relative.size.height = 0.40;
    }else
    {
       
        startIcon->rect.relative.size.width = 0.55;
        startIcon->rect.relative.size.height = 0.55;
    }
    startIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - startIcon->rect.relative.size.width / 2.0,
                                                  [[SingleGraph sharedSingleGraph] screen].relative.size.height / 2.0 - startIcon->rect.relative.size.height /2.0);
    //ipad - 256x256
    [startIcon AssignTextureName: @"start_icon.png"];
    startIcon->blendNeeded = YES;
    [interfaceObjs insertObject: startIcon atIndex: INT_START_ICON];
    
    //////////////
    //game loose icon
    //////////////
    Button *looseIcon = [[Button alloc] init];
    looseIcon->type = BT_ICON;
    if(isIpad)
    {
       /*
        //307x153
        looseIcon->rect.relative.size.width = 0.40;
        looseIcon->rect.relative.size.height = 0.20;
       */
        //307x307
        looseIcon->rect.relative.size.width = 0.40;
        looseIcon->rect.relative.size.height = 0.40;
        
    }else
    {
        /*
        //160x80
        looseIcon->rect.relative.size.width = 0.50;
        looseIcon->rect.relative.size.height = 0.25;
         */
        //160x160
        looseIcon->rect.relative.size.width = 0.50;
        looseIcon->rect.relative.size.height = 0.50;
    }
    looseIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - looseIcon->rect.relative.size.width / 2.0,
                                                  [[SingleGraph sharedSingleGraph] screen].relative.size.height / 2.0 - looseIcon->rect.relative.size.height /2.0);
    //ipad, iphone - 256x256
    [looseIcon AssignTextureName: @"loose_icon.png"];
    looseIcon->blendNeeded = YES;
    [interfaceObjs insertObject: looseIcon atIndex: INT_LOOSE_ICON];
    
    ////////////
    //drill board
    ////////////
    Button *drillBoardIcon = [[Button alloc] init];
    drillBoardIcon->type = BT_ICON;
    if(isIpad)
    {
        //537x115
        drillBoardIcon->rect.relative.size.width = 0.7;
        drillBoardIcon->rect.relative.size.height = 0.15;
    }else
    {
        //224x48
        drillBoardIcon->rect.relative.size.width = 0.7;
        drillBoardIcon->rect.relative.size.height = 0.15;
    }
    
    drillBoardIcon->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - [drillBoardIcon HalfWidthRelative],
                                                       [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemInvB->rect.relative.size.height- drillBoardIcon->rect.relative.size.height - 0.05);

    //ipad - 512x128 , iphone - 256x64
    [drillBoardIcon AssignTextureDouble : @"drill_board_icon.png" : @"drill_board_icon-ipad.png"];
    drillBoardIcon->blendNeeded = YES;
    [interfaceObjs insertObject: drillBoardIcon atIndex: INT_DRILLBOARD_ICON];
    
    
    ////////////
    //drill board stick to help visalise drilling
    ////////////
    Button *drillStick = [[Button alloc] init];
    drillStick->type = BT_ICON;
    if(isIpad)
    {
        //115x115
        drillStick->rect.relative.size.width = drillBoardIcon->rect.relative.size.height;
        drillStick->rect.relative.size.height = drillBoardIcon->rect.relative.size.height;
    }else
    {
        //48x48
        drillStick->rect.relative.size.width = drillBoardIcon->rect.relative.size.height;
        drillStick->rect.relative.size.height = drillBoardIcon->rect.relative.size.height;
    }
    drillStick->rect.relative.origin = CGPointMake([drillBoardIcon CenterPointRelative].x - [drillStick HalfWidthRelative],
                                                   [drillBoardIcon CenterPointRelative].y - [drillStick HalfHeightRelative]);
    //ipad - 128x128, iphone - 64x64
    [drillStick AssignTextureDouble : @"drill_stick.png" : @"drill_stick-ipad.png"];
    drillStick->blendNeeded = YES;
    [interfaceObjs insertObject: drillStick atIndex : INT_DRILL_STICK_ICON];
    
    ////////////
    //item drop disallowed
    ////////////
    Button *itemDisallowed = [[Button alloc] init];
    itemDisallowed->type = BT_ICON;
    itemDisallowed->rect.relative.origin = CGPointMake(0, 0);
    //make it 4 times less than inventory item
    //ipad - 32x32 iphone - 15x15
    itemDisallowed->rect.relative.size.width = itemSize.relative.size.width / 4.0;
    itemDisallowed->rect.relative.size.height = itemSize.relative.size.height / 4.0;
    //32x32
    [itemDisallowed AssignTextureName: @"disallowed_icon.png" ];
    itemDisallowed->blendNeeded = YES;
    itemDisallowed->manualDraw = YES;
    [interfaceObjs insertObject: itemDisallowed atIndex: INT_ITEM_DISALLOWED];
    
    ////////////
    //item put on fire allowed
    ////////////
    Button *itemOnFire = [[Button alloc] init];
    itemOnFire->type = BT_ICON;
    itemOnFire->rect.relative.origin = CGPointMake(0, 0);
    //make it 4 times less than inventory item
    //ipad - 32x32 iphone - 15x15
    itemOnFire->rect.relative.size.width = itemSize.relative.size.width / 4.0;
    itemOnFire->rect.relative.size.height = itemSize.relative.size.height / 4.0;
    //32x32
    [itemOnFire AssignTextureName: @"put_on_fire_icon.png" ];
    itemOnFire->blendNeeded = YES;
    itemOnFire->manualDraw = YES;
    [interfaceObjs insertObject: itemOnFire atIndex: INT_ITEM_ON_FIRE];
    
    ////////////
    //item put on raft allowed
    ////////////
    Button *itemOnRaft = [[Button alloc] init];
    itemOnRaft->type = BT_ICON;
    itemOnRaft->rect.relative.origin = CGPointMake(0, 0);
    //make it 4 times less than inventory item
    //ipad - 32x32 iphone - 15x15
    itemOnRaft->rect.relative.size.width = itemSize.relative.size.width / 4.0;
    itemOnRaft->rect.relative.size.height = itemSize.relative.size.height / 4.0;
    //32x32
    [itemOnRaft AssignTextureName: @"put_on_raft_icon.png" ];
    itemOnRaft->blendNeeded = YES;
    itemOnRaft->manualDraw = YES;
    [interfaceObjs insertObject: itemOnRaft atIndex: INT_ITEM_ON_RAFT];
    
    ////////////
    //mark the place when item is dragged over (mouth, hand)
    ////////////
    Button *itemPlaceMark = [[Button alloc] init];
    itemPlaceMark->type = BT_ICON;
    itemPlaceMark->rect.relative.origin = CGPointMake(0, [[SingleGraph sharedSingleGraph] screen].relative.size.height - itemSize.relative.size.height);
    //ipad - 128x128 iphone - 60x60, iphone long 63.1x63.1
    itemPlaceMark->rect.relative.size.width = itemSize.relative.size.width;
    itemPlaceMark->rect.relative.size.height = itemSize.relative.size.height;
    //[itemPlaceMark AssignTextureName: @"item_placemark.png" ];
    //ipad - 128x128, iphone - 64x64
    [itemPlaceMark AssignTextureDouble : @"item_placemark.png" : @"item_placemark-ipad.png"];
    itemPlaceMark->blendNeeded = YES;
    itemPlaceMark->manualDraw = YES;
    [interfaceObjs insertObject: itemPlaceMark atIndex: INT_ITEM_PLACEMARK];


    /////////////
    //begin building shelter
    /////////////
    Button *startShelterButt = [[Button alloc] init];
    startShelterButt->type = BT_BUTTON_AUTO;
    //ipad - 128x128, iphone - 60x60, iphone long 63.1x63.1
    startShelterButt->rect.relative.size.width = itemSize.relative.size.width;
    startShelterButt->rect.relative.size.height = itemSize.relative.size.height;
    startShelterButt->rect.relative.origin = CGPointMake([[SingleGraph sharedSingleGraph] screen].relative.size.width / 2.0 - startShelterButt->rect.relative.size.width / 2.0,
                                                         [[SingleGraph sharedSingleGraph] screen].relative.size.height - 2 * startShelterButt->rect.relative.size.height);
    
    //ipad - 128x128, iphone - 64x64
    [startShelterButt AssignTextureDouble: @"shelter_begin_butt.png" :  @"shelter_begin_butt-ipad.png"];
    [startShelterButt AssignSelectedTextureDouble: @"shelter_begin_sel_butt.png" : @"shelter_begin_sel_butt-ipad.png"];
    startShelterButt->blendNeeded = YES;
    [interfaceObjs insertObject: startShelterButt atIndex: INT_SHELTER_BEGIN_BUTT];

    ////////////
    //item put on shelter allowed
    ////////////
    Button *itemOnShelter = [[Button alloc] init];
    itemOnShelter->type = BT_ICON;
    itemOnShelter->rect.relative.origin = CGPointMake(0, 0);
    //make it 4 times less than inventory item
    //ipad - 32x32 iphone - 15x15
    itemOnShelter->rect.relative.size.width = itemSize.relative.size.width / 4.0;
    itemOnShelter->rect.relative.size.height = itemSize.relative.size.height / 4.0;
    //32x32
    [itemOnShelter AssignTextureName: @"put_on_shelter_icon.png" ];
    itemOnShelter->blendNeeded = YES;
    itemOnShelter->manualDraw = YES;
    [interfaceObjs insertObject: itemOnShelter atIndex: INT_ITEM_ON_SHELTER];

    
    //------ post processing
    [self HideAllOverlays];
    //calculate screen points
    for(Button *obj in  interfaceObjs)
    {
        [obj CalcScrPointsFromRelative: [[SingleGraph sharedSingleGraph] screen].points.size];
        /*
        NSLog(@"interface %@ - %f %f ; %f %f",obj->iconFile,  obj->rect.relative.size.width, obj->rect.relative.size.height,
                                              obj->rect.points.size.width, obj->rect.points.size.height);
        */
    }
}

#pragma mark - Day numbers

//intialize number for day represenatation
- (void) InitDayNumbersArray
{
    float relMargin = 0.01; //margin for icons from sides of screen
    
    Button *dayIcon = [interfaceObjs objectAtIndex: INT_DAY_ICON];
    //insertion order is important
    for (int i = 0; i < 10; i++)
    {
        Button *item = [[Button alloc] init];
        item->type = BT_ICON;
        item->rect.relative.origin = CGPointMake(dayIcon.rect.relative.size.width + relMargin * 2, relMargin);
        //ipad - 128x128 iphone - 60x60, iphone long 63.1x63.1
        if(isIpad)
        {
            //62x62
            item->rect.relative.size.width = 0.08;
            item->rect.relative.size.height = 0.08;
        }else
        {
            //32x32
            item->rect.relative.size.width = 0.10;
            item->rect.relative.size.height = 0.10;
        }
        item->visible = YES; //visibility will be checked manually depending on 'day' icon
        item->blendNeeded = YES;
        //ipad - 64x64, iphone - 64x64
        [item AssignTextureName: [NSString stringWithFormat:@"number%d.png" , i]];
        
        [dayNumbers insertObject:item atIndex:i];
    }
}

//draw number of day
- (void) DrawDayNumbers: (Environment*) env
{
    if([self IsVisible:INT_DAY_ICON])
    {
        //single digit day number
        if(env.dayNumber <= 9)
        {
            Button *object = [dayNumbers objectAtIndex: env.dayNumber ];
            [object Draw];
        }
        //double digit day number
        else if(env.dayNumber <= 99)
        {
            int firstDigit = env.dayNumber / 10;
            int secondDigit = env.dayNumber % 10;
            
            //first digit
            Button *object1 = [dayNumbers objectAtIndex: firstDigit ];
            [object1 Draw];
            
            //second digit
            Button *object2 = [dayNumbers objectAtIndex: secondDigit ];
            object2.rePosition = GLKVector2Make(object1.rect.relative.size.width * 0.75 ,0);
            object2.modelviewMat = GLKMatrix4MakeTranslation(object2.rePosition.x, 0, 0);
            [object2 Draw];
            //move back to be able to draw properly first digit (by moving back we simply et offset to 0)
            object2.rePosition = GLKVector2Make(0,0);
            object2.modelviewMat = GLKMatrix4MakeTranslation(object2.rePosition.x, 0, 0);
        }
    }
}


#pragma mark - Inventory items

//create inventory items from array
//always add at the same order as defined in enumInventoryItems structure
- (void) InitInventoryArray
{
    //NOTE: file names must mach order of enumInventoryItems
    NSArray *itemFileNames = [NSArray arrayWithObjects:
                              @"item_knife.png",
                              @"item_coconut.png",
                              @"item_coconut_half.png",
                              @"item_wood.png",
                              @"item_stick.png",
                              @"item_spear.png",
                              @"item_tinder.png",
                              @"item_kindling.png",
                              @"item_fish_raw.png",
                              @"item_fish_2_raw.png",
                              @"item_fish_cleaned.png",
                              @"item_fish_cooked.png",
                              @"item_leaf.png",
                              @"item_berries.png",
                              @"item_shell.png",
                              @"item_raincatch.png",
                              @"item_raincatch_full.png",
                              @"item_rock_flat.png",
                              @"item_deadfall_trap.png",
                              @"item_rat_raw.png",
                              @"item_rat_cleaned.png",
                              @"item_rat_cooked.png",
                              @"item_sharp_wood.png",
                              @"item_crab_raw.png",
                              @"item_crab_cooked.png",
                              @"item_raft_log.png",
                              @"item_rag.png",
                              @"item_sail.png",
                              @"item_stone.png",
                              @"item_smallpalm_leaf.png",
                              @"item_honeycomb.png",
                              @"item_sea_urchin.png",
                              @"item_sea_urchin_food.png",
                              @"item_egg.png",
                              @"item_egg_opened.png",
                              nil];
    
    //insertion order is important
    for (int i = 0; i < [itemFileNames count]; i++)
    {
        Button *item = [[Button alloc] init];
        item->rect.relative.origin = CGPointMake(0.0, 0.0);
        //ipad - 128x128 iphone - 60x60, iphone long 63.1x63.1
        item->rect.relative.size.width = itemSize.relative.size.width;
        item->rect.relative.size.height = itemSize.relative.size.height;
        item->visible = YES;
        item->blendNeeded = YES;
        //128x128, (OPTI could be 64x64 for standrad iphone, especially older iphone 3)
        [item AssignTextureName: [itemFileNames objectAtIndex:i]];
        
        [inventoryItems insertObject: item atIndex: i];
    }
    
    //calculate screen points
    for(Button *obj in inventoryItems)
    {
        [obj CalcScrPointsFromRelative: [[SingleGraph sharedSingleGraph] screen].points.size];
        
        /*
        NSLog(@"items %@ - %f %f ; %f %f",obj->iconFile,  obj->rect.relative.size.width, obj->rect.relative.size.height,
                                          obj->rect.points.size.width, obj->rect.points.size.height);
        */
    }
}

//draw inventory
- (void) DrawInventory: (Character*) character : (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates
{
    //items in inventory slots
    for (int i = 0; i < character.inventory.slotCount; i++)
    {
        if(character.inventory.itemSlots[i] != kItemEmpty)
        {
            Button *object = [inventoryItems objectAtIndex: character.inventory.itemSlots[i] ]; //17
            
            //begin inventory slot animation if needed
            [self InitiateSlotAnimation: character : i];

            object.rePosition = GLKVector2Make(slotCoordinates[i].relative.origin.x,
                                               slotCoordinates[i].relative.origin.y - [self CalculateSloAnimOffset:i]);
            object.modelviewMat = GLKMatrix4MakeTranslation(object.rePosition.x, object.rePosition.y, 0);
            
           // NSLog(@"%@ %d", object.iconFile, object.textureID);
            
            [object Draw];
        }
    }
    
    //draw dragged item
    if(character.inventory.grabbedItem.type != kItemEmpty)
    {
        Button *object = [inventoryItems objectAtIndex:character.inventory.grabbedItem.type];
        
        float relX = [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.x];
        float relY = [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.y];
        object.rePosition = GLKVector2Make(relX, relY);
        object.modelviewMat = GLKMatrix4MakeTranslation(object.rePosition.x, object.rePosition.y, 0);
        [object Draw];
    }
    
    //draw item in hand
    if(character.handItem.ID != kItemEmpty || character.prevHandItem.ID != kItemEmpty )
    {
        Button *object;
        
        if(character.handItem.ID != kItemEmpty)
        {
            object = [inventoryItems objectAtIndex:character.handItem.ID]; //draw real hand item
        }else
        {
            object = [inventoryItems objectAtIndex:character.prevHandItem.ID]; //draw backed up item
        }
        
        object.rePosition = GLKVector2Make(handCoordinates.relative.origin.x, handCoordinates.relative.origin.y);
        object.modelviewMat = GLKMatrix4MakeTranslation(object.rePosition.x, object.rePosition.y, 0);
        [object Draw];
    }
}


//draw item highlighter
- (void) DrawItemHighlighter: (Character*) character : (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates
{
    //when item is grabbed
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_EASY && character.inventory.grabbedItem.type != kItemEmpty)
    {
        //for every non-empty item slot, check weather grabbed item is combinable with that slots item, and mark it
        for(int i = 0; i < character.inventory.slotCount; i++)
        {
            if(character.inventory.itemSlots[i] != kItemEmpty)
            {
                for(int j = 0; j < character.inventory.itemCombinerCount; j++)
                {
                    if((character.inventory.itemCombiner[j].item1 == character.inventory.grabbedItem.type &&
                        character.inventory.itemCombiner[j].item2 == character.inventory.itemSlots[i])
                       ||
                       (character.inventory.itemCombiner[j].item2 == character.inventory.grabbedItem.type &&
                        character.inventory.itemCombiner[j].item1 == character.inventory.itemSlots[i]))
                    {
                        //combiner found in slot
                        //draw highlighted icon
                        Button *itemHighlighted = [interfaceObjs objectAtIndex: INT_ITEM_HIGHLIGHT];
                        itemHighlighted->visible = YES;
                        itemHighlighted.rePosition = GLKVector2Make(slotCoordinates[i].relative.origin.x, 0);
                        itemHighlighted.modelviewMat = GLKMatrix4MakeTranslation(itemHighlighted.rePosition.x, itemHighlighted.rePosition.y, 0);
                        [itemHighlighted Draw];
                        itemHighlighted->visible = NO;
                    }
                }
            }
        }
        
        //check weather item is edible or holdable and mark
        if(character.inventory.items[character.inventory.grabbedItem.type].holdable && character.handItem.ID == kItemEmpty && character.state == CS_BASIC)
        {
            Button *itemHighlighted = [interfaceObjs objectAtIndex: INT_ITEM_HIGHLIGHT];
            itemHighlighted->visible = YES;
            itemHighlighted.rePosition = GLKVector2Make(handCoordinates.relative.origin.x, 0);
            itemHighlighted.modelviewMat = GLKMatrix4MakeTranslation(itemHighlighted.rePosition.x, itemHighlighted.rePosition.y, 0);
            [itemHighlighted Draw];
            itemHighlighted->visible = NO;
        }
        if(character.inventory.items[character.inventory.grabbedItem.type].edible)
        {
            Button *itemHighlighted = [interfaceObjs objectAtIndex: INT_ITEM_HIGHLIGHT];
            itemHighlighted->visible = YES;
            itemHighlighted.rePosition = GLKVector2Make(mouthCoordinates.relative.origin.x, 0);
            itemHighlighted.modelviewMat = GLKMatrix4MakeTranslation(itemHighlighted.rePosition.x, itemHighlighted.rePosition.y, 0);
            [itemHighlighted Draw];
            itemHighlighted->visible = NO;
        }
    }
}


//draw place mork on inventory board when edible, holdable item is dragged over
- (void) DrawPlaceMark: (Character*) character: (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates
{
    Button *itemPlaceMark = [interfaceObjs objectAtIndex: INT_ITEM_PLACEMARK];
    if(itemPlaceMark->visible && character.inventory.grabbedItem.type != kItemEmpty)
    {
        //chose witch place to mark on inventory borard depending on type of item dragged
        if(character.inventory.items[character.inventory.grabbedItem.type].edible)
        {
            itemPlaceMark.rePosition = GLKVector2Make(mouthCoordinates.relative.origin.x, 0);
        }else
        if(character.inventory.items[character.inventory.grabbedItem.type].holdable)
        {
            itemPlaceMark.rePosition = GLKVector2Make(handCoordinates.relative.origin.x, 0);
        }
        itemPlaceMark.modelviewMat = GLKMatrix4MakeTranslation(itemPlaceMark.rePosition.x, itemPlaceMark.rePosition.y, 0);
        
        //we need to set manualDraw here not to draw in loop but only here, because visibility can not be checked here - it is set in other file
        itemPlaceMark->manualDraw = NO;
        [itemPlaceMark Draw];
        itemPlaceMark->manualDraw = YES;
    }else
    {
        itemPlaceMark->visible = NO; //if nothing is dragged currently
    }
}


//puts dissalowed icon over currently dragged item
//itemDisallowed->visible needs to be set in order to draw (is set in playscene)
//non-droppable items are marked here automatically, dropable items must be set in playsecene file
- (void) DrawDisallowedIcon: (Character*) character : (SScreenCoordinates *) slotCoordinates
{
    Button *itemDisallowed = [interfaceObjs objectAtIndex: INT_ITEM_DISALLOWED];
    
    //if item is not droppable, show always disapling when dragged
    if(character.inventory.grabbedItem.type != kItemEmpty && !character.inventory.items[character.inventory.grabbedItem.type].droppable)
    {
        itemDisallowed->visible = true;
    }
    //Special case -  generally not droppable, but when is about to be put on object, dont show dissalowed icon
    Button *itemOnRaft = [interfaceObjs objectAtIndex: INT_ITEM_ON_RAFT];
    if(character.inventory.grabbedItem.type == ITEM_SAIL && itemOnRaft->visible)
    {
        itemDisallowed->visible = false;
    }
    /*
    Button *itemOnShelter = [interfaceObjs objectAtIndex: INT_ITEM_ON_SHELTER];
    if(character.inventory.grabbedItem.type == ITEM_SMALLPALM_LEAF && itemOnShelter->visible)
    {
        itemDisallowed->visible = false;
    }
    */
    
    
    //if item is dragged on inventory board, dont show
    //check against middle of grabbed icon
    Button *itemInvB = [interfaceObjs objectAtIndex: INT_INVENTORY_BOARD];
    CGPoint ipos = CGPointMake(character.inventory.grabbedItem.position.x + slotCoordinates[0].points.size.width / 2.0 ,
                               character.inventory.grabbedItem.position.y + slotCoordinates[0].points.size.width / 2.0);
    
    if([itemInvB  RectContains: ipos])
    {
        itemDisallowed->visible = false;
    }
    
    //draw disabled icon
    if(itemDisallowed->visible && character.inventory.grabbedItem.type != kItemEmpty)
    {
        itemDisallowed.rePosition = GLKVector2Make([CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.x] + itemSize.relative.size.width,
                                                   [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.y]);
        itemDisallowed.modelviewMat = GLKMatrix4MakeTranslation(itemDisallowed.rePosition.x, itemDisallowed.rePosition.y, 0);
        
        //we need to set manualDraw here not to draw in loop but only here, because visibility can not be checked here - it is set in other file
        itemDisallowed->manualDraw = NO;
        [itemDisallowed Draw];
        itemDisallowed->manualDraw = YES;
    }else
    {
        itemDisallowed->visible = NO; //if nothing is dragged currently
    }
}


//puts "put on fire" icon over currently dragged item
- (void) DrawPutOnFireIcon: (Character*) character
{
    Button *itemOnFire = [interfaceObjs objectAtIndex: INT_ITEM_ON_FIRE];
        
    //draw "put on fire" icon
    if(itemOnFire->visible && character.inventory.grabbedItem.type != kItemEmpty)
    {
        itemOnFire.rePosition = GLKVector2Make([CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.x] + itemSize.relative.size.width,
                                               [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.y]);
        itemOnFire.modelviewMat = GLKMatrix4MakeTranslation(itemOnFire.rePosition.x, itemOnFire.rePosition.y, 0);
        
        //we need to set manualDraw here not to draw in loop but only here, because visibility can not be checked here - it is set in other file
        itemOnFire->manualDraw = NO;
        [itemOnFire Draw];
        itemOnFire->manualDraw = YES;
    }else
    {
        itemOnFire->visible = NO; //if nothing is dragged currently
    }
}

//puts "put on raft" icon over currently dragged item
- (void) DrawPutOnRaftIcon: (Character*) character
{
    Button *itemOnRaft = [interfaceObjs objectAtIndex: INT_ITEM_ON_RAFT];
    
    //draw "put on fire" icon
    if(itemOnRaft->visible && character.inventory.grabbedItem.type != kItemEmpty)
    {
        itemOnRaft.rePosition = GLKVector2Make([CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.x] + itemSize.relative.size.width,
                                               [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.y]);
        itemOnRaft.modelviewMat = GLKMatrix4MakeTranslation(itemOnRaft.rePosition.x, itemOnRaft.rePosition.y, 0);
        
        //we need to set manualDraw here not to draw in loop but only here, because visibility can not be checked here - it is set in other file
        itemOnRaft->manualDraw = NO;
        [itemOnRaft Draw];
        itemOnRaft->manualDraw = YES;
    }else
    {
        itemOnRaft->visible = NO; //if nothing is dragged currently
    }
}


//puts "put on shelter" icon over currently dragged item
- (void) DrawPutOnShelterIcon: (Character*) character
{
    Button *itemOnShelter = [interfaceObjs objectAtIndex: INT_ITEM_ON_SHELTER];
    
    //draw "put on fire" icon
    if(itemOnShelter->visible && character.inventory.grabbedItem.type != kItemEmpty)
    {
        itemOnShelter.rePosition = GLKVector2Make([CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.x] + itemSize.relative.size.width,
                                                 [CommonHelpers ConvertToRelative:character.inventory.grabbedItem.position.y]);
        itemOnShelter.modelviewMat = GLKMatrix4MakeTranslation(itemOnShelter.rePosition.x, itemOnShelter.rePosition.y, 0);
        
        //we need to set manualDraw here not to draw in loop but only here, because visibility can not be checked here - it is set in other file
        itemOnShelter->manualDraw = NO;
        [itemOnShelter Draw];
        itemOnShelter->manualDraw = YES;
    }else
    {
        itemOnShelter->visible = NO; //if nothing is dragged currently
    }
}


#pragma mark - Item animation

//start animating item in particular slot
- (void) StartSlotAnimation: (int) slodId
{
    itemSlotAnimation[slodId].enabled = YES;
    itemSlotAnimation[slodId].timeInAction = 0;
    itemSlotAnimation[slodId].actionTime = 0.3;
}

- (void) EndSlotAnimation: (int) slodId
{
    itemSlotAnimation[slodId].enabled = NO;
}

//check for start and start if needed
- (void) InitiateSlotAnimation: (Character*) character: (int) slodId
{
    if(character.inventory.lastAddedSlotId == slodId)
    {
        [self StartSlotAnimation: slodId];
        character.inventory.lastAddedSlotId = -1; //set this to -1, so we do not go here twice, but once after item is just added
    }
}

//function to support inventory item picking up animation
- (void) NillInventoryAnimation: (Character*) character
{
    for (int i = 0; i < character.inventory.slotCount; i++)
    {
        [self EndSlotAnimation: i];
    }
}


//update given slot animation
- (void) UpdateSlotAnimation: (Character*) character: (float) dt
{
    for (int i = 0; i < character.inventory.slotCount; i++)
    {
        //end slot animation when item is rmeoved
        if(character.inventory.itemSlots[i] == kItemEmpty)
        {
            [self EndSlotAnimation: i];
        }
        
        //update
        if(itemSlotAnimation[i].enabled)
        {
            itemSlotAnimation[i].timeInAction += dt;
            
            if(itemSlotAnimation[i].timeInAction < itemSlotAnimation[i].actionTime)
            {
                
            }else
            {
                [self EndSlotAnimation: i];
            }
        }
    }
}

//calculate Y offset of given slot animation, based on time animation has passed
- (float) CalculateSloAnimOffset: (int) slodId
{
    float itemSlideOffset = 0.0;
    float slideTopHeight = 0.1; //maxiumum 'y' height above item slot from where to start animating
    
    if(itemSlotAnimation[slodId].enabled)
    {
        //ranges form 0 to slideTopHeight
        itemSlideOffset = slideTopHeight * (1.0 - itemSlotAnimation[slodId].timeInAction / itemSlotAnimation[slodId].actionTime);
    }
    
    return itemSlideOffset;
}

#pragma mark - Additional functions

//how manu vertices needed for all interface objects
- (int) GetNumberOfTotalVertices
{
    int inventoryObjCount = (int)[inventoryItems count];
    int dayNumberObjCount = (int)[dayNumbers count];
    int interfaceObjectCount = 0;
    for(Button *obj in interfaceObjs)
    {
        //use only the ones we need to draw
        if(obj->type != BT_AREA)
        {
            interfaceObjectCount++;
        }
    }
    
    return (inventoryObjCount + interfaceObjectCount + dayNumberObjCount) * 4;
}


//set all interface elemnts hidden (except inventory items)
- (void) HideAllOverlays
{
    for(Button *obj in interfaceObjs)
    {
        obj->visible = false;
    }
}

//hide/show given elemnt from interface array
- (void) SetInterfaceVisibility: (enumInterfaceObjects) objId : (BOOL) visible
{
    Button *obj  = [interfaceObjs objectAtIndex:objId];
    obj->visible = visible;
}

//check visibility
- (BOOL) IsVisible: (enumInterfaceObjects) objId
{
    Button *obj  = [interfaceObjs objectAtIndex:objId];
    return obj->visible;
}


@end
