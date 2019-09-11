//
//  ObjectHelpers.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/03/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//

#import "ObjectHelpers.h"

@implementation ObjectHelpers

#pragma mark - Physics


//object dropping
//use physics functions to simulate droping
//NOTE: Do not use (use carefully) these generic functions for objects that already use physics for other purposes,
//because they have their own function and these will overlap
+ (void) StartDropping : (SModelRepresentation*) c
{
    float dropHeight = 0.7; //by how much raise from ground before starting to drop
    float dropSpeed = 0.0; //hirizontal speed
    GLKVector3 dropVector = GLKVector3Make(0.0, -1.0, 0.0); //droop vector to ground
    
    c->position.y += dropHeight; //raise
    [ObjectPhysics ResetMotionByVector:  c : dropSpeed : dropVector];
}


//update dropping
//NOTE: should be updated outside visibility check
//usually for objects that have their own projectile motion functions this is not needed
+ (void) UpdateDropping: (SModelRepresentation*) c : (float) dt : (Interaction*) inter : (float) speedMinlimit : (float) groundSlowdownKoef
{
    if([ObjectPhysics IsInMotion: c])
    {
        GLKVector3 prevPoint = c->position;
        [ObjectPhysics UpdateMotion: c : dt];
        [ObjectPhysics GetResultantVelocity: c]; //#OPTI velocity could be calculated once before is used
        //[self GroundCollisionDetection: c : terr : prevPoint : speedMinlimit : groundSlowdownKoef];
        [inter ObjectVsGroundCollision: c : prevPoint : speedMinlimit : groundSlowdownKoef];
    }
}

//check object collision with ground
//should be called after update mnotion and prevPoint is previous position before update
//if speedMinlimit or groundSlowdownKoef are < 0 , use default values
/*
+ (void) GroundCollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (float) speedMinlimit : (float) groundSlowdownKoef
{
    //obj can only stop on ground if speed reaches below certain number - it is percieved as 0 and stopped
    if(speedMinlimit < 0)
    {
        speedMinlimit = 5.0; //speed limit below wich stone is considered to stop
    }
    if(groundSlowdownKoef < 0)
    {
        groundSlowdownKoef = 0.3; //by how much velocity decreases after hitting ground
    }
    
    //ground has been hit
    if([terr ObjectHitsGround: c->position : c->boundToGround])
    {
        //if speed is high, check only for bouncing against the ground
        if(c->physics.velocity > speedMinlimit)
        {
            c->position = prevPoint; //use previous position so it doesnt look like went under ground
            float bounceSpeed = c->physics.velocity * groundSlowdownKoef; //slowed down new horizontal speed
            //[ObjectPhysics ResetMotionByAngles:  c : newSpeed : -[ObjectPhysics GetXAngle:c] : [ObjectPhysics GetYAngle:c]];
            GLKVector3 groundNormal = GLKVector3Make(0.0, 1.0, 0.0);
            [ObjectPhysics ResetMotionByVector:  c : bounceSpeed : [ObjectPhysics GetReflectionVector: c : groundNormal]];
        }else
        {
            //for low speed don't bounce any more but stop
            c->position = [terr GetCollisionPoint: prevPoint : c->position];
            c->position.y += c->boundToGround; //add ground val
            //flight ended by hitting obstacle, put back in normal mode
            [ObjectPhysics HaltMotion: c];
        }
    }
}
*/

//stop dropping
+ (void) NillDropping: (SModelRepresentation*) c
{
    [ObjectPhysics HaltMotion: c];
}

//at long object picking usefull to check for multiple speheres instead of one
//object must be centered
//endPoint1 and endPoint2 have to be set
+ (BOOL) CheckMultipleSpheresCollision: (int) numberOfSpheres : (float) objLength : (SModelRepresentation*) c : (GLKVector3) charPos : (GLKVector3) pickedPos : (float) pickDistance
{
    BOOL resultBool = NO;
    
    //check through all spheres along the object
    float step = 1.0 / (numberOfSpheres * 2); //step from 0.0-1.0 depending on number of spheres
    float sphereRadius = step * objLength; //radius of step spheres
    for(int n = 0; n < numberOfSpheres; n++)
    {
        //divide length into given number of spheres and find each radius and center
        //lerp is suposed to be from 0.0 - 1.0
        float lerpVal = step + 2 * n * step;
        GLKVector3 sphereCenter = GLKVector3Lerp(c->endPoint1, c->endPoint2, lerpVal);
        
        resultBool = [CommonHelpers IntersectLineSphere: sphereCenter: sphereRadius: charPos: pickedPos: pickDistance];
        
        //NSLog(@"%f %f %f",sphereCenter.x, sphereCenter.y, sphereCenter.z);
        //NSLog(@"%f",sphereRadius);
        
        if(resultBool)
        {
            break;
        }
    }
    
    return resultBool;
}



@end
