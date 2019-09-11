//
//  Rain.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Rain engine

#import <Foundation/Foundation.h>
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "SingleGraph.h"
#import "Character.h"
#import "Environment.h"
#import "Shelter.h"

@interface Rain : NSObject
{
    //geometry
    GeometryShape *mesh;
    
    //effects
    GLKBaseEffect *effect;
    
    //parameters
    BOOL enabled; //weather rain is rendered or not
    GLKVector3 position; //position of emiting 
    float lowerBound; //y coordinate when particle block dissapers
    float rainDropSize; 
    float leftPosition; //left starting point of rain (both x and y) (+leftPosition .... -leftPosition)

    //geometry params
    int numberOfPatches; //number of rain patches
    SObjectPatch *rainPatches; //holds indexes in mesh
    int dropsPerSide; //how many raind drop row and colums are in single rain patch
    
    //matrices
    GLKMatrix4 globalTransMat;
    
    //daytime coloring
    //GLKVector4 dayTimeColor;
    //GLKVector4 middayColor, eveningColor, nightColor, morningColor;
    SDaytimeColors coloring; //#v1.1.
}
@property (strong, nonatomic) GeometryShape *mesh;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (nonatomic) BOOL enabled;

- (id) initWithParams: (Character*) character;
- (void) ResetData;
- (void) InitGeometry: (Character*) character;
- (void) SetupRendering;
- (void) Update: (float)dt: (float)curTime: (GLKMatrix4*) modelviewMat : (Character*) character: (Environment*) env : (Shelter*) shelter;
- (void) Render;
- (void) ResourceCleanUp;
- (void) SetVelocity: (SObjectPatch*) p;
- (void) Start;
- (void) Stop;
@end
