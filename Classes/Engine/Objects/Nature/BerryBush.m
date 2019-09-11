//
//  BerryBush.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/7/13.
//
// STATUS: - OK

#import "BerryBush.h"

@implementation BerryBush
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
- (void) ResetData: (Terrain*) terr : (Interaction*) intr
{
    for (int i = 0; i < count; i++)
    {
        collection[i].orientation.y = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 10];
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircle : terr.middleCircle.center : terr.middleCircle.radius : 0];
            [model  AssignBounds: &collection[i] : 0];
            /*
            float size = (model.AABBmax.x - model.AABBmin.x);
            collection[i].locationRct = CGRectMake(collection[i].position.x - size/2,
                                                   collection[i].position.z - size/2,
                                                   size, size);
            */
            
            if(![intr IsPlaceOccupiedOnStartup:&collection[i]])
            {
                break;
            }
            
           // NSLog(@"In berrybush");
        }
        
        
        collection[i].located = true;
        collection[i].position.y = [terr GetHeightByPoint: &collection[i].position];
        collection[i].visible = true;
        collection[i].marked = true; //if true, means taht berries are on bush
        //collection[i].bsRadius = model.bsRadius;
        //AABB box
        [model  AssignBounds: &collection[i] : 1.0];
    }

    //[self UpdateVertexArray:mesh];
}


- (void) InitGeometry
{
    count = 3;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.3;
    model = [[ModelLoader alloc] initWithFileScale: @"berry_bush.obj" : scale];
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    /*
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
    */
    
    //load model into external geometry mesh
    //we ned only one actual object in array
    firstVertex = *vCnt;
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
    texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0] : YES]; //128x128
    texIDempty = [[SingleGraph sharedSingleGraph] AddTexture: @"berry_bush_empty.png" : YES];     //128x128
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor
{
    //self.effect.transform.modelviewMatrix = *modelviewMat;
    self.effect.constantColor = daytimeColor;
    
    for (int i = 0; i < count; i++)
    {
        collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
        collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
    }
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    [[SingleGraph sharedSingleGraph] SetCullFace:YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    for (int i = 0; i < count; i++)
    {
        if(collection[i].marked)
        {
            //berries on
            self.effect.texture2d0.name = texID;
        }else
        {
            self.effect.texture2d0.name = texIDempty;
        }
        
        self.effect.transform.modelviewMatrix = collection[i].displaceMat;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));

        
        //OPTI - possible to use batching (draw together equal textures)
       // [effect prepareToDraw];
       // glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[0].indexCount * i) * sizeof(GLushort)));
    }
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
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
        if(collection[i].visible && collection[i].marked)
        {
            //resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius: charPos: pickedPos: pickDistance];
            resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : collection[i].AABBmin : collection[i].AABBmax : pickDistance];

            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance:ITEM_BERRIES]) //succesfully added
                {
                    returnVal = 1;
                    collection[i].marked = false;
                }
                break;
            }
        }
    }
    
    return returnVal;
}

@end

