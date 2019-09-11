//
//  PlayScene.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// In-game scene management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleDirector.h"
#import "CommonHelpers.h"
#import "SingleSound.h"
#import "SingleGraph.h"
#import "MacrosAndStructures.h"
#import "Environment.h"
#import "Character.h"
#import "Terrain.h"
#import "SkyDome.h"
#import "Ocean.h"
#import "Clouds.h"
#import "Objects.h"
#import "Interface.h"
#import "Rain.h"
#import "Interaction.h"
#import "Particles.h"

@interface PlayScene : NSObject
{
    //configuration
    int vieportParams[4];
    //matrices
    GLKMatrix4 modelViewMatrix;
    GLKMatrix4 modelViewProjectionMatrix;
    
    //touch parameters
    NSTimeInterval lastPickTouch; //last picking touch timestamp
    
    //game objects
    Environment *environment;
    Interaction *interaction;
    Character *character;
    //Overlays *overlay;
    Terrain *terrain;
    SkyDome *skyDome;
    Ocean *ocean;
    Clouds *clouds;
    Objects *objects;
    Interface *interface;
    Rain *rain;
    Particles *particles;
}

@property (strong, nonatomic) Environment *environment;
@property (strong, nonatomic) Interaction *interaction;
@property (strong, nonatomic) Character *character;
@property (strong, nonatomic) Terrain *terrain;
@property (strong, nonatomic) SkyDome *skyDome;
@property (strong, nonatomic) Ocean *ocean;
@property (strong, nonatomic) Clouds *clouds;
@property (strong, nonatomic) Objects *objects;
@property (strong, nonatomic) Interface *interface;
@property (strong, nonatomic) Rain *rain;
@property (strong, nonatomic) Particles *particles;

- (void) ResetData;
- (void) NillData;
- (void) SetupRendering;
- (void) Update: (float) dt;
- (void) Render;
- (void) ResourceCleanUp;

- (void) TouchesBegin:(NSSet *)touches;
- (void) TouchesMove:(NSSet *)touches: (GLKViewController*) vc;
- (void) TouchesEnd:(NSSet *)touches;
- (void) TouchesCancel:(NSSet *)touches;
@end

