//
//  Cocos.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK
// #v.1.1. change - cocos no longer fall on their own (except first one), they should be shot down using stone

#import "Cocos.h"

@implementation Cocos
@synthesize model, effect, collection, vertexCount, indexCount, count;


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
//must initialize only after Palmtree is initialized
- (void) ResetData: (Terrain*) terr : (PalmTree*) palm
{
    firstReleased = false; //first cocos is released on his won, others are need to be shot doen
    //flags
    //visible - currently rendered
    //marked - if has fallen from tree (falling from trees only those who marked=false)
    //num - number of palm that cocos is attached
    for(int i = 0; i < count; i++)
    {
        [model  AssignBounds: &collection[i] : 0];
        //show on palms
        collection[i].visible = true;
        collection[i].marked = false; //this parameters tells weather cocos is released from palm
        //put on palm tree - changes position and asigns order number(num) of palm cocos is attached to
        [palm PlaceOnPalmtree: &collection[i]];
        collection[i].boundToGround = model.bsRadius; //axtra space to ground
        
        [ObjectPhysics HaltMotion: &collection[i]];
        
    }
}

//initializes first
- (void) InitGeometry
{
    //NOTE: cocos max count should not exceed  palms_count * 4
    count = 8;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float cocosScale = 0.25;
    model = [[ModelLoader alloc] initWithFileScale: @"cocos.obj" : cocosScale]; //#v.1.1. - cocos origin is now in center
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    //parameters
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    int firstVertex = *vCnt;
    firstIndex = *iCnt;
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
        mesh.indices[*iCnt] =  model.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0] : YES]; //64x64
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (Interaction*) inter  : (Particles*) particles
{
    for (int i = 0; i < count; i++) 
    {
        //[ObjectHelpers UpdateDropping: &collection[i] : dt : terr : -1 : -1]; //#v1.1.
        
        if(collection[i].visible)
        {
            //ON PALMTREE
            if(!collection[i].marked)
            {
                if(!firstReleased) //release the first coconut without hitting ir
                {
                    [self Release: &collection[i]];
                    firstReleased = true;
                }
            }
            
            //IN FLIGHT
            if([ObjectPhysics IsInMotion: &collection[i]])
            {
                GLKVector3 prevPoint = collection[i].position; //needed for colision calculation
                //projectile motion
                [ObjectPhysics UpdateMotion: &collection[i] : dt];
                [ObjectPhysics GetResultantVelocity: &collection[i]]; //#OPTI velocity could be calculated once before is used
                //collision detection
                [self CollisionDetection: &collection[i] : terr : prevPoint : inter : particles];
            }
            
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
        }
    }
    self.effect.constantColor = daytimeColor;
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace: YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
        }
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}


#pragma mark - Cocos release, falling , collision

//release a cocos on its own fom tree falls sriaght down
- (void) Release: (SModelRepresentation*) c
{
    c->marked = true; //no more on palmtree
    float throwSpeed = 0.0; //initial horizontal speed
    //fall down
    [ObjectPhysics ResetMotionByVector:  c : throwSpeed : GLKVector3Make(0, -1, 0)];
}

//release a cocos after being hit by object, give it push from direction it was hit
- (void) ReleaseAfterHit: (SModelRepresentation*) c : (SModelRepresentation*) hitterObj
{
    c->marked = true; //no more on palmtree
    float recievedSpeedSlowdownKoef = 0.1; //how much of hitter speed is released at release
    float throwSpeed = hitterObj->physics.velocity * recievedSpeedSlowdownKoef; //initial horizontal speed
    
    //give it direction of release after being hit
    GLKVector3 releaseDirection = [CommonHelpers GetVectorFrom2Points: hitterObj->position : c->position : false];
    
    [ObjectPhysics ResetMotionByVector:  c : throwSpeed : releaseDirection];
}

//all collision detection,
- (void) CollisionDetection: (SModelRepresentation*) c : (Terrain*) terr : (GLKVector3) prevPoint : (Interaction*) inter  : (Particles*) particles
{
    //---------- Ground check and ending position.
    //Stone can only stop on ground if speed reaches below certain number - it is percieved as 0 and stopped
    float speedMinlimit = 5.0; //speed limit below wich stone is considered to stop
    float groundSlowdownKoef = 0.3; //by how much velocity decreases after hitting ground
    float palmSlowdownKoef = 0.4; //by how much velocity slows down after colliding with palm
    float velocityBeforeCollision = c->physics.velocity;
    int groundResult = 0;
    
    groundResult = [inter ObjectVsGroundCollision: c : prevPoint : speedMinlimit : groundSlowdownKoef];
    
    [inter ObjectVsPalmCollision: c : prevPoint : palmSlowdownKoef];
    
    //ground splash
    if(groundResult == 1) //hit ground without stopping
    {
        float minSplashSpeed = 10.0; //minimal speed  below which splashes arent shown
        if(velocityBeforeCollision > minSplashSpeed && ![terr IsOcean: c->position])
        {
            //NSLog(@"splash");
            [particles.groundSplashPrt Start: c->position]; //self ending, does not rquire ending
            
            //sound
            [[SingleSound sharedSingleSound]  PlayAbsoluteSound: SOUND_HIT_SOFT : c->position : NO];
        }
    }
}


#pragma mark - Picking /Dropping function

//check if object is picked, and add to inventory
//return 0 - has not picked, 1 - picked, 2 - invenotry was full, not able to pick
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv 
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].marked && collection[i].visible)
        {
            //adjust AABB to current position
            //GLKVector3 AABBmin = GLKVector3Add(collection[i].position, model.AABBmin);
            //GLKVector3 AABBmax = GLKVector3Add(collection[i].position, model.AABBmax);
            
            //resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : AABBmin : AABBmax : pickDistance];
            resultBool = [CommonHelpers IntersectLineSphere: collection[i].position : collection[i].bsRadius : charPos : pickedPos : pickDistance];
            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance: ITEM_COCONUT]) //succesfully added
                {
                    collection[i].visible = false;
                    returnVal = 1;
                }
                
                break;
            }
        }
    }
    
    return returnVal;
}

//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct
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
                collection[i].marked = true;
                
                [ObjectHelpers StartDropping: &collection[i]]; //#v1.1.
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                
                break;
            }
        }
    }else 
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: ITEM_COCONUT: character.inventory.grabbedItem.previousSlot];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{ 
    //weather object is placed in allowed terrain area
    if(![intct FreeToDrop:placePos])
    {
        return NO;
    }
    
    return YES;
}


@end
