//
//  ViewController.m
//  The Survivor
//
//  Created by Ivars Rusbergs on 9/13/13.
//  Copyright (c) 2013 Ivars Rusbergs. All rights reserved.
//
// STATUS: OK

#import "ViewController.h"


@interface ViewController () {
    EAGLContext *context;
    PlayScene *playScene;
    MainMenuScene *mainMenuScene;
    
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) PlayScene *playScene;
@property (strong, nonatomic) MainMenuScene *mainMenuScene;

- (void)setupGL;
- (void)tearDownGL;
- (void) InitGameSceneData;
@end


@implementation ViewController

@synthesize context,playScene, mainMenuScene;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
       // NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    //view.drawableColorFormat = GLKViewDrawableColorFormatSRGBA8888;
    ///view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    view.multipleTouchEnabled = YES;
    /*
    NSArray *gestures = view.gestureRecognizers;
    for(UIGestureRecognizer *gesture in gestures)
    {
        if([gesture isKindOfClass: [UIScreenEdgePanGestureRecognizer class]])
        {
            gesture.enabled = NO;
        }
    }
    */
    
    
    //NSLog(@"%f", view.contentScaleFactor);
    
    //setu up graphics
    [self setupGL];
    
    //set up states
    [[SingleDirector sharedSingleDirector] setGameScene:SC_MAIN_MENU];
    
    //set up sounds
    [[SingleSound sharedSingleSound] InitOpenAL];

}

//first place to get correct bounds, but without orientation, so check largest value as width for landscape
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if(![[SingleDirector sharedSingleDirector] initialized]) //make sure if method called twice to initialize only once
    {
        CGSize scrSize = self.view.bounds.size;
        //make sure largest value is always width, because orientation is not performed here
        if(scrSize.width < scrSize.height)
        {
            scrSize.width = self.view.bounds.size.height;
            scrSize.height = self.view.bounds.size.width;
        }
        
        [[SingleDirector sharedSingleDirector] GetCurrentDevice: scrSize]; //set  deviceType
        
        //frames per second differs on different devices
        int prefferedFPS;
        switch ([[SingleDirector sharedSingleDirector] deviceType])
        {
            case DEVICE_IPHONE_CLASSIC:
                prefferedFPS = 30;
                break;
            case DEVICE_IPHONE_RETINA:
                prefferedFPS = 30;
                break;
            case DEVICE_IPHONE_5:
                prefferedFPS = 30;
                break;
            case DEVICE_IPAD_CLASSIC:
                prefferedFPS = 30;
                break;
            case DEVICE_IPAD_RETINA:
                prefferedFPS = 30;
                break;
            case DEVICE_IPHONE_6:
                prefferedFPS = 30;
                break;
            case DEVICE_IPHONE_6_PLUS:
                prefferedFPS = 30;
                break;
            default:
                prefferedFPS = 30;
                break;
        }
        
        [self setPreferredFramesPerSecond: prefferedFPS];
        
        //multisample set up
        //do not put multisample on ipod 2gen and iphone3s
        GLKView *view = (GLKView *)self.view;
        if([[SingleDirector sharedSingleDirector] deviceType] != DEVICE_IPHONE_CLASSIC)
        {
            view.drawableMultisample = GLKViewDrawableMultisample4X;
        }
       // NSLog(@"%d", [[SingleDirector sharedSingleDirector] deviceType]);
        
        [[SingleGraph sharedSingleGraph] SetScreenParameters: scrSize];
        [[SingleGraph sharedSingleGraph] SetUpProjectionMatrices]; //takes screen size to determine proj matrices
        
        [self InitGameSceneData];
        
        [[SingleDirector sharedSingleDirector] setInitialized: YES];
    }
   // NSLog(@"w %f %f",scrSize.width, scrSize.height );
}


/*
 //gets called a bit after viewillappear, but is called also when view changes orientation
- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    //[self InitGameSceneData];
    //NSLog(@"L %f %f",self.view.bounds.size.width,self.view.bounds.size.height );
}
*/

- (void)dealloc
{    
   // [super viewDidUnload];  //#NOTE: this was not here in this template
    
    //clear graphics
    [self tearDownGL];
    
    //clear sounds
    [[SingleSound sharedSingleSound] CleanUpOpenAL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        //clear graphics
        [self tearDownGL];
        
        //clear sounds
        [[SingleSound sharedSingleSound] CleanUpOpenAL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

//---- For IOS 5 only
//NOTE: plist orientations setup does not work on ios 5

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //NSLog(@"auto rotate ios 5");
    if(interfaceOrientation == UIInterfaceOrientationPortrait ||
       interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


//---- For IOS 6 only
//NOTE: if plist orientations are not set, implement these functions
/*
- (BOOL)shouldAutorotate
{
   // NSLog(@"auto rotate ios 6");
    return YES;
}

- (NSInteger)supportedInterfaceOrientations
{
   // NSLog(@"auto rotate ios 6");
    return UIInterfaceOrientationMaskLandscape;
}
*/
 
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    //[self setPreferredFramesPerSecond: PREFERRED_FPS];
    
    //set default states
    //we first need to set ass it is, so it changes properly in graph singleton
    [[SingleGraph sharedSingleGraph] SetCullFace:glIsEnabled(GL_CULL_FACE)]; //as it is
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];//switch OFF, if wasnt
    
    [[SingleGraph sharedSingleGraph] SetDepthTest:glIsEnabled(GL_DEPTH_TEST)]; //as it is
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES]; //switch ON, if wasnt
    
    GLboolean bdepthMask;
    glGetBooleanv(GL_DEPTH_WRITEMASK, &bdepthMask);
    [[SingleGraph sharedSingleGraph] SetDepthMask:bdepthMask];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    
    [[SingleGraph sharedSingleGraph] SetBlend:glIsEnabled(GL_BLEND)];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    [[SingleGraph sharedSingleGraph] SetDefaultBlendFunc:F_GL_ONE];
    
    glClearColor(0.1f, 0.1f, 1.0f, 1.0f);
}

//function is separated from setupGL, because we need set screen bound dependant functions in toher method
- (void) InitGameSceneData
{    
    mainMenuScene = [[MainMenuScene alloc] init];
    playScene = [[PlayScene alloc] init];
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [[SingleGraph sharedSingleGraph] CleanUpGraph];
    
    [mainMenuScene ResourceCleanUp];
    [playScene ResourceCleanUp];
    
    [[SingleDirector sharedSingleDirector] setInitialized:NO]; //just in case
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float dt = self.timeSinceLastUpdate;
    
    switch([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene Update:dt];
            break;
        case SC_PLAY:
            [playScene Update:dt];
            break;
        default:
            break;
    }
    // NSLog(@"%f", 1 / self.timeSinceLastUpdate);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    switch ([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene Render];
            break;
        case SC_PLAY:
            [playScene Render];
            break;
        default:
            break;
    }
    
    // NSLog(@"-- end of frame");
}

#pragma mark -  Touches management

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene TouchesBegin: touches];
            break;
        case SC_PLAY:
            [playScene TouchesBegin: touches];
            break;
        default:
            break;
    }
    
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene TouchesMove:touches:self];
            break;
        case SC_PLAY:
            [playScene TouchesMove:touches:self];
            break;
        default:
            break;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene TouchesEnd: touches : playScene];
            break;
        case SC_PLAY:
            [playScene TouchesEnd: touches];
            break;
        default:
            break;
    }
}

//canceled by incoming phone etc
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[SingleDirector sharedSingleDirector] gameScene])
    {
        case SC_MAIN_MENU:
        case SC_MAIN_MENU_PAUSE:
            [mainMenuScene TouchesCancel: touches : playScene];
            break;
        case SC_PLAY:
            [playScene TouchesCancel: touches];
            break;
        default:
            break;
    }
}


@end
