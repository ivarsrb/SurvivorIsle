//
//  Leaves.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "Leaves.h"

@implementation Leaves
@synthesize model, effect, collection, vertexCount, indexCount,firstVertex,count,firstIndex;

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
- (void) ResetData: (GeometryShape*) mesh : (Terrain*) terr : (Interaction*) intr
{
    for (int i = 0; i < count; i++) 
    {
        collection[i].orientation.y = [CommonHelpers RandomInRange:0 :PI_BY_2 :10];
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircle: terr.grassCircle.center : terr.grassCircle.radius : 0];
            
            //calculate location rect (0 because we dont calculate AABB here because we dont have y value yet)
            [model  AssignBounds: &collection[i] : 0];
            
            if(![intr IsPlaceOccupiedOnStartup:&collection[i]])
            {
                break;
            }
            
            //NSLog(@"In leaves");
        }
       
        collection[i].located = true;
        collection[i].position.y = [terr GetHeightByPoint:&collection[i].position];
        collection[i].visible = true;
        
        //AABB box
        [model  AssignBounds: &collection[i] : 0.7];
    }
    
    [self UpdateVertexArray:mesh];
}


- (void) InitGeometry
{
    count = 3;
    float scale = 0.7;
    collection = malloc(count * sizeof(SModelRepresentation));

    model = [[ModelLoader alloc] initWithFileScale: @"leaves.obj" : scale];

    vertexCount = model.mesh.vertexCount * count;
    indexCount = model.mesh.indexCount * count;
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
            //dummy
            mesh.verticesT[*vCnt].vertex = GLKVector3Make(0, 0, 0);
            mesh.verticesT[*vCnt].tex = GLKVector2Make(0, 0);
            *vCnt = *vCnt + 1;
        }
        for (int n = 0; n < model.mesh.indexCount; n++) 
        {
            //indices
            mesh.indices[*iCnt] =  model.mesh.indices[n] + firstVertex + (i*model.mesh.vertexCount);
            *iCnt = *iCnt + 1;
        }
    }
}


//fill vertex array with new values
- (void) UpdateVertexArray:(GeometryShape*) mesh
{
    //load model into external geometry mesh
    int vCnt = firstVertex;
    
    for (int i = 0; i < count; i++) 
    {
        for (int n = 0; n < model.mesh.vertexCount; n++) 
        {
            //vertices
            mesh.verticesT[vCnt].vertex = GLKVector3Add(model.mesh.verticesT[n].vertex, collection[i].position);
            mesh.verticesT[vCnt].tex =  model.mesh.verticesT[n].tex;
            
            //rotate to orientation
            [CommonHelpers RotateY:&mesh.verticesT[vCnt].vertex :collection[i].orientation.y: collection[i].position];

            vCnt = vCnt + 1;
        }
    }
}

- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //64x64

    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor
{
    self.effect.transform.modelviewMatrix = *modelviewMat;
    self.effect.constantColor = daytimeColor;    
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, model.patches[0].indexCount * count, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
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
            resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : collection[i].AABBmin : collection[i].AABBmax : pickDistance];

            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance: ITEM_LEAF]) //succesfully added
                {
                    returnVal = 1;
                }
                
                break;
            }
        }
    }
    
    return returnVal;
}




@end
