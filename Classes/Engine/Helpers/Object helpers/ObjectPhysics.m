//
//  ObjectPhysics.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 10/04/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//

#import "ObjectPhysics.h"

@implementation ObjectPhysics

+ (BOOL) IsInMotion: (SModelRepresentation*) c
{
    return c->physics.inMotion;
}

//stop motion
+ (void) HaltMotion: (SModelRepresentation*) c
{
    c->physics.inMotion = false;
    c->physics.velocity = 0;
    c->physics.projectVel = GLKVector3Make(0.0, 0.0, 0.0);
}

//start/change current motion of object givent speed and normalized direction vector
//speed - speed of launch / redirection
//directionVect - origin normalized vector of motion direction
+ (void) ResetMotionByVector: (SModelRepresentation*) c : (float) speed : (GLKVector3) directionVect
{
    c->physics.inMotion = true;
    c->physics.velocity = speed; //initial velocity, recalculate when nececery
    c->physics.projectVel = GLKVector3MultiplyScalar( directionVect , c->physics.velocity);;
}

//start/change current motion of object given speed and angles around x and y axis (imagining that initial direction vector is (0.0, 0.0, 1.0))
//speed - speed of launch / redirection
//xangle = angle around x axis, imagining that initial direction vector is (0.0, 0.0, 1.0)
//yangle - angle around yaxis (anticlockwise)
+ (void) ResetMotionByAngles: (SModelRepresentation*) c : (float) speed : (float) xAngle : (float) yAngle
{
    c->physics.inMotion = true;
    c->physics.velocity = speed; //initial velocity, recalculate when nececery
    c->physics.projectVel.x = 0.0;
    c->physics.projectVel.y = c->physics.velocity * sinf(xAngle);
    c->physics.projectVel.z = c->physics.velocity * cosf(xAngle);
    //turn movement vector  to desired y angle anticlocwise
    [CommonHelpers RotateY: &c->physics.projectVel : yAngle];
}


//update motion of object given it has velocity vector, no collision check is here, this is like in space but with gravity
+ (void) UpdateMotion: (SModelRepresentation*) c : (float) dt
{
    if([self IsInMotion:c])
    {
        //projectile motion
        c->position = GLKVector3Add(c->position, GLKVector3MultiplyScalar(c->physics.projectVel, dt));
        c->physics.projectVel.y -= G_VAL * dt; //gravity force
    }
}


//return current resultant velocity (and assign inside) from all velocity components
+ (float) GetResultantVelocity: (SModelRepresentation*) c
{
    return c->physics.velocity = GLKVector3Length(c->physics.projectVel);
}

//return angle around Y axis from Z axis clockwise
+ (float) GetYAngle: (SModelRepresentation*) c
{
    return [CommonHelpers AngleBetweenVectorAndZ: c->physics.projectVel];
}


//return current angle between motion vector and horizontal plane
/*
+ (float) GetXAngle: (SModelRepresentation*) c
{
    //rotate velocity vector to origin (0,0,1)
    GLKVector3 rotatedVel = c->physics.projectVel;
    float yAngle = [CommonHelpers AngleBetweenVectorAndZ: rotatedVel];
    [CommonHelpers RotateY: &rotatedVel :-yAngle];
    
    //then calculate like it was 2
    return atanf(rotatedVel.y / rotatedVel.z);
}
*/

//return normalized (velocity is lost) reflection vector agounst a plane
//planeNormal - plane normal agoinst wich struck
+ (GLKVector3) GetReflectionVector: (SModelRepresentation*) c : (GLKVector3) planeNormal
{
    GLKVector3 strikeVect = GLKVector3Normalize(c->physics.projectVel);
    //Vnew = -2*(V dot N)*N + V

    return GLKVector3Add( GLKVector3MultiplyScalar(planeNormal, -2 * GLKVector3DotProduct(strikeVect, planeNormal)), strikeVect);
}


@end
