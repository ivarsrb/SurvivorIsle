//
//  Shipwreck.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "Shipwreck.h"

@implementation Shipwreck
@synthesize model, effect, ship, vertexCount, indexCount;

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
- (void) ResetData: (Terrain*) terr : (Environment*) env
{
    //determine ship possible location circle around island
    SCircle shipCircle = terr.islandCircle;
    shipCircle.radius = SHIP_DIST; //how far away from center ship will be located

    //position the ship from direction of the wind
    float windAngle = -env.windAngle - M_PI_2;//[CommonHelpers AngleBetweenVectorAndZ:env.wind];
    ship.position = [CommonHelpers PointOnCircle: shipCircle : windAngle]; //-x based
    ship.position.y = 1.0;
    ship.visible = true;
}

- (void) InitGeometry
{
    ship.scale = 5.0;
    
    //OPTI - could use long cubes for ship masts not logs
    model = [[ModelLoader alloc] initWithFileScale: @"shipwreck.obj" : ship.scale];
    
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
    
    //textures
    for (int i = 0; i < model.materialCount; i++)
    {
        texIDs[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.materials objectAtIndex:i]: YES]; //shipwreck- 64x64, stick - 128x64 , rag -64x64
    }
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor
{
    ship.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, ship.position);
    
    self.effect.constantColor = daytimeColor;
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    if(ship.visible)
    {
        //OPTI - could not cull only sail
        [[SingleGraph sharedSingleGraph] SetCullFace: NO]; //must cull
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        self.effect.transform.modelviewMatrix = ship.displaceMat;
        //render all materials
        for (int m = 0; m < model.materialCount ; m++)
        {
            self.effect.texture2d0.name = texIDs[m];
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));
        }
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(texIDs);
}

@end
