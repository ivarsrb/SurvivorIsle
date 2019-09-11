//
//  Fish.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "Fish.h"

@implementation Fish
@synthesize model, effect, collection, vertexCount, indexCount, count, floatSpeedFast, wagSpeedFast, uppertTimeFast;

- (id) initWithParams: (Terrain*) terr
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry: terr];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    for (int i = 0; i < count; i++) 
    {
        [self ResetFish: &collection[i] : i];
    }
}

- (void) InitGeometry: (Terrain*) terr
{
    count = FISH_COUNT; //should be even number, becouse fish are divided in half by types
    collection = malloc(count * sizeof(SModelRepresentation));
    float fishScale = 0.7;//0.8; //all fish should be same scale
    model = [[ModelLoader alloc] initWithFileScale: @"fish.obj" : fishScale]; //Z-Based model, head to positive
    
    for (int i = 0; i < count; i++) 
    {
        //collection[i].bsRadius = model.bsRadius; //baounding sphere
        [model  AssignBounds: &collection[i] : 0];
    }
    
    vertexCount = model.mesh.vertexCount * count;
    indexCount = model.mesh.indexCount * count;
    numberOfIndexesperHalf = indexCount / 2;
    
    //dtermine rotation factors for vertices
    rotationFactor = malloc(model.mesh.vertexCount * sizeof(float));
    for (int n = 0; n < model.mesh.vertexCount; n++)
    {
        //determine factor of vertex farness from center
        rotationFactor[n] = fabs(model.mesh.verticesT[n].vertex.z) / model.bsRadius;
    }
    
    //parameters
    floatSpeedFast = 10.0;
    wagSpeedFast = 13.0;
    uppertTimeFast = 1;
    //fish areas
    //maximum radius from center till what fish can swim
    fishOuterCr = terr.majorCircle;
    fishTerrainMaxHeight = 0.2; //maximal hight of terrain where fish can float
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    firstVertex = *vCnt;
    firstIndex = *iCnt;
    
    for (int i = 0; i < count; i++)
    {
        for (int n = 0; n < model.mesh.vertexCount; n++)
        {
            //vertices
            mesh.verticesT[*vCnt].vertex = model.mesh.verticesT[n].vertex; 
            mesh.verticesT[*vCnt].tex = model.mesh.verticesT[n].tex;
            *vCnt = *vCnt + 1;
        }
        
        for (int n = 0; n < model.mesh.indexCount; n++)
        {
            //indices
            mesh.indices[*iCnt] = model.mesh.indices[n] + firstVertex + (i * model.mesh.vertexCount);
            *iCnt = *iCnt + 1;
        }
    }
}

//fill vertex array with new values
- (void) UpdateVertexArray:(GeometryShape*) mesh
{
    //load model into external geometry mesh
    int vCnt = firstVertex;
    
    float angle;
    float headAngle;
    
    for (int i = 0; i < count; i++)
    {
        headAngle = collection[i].movementAngle + (collection[i].taleAnimation.angle.y / -6.0); //head moves in oposite to tail

        for (int n = 0; n < model.mesh.vertexCount; n++)
        {
            if(collection[i].visible)
            {
                //tail
                if(model.mesh.verticesT[n].vertex.z < 0)
                {
                    //the further away vertex is from center, the more rotated vertex will be
                    angle = collection[i].movementAngle + (collection[i].taleAnimation.angle.y * rotationFactor[n]);
                }
                //head
                else
                {
                    angle = headAngle;
                }
                
                mesh.verticesT[vCnt].vertex = GLKVector3Add(model.mesh.verticesT[n].vertex, collection[i].position);
                [CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex: angle: collection[i].position];
            }else
            {
                //if fish is not visible, put all vertices in one point
                mesh.verticesT[vCnt].vertex = GLKVector3Make(0, 0, 0);
            }
            vCnt = vCnt + 1;
        }
    }
}

- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //textures
    texID[0] = [[SingleGraph sharedSingleGraph] AddTexture: [model.materials objectAtIndex:0]: YES]; //128x64
    //add alternative fish skin
    texID[1] = [[SingleGraph sharedSingleGraph] AddTexture: @"fish_body_2.png": YES]; //128x64
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (GLKVector3) spearPos : (Interface*) inter : (Character*) character : (GeometryShape*) mesh
{
    self.effect.transform.modelviewMatrix = *modelviewMat;
    self.effect.constantColor = daytimeColor;
    
    for (int i = 0; i < count; i++) 
    {
        SModelRepresentation *c = &collection[i];
        
        if(c->visible)
        {
            //MOVING
            //update fish movement
            if(!c->marked)
            {
                [self UpdateFish:c :dt: terr: character];
            }
            //STRUCK
            else
            //fish is currently struck
            //animate as spear drags it our of water
            {
                float timeOnSpear = 0.9; //0.35; //how many second we see fish dragged out of water  0.35
                c->position = spearPos;
                c->position.y -= c->bsRadius / 2.; //lower fish so it looks speared in middle
                c->timeInMove += dt; //how long fish will show out of water
                //wag tale in faster speed when on spear
                float wagAmplitude = 1.0;
                [self WagTale: c: wagAmplitude:dt];
                
                if(c->timeInMove > timeOnSpear)
                {                
                    if(character.inventory.grabbedItem.type != kItemEmpty)  //if someting was dragged at the time of picking fish, release
                    {
                        //release fish back
                        c->moving = false;
                    }else
                    if(c->type == FT_1 && [character.inventory AddItemInstance:ITEM_FISH_RAW]) //add fish to inventory
                    {
                        //fish added OK
                        c->visible = false;
                    }else
                    if(c->type == FT_2 && [character.inventory AddItemInstance:ITEM_FISH_2_RAW]) //add fish to inventory
                    {
                        //fish added OK
                        c->visible = false;
                    }
                    else
                    {
                        //inventory is full
                        //release fish back
                        c->moving = false;
                        [[SingleSound sharedSingleSound]  PlaySound: SOUND_PICK_FAIL];
                        //blink 
                        [inter InvenotryFullBlink]; //graphically show that invenotry is full
                    }
                    //fish dissapears
                    c->marked = false;
                }
            }
        }
    }
    
    [self UpdateVertexArray:mesh];
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    //for type 1
    if([self AnyFishAlive: FT_1])
    {
        self.effect.texture2d0.name = texID[0];
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, numberOfIndexesperHalf, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
    }
    
    //for type 2
    if([self AnyFishAlive: FT_2])
    {
        self.effect.texture2d0.name = texID[1];
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, numberOfIndexesperHalf, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + numberOfIndexesperHalf) * sizeof(GLushort)));
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
    free(rotationFactor);
}

#pragma mark - Movement helper Functions

//reset fish to new random location on map
- (void)  ResetFish: (SModelRepresentation*) c: (int) i
{
    float floatHeight = 0;  //fish floating height
    SCircle fishCircle =  fishOuterCr;
    fishCircle.radius -= 1.0; //slightly decrease radius so fish are lessnlikely to stuck at first
    c->position = [CommonHelpers RandomOnCircleLine:fishCircle];
    c->position.y = floatHeight;
    c->movementAngle = [CommonHelpers RandomInRange:0 :PI_BY_2 :100];
    c->visible = true;
    c->moving = false;
    c->marked = false; //on spear
    c->runaway = false;
    
    //first half of fish
    if(i < count / 2)
    {
        c->type = FT_1;
    }else
    {
        c->type = FT_2;
    }
}


//spearing check
- (BOOL) StrikeFishCheck: (GLKVector3) spearPos
{
    bool resultBool = false;
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible && !collection[i].marked)
        {
            //spear strikes fish
            float fishStrikeRadius = collection[i].bsRadius + 0.15; //+easier to strike
            resultBool = [CommonHelpers PointInSphere: collection[i].position : fishStrikeRadius : spearPos];
            
            /*
            [CommonHelpers Log: [NSString stringWithFormat:@"StrikeFishCheck %f  %d  (%f %f %f) (%f %f %f)", fishStrikeRadius, resultBool,
                                                           collection[i].position.x, collection[i].position.y,collection[i].position.z,
                                                           spearPos.x, spearPos.y, spearPos.z]];
            */
            if(resultBool)
            {                
                collection[i].marked = true; //mark as struck
                //collection[i].moving = false;
                collection[i].timeInMove = 0; //re-use this variable to store time that fish is dragged out of water
                //reset wag parameters after fish has been struck
                collection[i].taleAnimation.angle.y = 0;
                collection[i].taleAnimation.velocity.y = 40.0; //fast tale wag speed when on spear
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_SPLASH];
                return resultBool;
            }
        }
    }
    
    //[CommonHelpers Log: @"StrikeFishCheck --------------------"];
    return resultBool;
}

//update fish movement
- (void) UpdateFish: (SModelRepresentation*) object: (float) dt: (Terrain*) terr: (Character*) character
{
    float floatSpeed; //normal float speed
    int uppertTime; //time of the move
    
    //difficulty related
    //easy
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_EASY)
    {
        floatSpeed = 1.5;
        uppertTime = 6;
    }
    //hard
    else
    {
        floatSpeed = 2.0;
        uppertTime = 4;
    }
    
    float wagSpeed = 4.0;
    
    GLKVector3 prevPosition = object->position; //store previous position
    
    //init new move, for fiorst time
    if(!object->moving)
    {
        [self InitNewFishMove: object : floatSpeed : wagSpeed : uppertTime];
    }
    
    //------ movement
    if(object->moving)
    {
        object->timeInMove += dt;
        //add movement to position
        object->position = GLKVector3Add(object->position, GLKVector3MultiplyScalar(object->movementVector, dt));
        object->position.y = [terr GetHeightByPoint:&object->position];
        //wag fish tale
        float wagAmplitude = 0.5;
        [self WagTale:object:wagAmplitude :dt];
    }
    
    //------ conditions
    //if time to change move in normal conditions
    if(object->moving && object->timeInMove > object->moveTime)
    {
        object->movementAngle += [CommonHelpers RandomInRange: -M_PI_4 : M_PI_4 : 100];
        [self InitNewFishMove: object : floatSpeed : wagSpeed : uppertTime];
        if(object->runaway) object->runaway = false;
    }
    
    //if character aproaches and runs, move away from character
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_HARD)
    {
        float minCharacterDistance = 9; //how close can you get to fishm, before it flows away
        float distanceObjectCharacter = GLKVector3Distance(character.camera.position,object->position);
        if(distanceObjectCharacter < minCharacterDistance && [character IsRunning])
        {
            //GLKVector3 awayDirection =  GLKVector3Subtract(object->position,character.camera.position);
            //awayDirection.y = 0; //becouse normalized vector must not depend on heights
            /*
            GLKVector3 awayDirection = [CommonHelpers GetVectorFrom2Points: character.camera.position:  object->position : true];
            object->movementAngle = [CommonHelpers AngleBetweenVectorAndZ: awayDirection];
            object->runaway = true;
            [self InitNewFishMove:object :floatSpeedFast :wagSpeedFast : uppertTimeFast];
            */
            
            [self StartRunaway: object : character.camera.position : floatSpeedFast : wagSpeedFast : uppertTimeFast];
        }
    }
    //check for fish moving boundries
    //fish has to stay between inner and outer circles
    if(object->moving)
    {
        GLKVector3 fishPositionFlat = object->position;
        fishPositionFlat.y = 0;
        //check outer circle and terrain height position
        if(object->position.y > fishTerrainMaxHeight || ![CommonHelpers PointInCircle: fishOuterCr.center: fishOuterCr.radius: fishPositionFlat])
        {
            //dont use 0 because it is the same dirrection
            object->movementAngle += [CommonHelpers RandomInRange: 0.1 : PI_BY_2 - 0.1 : 100];
            //substract the same amount back when run out of allwed space, so it does not get tsuck
            //object->position = GLKVector3Subtract(object->position, GLKVector3MultiplyScalar(object->movementVector, dt));
            object->position = prevPosition;// put back so it doesnt get tsuck
            if(!object->runaway)
            {
                [self InitNewFishMove:object :floatSpeed :wagSpeed :uppertTime]; //normal floating from obsatcle
            }else
            {
                [self InitNewFishMove:object :floatSpeedFast :wagSpeedFast :uppertTimeFast]; //when bumped in while running from char
            }
        }
    }
}

//set new move arameters for fish
- (void) InitNewFishMove: (SModelRepresentation*) object: (float) speed: (float) wagSpeed: (int) upperTime
{
    object->moving = true;
    object->moveTime = [CommonHelpers RandomInRange:1 :upperTime];
    object->timeInMove = 0;
    //tale motions
    object->taleAnimation.angle.y = 0; //nill tale wag angle
    object->taleAnimation.velocity.y = wagSpeed; //tale wag speed
    //set movement direction
    object->movementVector = GLKVector3Make(0.0,0.0,speed); ///movement speed
    [CommonHelpers RotateY: &object->movementVector: object->movementAngle];
}

//start runaway action from threat
//MOTE: also used outside this module
- (void) StartRunaway: (SModelRepresentation*) object : (GLKVector3) threatPosition : (float) speed: (float) wagSpeed: (int) upperTime
{
    if(object->moving && !object->runaway) //put all condition flags here because this function is used outside this modul
    {
        GLKVector3 awayDirection = [CommonHelpers GetVectorFrom2Points: threatPosition:  object->position : true];
        object->movementAngle = [CommonHelpers AngleBetweenVectorAndZ: awayDirection];
        object->runaway = true;
        [self InitNewFishMove: object : speed : wagSpeed : upperTime];
    }
}

#pragma mark - Animation

//wag fish tale
- (void) WagTale: (SModelRepresentation*) object: (float) wagAmplitude: (float) dt
{
    object->taleAnimation.limitUpper.y = wagAmplitude;
    object->taleAnimation.limitLower.y = -wagAmplitude;
    
    //change velocity
    if(object->taleAnimation.angle.y >= object->taleAnimation.limitUpper.y)
    {    
        object->taleAnimation.angle.y = object->taleAnimation.limitUpper.y;
        object->taleAnimation.velocity.y *= -1; //change velocty sign
    }
    else
    if(object->taleAnimation.angle.y <= object->taleAnimation.limitLower.y)
    {
        object->taleAnimation.angle.y = object->taleAnimation.limitLower.y;
        object->taleAnimation.velocity.y *= -1;
    }
    
    object->taleAnimation.angle.y += object->taleAnimation.velocity.y * dt;
}


//helper functions
//if any 
- (BOOL) AnyFishAlive:(int) fishType
{
    BOOL retVal = NO;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].type == fishType && collection[i].visible)
        {
            retVal = YES;
            break;
        }
    }
    
    return retVal;
}


#pragma mark - Picking / Dropping function


//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (int) droppedItemType
{
    if([self IsPlaceAllowed: placePos: terr])
    {
        for (int i = 0; i < count; i++)
        {
            //find some already picked item, assign coords and make visible
            if(!collection[i].visible)
            {
                if((droppedItemType == ITEM_FISH_RAW && collection[i].type == FT_1) ||
                   (droppedItemType == ITEM_FISH_2_RAW && collection[i].type == FT_2)) //find appropriate free type
                {                
                    //release fish back
                    collection[i].position = placePos;
                    collection[i].position.y = 0;
                    collection[i].visible = true;
                    collection[i].moving = false;
                    collection[i].movementAngle = [CommonHelpers RandomInRange:0 :PI_BY_2 :100];
                    
                    [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                    break;
                }
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: droppedItemType: character.inventory.grabbedItem.previousSlot];
    }
}

//NOTE: this item is picked up in campfire module
//place raw fish object at given coordinates
- (void) PlaceObjectRawFish: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*) intct : (CampFire*) cmpFire : (int) droppedItemType
{
    if([self IsPlaceAllowedRawFish: placePos: terr: intct])
    {
        //orientation maches user
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
        float obOrientation = [CommonHelpers AngleBetweenVectorAndZ: pVect] + M_PI_2; //turn 90 more because cooking things will look perpendicular to view vector
        [cmpFire AddItemToStore: droppedItemType : CI_COOKING :placePos: obOrientation];
        
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: droppedItemType: character.inventory.grabbedItem.previousSlot];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr
{
    //weather object is placed in allowed terrain area
    if(placePos.y > fishTerrainMaxHeight)
    {
        return NO;
    }
    
    //not outside fish outer circle
    if(![CommonHelpers PointInCircle: fishOuterCr.center: fishOuterCr.radius: placePos])
    {
        return NO;
    }
    
    return YES;
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowedRawFish: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    //if(![CommonHelpers PointInCircle: terr.oceanLineCircle.center: terr.oceanLineCircle.radius: placePos])
    if(![terr IsInland: placePos])
    {
        return NO;
    }
    
    if(![intct FreeToDrop:placePos])
    {
        return NO;
    }
    
    return YES;
}

@end
