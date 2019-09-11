//
//  RainCatch.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "RainCatch.h"

@implementation RainCatch
@synthesize model,modelDrops, effect,effectDrops, vertexCount, indexCount,collection,
            vertexDynamicCount, indexDynamicCount, count;

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
        collection[i].orientation.y = 0;
        collection[i].visible = false;
        collection[i].marked = true; //is empty
        collection[i].time = 0; //time this object cought the raion
        collection[i].bsRadius = model.bsRadius / 2.0;
        collection[i].crRadius = model.crRadius;
        collection[i].boundToGround = 0.04; //axtra space to ground, space above ground so ground doest show through bottom
        [ObjectHelpers NillDropping: &collection[i]]; //#v1.1.
    }
}


- (void) InitGeometry
{
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    catchTime = 4; //seconds
    
    float scale = 0.33; //scale must match shell loaded model scale, leave is scaled within blender model
    //shell,leaves,water
    model = [[ModelLoader alloc] initWithFileScale:@"raincatch.obj": scale];
    //drops
    modelDrops = [[ModelLoader alloc] initWithFileScale:@"raincatch_drops.obj": scale];

    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
    vertexDynamicCount = modelDrops.mesh.vertexCount;
    indexDynamicCount = modelDrops.mesh.indexCount;
    
    //texture array
    texIDs = malloc(model.materialCount+modelDrops.materialCount * sizeof(GLuint));
}

- (void) SetupRendering
{
    //load textures
    for (int i = 0; i < model.materialCount; i++) 
    {
        texIDs[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.materials objectAtIndex:i]: YES];  //water - 32x32
    }
    
    //load textures drop
    for (int i = 0; i < modelDrops.materialCount; i++)
    {
        texIDs[i+model.materialCount] = [[SingleGraph sharedSingleGraph] AddTexture:[modelDrops.materials objectAtIndex:i]: YES]; //32x64
        glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    }
    
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effect.texture2d0.enabled = GL_TRUE; 
    self.effect.useConstantColor = GL_TRUE;
    
    //for drops
    self.effectDrops = [[GLKBaseEffect alloc] init];
    self.effectDrops.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectDrops.texture2d0.enabled = GL_TRUE;
    self.effectDrops.useConstantColor = GL_TRUE;
    self.effectDrops.texture2d0.name = texIDs[model.materialCount];
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

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    firstVertexDrops = *vCnt;
    firstIndexDrops = *iCnt;
    for (int n = 0; n < modelDrops.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelDrops.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelDrops.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < modelDrops.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelDrops.mesh.indices[n] + firstVertexDrops;
        *iCnt = *iCnt + 1;
    }
}

//update drops texture coordinates
- (void) UpdateDynamicVertexArray:(GeometryShape*) mesh:(float) dt
{
    int vCnt = firstVertexDrops;

    //if at least one is visible
    BOOL isVisible = NO;
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            isVisible = YES;
            break;
        }
    }
    //--
    
    if(isVisible)
    {
        float tspeed = 0.3 * dt; //texture update speed
        for (int n = 0; n < modelDrops.mesh.vertexCount; n++)
        {
            //update textures
            mesh.verticesT[vCnt].tex.t += tspeed;
    
            //limit check
            int whileNum = 10; //10 is random whole number
            if(mesh.verticesT[vCnt].tex.t - modelDrops.mesh.verticesT[n].tex.t >= whileNum)
            {
                //take into account gap, so it does not look like jumping
                mesh.verticesT[vCnt].tex.t = modelDrops.mesh.verticesT[n].tex.t + ((mesh.verticesT[vCnt].tex.t - modelDrops.mesh.verticesT[n].tex.t) - whileNum);
            }
            
            vCnt++;
        }
    }
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor: (Environment*) env:(GeometryShape*) meshDynamic : (Interaction*) inter
{
    for (int i = 0; i < count; i++)
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : -1 : -1]; //#v1.1.
        
        if(collection[i].visible)
        {
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);

            if(env.raining && collection[i].marked) //empty
            {
                collection[i].time += dt;
                //fill with rain water
                if(collection[i].time >= catchTime) //catch time has expired
                {
                    collection[i].marked = false; //full
                }
            }
        }
    }
    
    //drop update, only when raining
    if(env.raining)
    {
        [self UpdateDynamicVertexArray:meshDynamic:dt];
    }
    
    self.effect.constantColor = daytimeColor;
    self.effectDrops.constantColor = daytimeColor;
}

- (void) Render
{
    //leave, shell, water
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:NO];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            //[[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            for (int j = model.materialCount - 1; j >= 0 ; j--) //render by material (upside down)
            {
                //if is empty, downt draw water inside
                //NOTE water should be first object in model file
                if(collection[i].marked && j == 0)
                    continue;
                
                if(!collection[i].marked && j == 0)
                {
                    //water trasanprent
                    //water texture should be semi transaprent
                    [[SingleGraph sharedSingleGraph] SetBlend:YES];
                    [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
                }else
                {
                    //other solid
                    [[SingleGraph sharedSingleGraph] SetBlend:NO];
                }
                
                //#NOTE - if more than one raincatch, make rendering in baches - leaf, leaf - shell , shell
                self.effect.texture2d0.name = texIDs[j];
                [self.effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[j].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[j].startIndex) * sizeof(GLushort)));
            }
        }
    }
}

- (void) RenderDynamic :(BOOL) raining
{
    //render catch drops
    if(raining)
    {
        for (int i = 0; i < count; i++)
        {
            if(collection[i].visible)
            {
                [[SingleGraph sharedSingleGraph] SetCullFace:YES]; 
                [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
                [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
                [[SingleGraph sharedSingleGraph] SetBlend:YES];
                [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
                
                self.effectDrops.transform.modelviewMatrix = collection[i].displaceMat;
                [self.effectDrops prepareToDraw];
                glDrawElements(GL_TRIANGLES, modelDrops.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexDrops + modelDrops.patches[0].startIndex) * sizeof(GLushort)));
            }
        }
    }
}

- (void) ResourceCleanUp
{
    [model ResourceCleanUp];
    [modelDrops ResourceCleanUp];
    self.effect = nil;
    self.effectDrops = nil;
    free(collection);
    free(texIDs);
}

#pragma mark - Picking function


//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv 
{
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    int returnVal = 0;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius: 
                                                    charPos: pickedPos: pickDistance];
           
            if(resultBool)
            {
                returnVal = 2;
                if(collection[i].marked) //pick empty catch
                {
                    if([inv AddItemInstance:ITEM_RAINCATCH]) //succesfully added
                    {
                        returnVal = 1;
                        collection[i].visible = false;
                    }
                }else //pick catch filled with water
                {
                    if([inv AddItemInstance:ITEM_RAINCATCH_FULL]) //succesfully added
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
                collection[i].position.y += collection[i].boundToGround;
                collection[i].visible = true;
                collection[i].marked = true;
                collection[i].time = 0;
                
                [ObjectHelpers StartDropping: &collection[i]]; //#v1.1.
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect] - M_PI;
                
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
    if(![CommonHelpers PointInCircle: terr.oceanLineCircle.center: terr.oceanLineCircle.radius: placePos])
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
