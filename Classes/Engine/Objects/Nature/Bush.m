//
//  Bush.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Bush.h"

@implementation Bush
@synthesize model, effect, collection, vertexCount, indexCount, firstVertex, count;

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
        //collection[i].scale = 0.7;
        collection[i].orientation.y = 0;
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircle:terr.middleCircle.center :terr.middleCircle.radius :0];            
            //calculate location rect for position availability check
            [model  AssignBounds: &collection[i] : 0];
            
            if(![intr IsPlaceOccupiedOnStartup:&collection[i]])
            {
                break;
            }
            
           // NSLog(@"In bush");
        }
        
        //if place is free, set it
        collection[i].located = true;
        collection[i].position.y = [terr GetHeightByPoint:&collection[i].position];
        collection[i].visible = true;
        
        //AABB recalculation (y position available and also make it smaller)
        [model  AssignBounds: &collection[i] : 0.65];
        //add extra crradious for movement detection
        float extraCrRadius = 0.4;
        collection[i].crRadius += extraCrRadius;
    }
    
    [self UpdateVertexArray:mesh];
}


- (void) InitGeometry
{
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.5; //0.7;
    model = [[ModelLoader alloc] initWithFileScale:@"bush.obj":scale];
    
    vertexCount = model.mesh.vertexCount * count;
    indexCount = model.mesh.indexCount * count;
    
   // NSLog(@"%d %d ", vertexCount, indexCount);//480 2520
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
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
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
    [[SingleGraph sharedSingleGraph] SetCullFace:YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, model.patches[0].indexCount * count, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
}

/*
 #pragma mark - Bounds
- (void) SetLocationRect: (SModelRepresentation*) coll
{
    //calculate location rect
    float halfsize = model.crRadius;
    coll->locationRct = CGRectMake(coll->position.x - halfsize,
                                   coll->position.z - halfsize,
                                   halfsize * 2,
                                   halfsize * 2);
    
    //NSLog(@"%f %f %f", model.AABBmax.x , model.AABBmin.x, model.crRadius);
}

- (void) SetAABBRadius: (SModelRepresentation*) coll
{
    //for picking
    float BBscale = 0.65; //scale of bounding box from model scale (percentage of real size for AABB)
    coll->AABBmin = GLKVector3MultiplyScalar(model.AABBmin,BBscale);
    coll->AABBmin = GLKVector3Add(coll->position, coll->AABBmin);
    coll->AABBmax = GLKVector3MultiplyScalar(model.AABBmax,BBscale);
    coll->AABBmax = GLKVector3Add(coll->position, coll->AABBmax);
    
    //for colision detection
    float extraColRadius = 0.4;
    coll->crRadius = model.crRadius + extraColRadius;
}
*/


#pragma mark - Picking

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
            resultBool = [CommonHelpers IntersectLineAABB:charPos: pickedPos: collection[i].AABBmin :collection[i].AABBmax :pickDistance];

            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance:ITEM_WOOD]) //succesfully added
                {
                    returnVal = 1;
                }
                break;
            }
        }
    }
    
    return returnVal;
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}


@end
