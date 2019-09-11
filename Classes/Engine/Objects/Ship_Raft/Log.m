//
//  Log.m
//  Island survival
//
//  Created by Ivars Rusbergs on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK
//
// log management
////////////////////////////////////////////////
// Descr.
// 7 logs
// Each log starts (from ship) at same time, exactly 24 game hours after game starts
// All logs are on island after full 7 days
////////////////////////////////////////////////

#import "Log.h"

@implementation Log
@synthesize model, effect, collection, vertexCount, indexCount, count, firstIndex;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry];
    }
    return self;
}

- (void) ResetData: (Shipwreck*) ship: (Environment*) env
{
    for (int i = 0; i < count; i++) 
    {
        collection[i].position = ship.ship.position; //inital ship wrck position
        collection[i].orientation.y = [CommonHelpers RandomInRange:0 :M_PI :10]; //step 0.1
        collection[i].visible = false; //dont show if not released
        collection[i].enabled = false; //weather released already
        collection[i].marked = false;  //log is held in hands
        collection[i].moving = false;  //floating towards island
        
        [model  AssignBounds: &collection[i] : 0];
        collection[i].boundToGround = 0; //axtra space to ground
        [ObjectHelpers NillDropping: &collection[i]]; //#v1.1.
    }
    
    //parameters
    release.current = 0;
    release.max = env.dayLength * 60;  //seconds between release
}

- (void) InitGeometry
{
    count = 7; //maximum number of logs
    collection = malloc(count * sizeof(SModelRepresentation)); //log collection
    
    float logScale = 2.0;
    model = [[ModelLoader alloc] initWithFileScale:@"log.obj": logScale];
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
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
    
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //64x128
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
    
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor:(Environment*) env: (Ocean*) ocean : (Terrain*) terr : (Character*) character : (Interaction*) inter
{
    [self ReleaseLog:dt:env];
    
    [self MoveLogs:dt:curTime:ocean:terr];
    
    for (int i = 0; i < count; i++) 
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : -1 : -1]; //#v1.1.
        
        //carry in hand
        if(collection[i].marked)
        {
            GLKVector3 logDisplaceVector = GLKVector3Make(0.3, 0.9, 0.0); //detemines position in hand
            [CommonHelpers RotateY:&logDisplaceVector :character.camera.yAngle]; //displacement should always match rotation
            
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat,GLKVector3Subtract(character.camera.position, logDisplaceVector));
            //rotate it always facing the camera
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, character.camera.yAngle);
        }else
        {
            if(collection[i].visible)
            {
                //floating and laying on ground
                collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat,  collection[i].position);
                collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
                if(!collection[i].moving)
                {
                    //adjust to ground only when stopped
                    collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat, collection[i].orientation.x);
                }
            }
        }
    }
    
    self.effect.constantColor = daytimeColor;
}

- (void) Render: (Character*) character
{
    //vertex buffer object is determined by global mesh in upper level class
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible &&
         !(collection[i].marked && character.handItem.ID == kItemEmpty)) //when leaning to fire, dont show log
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
        }
    }
}


- (void) ResourceCleanUp;
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}

#pragma mark - Logs Management

//release log after given time interval from ship to island
- (void) ReleaseLog:(float) dt: (Environment*) env
{
    BOOL allReleased = YES; //check weather alllogs are released
    
    //log releasing
    for (int i = 0; i < count; i++) 
    {
        if(!collection[i].enabled) //not released yet
        {
            allReleased = NO;
            //first is released imidiatly after game starts, all others after interval
            if(i == 0 || release.max < release.current)
            {
                collection[i].visible = true;
                collection[i].enabled = true;
                collection[i].moving = true;
                
                //move by wind
                //release angle maximum offset
                float movementAngleOffset = M_PI / 20.0;
                //calculate offset angle depending on number of log, so it spreads evenly on coeast
                float dirRotAngle = i * ((2 * movementAngleOffset) / (count-1)) - movementAngleOffset;
                float speedFactor = 1.0; //by how much multiply wind speed to get log speed
                
                GLKVector3 movDir = GLKVector3MultiplyScalar(env.wind, speedFactor);
                [CommonHelpers RotateY: &movDir: dirRotAngle]; //rotate direction according to random offset
                collection[i].movementVector = movDir;
                
                release.current = 0;
                break;
            }
        }
    }
    
    if(!allReleased)
    {
        release.current += dt;
    }
}


//move logs to island from ship
- (void) MoveLogs: (float) dt: (float) curTime: (Ocean*) ocean: (Terrain*) terr
{
    //log movement
    for(int i = 0; i < count; i++) 
    {
        if(collection[i].moving) //released and moving
        {
            //move by wind
            GLKVector3 sV = GLKVector3MultiplyScalar(collection[i].movementVector, dt);
            collection[i].position  = GLKVector3Add(collection[i].position, sV);
            float sinkFactor = model.AABBmax.y / 5.0; //how much log sinnks in water when floating
            collection[i].position.y = [ocean GetHeightByPoint:collection[i].position] - sinkFactor;
            
            //check weather log has hit island
            float logStopHeight = ocean.waterBaseHeight;
            if([terr GetHeightByPoint: &collection[i].position] > logStopHeight)
            {
                collection[i].moving = false;
                //place properly on ground
                //[self AdjustEndPoints: terr: &collection[i]];
                [terr AdjustModelEndPoints: &collection[i]: model];
            }
        }
    }
}


//hides the log that is currently in hand
//used in Raft module
- (void) HideLogInHand
{
    for (int i = 0; i < count; i++)
    {
        if(collection[i].marked)
        {
            collection[i].marked = false;
            collection[i].visible = false; //hide log in logs module
            break;
        }
    }
}


#pragma mark - Touch functions

//check if stick object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    BOOL resultBool;
    float objLength = model.AABBmax.z - model.AABBmin.z;
    float numberOfSpheres = 7;
    
    for(int i = 0; i < count; i++)
    {
        if(collection[i].visible && !collection[i].marked && !collection[i].moving)
        {
            /*
            resultBool = NO;
            
            //check through all spheres along the object
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
            
            resultBool = [ObjectHelpers CheckMultipleSpheresCollision: numberOfSpheres : objLength :&collection[i] :charPos :pickedPos :pickDistance];
            //when object is picked
            if(resultBool)
            {
                returnVal = 2;
                if([character PickItemHand: inter :ITEM_RAFT_LOG])
                {
                    returnVal = 1;
                    collection[i].marked = true;
                    [[SingleSound sharedSingleSound]  PlaySound: SOUND_PICK];
                }else
                {
                    //did not pick up
                    [[SingleSound sharedSingleSound]  PlaySound: SOUND_PICK_FAIL];
                    //blink
                    [inter HandFullBlink]; //graphically show that hand is full
                }
                break;
            }
        }
    }
    
    return returnVal;
}

//place stick object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*) intct  : (Interface*) inter
{
    if([self IsPlaceAllowed: placePos: terr: intct])
    {
        for (int i = 0; i < count; i++)
        {
            //find some already picked item, assign coords and make visible
            if(collection[i].marked)
            {
                collection[i].position = placePos;
                collection[i].marked = false;
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect];
                
                //[self AdjustEndPoints: terr: &collection[i]];
                [terr AdjustModelEndPoints: &collection[i]: model];
                
                //this hould be called after AdjustModelEndPoints because in that function position.y is altered
                [ObjectHelpers StartDropping: &collection[i]]; //#v1.1.
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item in hand
        [character PickItemHand: inter : ITEM_RAFT_LOG];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    if(![terr IsBeach:placePos])
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
