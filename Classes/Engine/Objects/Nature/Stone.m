//
//  Stone.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 30/03/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Status - OK

#import "Stone.h"

@implementation Stone
@synthesize model, effect, collection, bufferAttribs;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
        
    }
    return self;
}

//data that needs to set before resetting data, like nilling object locations (so random locations detection work correctly)
- (void) PresetData
{
    for (int i = 0; i < count; i++)
    {
        collection[i].located = false;
    }
}


//data that changes from game to game
- (void) ResetData: (Terrain*) terr : (Interaction*) intr
{
    //stones on ground
    for (int i = 0; i < count; i++)
    {
        collection[i].visible = true;
        collection[i].marked = false; //weather is held in hand
        [ObjectPhysics HaltMotion: &collection[i]];
        collection[i].boundToGround = model.bsRadius; //axtra space to ground
        [self PlaceOnBeach: &collection[i] :terr :intr];
        
        //dropping
        //[ObjectHelpers NillDropping: &collection[i]];
    }
}


- (void) InitGeometry
{
    count = 10;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.14; //0.1;
    model = [[ModelLoader alloc] initWithFileScale: @"stone.obj" : scale];
    
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
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //64x64
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID;
    self.effect.useConstantColor = GL_TRUE;
}


- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Terrain*) terr : (Interaction*) inter : (Particles*) particles : (Ocean*) ocean
{
    self.effect.constantColor = daytimeColor;
    
    //draw stones that are on ground
    for (int i = 0; i < count; i++)
    {
        //[ObjectHelpers UpdateDropping: &collection[i] : dt];
        
        //when removed from hand, return in basic state
        if(character.handItem.ID != ITEM_STONE && collection[i].visible && collection[i].marked)
        {
            collection[i].marked = false; //not in hand
            collection[i].visible = false; //not anywhere but inventory
            [ObjectPhysics HaltMotion: &collection[i]];
        }
        
        //if not visible, means that it is picked up, so put first invisible stone in hand in case stone icon is placed in hand
        if(!collection[i].visible && character.handItem.ID == ITEM_STONE && ![self IsStoneInHand]) //and no stone is attached to hand
        {
            collection[i].visible = true; //make it visible again
            collection[i].marked = true; //held in hand
            [ObjectPhysics HaltMotion: &collection[i]];
        }
        
        if(collection[i].visible)
        {
            //IN HAND
            if(collection[i].marked)
            {
                collection[i].orientation.x = -character.camera.xAngle; //always face camera
                collection[i].orientation.y = character.camera.yAngle; //always face camera
                
                GLKVector3 displaceVector = GLKVector3Make(0.3, -0.11, -0.6); //determines position on screen
                [CommonHelpers RotateX: &displaceVector : collection[i].orientation.x]; //displacement should always match rotation
                [CommonHelpers RotateY: &displaceVector : collection[i].orientation.y]; //displacement should always match rotation
                
                collection[i].position = GLKVector3Subtract(character.camera.position, displaceVector);
            }
            
            //IN FLIGHT
            if([ObjectPhysics IsInMotion: &collection[i]])
            {
                GLKVector3 prevPoint = collection[i].position; //needed for colision calculation
                //projectile motion
                [ObjectPhysics UpdateMotion: &collection[i] : dt];
                [ObjectPhysics GetResultantVelocity: &collection[i]]; //#OPTI velocity could be calculated once before is used
                //collision detection
                [self CollisionDetection: &collection[i] : terr : prevPoint : inter : particles : ocean : character];
            }
            
            //matrix
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            //rotate to face camera when in hand or flying
            if(collection[i].marked /*|| [ObjectPhysics IsInMotion:&collection[i]]*/)
            {
                collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
               // collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat, collection[i].orientation.x);
            }
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
            [[SingleGraph sharedSingleGraph] SetCullFace:YES];
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

#pragma mark - Stone throwing functions

//initiate stone throw
- (void) Throw: (SModelRepresentation*) c : (Character*) character
{
    //set up throw
    c->marked = false; //not held in hand any more
    
    float throwSpeed = 22;//20.0; //initial horizontal speed
    
    //[ObjectPhysics ResetMotionByAngles:  c : throwSpeed : character.camera.xAngle : character.camera.yAngle];
    GLKVector3 throwVector = character.camera.viewVector; //[character.camera GetViewVector];
    //turn throwing sidewy since stone is to the right
    float offsetAngle = 0.03;
    [CommonHelpers RotateY: &throwVector : offsetAngle];
    
    [ObjectPhysics ResetMotionByVector:  c : throwSpeed : throwVector];
}


//all collision detection,
- (void) CollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (Interaction*) inter  : (Particles*) particles : (Ocean*) ocean : (Character*) character
{
    //---------- Ground check and ending position.
    //Stone can only stop on ground if speed reaches below certain number - it is percieved as 0 and stopped
    float speedMinlimit = 5.0; //speed limit below wich stone is considered to stop
    float groundSlowdownKoef = 0.3; //by how much velocity decreases after hitting ground
    float cocosSlowdownKoef = 0.03; //by how much velocity slows down after colliding with cocos
    float palmSlowdownKoef = 0.3; //by how much velocity slows down after colliding with palm
    float velocityBeforeCollision = c->physics.velocity;
    int groundResult = 0;
    
    
    groundResult = [inter ObjectVsGroundCollision: c : prevPoint : speedMinlimit : groundSlowdownKoef];
    if(groundResult == 2) //just hit the ground and stopped
    {
        //when stone flies out of reach, put it back on beach
        if(![CommonHelpers PointInCircle: terr.majorCircle.center: terr.majorCircle.radius: c->position])
        {
            [self PlaceOnBeach: c : terr : inter];
        }
    }else
    {
        BOOL cocosHit = [inter ObjectVsCocosCollision: c : prevPoint : cocosSlowdownKoef];
        BOOL palmHit = [inter ObjectVsPalmCollision: c : prevPoint : palmSlowdownKoef];
        
        //sound
        if(cocosHit || palmHit)
        {
            [[SingleSound sharedSingleSound]  PlayAbsoluteSound: SOUND_HIT_WOOD : c->position : NO];
        }
    }
    
    //wildlife interaction
    if(groundResult == 1 || groundResult == 2) //hit the ground
    {
        [inter ObjectVsWildlifeInteraction: c : character];
    }
    
    //particles
    //water splash
    //currently undr water but previous was above water, so it just struck water
    if(c->position.y <= ocean.oceanBase.y && prevPoint.y > ocean.oceanBase.y && [terr IsOcean: c->position])
    {
        [particles.splashDropPrt Start: c->position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlayAbsoluteSound: SOUND_HIT_WATER : c->position : NO];
    }
    
    //ground splash
    if(groundResult == 1) //hit ground without stopping
    {
        float minSplashSpeed = 10.0; //minimal speed  below which splashes arent shown
        if(velocityBeforeCollision > minSplashSpeed && ![terr IsOcean: c->position])
        {
            [particles.groundSplashPrt Start: c->position]; //self ending, does not rquire ending
            //sound
            [[SingleSound sharedSingleSound]  PlayAbsoluteSound: SOUND_HIT_SOFT : c->position : NO];
        }
    }
    
    //palm crown explosion check
    if([inter ObjectVsPalmCrownCollision:c])
    {
        [particles.palmExplosionPrt Start: c->position]; //self ending, does not rquire ending
    }
}


#pragma mark - Helper functions

//weather any stone is currently held in hand
- (BOOL) IsStoneInHand
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

//place object on beach
- (void) PlaceOnBeach: (SModelRepresentation*) c : (Terrain*) terr : (Interaction*) intr
{
    while (YES) //reselect location until free space found
    {
        c->position = [CommonHelpers RandomInCircleSector: terr.inlandCircle.center : terr.inlandCircle.radius : terr.oceanLineCircle.radius : 0];
        [model  AssignBounds: c : 0];
        if(![intr IsPlaceOccupiedOnStartup: c])
        {
            break;
        }
    }
    //#TODO what if raft is built or any other object ten it will throw itself onto it, may be use similar function to GetHeightByPoint
    c->position.y = [terr GetHeightByPoint:&c->position] + c->boundToGround;
    c->located = true; //placed on ground
}
#pragma mark - Picking / Dropping function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible && !collection[i].marked)
        {
            resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius:
                                                    charPos: pickedPos: pickDistance];
            
            if(resultBool)
            {
                returnVal = 2;
                //it can be held in hand so first try to put in hand
                if([character PickItemHand: inter : ITEM_STONE])
                {
                    returnVal = 1;
                    collection[i].visible = false;
                }else
                {
                    //if hand was not empty, try adding to inventory
                    if([character.inventory AddItemInstance: ITEM_STONE]) //succesfully added
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
                collection[i].position.y += collection[i].boundToGround;
                collection[i].visible = true;
                [ObjectHelpers StartDropping: &collection[i]];
                
                //orientation maches user
                //GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                //collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        if(![character.inventory PutItemInstance: ITEM_STONE : character.inventory.grabbedItem.previousSlot])
        {
            //this case happens when spear was in hand, inventory full and tried to place spear on ground where not allowed
            [character PickItemHand: inter : ITEM_STONE];
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
    
    if([intr IsStoneThrowButtTouched: tpos])
    {
        //in this case action button is for action
        Button *actionButt = [intr.overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
        [actionButt PressBegin: touch];
        
        //throw stone
        for (int i = 0; i < count; i++)
        {
            if(collection[i].marked) //the on that is in hand
            {
                [self Throw: &collection[i] : character];
                //flight ended
                //empty hand item
                [character ClearHand];
                [intr SetBasicInterface];
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_THROW];
                break;
            }
        }
        
        retVal = YES;
    }
    
    return retVal;
}

@end
