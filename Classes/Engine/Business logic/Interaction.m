//
//  Interaction.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: CHECK COLISIONS IF THEY ARE ALL THAT NEEDED 

#import "Interaction.h"
#import "Terrain.h"
#import "Objects.h"
#import "Ocean.h"
#import "Character.h"

@implementation Interaction
@synthesize terrain, objects, ocean;

- (id) initWithObjects: (Terrain*) terr: (Objects*) obj: (Ocean*) ocn
{
    self = [super init];
    if (self != nil) 
    {
        terrain = terr;
        objects = obj;
        ocean = ocn;
    }
    return self;
}


- (void) ResourceCleanUp
{
    self.terrain = nil;
    self.objects = nil;
    self.ocean = nil;
}

//------------------------------------------------------------------------------

//get height of given point taking all object into account
- (float) GetHeightByPoint: (GLKVector3) pos
{
    float height = 0;
    
    height = [terrain GetHeightByPoint: &pos];

    //stepped on raft
    if((objects.raft.state == RS_DONE || objects.raft.state == RS_PUT_SAIL) && [objects.raft PointOnRaft:pos])
    {
        //add log height
        float raftHeight = objects.logs.model.AABBmax.y - objects.logs.model.AABBmin.y;
        height += raftHeight;
    }
    
    
    return height;
}

//get height point, but does not allow to go beneth water level
- (float) GetHeightByPointAboveWater: (GLKVector3) pos
{
    float height  = [self GetHeightByPoint: pos];

    if(height < ocean.oceanBase.y)
    {
        height = ocean.oceanBase.y;
    }
    
    return height;
}

#pragma mark - MOVEMENT

//if view vector after step is in blocked area, retrun NO
//stepVector - previous step which led to  this current positionb
//calculate rebound point - point where character will end up after collision with obstacle
- (BOOL) MovementAllowed: (Character*) character : (GLKVector3) stepVector : (GLKVector3*) reboudnPoint
{
    return YES; //#TODO style line (comment it out)
    
    //character walking colision detection
    if(character.state == CS_BASIC)
    {
        int colidedType = 0; //0 - colision did not happen
                             //1 - character came from outside ring
                             //2 - caharcter came from inside ring
        GLKVector3 colisionCenter; //center of colision detected circle
        
        //can walk only in island circle
        if(![CommonHelpers PointInCircle: terrain.majorCircle.center: terrain.majorCircle.radius: character.camera.position])
        {
            colisionCenter = terrain.majorCircle.center;
            colidedType = 2;
        }
        
        //colision detection against objects
        //palms
        if(!colidedType)
        for (int i = 0; i < objects.palms.count; i++) 
        {
            if([CommonHelpers PointInCircle: objects.palms.collection[i].position : objects.palms.collection[i].crRadius : character.camera.position])
            {
                /*
                [CommonHelpers Log: [NSString stringWithFormat:@"MovementAllowed (%f %f %f) (%f %f %f) %f", objects.palms.collection[i].position.x,
                                                               objects.palms.collection[i].position.y,objects.palms.collection[i].position.z,
                                                               character.camera.position.x,character.camera.position.y,character.camera.position.z,
                                                                objects.palms.collection[i].crRadius]];
                */
                //NSLog(@"aaa");
                colisionCenter = objects.palms.collection[i].position;
                colidedType = 1;
            }
        }
        
        //smallpalm
        if(!colidedType)
        for (int i = 0; i < objects.smallPalm.count; i++)
        {
            if(objects.smallPalm.collection[i].visible && [CommonHelpers PointInCircle: objects.smallPalm.collection[i].position : objects.smallPalm.collection[i].crRadius : character.camera.position])
            {
                colisionCenter = objects.smallPalm.collection[i].position;
                colidedType = 1;
            }
        }
        
        //bushes
        if(!colidedType)
        for (int i = 0; i < objects.bushes.count; i++) 
        {
            if([CommonHelpers PointInCircle: objects.bushes.collection[i].position : objects.bushes.collection[i].crRadius : character.camera.position])
            {
                colisionCenter = objects.bushes.collection[i].position;
                colidedType = 1;
            }
        }
        
        //shelter
        if(!colidedType)
        if(objects.shelter.state > SS_NONE && [CommonHelpers PointInCircle: objects.shelter.shelter.position : objects.shelter.shelter.crRadius : character.camera.position])
        {
            colisionCenter = objects.shelter.shelter.position;
            colidedType = 1;
        }


        //-----------------------------
        //find rebound point and return
        if(colidedType == 1) //colided from outside circle
        {
            float stepLength = GLKVector3Length(stepVector); //length of current step
            colisionCenter.y = character.camera.position.y; //make sure y is equal for vectors, will not work otherwise
            //find pint that is step length outside of circle from current position inside circle (in direction from center to current position)
            *reboudnPoint = [CommonHelpers PointOnLine: colisionCenter : character.camera.position : stepLength];
            
            return NO;
        }else
        if(colidedType == 2) //colided from inside circle
        {
            float stepLength = GLKVector3Length(stepVector); //length of current step
            colisionCenter.y = character.camera.position.y; //make sure y is equal for vectors, will not work otherwise
            
            //first find new point outside circle that is some distance behind current position
            GLKVector3 newPoint = [CommonHelpers PointOnLine: colisionCenter : character.camera.position : 1.0];;
            //then the same idea as in colidedType==1
            *reboudnPoint = [CommonHelpers PointOnLine: newPoint : character.camera.position : stepLength];

            return NO;
        }
    }
    
    return YES;
}

#pragma mark - FOR SETTING PLACES ON STARTUP

//is passed objects desired place occupied by other object
//NOTE: use only at startup because in game objects are not checked here
//crRadius must be initialized first
- (BOOL) IsPlaceOccupiedOnStartup: (SModelRepresentation*) obj 
{
    //palms
    for (int i = 0; i < objects.palms.count; i++)
    {
        float radiusIncr = objects.palms.modelBranch.crRadius * 0.7; //increase palm trunk rdious, we dont want palms to close
        if(objects.palms.collection[i].located && [CommonHelpers CirclesColliding: objects.palms.collection[i].position : objects.palms.collection[i].crRadius + radiusIncr:
                                                                                    obj->position : obj->crRadius])
        {
            NSLog(@"palm r: %f obj r: %f" , objects.palms.collection[i].crRadius + radiusIncr, obj->crRadius);
            return YES;
        }
    }
    
    //smallpalms
    for (int i = 0; i < objects.smallPalm.count; i++)
    {
        float radiusIncr = objects.smallPalm.modelBranch.crRadius * 0.4; //increase palm turnk rdious, we dont want palms to close
        if(objects.smallPalm.collection[i].located && [CommonHelpers CirclesColliding: objects.smallPalm.collection[i].position : objects.smallPalm.collection[i].crRadius + radiusIncr :
                                                    obj->position : obj->crRadius])
        {
            NSLog(@"smallpalm");
            return YES;
        }
    }
    
    //bushes
    for (int i = 0; i < objects.bushes.count; i++)
    {
        if(objects.bushes.collection[i].located && [CommonHelpers CirclesColliding: objects.bushes.collection[i].position : objects.bushes.collection[i].crRadius :
                                                                                    obj->position : obj->crRadius])
        {
            NSLog(@"bush");
            return YES;
        }
    }
    
    //dry grass
    for (int i = 0; i < objects.dryGrass.count; i++)
    {
        if(objects.dryGrass.collection[i].located && [CommonHelpers CirclesColliding: objects.dryGrass.collection[i].position : objects.dryGrass.collection[i].crRadius :
                                                      obj->position : obj->crRadius])

        {
            NSLog(@"dry grass");
            return YES;
        }
    }
    
    //berry bush
    for (int i = 0; i < objects.berryBush.count; i++)
    {
        if(objects.berryBush.collection[i].located && [CommonHelpers CirclesColliding: objects.berryBush.collection[i].position : objects.berryBush.collection[i].crRadius :
                                                                                       obj->position : obj->crRadius])
        {
            NSLog(@"berry bush");
            return YES;
        }
    }
    
    //leaves
    for (int i = 0; i < objects.leaves.count; i++)
    {
        if(objects.leaves.collection[i].located && [CommonHelpers CirclesColliding: objects.leaves.collection[i].position : objects.leaves.collection[i].crRadius :
                                                                                     obj->position : obj->crRadius])
        {
            NSLog(@"leave");
            return YES;
        }
    }
    
    //flat rocks
    for (int i = 0; i < objects.flatRocks.count; i++)
    {
        if(objects.flatRocks.collection[i].located && [CommonHelpers CirclesColliding: objects.flatRocks.collection[i].position : objects.flatRocks.collection[i].crRadius :
                                                                                        obj->position : obj->crRadius])
        {
            NSLog(@"flat rock");
            return YES;
        }
    }
    
    //stick
    for (int i = 0; i < objects.sticks.count; i++)
    {
        if(objects.sticks.collection[i].located && [CommonHelpers CirclesColliding: objects.sticks.collection[i].position : objects.sticks.collection[i].crRadius :
                                                            obj->position : obj->crRadius])
        {
            NSLog(@"stick");
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - FOR DROPPING ITEM

//check of given circle is allowed to be placed on land
//return true if can not be placed
//this function shouldnt be used at satrtup but in game place checking
- (BOOL) PlaceOccupied: (GLKVector3) position : (float) radius
{
    //palms
    for (int i = 0; i < objects.palms.count;i++)
    {
        if([CommonHelpers CirclesColliding: objects.palms.collection[i].position : objects.palms.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //smallpalms
    for (int i = 0; i < objects.smallPalm.count;i++)
    {
        if(objects.smallPalm.collection[i].visible && [CommonHelpers CirclesColliding: objects.smallPalm.collection[i].position : objects.smallPalm.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //bushes
    for (int i = 0; i < objects.bushes.count; i++)
    {
        if([CommonHelpers CirclesColliding: objects.bushes.collection[i].position : objects.bushes.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //berry bushes
    for (int i = 0; i < objects.berryBush.count; i++)
    {
        if([CommonHelpers CirclesColliding: objects.berryBush.collection[i].position : objects.berryBush.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //dry grass
    for (int i = 0; i < objects.dryGrass.count; i++)
    {
        if([CommonHelpers CirclesColliding: objects.dryGrass.collection[i].position : objects.dryGrass.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //leaves
    for (int i = 0; i < objects.leaves.count; i++)
    {
        if([CommonHelpers CirclesColliding: objects.leaves.collection[i].position : objects.leaves.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //shell
    for (int i = 0; i < objects.shells.count; i++)
    {
        if(objects.shells.collection[i].visible  && [CommonHelpers CirclesColliding: objects.shells.collection[i].position : objects.shells.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //sea urchin
    for (int i = 0; i < objects.seaUrchin.count; i++)
    {
        if(objects.seaUrchin.collection[i].visible  && [CommonHelpers CirclesColliding: objects.seaUrchin.collection[i].position : objects.seaUrchin.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    
    //raincatch
    for (int i = 0; i < objects.rainCatch.count; i++)
    {
        if(objects.rainCatch.collection[i].visible  && [CommonHelpers CirclesColliding: objects.rainCatch.collection[i].position : objects.rainCatch.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //cocos
    for (int i = 0; i < objects.cocos.count; i++)
    {
        if(objects.cocos.collection[i].visible  && objects.cocos.collection[i].marked &&
           [CommonHelpers CirclesColliding: objects.cocos.collection[i].position : objects.cocos.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //fireplace
    if(objects.campFire.state != FS_NONE)
    {
        //NOTE: koef must match in campfire module CookingItemAllowed,WoodItemAllowed
        float takenRadiues = objects.campFire.kindlingModel.bsRadius * 3.0;
        
        if(objects.campFire.state != FS_NONE && objects.campFire.state != FS_DRY &&
           [CommonHelpers CirclesColliding: objects.campFire.campfire.position : takenRadiues : position : radius])
        {
            return YES;
        }
    }
    
    //stored cooked items
    for (int i = 0; i < objects.campFire.storedCount; i++)
    {
        if(objects.campFire.storedItems[i].type != kItemEmpty)
        {
            float takenRadiues = objects.campFire.kindlingModel.bsRadius * 2;
            
            if([CommonHelpers CirclesColliding: objects.campFire.storedItems[i].position : takenRadiues : position : radius])
            {
                return YES;
            }
        }
    }
    
    //flat rocks
    for (int i = 0; i < objects.flatRocks.count; i++)
    {
        if(objects.flatRocks.collection[i].visible &&
           [CommonHelpers CirclesColliding: objects.flatRocks.collection[i].position : objects.flatRocks.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //deadfall traps
    for (int i = 0; i < objects.deadfallTraps.count; i++)
    {
        if(objects.deadfallTraps.collection[i].visible &&
           [CommonHelpers CirclesColliding: objects.deadfallTraps.collection[i].position : objects.deadfallTraps.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //stick traps
    for (int i = 0; i < objects.stickTraps.count; i++)
    {
        if(objects.stickTraps.collection[i].visible &&
           [CommonHelpers CirclesColliding: objects.stickTraps.collection[i].position : objects.stickTraps.collection[i].crRadius : position : radius])
        {
            return YES;
        }
    }
    
    //logs
    for (int i = 0; i < objects.logs.count; i++)
    {
        float reducedRadius = objects.logs.collection[i].crRadius / 2.5; //use smaller radious ebcause log is not round
        
        if(objects.logs.collection[i].enabled && !objects.logs.collection[i].marked && !objects.logs.collection[i].moving &&
           [CommonHelpers CirclesColliding: objects.logs.collection[i].position : reducedRadius : position : radius])
        {
            return YES;
        }
    }
    
    //rag
    if(objects.rags.rag.enabled && !objects.rags.rag.moving &&
       [CommonHelpers CirclesColliding: objects.rags.rag.position : objects.rags.rag.crRadius : position : radius])
    {
        return YES;
    }
    
    //raft
    //PointIncircle used there so no current object radius is taken into account
    if(objects.raft.state >= RS_PUT_LOG  && [objects.raft PointOnRaft:position])
    {
        return YES;
    }
    
    //shelter
    if(objects.shelter.state > SS_NONE && [CommonHelpers CirclesColliding: objects.shelter.shelter.position : objects.shelter.shelter.crRadius : position : radius])
    {
        return YES;
    }

    
    //knife
    if(objects.knife.knife.visible && !objects.knife.knife.marked //not in hand
       && [CommonHelpers CirclesColliding: objects.knife.knife.position : objects.knife.knife.crRadius : position : radius])
    {
        return YES;
    }
    
    //small palm leaf
    for (int i = 0; i < objects.handLeaf.count; i++)
    {
        float radiusDiminisher = 0.8; //not round so we can remove something from radius
        
        if(objects.handLeaf.collection[i].visible && !objects.handLeaf.collection[i].marked && //on ground, not in hand
           [CommonHelpers CirclesColliding: objects.handLeaf.collection[i].position : objects.handLeaf.collection[i].bsRadius * radiusDiminisher : position : radius])
        {
            return YES;
        }
    }
    
    return NO;
}



//weather simulated point is free to drop (this position is not occupied by another elemnt)
- (BOOL) FreeToDrop: (GLKVector3) position
{
    //was 0.01
    float tinyRadius = 0.0005; //before freetodrop function checked point against circle, now circle vs circle, so we make radius very small to look similar to previous
    return ![self PlaceOccupied: position : tinyRadius];
}

#pragma mark - MOTION OBJECT COLLISION DETECTION

//check object collision with ground
//should be called after update mnotion and prevPoint is previous position before update
//origin is checked + boundToGround value
//if speedMinlimit or groundSlowdownKoef are < 0 , use default values
//return:
//    0 - did not hit anything
//    1 - hit ground and reflected
//    2 - hit ground and just stopped
- (int) ObjectVsGroundCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) speedMinlimit : (float) groundSlowdownKoef
{
    int result = 0;
    
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
    if([terrain ObjectHitsGround: c->position : c->boundToGround])
    {
        //if speed is high, check only for bouncing against the ground
        if(c->physics.velocity > speedMinlimit)
        {
            c->position = prevPoint; //use previous position so it doesnt look like went under ground
            float bounceSpeed = c->physics.velocity * groundSlowdownKoef; //slowed down new horizontal speed
            //[ObjectPhysics ResetMotionByAngles:  c : newSpeed : -[ObjectPhysics GetXAngle:c] : [ObjectPhysics GetYAngle:c]];
            GLKVector3 groundNormal = GLKVector3Make(0.0, 1.0, 0.0);
            [ObjectPhysics ResetMotionByVector:  c : bounceSpeed : [ObjectPhysics GetReflectionVector: c : groundNormal]];
            result = 1;
        }else
        {
            //for low speed don't bounce any more but stop
            c->position = [terrain GetCollisionPoint: prevPoint : c->position];
            c->position.y += c->boundToGround; //add ground val
            //flight ended by hitting obstacle, put back in normal mode
            [ObjectPhysics HaltMotion: c];
            result = 2;
        }
    }
    
    return result;
}


//object against palm trunk collision detection
//object radous is checked against circle of palm joint
//prevPoint - previous point, to move back step before collision
//slowdownKoef - by how much collision slows down object
- (BOOL) ObjectVsPalmCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) slowdownKoef
{
    BOOL retVal = false;
    
    //collision detection with palms
    for (int i = 0; i < objects.palms.count; i++)
    {
        //between these twi joints the collision will be detected
        int lowerJoint;
        int upperJoint;
        //#OPTI could use bigger circle to first determine which palm is close
        if([objects.palms GetUpDownJointsByY: i : c->position.y : &lowerJoint : &upperJoint]) //if in level of palm trunk
        {
            //find radious and center from 2 lerped joints to caculate colision (for optimization could find wich is closer and use it here)
            float lerpValue = (c->position.y - objects.palms.trunkBounds[i].center[lowerJoint].y) / (objects.palms.trunkBounds[i].center[upperJoint].y - objects.palms.trunkBounds[i].center[lowerJoint].y);
            GLKVector3 lerpedCenter = GLKVector3Lerp(objects.palms.trunkBounds[i].center[lowerJoint], objects.palms.trunkBounds[i].center[upperJoint], lerpValue);
            float lerpedRadius = [CommonHelpers LinearInterpolation: objects.palms.trunkBounds[i].radius[lowerJoint] : objects.palms.trunkBounds[i].radius[upperJoint] : 0.0 : 1.0 : lerpValue];
            
            if([CommonHelpers CirclesColliding: c->position : c->crRadius :  lerpedCenter :  lerpedRadius])
            {
                c->position = prevPoint; //use previous position so it doesnt get stuck
                
                //calculate vector from center of palm joint to object, it will be our normal
                GLKVector3 normalVect = [CommonHelpers GetVectorFrom2Points:lerpedCenter : c->position : true];
                float normalAngle = -M_PI / 12.0; //slightly lift normal upward so falling items are not stuck in but bounc off palm trunk
                [CommonHelpers RotateVectorByHorizontalPLane: &normalVect : normalAngle];
                [ObjectPhysics ResetMotionByVector: c : c->physics.velocity * slowdownKoef : [ObjectPhysics GetReflectionVector: c : normalVect]];
                retVal = true;
                break;
            }
        }
    }
    
    return retVal;
}

//object agoinst palm collision
//spheres are compared, so radiuses needs to be set
//prevPoint - previous point, to move back step before collision
//slowdownKoef - by how much collision slows down object
- (BOOL) ObjectVsCocosCollision: (SModelRepresentation*) c : (GLKVector3) prevPoint : (float) slowdownKoef
{
    BOOL retVal = false;
    //Collision detection with cocos
    for (int i = 0; i < objects.cocos.count; i++)
    {
        if(!objects.cocos.collection[i].marked && [CommonHelpers SpheresColliding: c->position : c->bsRadius : objects.cocos.collection[i].position : objects.cocos.collection[i].bsRadius])
        {
            c->position = prevPoint; //use previous position so it doesnt get stuck
            [objects.cocos ReleaseAfterHit: &objects.cocos.collection[i] : c];
            [ObjectPhysics ResetMotionByVector: c : c->physics.velocity * slowdownKoef : GLKVector3Normalize(c->physics.projectVel)];
            retVal = true;
            break;
        }
    }
    
    return retVal;
}

//check object vs top of palm leaf collision
//return true if crown of palm hit
//crown is typicaly smaller than full leaf length
- (BOOL) ObjectVsPalmCrownCollision: (SModelRepresentation*) c
{
    BOOL retVal = false;
    float crownHeight = fabs(objects.palms.modelBranch.AABBmax.y - objects.palms.modelBranch.AABBmin.y);
    
    //collision detection with palms
    for (int i = 0; i < objects.palms.count; i++)
    {
        //interested only in height between palm top and slightlu above
        float palmTop = objects.palms.collection[i].position.y + objects.palms.palmHeight;
        float crownRadius = objects.palms.collection[i].crRadius * 1.7;
        if(c->position.y > palmTop && c->position.y < palmTop + crownHeight &&
           [CommonHelpers PointInCircle: objects.palms.collection[i].position : crownRadius :c->position])
        {
            retVal = true;
        }
    }
    return retVal;
}


//check interaction of object and wildlife, usually after approched or hit ground water by object close to animal
- (void) ObjectVsWildlifeInteraction: (SModelRepresentation*) c : (Character*) character
{
    //#OPTI - possible to check appropriate area position area before checking all wildlife
    
    //fishes
    float minObjectDistance = 6.0; //how close object appears to animal before it runs away
    
    for (int i = 0; i < objects.fishes.count; i++)
    {
        if(objects.fishes.collection[i].visible && !objects.fishes.collection[i].marked)
        {
            float distanceObjectFish = GLKVector3Distance(objects.fishes.collection[i].position,c->position);
            if(distanceObjectFish < minObjectDistance)
            {
                [objects.fishes StartRunaway: &objects.fishes.collection[i] : c->position : objects.fishes.floatSpeedFast : objects.fishes.wagSpeedFast : objects.fishes.uppertTimeFast];
            }
        }
    }
    
    //crab
    for (int i = 0; i < objects.crabs.count; i++)
    {
        if(objects.crabs.collection[i].visible && objects.crabs.collection[i].moving && !objects.crabs.collection[i].runaway)
        {
            float distanceObjectCrab = GLKVector3Distance(objects.crabs.collection[i].position, c->position);
            if(distanceObjectCrab < minObjectDistance)
            {
                [objects.crabs.actions HaltToRunaway: &objects.crabs.collection[i]];
                [objects.crabs.actions StartRunaway: &objects.crabs.collection[i] : c->position];
            }
        }
    }
    
    //rat
    for (int i = 0; i < objects.rats.count; i++)
    {
        if(objects.rats.collection[i].visible && objects.rats.collection[i].moving && !objects.rats.collection[i].runaway)
        {
            float distanceObjectCrab = GLKVector3Distance(objects.rats.collection[i].position, c->position);
            if(distanceObjectCrab < minObjectDistance)
            {
                [objects.rats.actions HaltToRunaway: &objects.rats.collection[i]];
                [objects.rats.actions StartRunaway: &objects.rats.collection[i] : c->position];
            }
        }
    }
    
    
    //bird
    for (int i = 0; i < objects.bird.count; i++)
    {
        if(objects.bird.collection[i].visible && !objects.bird.collection[i].enabled)
        {
            float distanceObjectBird = GLKVector3Distance(objects.bird.collection[i].position, c->position);
            if(distanceObjectBird < minObjectDistance)
            {
                [objects.bird StartMovement:&objects.bird.collection[i] : character];
            }
        }
    }
}


@end
