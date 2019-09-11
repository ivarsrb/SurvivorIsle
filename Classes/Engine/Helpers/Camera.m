//
//  Camera.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "Camera.h"

@implementation Camera

@synthesize position, viewVector, upVector, yAngle, actionCloseup, actionSlide, xAngle, actionDirect;

//takes position in real space, and vie and up vectors of origin
- (void) PositionCamera: (GLKVector3) pos: (GLKVector3) viewV : (GLKVector3) upV
{
    position = pos;                         
    viewVector = GLKVector3Normalize(viewV);
    upVector = GLKVector3Normalize(upV);
    
    [self NillActions];
   
    [self RecalCulateXYAngles];
    
    /*
    xAngle = 0.0; //angle around x axis
    yAngle = [CommonHelpers AngleBetweenVectorAndZ: viewVector]; //angle around y axis
    //NSLog(@"subbed %f", yAngle);
     */
}

- (void) LiftCamera: (float) height
{
    //view.y     = height + view.y - position.y;
	position.y = height;  
}


//move camera to new position
- (void) MoveToPosition: (GLKVector3) newPosition
{
   // GLKVector3 vvector = GLKVector3Subtract(view, position);
    
    position = newPosition;
   // view = GLKVector3Add(position, vvector);
}

//add vector to position
- (void) AddVector:(GLKVector3)vector
{
    position = GLKVector3Add(position, vector);
   // view = GLKVector3Add(view, vector);
}

//add vector to position with fixed height
- (void) AddVectorFixedY: (GLKVector3) vector : (float)height
{
    position = GLKVector3Add(position, vector);
 //   view = GLKVector3Add(view, vector);
    [self LiftCamera: height];
}

//rotate view point around y axis, first 2 params are current location of camera vector, 3 - angle of rotation
- (void) RotateViewY: (float) angle
{
    if(![self IsInAction]) //dont allow during actions
    {
        yAngle += angle;
        
        if(yAngle >= PI_BY_2)
        {
            yAngle = yAngle - PI_BY_2;
        }else
        if(yAngle <= -PI_BY_2)
        {
            yAngle = yAngle + PI_BY_2;
        }
        [CommonHelpers RotateY: &viewVector : angle];
    }
} 

//lift view up and down by given angle
- (void) RotateViewUpDown: (float) angle
{ 
    if(![self IsInAction])
    {
        xAngle += angle;
        
        //up/down looking restrictions
        if(xAngle >= M_PI_2 - 0.6 && angle > 0)
        {
            //xAngle = M_PI_2 - 0.6;
            xAngle -= angle;
            return; 
        }
        if(xAngle <= -M_PI_2 + 0.6 && angle < 0)
        {
            //xAngle = -M_PI_2 + 0.6;
            xAngle -= angle;
            return; 
        }
        
        [CommonHelpers RotateVectorByHorizontalPLane: &viewVector : -angle];
        
        /*
        GLKVector3 tvector; //temporary vector	
        
        float tempz, //temporary coordinate
              cosa; //cosine between vector and x axis
        int negator; //used to store negative or pozitive x value sign
        
        // # 1. Move vector to 0,0,0
        tvector = viewVector;//[self GetViewVector];
        float sqrtTvector = sqrt(tvector.x * tvector.x + tvector.z * tvector.z); //temp variable
        // # 2a. Cos alpha from centered vector    
        cosa = tvector.z / sqrtTvector;
        // # 2. Stick vector to Z axis, so it can rotate around X axis   
        tvector.z = sqrtTvector;
        if(tvector.x < 0)
            negator = -1;
        else
            negator = 1;
        tvector.x = 0;
        // # 3. Rotate vector by recieved degrees
        //[self RotateX: &tvector : angle];   //rotate vector by the given angle
        [CommonHelpers RotateX:&tvector :-angle];
        // # 2. Rotate back to previous normal position
        tempz = tvector.z; //store for later use
        tvector.z = tvector.z * cosa; 
        tvector.x = sqrt(tempz * tempz - tvector.z * tvector.z) * negator;
        viewVector = tvector;

        // # 1. Translate back to start position
        //view = GLKVector3Add(tvector, position);
        */
    }
}


#pragma mark - Movement special action

//move camera view to given point
//viewPoint - point to which view is directed
//distanceFromObject how far position has to be from object
- (void) StartCloseupAction: (GLKVector3) viewPoint : (float) distanceFromObject : (float) actionTime
{
    if(![self IsInAction])
    {
        //set action parameters
        actionCloseup.enabled = true;
        actionCloseup.actionTime = actionTime;
        actionCloseup.timeInAction = 0;
        
        //store previous positions
        backupViewVector = viewVector;
        backupPosition = position;
        
        //set camera to look at viewpoint
        destPosition = [CommonHelpers PointOnLine: position : viewPoint  : -distanceFromObject]; //point that is distance from view point to previous position
        destViewVector = [CommonHelpers GetVectorFrom2Points: destPosition : viewPoint : NO];
    }
}

//closeup moving prcess
- (void) UpdateCloseupAction:(float) dt
{
    if(actionCloseup.enabled)
    {
        if(actionCloseup.timeInAction < 1.0)
        {
            float rate = 1.0 / actionCloseup.actionTime; //movement rate (from 0 to 1)
            actionCloseup.timeInAction += rate * dt;
            
            //move vectors
            position = GLKVector3Lerp(backupPosition, destPosition, actionCloseup.timeInAction);
            viewVector = GLKVector3Lerp(backupViewVector, destViewVector, actionCloseup.timeInAction);
            
            [self RecalCulateXYAngles];
        }else
        {
            actionCloseup.enabled = false;
        }
    }
}

//slide action is when position is slowly slid to the destination point, and virew vectors slides accordingly
//destPoint - position ends in destination point, and view vector acordingly
- (void) StartSlideAction:(GLKVector3) destPoint: (float) actionTime
{
    if(![self IsInAction])
    {
        //set action parameters
        actionSlide.enabled = true;
        actionSlide.actionTime = actionTime;
        actionSlide.timeInAction = 0;
        
        //store previous positions
        backupViewVector = viewVector;
        backupPosition = position;
        
        //set camera to destination
        //destView = GLKVector3Add(destPoint, [self GetViewVector]);
        destPosition = destPoint;
    }
}
//slide moving prcess
- (void) UpdateSlideAction:(float) dt
{
    if(actionSlide.enabled)
    {
        if(actionSlide.timeInAction < 1.0)
        {
            float rate = 1.0 / actionSlide.actionTime; //movement rate (from 0 to 1)
            actionSlide.timeInAction += rate * dt;
            
            //move vectors
            //viewVector = GLKVector3Lerp(backupViewVector, destViewVector, actionSlide.timeInAction);
            position = GLKVector3Lerp(backupPosition, destPosition, actionSlide.timeInAction);
           
            [self RecalCulateXYAngles];
        }else
        {
            actionSlide.enabled = false;
        }
    }
}

//direct action is when position goes to destPos and view is turned to viewvector
- (void) StartDirectAction: (GLKVector3) destPos : (GLKVector3) viewVect : (float) actionTime
{
    if(![self IsInAction])
    {
        //set action parameters
        actionDirect.enabled = true;
        actionDirect.actionTime = actionTime;
        actionDirect.timeInAction = 0;
        
        //store previous positions
        backupViewVector = viewVector;
        backupPosition = position;
        //!!! if something wrong with yangle, save the backup here and later restore
        
        //set camera to destination
        destViewVector = viewVect;
        destPosition = destPos;
    }
}

//slide moving prcess
- (void) UpdateDirectAction: (float) dt
{
    if(actionDirect.enabled)
    {
        if(actionDirect.timeInAction < 1.0)
        {
            float rate = 1.0 / actionDirect.actionTime; //movement rate (from 0 to 1)
            actionDirect.timeInAction += rate * dt;
            
            //move vectors
            viewVector = GLKVector3Normalize( GLKVector3Lerp(backupViewVector, destViewVector, actionDirect.timeInAction) );
            //NSLog(@"%f", GLKVector3Length(viewVector));
            
            position = GLKVector3Lerp(backupPosition, destPosition, actionDirect.timeInAction);
            
            [self RecalCulateXYAngles];
        }else
        {
            actionDirect.enabled = false;
        }
    }
}

//restore to previous position and view vectors
- (void) RestoreVectors
{
    viewVector = backupViewVector;
    position = backupPosition;
    [self NillActions];
    [self RecalCulateXYAngles];
}

//restore to previous position and view vectors
//restores original camera position but view is turned to given point
- (void) RestoreVectorsWithViewAt: (GLKVector3) viewPoint
{
    position = backupPosition;
    viewVector = [CommonHelpers GetVectorFrom2Points: position : viewPoint : NO];
    
    [self NillActions];
    [self RecalCulateXYAngles];
}

//restore previous position with new passed view vector
//viewV - MUST be normalized new view vector
- (void) RestoreVectorsWithViewVector: (GLKVector3) viewV
{
    position = backupPosition;
    viewVector = viewV;
    
    [self NillActions];
    [self RecalCulateXYAngles];
}

//update camera actions
- (void) UpdateActions: (float) dt
{
    [self UpdateCloseupAction: dt];
    [self UpdateDirectAction: dt];
    [self UpdateSlideAction: dt];
}

//if currently camera is in any slide speial action
- (BOOL) IsInAction
{
    return (actionCloseup.enabled || actionSlide.enabled || actionDirect.enabled);
}

//stop all actions
- (void) NillActions
{
    actionCloseup.enabled = false;
    actionSlide.enabled = false;
    actionDirect.enabled = false;
}

#pragma mark - Helpers

//get current view vector as origin
/*
- (GLKVector3) GetViewVector
{
    return [CommonHelpers GetVectorFrom2Points: position : view : NO];  //GLKVector3Normalize(GLKVector3Subtract(view, position));
}
*/

//get point character is looking at right now in origin distance in front of him
- (GLKVector3) GetLookAtPoint
{
    return GLKVector3Add(position, viewVector);
}

//return point that is distance from character in direction of view
//(distance is taken as if position.y and view.y are equal)
- (GLKVector3) PointInFrontOfCamera: (float) distanceFromCharacter
{
    //get view direction vector but not take account xAngle
    GLKVector3 flatViewVector = GLKVector3Normalize(GLKVector3Make(viewVector.x, 0, viewVector.z));
    distanceFromCharacter -= 1.0; //remove because PointOnLine calculates distance from second parameter, and view vector is length of 1.0
    return [CommonHelpers PointOnLine: position : GLKVector3Add(position, flatViewVector) : distanceFromCharacter];
}

//reclculate current x and y angles depending on cirrent vie vector
- (void) RecalCulateXYAngles
{
    GLKVector3 diffVector = viewVector;
    //calculate x and y angle)
    yAngle = [CommonHelpers AngleBetweenVectorAndZ: viewVector];
    //to calculate xAngle, rotate vector to its origin then calculate simple arctang
    [CommonHelpers RotateY:&diffVector :-yAngle];
    xAngle = atan2f(diffVector.y,diffVector.z);
}

//return angle between view vector and given vector in horizontal plane (used when aproximate direction of view are needed)
- (float) HorAngleBetweenViewAndVector: (GLKVector3) vector
{
    return [CommonHelpers AngleBetweenVectors: viewVector : vector];
}


@end
