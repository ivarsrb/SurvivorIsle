//
//  ObjectActions.m
//  Island survival
//
//  Created by Ivars Rusbergs on 4/30/13.
//
// STATUS: OK 
//
// For each object group one objet should be created and all object within that grup will have same parameters



#import "ObjectActions.h"

@implementation ObjectActions
@synthesize type,normalSpeed, runawaySpeed, moveMaxTimeNormal, moveMaxTimeRunaway, minObjCharDistance,minObjTrapDistance;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        //default values
        //needs setting after object is created in code where this object is used
        type = WT_CRAB; //default
        normalSpeed = 0;
        runawaySpeed = 0;
        moveMaxTimeNormal = 0;
        moveMaxTimeRunaway = 0;
        minObjCharDistance = 0;
        minObjTrapDistance = 0;
    }
    return self;
}

- (void) ResourceCleanUp
{

}

#pragma mark - Movement functions
//NOTE - movement parameters must be set before using this function
//functions take in model representation and change it's parameters

//updates movement for given object
//trapNoticed - comes form object to which function is used, if no traps are used, pass - false
//trapPoint - if trap is noticed pass position of that trap
- (void) UpdateMovement: (SModelRepresentation*) obj: (float) dt: (Terrain*) terr: (Character*) character:(BOOL) trapNoticed: (GLKVector3) trapPoint
{
    if(obj->moving)
    {
        float distanceObjectCharacter=0;
        //-------runaway distance check
        if(minObjCharDistance > 0) //if is set to 0, dont check this condition
        {
            //calculate distance for object to character
            distanceObjectCharacter = GLKVector3Distance(character.camera.position, obj->position);
            
            //start running away if too close
            if(!obj->runaway && distanceObjectCharacter < minObjCharDistance)
            {
                [self HaltToRunaway:obj];
            }
        }
        /*
        else
        {
            NSLog(@"happens");
        }
        */
            
        //-------new move
        if(obj->timeInMove >= obj->moveTime)
        {
            //end running away
            if(minObjCharDistance > 0 && distanceObjectCharacter > minObjCharDistance && obj->runaway)
            {
                obj->runaway = false;
            }
            
            //bounced in obstacle
            if(obj->bouncedInObstacle)
            {
                //bounced in obstacle, move in random direction
                if(obj->runaway)
                {
                    [self SetMoveRandom: obj: runawaySpeed: moveMaxTimeRunaway];
                }else
                {
                    [self SetMoveRandom: obj: normalSpeed: moveMaxTimeNormal];
                }
                obj->bouncedInObstacle = false;
            }
            else
            if(obj->runaway)
            {
                //get runaway direction
                //GLKVector3 runDirection =  GLKVector3Subtract(obj->position, character.camera. position);
                //runDirection.y = 0; //becouse normalized vector must not depend on heights
                /*
                GLKVector3 runDirection = [CommonHelpers GetVectorFrom2Points: character.camera. position:  obj->position : true];
                [self SetMoveDirectionRandom: obj: runawaySpeed: moveMaxTimeRunaway: runDirection];
                */
                [self StartRunaway: obj : character.camera.position];
            }else
            {
                //direct to trap check, if not in trap area, set new random move
                if(trapNoticed)
                {
                    [self SetMoveToPoint:obj:trapPoint];
                }
                else
                {
                    //NSLog(@"%d",[terr IsInland:obj->position]);
                    //new move in normal speed
                    [self SetMoveRandom: obj: normalSpeed: moveMaxTimeNormal];
                }
            }
        }else
        {
            //currently in move
            obj->timeInMove += dt;
        }
        
        //-------update position
        obj->position = GLKVector3Add(obj->position, GLKVector3MultiplyScalar(obj->movementVector, dt));
        obj->position.y = [terr GetHeightByPoint: &obj->position];
        
        //collision detection after this
    }
}

//recieves colision check parameter fro outside and recacluates poition and flags if ostacle was hit
//used only when collision detection needed and MUST be called after UpdateMovement at the same iteration
- (void) CollisionProcession: (SModelRepresentation*) obj: (float) dt: (BOOL) obstacleHit
{
    if(obstacleHit)
    {
        [self HaltToBounce:obj:dt];
    }
}


//use this function after update and collision
//recieves weather object is in trap area, if is, catch it
- (void) ObjectCatchProcession: (SModelRepresentation*) obj: (BOOL) objectInTrap
{
    if(!obj->runaway && objectInTrap)
    {
        [self ObjectCatch:obj];
    }
}

//start runaway action from threat position
//NOTE: used also outside
- (void) StartRunaway: (SModelRepresentation*) obj : (GLKVector3) threatPosition
{
    GLKVector3 runDirection = [CommonHelpers GetVectorFrom2Points: threatPosition:  obj->position : true];
    [self SetMoveDirectionRandom: obj: runawaySpeed: moveMaxTimeRunaway: runDirection];
}


//START AND STOP GENERAL MOVEMENT

//start object movement in general
- (void) StartMovement: (SModelRepresentation*) obj: (GLKVector3) startPosition
{
    obj->position = startPosition;
    obj->moveTime = 0;
    obj->timeInMove = 0;
    obj->movementAngle = 0;
    obj->movementVector = GLKVector3Make(0,0,0); //movement vector is set when new move is initilized
    obj->visible = true;
    obj->moving = true;
    obj->runaway = false; //running away from character
    obj->marked = false; //interpreted differently for each objct (usually means - cought)
    obj->bouncedInObstacle = false;
}

//stop object movement
- (void) StopMovement: (SModelRepresentation*) obj
{
    obj->moving = false;
}

//MOVEMENTS INITIALIZATIONS

//not used directly, used as helper in other move functions, becouse no direction is set here
- (void) SetMove:(SModelRepresentation *)obj :(float)speed :(int)upperTime
{
    obj->moveTime = [CommonHelpers RandomInRange:1 :upperTime];
    obj->timeInMove = 0;
    obj->movementVector = GLKVector3Make(0,0,speed);
}

//set random normal direction at given speed and upper time max length
- (void) SetMoveRandom: (SModelRepresentation*) obj: (float) speed: (int) upperTime
{
    [self SetMove:obj :speed :upperTime];
    
    obj->movementAngle = [CommonHelpers RandomInRange:0 :PI_BY_2 :100]; //random angle
    [CommonHelpers RotateY: &obj->movementVector: obj->movementAngle];
}

//set new move at given direction
- (void) SetMoveDirection: (SModelRepresentation*) obj: (float) speed: (int) upperTime: (GLKVector3) direction
{
    [self SetMove:obj :speed :upperTime];
    
    obj->movementAngle = [CommonHelpers AngleBetweenVectorAndZ:direction];
    [CommonHelpers RotateY: &obj->movementVector: obj->movementAngle];
}

//set new move at given direction but add random offset also
- (void) SetMoveDirectionRandom: (SModelRepresentation*) obj: (float) speed: (int) upperTime: (GLKVector3) direction
{
    [self SetMove:obj :speed :upperTime];
    
    obj->movementAngle = [CommonHelpers AngleBetweenVectorAndZ:direction];
    obj->movementAngle += [CommonHelpers RandomInRange:-M_PI_4 :M_PI_4: 100]; //random offset
    [CommonHelpers RotateY: &obj->movementVector: obj->movementAngle];
}

//set move from current position to given position
- (void) SetMoveToPoint: (SModelRepresentation*) obj: (GLKVector3) destPoint
{
    GLKVector3 destDirection =  GLKVector3Subtract(destPoint,obj->position);
    destDirection.y = 0; //becouse normalized vector must not depend on heights
    [self SetMoveDirection: obj: normalSpeed: moveMaxTimeNormal: GLKVector3Normalize(destDirection)];
}

//HALT MOVE

//stop current move and shift into runaway mode
- (void) HaltToRunaway: (SModelRepresentation*) obj
{
    obj->timeInMove = 0;
    obj->moveTime = 0;
    obj->runaway = true; //run away mode
    
    //sound when scared
    switch (type) {
        case WT_RAT:
            //dont play every time
            if([CommonHelpers RandomInRangeInt: 0 : 2] == 0)
            {
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_RAT_SQUEAK];
            }
            break;
        default:
            break;
    }

}

//stop current move becouse bounced in obstacle
- (void) HaltToBounce: (SModelRepresentation*) obj: (float) dt
{
    obj->timeInMove = 0;
    obj->moveTime = 0;
    obj->bouncedInObstacle = true;
    //move back the same ammount
    obj->position = GLKVector3Add(obj->position, GLKVector3MultiplyScalar(obj->movementVector, -dt));
}


//catch object in trap
- (void) ObjectCatch: (SModelRepresentation*) obj
{
    obj->runaway = false;
    obj->moving = false;
    obj->marked = true;
    
    if(type == WT_RAT)
    {
        obj->position.y -= obj->bsRadius / 10.0;//obj->bsRadius / 4.0; //put rat into ground when cought, so it looks pressed
    }
}

@end
