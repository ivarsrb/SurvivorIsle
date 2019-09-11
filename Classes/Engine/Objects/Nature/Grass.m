//
//  Grass.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Grass.h"

@implementation Grass
@synthesize model, effect, collection, vertexCount, indexCount,firstVertex,count;

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
- (void) ResetData: (GeometryShape*) mesh: (Terrain*) terr: (Interaction*) intr
{
    for (int i = 0; i < count; i++) 
    {
        collection[i].scale = 1.5; //#DECIDE maybe different scales
        collection[i].position = [CommonHelpers RandomInCircle: terr.grassCircle.center : terr.grassCircle.radius : 0];

        float heightLowener = 0.10;
        collection[i].position.y = [terr GetHeightByPoint:&collection[i].position] - heightLowener;
        
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(collection[i].position, terr.islandCircle.center));
        collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect];
        
        //for part of grass, turn it 180 degrees around, so it looks more diverse
        if(i > count / 2)
        {
            collection[i].orientation.y += M_PI;
        }
    }
    
    [self UpdateVertexArray:mesh];
}

- (void) InitGeometry
{
    count = 65;
    collection = malloc(count * sizeof(SModelRepresentation));

    model = [[ModelLoader alloc] initWithFile:@"grass.obj"];
    
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
            mesh.verticesT[*vCnt].tex = model.mesh.verticesT[n].tex;
            
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
            mesh.verticesT[vCnt].vertex.x = model.mesh.verticesT[n].vertex.x * collection[i].scale + collection[i].position.x;
            mesh.verticesT[vCnt].vertex.y = model.mesh.verticesT[n].vertex.y * collection[i].scale + collection[i].position.y; 
            mesh.verticesT[vCnt].vertex.z = model.mesh.verticesT[n].vertex.z * collection[i].scale + collection[i].position.z; 
            
            //rotate to orientation
            [CommonHelpers RotateY:&mesh.verticesT[vCnt].vertex :collection[i].orientation.y:collection[i].position];

            
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
    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]  : YES]; //128x32
    
    self.effect.texture2d0.enabled = GL_TRUE;
    //[[SingleGraph sharedSingleGraph] TextureName:[model.materials objectAtIndex:0]]
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
    [[SingleGraph sharedSingleGraph] SetDepthMask:NO];
    [[SingleGraph sharedSingleGraph] SetBlend:YES];
    [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
    
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, model.patches[0].indexCount * count, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}

@end
