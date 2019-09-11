//
//  DryGrass.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "DryGrass.h"

@implementation DryGrass
@synthesize model, effect, collection, vertexCount, indexCount, firstVertex,count;

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
- (void) ResetData: (GeometryShape*) mesh: (Terrain*) terr: (Interaction*) intr
{
    for (int i = 0; i < count; i++) 
    {
        float cradditSize = 0.3; //make icrcel larger
        collection[i].orientation.y = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 10];
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircle:terr.grassCircle.center :terr.grassCircle.radius :0];
            //calculate location rect
            /*
            float additSize = 1.0; //additional size for location check, so other objects dont get too close
            float size = model.AABBmax.x - model.AABBmin.x + additSize;
            collection[i].locationRct = CGRectMake(collection[i].position.x - size/2, 
                                                   collection[i].position.z - size/2,
                                                   size, size);
            */
            //calculate location rect (0 because we dont calculate AABB here because we dont have y value yet)
            [model  AssignBounds: &collection[i] : 0];
            collection[i].crRadius += cradditSize;
            
            if(![intr IsPlaceOccupiedOnStartup:&collection[i]])
            {
                break;
            }
            
            //NSLog(@"In dry grass");
        }
        collection[i].located = true;
        collection[i].position.y = [terr GetHeightByPoint:&collection[i].position];
        collection[i].visible = true;
    
        float BBscale = 0.8; //scale of bounding box from model scale (percentage of real size for AABB)
        //AABB box
        [model  AssignBounds: &collection[i] : BBscale];
        collection[i].crRadius += cradditSize;
        /*
        collection[i].AABBmin = GLKVector3MultiplyScalar(model.AABBmin,BBscale);
        collection[i].AABBmin = GLKVector3Add(collection[i].position, collection[i].AABBmin);
        collection[i].AABBmax = GLKVector3MultiplyScalar(model.AABBmax,BBscale);
        collection[i].AABBmax = GLKVector3Add(collection[i].position, collection[i].AABBmax);
        */
        
    }
    
    
    //init branch parameters
    int bcnt = 0;
    for (int i = 0; i < count; i++)
    {
        for (int j = 0; j < brachesPerGrass; j++)
        {
            //rotation point, position
            branches[bcnt].position = collection[i].position;
            //offset (swaying) angle
            branches[bcnt].offsetAngle = GLKVector3Make(0, 0, 0);
            bcnt++;
        }
    }

    
    swingTime = 0; //branch swing time, used in sine
    
    [self UpdateVertexArray:mesh:YES];
}


- (void) InitGeometry
{
    count = 3; //object count
    brachesPerGrass = 3;
    bracheCount = count * brachesPerGrass;
    
    collection = malloc(count * sizeof(SModelRepresentation));
    branches = malloc(bracheCount * sizeof(SBranchAnimation));
    
    float scale = 0.45;//0.55;
    model = [[ModelLoader alloc] initWithFileScale:@"dry_grass.obj":scale];
    
    vertexCount = model.mesh.vertexCount * count;
    indexCount = model.mesh.indexCount * count;
    
    vertexPerBranch = vertexCount / bracheCount;
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
- (void) UpdateVertexArray:(GeometryShape*) mesh: (BOOL) start
{
    //load model into external geometry mesh
    int vCnt = firstVertex;
    int bCnt = 0; //branch count
    
    for (int i = 0; i < count; i++) 
    {
        if(start) //statically init vertices
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
        }else  //dynamic updating
        {
            for (int n = 0; n < model.mesh.vertexCount; n++)
            {
                //change only top part vertices
                //NOTE: lower vertices MUST be y <= 0 in model file
                if(mesh.verticesT[vCnt].vertex.y - collection[i].position.y > 0)
                {
                    //one branch swing in X other in Z direction
                    if(bCnt % 2 == 0)
                    {
                        [CommonHelpers RotateX: &mesh.verticesT[vCnt].vertex: branches[bCnt].offsetAngle.x: branches[bCnt].position];
                    }else
                    {
                        [CommonHelpers RotateZ: &mesh.verticesT[vCnt].vertex: branches[bCnt].offsetAngle.x: branches[bCnt].position];
                    }
                }
               
                vCnt = vCnt + 1;
                
                //after every branch vertex patch, change branch
                if((vCnt-firstVertex) % vertexPerBranch == 0)
                {
                    bCnt++;
                }
            }
        }
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]  : YES]; //128/64

    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (GeometryShape*) mesh
{
    [self UpdateBranches:dt];
    [self UpdateVertexArray:mesh:NO];
    
    self.effect.transform.modelviewMatrix = *modelviewMat;
    self.effect.constantColor = daytimeColor;    
}

- (void) RenderDynamic
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
    free(branches);
}

#pragma mark - Additional functions

//update brach parameters
- (void) UpdateBranches: (float) dt
{
    float swingAplitude = 0.001;
    
    swingTime += dt;
    
    for (int i = 0; i < bracheCount; i++)
    {
        branches[i].offsetAngle.x = sinf(swingTime + i) * swingAplitude;
    }
    
    //nil sin value
    //must be from no 0 to 2 * PI
    if(swingTime >= PI_BY_2)
    {
        swingTime = 0;
    }
}


#pragma mark - Picking function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Inventory*) inv
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
                if([inv AddItemInstance: ITEM_TINDER]) //succesfully added
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
