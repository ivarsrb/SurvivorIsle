//
//  DeadfallTrap.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "DeadfallTrap.h"

@implementation DeadfallTrap
@synthesize model, effect, collection, vertexCount, indexCount,count;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    for (int i = 0; i < count; i++) 
    {
        collection[i].visible = false;
        collection[i].marked = false; //if true - trap has fallen and trapped game
        collection[i].orientation.y = 0;
        collection[i].boundToGround = 0; //axtra space to ground
        [ObjectHelpers NillDropping: &collection[i]]; //#v1.1.
    }
}


- (void) InitGeometry
{
    count = 1; //maximal number of objects, must be no less than maximal number of rock component
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float trapScale = 0.5;
    model = [[ModelLoader alloc] initWithFileScale: @"deadfall_trap.obj" : trapScale];
    
    //determine bounding sphere radius
    for (int i = 0; i < count; i++)
    {
        //collection[i].bsRadius = model.bsRadius;
        [model  AssignBounds: &collection[i] : 0];
    }
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
    //texture array
    texIDs = malloc(model.materialCount * sizeof(GLuint));
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
        
    //load textures
    for (int i = 0; i < model.materialCount; i++)
    {
        //rock - 64x64, bark - 64x64, bait - 16x16
        texIDs[i] = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex: i] : YES];
    }
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter
{
    //position objects
    for (int i = 0; i < count; i++) 
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : 100 : -1]; //#v1.1.
        
        if(collection[i].visible)
        {
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat,  collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
            //trapp is cought
            if(collection[i].marked)
            {
                //rotate it as fallen rock
                float blockRot = -M_PI_4 / 2.0; //how much rotate rock when falling
                float blockLower = -collection[i].bsRadius / 3.0; //after rotating need to move rock down
                collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat,blockRot);
                collection[i].displaceMat = GLKMatrix4Translate(collection[i].displaceMat, 0, blockLower, 0);
            }
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
            [[SingleGraph sharedSingleGraph] SetCullFace:YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            //render all materials
            for (int m = 0; m < model.materialCount ; m++)
            {
                //when rock is fallen dont draw sticks and bait
                //NOTE rock should be the last object in model
                if(collection[i].marked && m != model.materialCount - 1)
                    continue;
                
                self.effect.texture2d0.name = texIDs[m];
                [self.effect prepareToDraw];
                    
                glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));
            }
        }
    } 
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
    free(texIDs);
}

#pragma mark - Additional Functions


//if game is stepped into some trap, then catch it in trap
//#TODO - catch falling sound needed
- (BOOL) CatchInTrap: (GLKVector3*) gamePosition  : (Particles*) particles
{
    BOOL cought = NO;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible && !collection[i].marked)
        {
            //if game has approached trap
            float trapRadious = collection[i].bsRadius / 2.0; //area when trapps falls when rat enters
            if([CommonHelpers PointInSphere: collection[i].position :trapRadious :*gamePosition])
            {
                collection[i].marked = true;
                cought = YES;
                *gamePosition = collection[i].position; //force object to trap position //rat is pushhed into ground in objectactions module
                
                [particles.commonGroundAreaSplashPrt AssigneTriggerRadius: collection[i].crRadius];
                [particles.commonGroundAreaSplashPrt Start: collection[i].position]; //self ending, does not rquire ending
                break;
            }
        }
    }
    
    return cought;
}


#pragma mark - Picking function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv 
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            //adjust AABB to current position
            GLKVector3 AABBmin = GLKVector3Add(collection[i].position, model.AABBmin);
            GLKVector3 AABBmax = GLKVector3Add(collection[i].position, model.AABBmax);
            resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : AABBmin : AABBmax : pickDistance];
            //resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius:  charPos: pickedPos: pickDistance];
            
            if(resultBool)
            {
                returnVal = 2;
                
                if([inv AddItemInstance: ITEM_DEADFALL_TRAP]) //succesfully added
                {
                    returnVal = 1;
                    collection[i].visible = false;
                }
                
                break;
            }
        }
    }
    
    return returnVal;
}

//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct: (int) droppedItem
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
                
                [ObjectHelpers StartDropping: &collection[i]]; //#v1.1.
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect] - M_PI_2;
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: droppedItem: character.inventory.grabbedItem.previousSlot];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    /*
    if(![CommonHelpers PointInCircle: terr.inlandCircle.center: terr.inlandCircle.radius: placePos])
    {
        return NO;
    }
    */
    
    if(![terr IsInland: placePos])
    {
        return NO;
    }
    
    if(![intct FreeToDrop: placePos])
    {
        return NO;
    }
    
    return YES;
}




@end
