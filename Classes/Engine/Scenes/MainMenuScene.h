//
//  MainMenuScene.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Main menu scene management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SingleDirector.h"
#import "SingleSound.h"
#import "SingleGraph.h"
#import "MacrosAndStructures.h"
#import "Button.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "PlayScene.h"


@interface MainMenuScene : NSObject
{
    //universal geometry
    GeometryShape *menuMesh;
    
    //array of interface objects
    NSMutableArray *menuObjs;
    
    BOOL justEntered; //variable that is used to determine first time when entered into menu scene,
                      //use it because we can not control entering into menu scene from app delegate
                      //use it in in update function to determine actions taht are performed only once
    
    CGPoint touchLastLocation; //fro dragging in touch move store previous position
    
    float menuBeginningY; //menu top coordinate
}
@property (strong, nonatomic) GeometryShape *menuMesh;
@property (strong, nonatomic, readonly) NSMutableArray *menuObjs;


- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update: (float) dt;
- (void) Render;
- (void) ResourceCleanUp;
- (void) InitMenuArray;
- (int)  GetNumberOfTotalVertices;

- (void) StartLaunchSlide;
- (void) StartInfoSlide;
- (void) StartInfoBackSlide;

- (void) TouchesBegin:(NSSet *)touches;
- (void) TouchesMove:(NSSet *)touches: (GLKViewController*) vc;
- (void) TouchesEnd:(NSSet *)touches : (PlayScene*) plSc;
- (void) TouchesCancel:(NSSet *)touches : (PlayScene*) plSc;

@end