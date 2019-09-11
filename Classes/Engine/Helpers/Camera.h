//
//  Camera.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//  Camera management class

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "CommonHelpers.h"

@interface Camera : NSObject
{	
    GLKVector3 position; 
    GLKVector3 viewVector; //view vector of origin
    GLKVector3 upVector;
   	
    float xAngle; //current camera angle about X axis
    float yAngle; //current camera angle around Y axis from +z anti-clockwise
    
    //store prevois state vector values
    GLKVector3 backupPosition; 
    GLKVector3 backupViewVector; //origin vector
    
    //for closup/slide/direct actions determine destination points
    GLKVector3 destPosition; 
    GLKVector3 destViewVector; //origin vector
    SBasicAnimation actionCloseup; //for closeup actions
    SBasicAnimation actionSlide; //for slide actions
    SBasicAnimation actionDirect; //for slide actions
}

@property (readonly, nonatomic) GLKVector3 position;
@property (readonly, nonatomic) GLKVector3 viewVector;
@property (readonly, nonatomic) GLKVector3 upVector;
@property (readonly, nonatomic) float yAngle;
@property (readonly, nonatomic) float xAngle;
@property (readonly, nonatomic) SBasicAnimation actionCloseup;
@property (readonly, nonatomic) SBasicAnimation actionSlide;
@property (readonly, nonatomic) SBasicAnimation actionDirect;

- (void) PositionCamera: (GLKVector3)pos : (GLKVector3)eye : (GLKVector3) up;
// freelook movements
- (void) RotateViewY: (float) angle;
- (void) RotateViewUpDown: (float) angle;
- (void) LiftCamera: (float) height;

//DON'T use action functions simultaniously
//closeup action
- (void) StartCloseupAction:(GLKVector3) viewPoint : (float) distanceFromObject : (float) actionTime;
- (void) UpdateCloseupAction:(float) dt;
//slide
- (void) StartSlideAction:(GLKVector3) destPoint : (float) actionTime;
- (void) UpdateSlideAction:(float) dt;
//direct
- (void) StartDirectAction:(GLKVector3) destPos : (GLKVector3) viewVect : (float) actionTime;
- (void) UpdateDirectAction:(float) dt;

- (void) RestoreVectors;
- (void) RestoreVectorsWithViewAt :(GLKVector3) viewPoint;
- (void) RestoreVectorsWithViewVector: (GLKVector3) viewV;
- (void) UpdateActions: (float) dt;
- (BOOL) IsInAction;
- (void) NillActions;

//movement
- (void) MoveToPosition: (GLKVector3) newPosition;
- (void) AddVector: (GLKVector3) vector;
- (void) AddVectorFixedY: (GLKVector3) vector : (float) height;
//- (GLKVector3) GetViewVector;
- (GLKVector3) GetLookAtPoint;
- (GLKVector3) PointInFrontOfCamera: (float) distanceFromCharacter;
- (void) RecalCulateXYAngles;
- (float) HorAngleBetweenViewAndVector: (GLKVector3) vector;
@end

