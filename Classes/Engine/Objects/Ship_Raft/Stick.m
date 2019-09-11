//
//  Stick.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

/////////////////////
// NOTE:
// Ground spear and stick models should be equal in dimensions and size
// BOTH should use the same texture
/////////////////////

#import "Stick.h"

@implementation Stick
@synthesize model,modelSpear, effect, collection,collectionSpear, vertexCount, indexCount, count, firstIndex;

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
    //sticks
    for (int i = 0; i <  count; i++) 
    {
        collection[i].located = false;
    }
    
}

//data that changes from game to game
- (void) ResetData: (Terrain*) terr : (Interaction*) intr : (Environment*) env
{
    //sticks
    for (int i = 0; i < count; i++) 
    {
        collection[i].visible = true;

        while (YES) //reselect location until free space found
        {
            float windAngle = -env.windAngle - M_PI_2; //PointOnCircle is -x based
            float randomOffset = [CommonHelpers RandomInRange: -M_PI/5 : M_PI/5 : 1000];
            collection[i].position = [CommonHelpers PointOnCircle: terr.oceanLineCircle : windAngle + randomOffset];
            
            
            //calculate location rect
            //models should be Z-oriented
            /*
            float sizeZ = model.AABBmax.z - model.AABBmin.z;
            collection[i].locationRct = CGRectMake(collection[i].position.x - sizeZ/2, 
                                                   collection[i].position.z - sizeZ/2,
                                                   sizeZ, sizeZ);
            */
            
            [model  AssignBounds: &collection[i] : 0];
            
            if(![intr IsPlaceOccupiedOnStartup: &collection[i]])
            {
                break;
            }

        }
        
        collection[i].orientation.y = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 10]; //step 0.1
        collection[i].position.y = [terr GetHeightByPoint: &collection[i].position];
        collection[i].located = true;
        collection[i].boundToGround = 0; //axtra space to ground
        //end points to manipulate picking
        //[self AdjustEndPoints:terr:&collection[i]];
        //[model  AssignBounds: &collection[i] : 1.0];
        //AABB from model is taken here
        [terr AdjustModelEndPoints: &collection[i]: model];
        
        [ObjectHelpers NillDropping: &collection[i]]; 
    }
    
    //spear on ground
    for (int i = 0; i < countSpear; i++)
    {
        collectionSpear[i].visible = false;
        collectionSpear[i].boundToGround = 0; //axtra space to ground
        [ObjectHelpers NillDropping: &collectionSpear[i]]; //#v1.1.
    }
}

- (void) InitGeometry
{
    count = 4;
    countSpear = count;
    collection = malloc(count * sizeof(SModelRepresentation));
    collectionSpear = malloc(countSpear * sizeof(SModelRepresentation));
    
    float stickScale = 0.4;
    model = [[ModelLoader alloc] initWithFileScale:@"stick.obj":stickScale];
    modelSpear = [[ModelLoader alloc] initWithFileScale:@"spear_ground.obj":stickScale];
    
    vertexCount = model.mesh.vertexCount + modelSpear.mesh.vertexCount;
    indexCount = model.mesh.indexCount + modelSpear.mesh.indexCount;
    
    //for collision detection
    numberOfSpheres = 7;
}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    int firstVertex = *vCnt;
    firstIndex = *iCnt;
    
    //sticks
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
    
    //spears
    firstVertex = *vCnt;
    firstIndexSpear = *iCnt;
    for (int n = 0; n < modelSpear.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelSpear.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelSpear.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < modelSpear.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelSpear.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
    
}

- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //load model textures (both spear and stick use the same texture)
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //128x64
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter
{
    self.effect.constantColor = daytimeColor;
    
    //sticks
    for(int i = 0; i < count; i++)
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : -1 : -1];
        
        if(collection[i].visible)
        {
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
        
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);        
            collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat, collection[i].orientation.x);
        }
    }
    
    //spear
    for(int i = 0; i < countSpear; i++)
    {
        [ObjectHelpers UpdateDropping: &collectionSpear[i] : dt : inter : -1 : -1];
        
        if(collectionSpear[i].visible)
        {
            collectionSpear[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collectionSpear[i].position);
            
            collectionSpear[i].displaceMat = GLKMatrix4RotateY(collectionSpear[i].displaceMat, collectionSpear[i].orientation.y);
            collectionSpear[i].displaceMat = GLKMatrix4RotateX(collectionSpear[i].displaceMat, collectionSpear[i].orientation.x);
        }
    }
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    
    //sticks
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
            glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
        }
    }
    
    //spear
    for (int i = 0; i < countSpear; i++)
    {
        if(collectionSpear[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collectionSpear[i].displaceMat;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, modelSpear.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndexSpear * sizeof(GLushort)));
        }
    }
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    [modelSpear ResourceCleanUp];
    free(collection);
    free(collectionSpear);
}


#pragma mark - Picking / Dropping function

//check if stick object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos: (GLKVector3) pickedPos: (Inventory*) inv 
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    BOOL resultBool;
    float objLength = model.AABBmax.z - model.AABBmin.z;

    for(int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            /*resultBool = NO;
            
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
            }*/
            resultBool = [ObjectHelpers CheckMultipleSpheresCollision: numberOfSpheres : objLength :&collection[i] :charPos :pickedPos :pickDistance];
            
            //when object is picked
            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance: ITEM_STICK]) //succesfully added
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


//check if spear object is picked, and add to inventory
- (int) PickObjectSpear: (GLKVector3) charPos: (GLKVector3) pickedPos : (Character*) character : (Interface*) inter
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    BOOL resultBool;
    float objLength = modelSpear.AABBmax.z - modelSpear.AABBmin.z;
    
    for(int i = 0; i < countSpear; i++)
    {
        if(collectionSpear[i].visible)
        {
            //resultBool = NO;
            
            //check through all spheres along the object
            /*
            float step = 1.0 / (numberOfSpheres * 2); //step from 0.0-1.0 depending on number of spheres
            float sphereRadius = step * objLength; //radius of step spheres
            for(int n = 0; n < numberOfSpheres; n++)
            {
                //divide length into given number of spheres and find each radius and center
                //lerp is suposed to be from 0.0 - 1.0
                float lerpVal = step + 2 * n * step;
                GLKVector3 sphereCenter = GLKVector3Lerp(collectionSpear[i].endPoint1, collectionSpear[i].endPoint2, lerpVal);
                
                resultBool = [CommonHelpers IntersectLineSphere: sphereCenter: sphereRadius: charPos: pickedPos: pickDistance];
                
                //NSLog(@"%f %f %f",sphereCenter.x, sphereCenter.y, sphereCenter.z);
                //NSLog(@"%f",sphereRadius);
                
                if(resultBool)
                {
                    break;
                }
            }
            */
            resultBool = [ObjectHelpers CheckMultipleSpheresCollision: numberOfSpheres : objLength :&collectionSpear[i] :charPos :pickedPos :pickDistance];
            
            if(resultBool)
            {
                returnVal = 2;
                //it can be held in hand so first try to put in hand
                if([character PickItemHand: inter : ITEM_SPEAR])
                {
                    returnVal = 1;
                    collectionSpear[i].visible = false;
                }else
                {
                    //if hand was not empty, try adding to inventory
                    if([character.inventory AddItemInstance: ITEM_SPEAR]) //succesfully added
                    {
                        returnVal = 1;
                        collectionSpear[i].visible = false;
                    }
                }
                break;
            }
            
        }
    }
    
    return returnVal;
}




//place stick object at given coordinates
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
                collection[i].visible = true;
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect] + M_PI_2;
                
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
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: ITEM_STICK: character.inventory.grabbedItem.previousSlot];
    }
}

//place spear object at given coordinates
- (void) PlaceObjectSpear: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct : (Interface*) inter
{
    if([self IsPlaceAllowed: placePos: terr: intct])
    {
        for (int i = 0; i < countSpear; i++)
        {
            //find some already picked item, assign coords and make visible
            if(!collectionSpear[i].visible)
            {
                collectionSpear[i].position = placePos;
                collectionSpear[i].visible = true;
                
                //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collectionSpear[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect] + M_PI_2;
                
                //[self AdjustEndPoints:terr:&collectionSpear[i]];
                [terr AdjustModelEndPoints: &collectionSpear[i]: model];
                
                //this hould be called after AdjustModelEndPoints because in that function position.y is altered
                [ObjectHelpers StartDropping: &collectionSpear[i]]; //#v1.1.

                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        if(![character.inventory PutItemInstance: ITEM_SPEAR : character.inventory.grabbedItem.previousSlot])
        {
            //this case happens when spear was in hand, inventory full and tried to place spear on ground where not allowed
            [character PickItemHand: inter : ITEM_SPEAR];
        }
    }
}



//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    if(![intct FreeToDrop:placePos])
    {
        return NO;
    }
    
    return YES;
}


@end
