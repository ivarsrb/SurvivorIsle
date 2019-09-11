//
//  Egg.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 22/09/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// Status - 


#import "Egg.h"

@implementation Egg
@synthesize model, effect, collection, count, bufferAttribs;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}

- (void) ResetData: (Leaves*) leaves;
{
    for (int i = 0; i < count; i++)
    {
        //put in first leave
        collection[i].position = leaves.collection[i].position;
        collection[i].position.y += leaves.collection[i].crRadius;
        collection[i].orientation.y = leaves.collection[i].orientation.y; //[CommonHelpers RandomInRange: 0 : PI_BY_2 : 100];
        collection[i].visible = true;
        collection[i].boundToGround = 0; //axtra space to ground for dropping function
        [model  AssignBounds: &collection[i] : 0.0];
    }
}

- (void) InitGeometry
{
    //NOTE: this count should not be greater than leaves.count
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.21;
    model = [[ModelLoader alloc] initWithFileScale: @"eggnest.obj" : scale];
    //
    bufferAttribs.vertexCount = model.mesh.vertexCount;
    bufferAttribs.indexCount = model.mesh.indexCount;
    
    //texture array
    texIDs = malloc(model.materialCount * sizeof(GLuint));
}

- (void) SetupRendering
{
    //load textures
    for (int i = 0; i < model.materialCount; i++)
    {
        texIDs[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.materials objectAtIndex:i]: YES]; //egg - 64x64, nest - 64x64
    }
    
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
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

- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character
{
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
        }
    }
    
    self.effect.constantColor = daytimeColor;
}

- (void) Render
{
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace: YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            
            for (int j = 0; j < model.materialCount; j++)
            {
                self.effect.texture2d0.name = texIDs[j];
                [self.effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[j].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[j].startIndex) * sizeof(GLushort)));
            }
        }
    }
}

- (void) ResourceCleanUp
{
    [model ResourceCleanUp];
    self.effect = nil;
    free(collection);
    free(texIDs);
}


#pragma mark - Picking function


//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos :  (Inventory*) inv
{
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    int returnVal = 0;
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            resultBool = [CommonHelpers IntersectLineSphere: collection[i].position : collection[i].bsRadius :
                                                    charPos : pickedPos : pickDistance];
            
            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance: ITEM_EGG]) //succesfully added
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

@end
