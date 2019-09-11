//
//  HandLeaf.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 20/06/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Status - 
//
// -------------
// NOTE: leaf object is used in 3 places with 3 different models - here, shelter leaves and leaf on smallpalm
// Here we process leaf in hand and those dropped on ground, for small palm and just cut leaves go to SmallPalm module
// *smokeing is processed here
// -------------

#import "HandLeaf.h"

@implementation HandLeaf
@synthesize model, effect, collection, bufferAttribs, count;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}


//data that changes from game to game
- (void) ResetData
{
    for (int i = 0; i < count; i++)
    {
        collection[i].visible = false; //at first all leaves are attached to palms, so for ground collection all leaves are invisible
        collection[i].marked = false; //weather is held in hand
        collection[i].enabled = false; //not in blow(swing) motion
        [model  AssignBounds: &collection[i] : 0];
        collection[i].boundToGround = 0.0;
        
        [ObjectHelpers NillDropping: &collection[i]];
    }
}


- (void) InitGeometry
{
    //NOTE: this number is tied to number in SmallPalm module
    count = 8;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 1.2;
    model = [[ModelLoader alloc] initWithFileScale: @"smallpalm_leaf_flat.obj" : scale];
    
    bufferAttribs.vertexCount = model.mesh.vertexCount;
    bufferAttribs.indexCount = model.mesh.indexCount;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    bufferAttribs.firstVertex = *vCnt;
    bufferAttribs.firstIndex = *iCnt;
    for (int n = 0; n < model.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = model.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  model.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < model.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  model.mesh.indices[n] + bufferAttribs.firstVertex;
        *iCnt = *iCnt + 1;
    }
}

- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //64x128
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID;
    self.effect.useConstantColor = GL_TRUE;
}


- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Terrain*) terr : (Interaction*) inter : (Particles*) particles : (CampFire*) campfire : (Beehive*) beehive
{
    self.effect.constantColor = daytimeColor;
    
    //SMOKE CHECK
    //check beehive smoking
    if(!beehive.hive.marked &&  [self IsObjectSmoked: beehive.hive.position : particles])
    {
        [beehive SmokeBeehive];
    }
    
    //update smoke (mainly dicrease smoke when not blowing)
    [self UpdateSmoke: dt : particles : campfire];
    
    //draw leaves that are on ground
    for (int i = 0; i < count; i++)
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : -1 : -1];
        
        //when removed from hand, return in basic state
        if(character.handItem.ID != ITEM_SMALLPALM_LEAF && collection[i].visible && collection[i].marked)
        {
            collection[i].marked = false; //not in hand
            collection[i].visible = false; //not anywhere but inventory
            collection[i].enabled = false; //not in swing motion
        }
        
        //if not visible, means that it is picked up, so put first invisible leaf in hand in case smallpalm leaf icon is placed in hand
        if(!collection[i].visible && character.handItem.ID == ITEM_SMALLPALM_LEAF && ![self IsLeafInHand]) //and no stone is attached to hand
        {
            collection[i].visible = true; //make it visible again
            collection[i].marked = true; //held in hand
            collection[i].enabled = false; //not in swing motion
        }
        
        if(collection[i].visible)
        {
            //IN HAND
            if(collection[i].marked)
            {
                //collection[i].orientation.x = -character.camera.xAngle; //always face camera
                collection[i].orientation.y = character.camera.yAngle; //always face camera
                collection[i].orientation.x = 0.0;
                GLKVector3 displaceVector = GLKVector3Make(0.3, 0.6, -0.2); //determines position on screen
                //[CommonHelpers RotateX: &displaceVector : collection[i].orientation.x]; //displacement should always match rotation
                [CommonHelpers RotateY: &displaceVector : collection[i].orientation.y]; //displacement should always match rotation
                
                collection[i].position = GLKVector3Subtract(character.camera.position, displaceVector);
            
                //update blowing / swinging (self ending) orientation.x affected
                [self UpdateBlow: &collection[i] : dt : particles : character : terr : campfire];
            }
        
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
            collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat, collection[i].orientation.x);
        }
    }
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    //stone o ground
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:NO];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bufferAttribs.firstIndex * sizeof(GLushort)));
        }
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}


#pragma mark - Helper functions

//weather any leaf is currently held in hand
- (BOOL) IsLeafInHand
{
    BOOL retVal = false;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].marked) //the on that is in hand
        {
            retVal = true;
            break;
        }
    }
    
    return retVal;
}

//weather any leaf is currently blowing in swing action
- (BOOL) IsLeafInSwing
{
    BOOL retVal = false;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].enabled) //ins swing
        {
            retVal = true;
            break;
        }
    }
    
    return retVal;
}

#pragma mark - Blowing functions

//start blowing (swaying)function
- (void) StartBlow: (SModelRepresentation*) c
{
    if(!c->enabled) //not swaying/blowing
    {
        c->enabled = true; //start blowing
        c->moveTime = 1.0; //time of sway
        c->timeInMove = 0;
    }
    
}

//updating blowing swaying
//self ending
- (void) UpdateBlow: (SModelRepresentation*) c : (float) dt : (Particles*) particles : (Character*) character : (Terrain*) terr  : (CampFire*) campfire
{
    if(c->enabled) //is swaying / blowing
    {
        float lerpValueSin2Pi = sinf([CommonHelpers ValueInNewRange: 0.0 : c->moveTime : 0.0 : 2*M_PI : c->timeInMove]);
        float swingAmplitude = -0.4; //radians
        
        c->orientation.x = [CommonHelpers Lerp: 0.0 : swingAmplitude : lerpValueSin2Pi];
        
        c->timeInMove += dt;
        if(c->timeInMove > c->moveTime)
        {
            c->enabled = false; //set end of blow motion
        }
        
        //dust particles
        if(!waved && c->orientation.x > 0.0)//when leaf os moving down
        {
            waved = true;
            //check if there is active fireplace in front, then show smoke, otherwise  - dust
            GLKVector3 desiredParticlePosition = [self GetParticlePosition: character]; //get position where the dust/smoke wil blow from
            float blowAffectedRadius = 2.0; //radius of are where blowing will be directed at
            //if fire is burning and blowing in direction of fire
            if(campfire.state == FS_FIRE && [CommonHelpers PointInCircle: desiredParticlePosition : blowAffectedRadius : campfire.campfire.position])
            {
                //first time start smoke
                if(!particles.smokeLargePrt.started)
                {
                    [particles.dustGroundPrt End];
                    [self StartBlowSmokeParticles: terr : particles : character : campfire];
                }else
                {
                    //update soke by changing direction and height depending on new character position and waving intensity
                    [self ResetSmokeBlow: particles : character : campfire];
                }
            }else if(!particles.smokeLargePrt.started)// dont show dust if smoke is still burning
            {
                [particles.smokeLargePrt End];
                [self StartBlowDustParticles: c : terr : particles : character];
            }
        }
    }
}

//get place in fron of camera where particle from swingin/blowing leaf will be generated
- (GLKVector3) GetParticlePosition: (Character*) character
{
    float distFromChar = 3.0; //how far from character this radius is
    return [character.camera PointInFrontOfCamera: distFromChar];
}

#pragma mark - Particles

// DUST
//start blowing dust particles when leaf is swaying
- (void) StartBlowDustParticles: (SModelRepresentation*) c : (Terrain*) terr : (Particles*) particles : (Character*) character
{
    GLKVector3 blowDustPosition = [self GetParticlePosition:character]; //get position where the dust wil blow from
    if(![terr IsOcean:blowDustPosition]) //only on inland
    {
        [terr GetHeightByPointAssign: &blowDustPosition];
        //determine in what direction dusut will be blown
        GLKVector3 dustDirection = [CommonHelpers GetVectorFrom2Points: character.camera.position : blowDustPosition :YES];
        float directionSpeed = 5.0; //how fast dust blow in direction away (multiplied with direction vector)
        dustDirection = GLKVector3MultiplyScalar(dustDirection, directionSpeed);
        
        [particles.dustGroundPrt AssigneTriggerRadius: c->crRadius];
        [particles.dustGroundPrt Start: blowDustPosition : dustDirection]; //self ending, does not rquire endin
    }
}

// SMOKE
//start blowing smoke particles on campfire when leaf is swaying
- (void) StartBlowSmokeParticles : (Terrain*) terr : (Particles*) particles : (Character*) character : (CampFire*) campfire
{
    smokeEffect = 0.25;  //(0.0-1.0) initial effect of smoke from one to maximum , all other parameters should be tied to this
    
    //POSITION (DIRECTION is set to (0,0,0)
    GLKVector3 blowSmokePosition = campfire.campfire.position; //smoke will be on campfire
    [terr GetHeightByPointAssign: &blowSmokePosition];
    float aboveGround = 0.4;
    blowSmokePosition.y += aboveGround;
    [particles.smokeLargePrt Start: blowSmokePosition]; //self ending, does not rquire endin
}

//Used only when updating existing particle smoke
//update Smoke direction , blow speed (direction speed), and particle speed
- (void) ResetSmokeBlow: (Particles*) particles : (Character*) character : (CampFire*) campfire
{
    //SMOKE EFFECT
    float smokeEffectIncrement = 0.3;
    smokeEffect += smokeEffectIncrement; // increase smoke effect
    if(smokeEffect > 1.0) //maximum is 1.0
    {
        smokeEffect = 1.0;
    }
    
    //set new direction in case character changed his position
    GLKVector3 smokeDirection = [CommonHelpers GetVectorFrom2Points: character.camera.position : campfire.campfire.position :YES];
    float directionSpeed = 1.0;
    smokeDirection = GLKVector3MultiplyScalar(smokeDirection, directionSpeed);
    [particles.smokeLargePrt AssignDirection: smokeDirection];
}

//process smoke update
- (void) UpdateSmoke: (float) dt : (Particles*) particles : (CampFire*) campfire
{
    if(campfire.state != FS_FIRE)
    {
        [particles.smokeLargePrt End];
    }
    
    if(particles.smokeLargePrt.started)
    {
        //SMOKE EFFECT
        float smokeEffectDecr = -0.15; //decrement per secondper second
        smokeEffect += smokeEffectDecr * dt; // increase smoke effect
        if(smokeEffect < 0.0)
        {
            smokeEffect = 0.0;
        }
        //all parameters below are tied to smokeEffect value from 0 to 1.0
        
        //SPEED (from initial to 1.0)
        float prtclSpeedUpperLimit = 1.0;
        //tie to smoke effect
        float newParticleSpeed = [CommonHelpers ValueInNewRange: 0.0 : 1.0 : particles.smokeLargePrt.attributes.prtclSpeedInitial :prtclSpeedUpperLimit :smokeEffect];
        [particles.smokeLargePrt AssigneMaxParticleSpeed: newParticleSpeed];
        
        //COUNT (from 0 to max)
        int prtCount = (int) (smokeEffect * particles.smokeLargePrt.attributes.maxCount);
        [particles.smokeLargePrt AssignCurrentCount: prtCount];
        
        //DIRECT
        //put direction to 0 when smoke is low
        if(smokeEffect < 0.2)
        {
            GLKVector3 smokeDirection = GLKVector3Make(0.0, 0.0, 0.0);
            [particles.smokeLargePrt AssignDirection: smokeDirection];
        }
        
        //NSLog(@"******* total %d curr %d", particles.smokeLargePrt.attributes.maxCount, prtCount);
        //NSLog(@"=========== %f", smokeEffect);
        if(fequal(smokeEffect, 0.0) || smokeEffect < 0.0)
        {
            [particles.smokeLargePrt End];
        }
    }
}

#pragma mark - Checking from smoking

//check wetaher object with given position is smoked
//In order to get smoked object must be within maximal distance,
//smoke direction should be directed at object and
//smoke effect should be above given level
- (BOOL) IsObjectSmoked: (GLKVector3) objPosition : (Particles*) particles
{
    BOOL retBal = false;
    //1.
    //maximal distance to smokable object where smoking is possible
    float maxDistToObj = 5.0;
    float distFromFireToObj = [CommonHelpers DistanceInHorizPLane: objPosition : particles.smokeLargePrt.attributes.initialPos];
    
    //2.
    //direction of smoke flow
    GLKVector3 smokeDirection = GLKVector3Normalize(particles.smokeLargePrt.attributes.direction);
    //direction from fire place to object
    GLKVector3 directionFromFireToObj = [CommonHelpers GetVectorFrom2Points: particles.smokeLargePrt.attributes.initialPos : objPosition : YES ];
    float allowedAngleOffset = 0.2; //smoke direction allowed offset
    
    //3.
    //smoke effect should be above given level
    float effectiveSmokeSpeed = 0.8;
    
    if(particles.smokeLargePrt.started && distFromFireToObj <= maxDistToObj &&
       [CommonHelpers AngleBetweenVectors180: smokeDirection : directionFromFireToObj] <= allowedAngleOffset &&
       smokeEffect >= effectiveSmokeSpeed
      )
    {
        retBal = true;
    }
    
    return retBal;
}


#pragma mark - Picking / Dropping function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object

    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible && !collection[i].marked)
        {
           // resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius:
           //                                         charPos: pickedPos: pickDistance];
            
            //check through all spheres along the object
            int numberOfSpheres = 3;
            float objLength = model.AABBmax.z - model.AABBmin.z;
            BOOL resultBool = [ObjectHelpers CheckMultipleSpheresCollision: numberOfSpheres : objLength :&collection[i] :charPos :pickedPos :pickDistance];
            
            /*
            float step = 1.0 / (numberOfSpheres * 2); //step from 0.0-1.0 depending on number of spheres
            float sphereRadius = step * objLength; //radius of step spheres
            for(int n = 0; n < numberOfSpheres; n++)
            {
                //divide length into given number of spheres and find each radius and center
                //lerp is suposed to be from 0.0 - 1.0
                float lerpVal = step + 2 * n * step;
                GLKVector3 sphereCenter = GLKVector3Lerp(collection[i].endPoint1, collection[i].endPoint2, lerpVal);
                
                resultBool = [CommonHelpers IntersectLineSphere: sphereCenter: sphereRadius: charPos: pickedPos: pickDistance];
                
                //NSLog(@"%f %f %f",sphereCenter.x, sphereCenter.y, sphereCenter.z);
                //NSLog(@"%f",sphereRadius);
                
                if(resultBool)
                {
                    break;
                }
            }
            */
            
            if(resultBool)
            {
                returnVal = 2;
                //it can be held in hand so first try to put in hand
                if([character PickItemHand: inter : ITEM_SMALLPALM_LEAF])
                {
                    returnVal = 1;
                    collection[i].visible = false;
                }else
                {
                    //if hand was not empty, try adding to inventory
                    if([character.inventory AddItemInstance: ITEM_SMALLPALM_LEAF]) //succesfully added
                    {
                        returnVal = 1;
                        collection[i].visible = false;
                    }
                }
                break;
            }
        }
    }
  
    return returnVal;
}

//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*)intct  : (Interface*) inter
{
    if([self IsPlaceAllowed: placePos: terr: intct])
    {
        for (int i = 0; i < count; i++)
        {
            //find some already picked item, assign coords and make visible
            if(!collection[i].visible)
            {
                collection[i].position = placePos;
                collection[i].visible = true;
                collection[i].marked = false;
                collection[i].enabled = false;
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect] + M_PI_2;
                
                [terr AdjustModelEndPoints: &collection[i]: model];
                
                [ObjectHelpers StartDropping: &collection[i]];
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        if(![character.inventory PutItemInstance: ITEM_SMALLPALM_LEAF : character.inventory.grabbedItem.previousSlot])
        {
            //this case happens when spear was in hand, inventory full and tried to place spear on ground where not allowed
            [character PickItemHand: inter : ITEM_SMALLPALM_LEAF];
        }
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct
{
    if(![intct FreeToDrop: placePos])
    {
        return NO;
    }
    
    return YES;
}


#pragma mark - Touch functions

- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character
{
    BOOL retVal = NO;
    
    if([intr IsLeafBlowButtTouched: tpos] && ![self IsLeafInSwing])
    {
        //in this case action button is for action
        Button *actionButt = [intr.overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
        [actionButt PressBegin: touch];
        
        for (int i = 0; i < count; i++)
        {
            if(collection[i].marked)
            {
                [self StartBlow: &collection[i]]; //swinging action
                waved = false; //hold value of weather already waved in this wave (to check particles etc)
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_BLOW];
                break;
            }
        }
        retVal = YES;
    }
    
    return retVal;
}

@end
