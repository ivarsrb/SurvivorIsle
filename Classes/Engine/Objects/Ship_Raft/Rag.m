//
//  Rag.m
//  Island survival
//
//  Created by Ivars Rusbergs on 11/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "Rag.h"

@implementation Rag
@synthesize model, texture, effect, rag, vertexCount, indexCount, firstIndex;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry];
    }
    return self;
}

- (void) ResetData: (Shipwreck*) ship : (Environment*) env : (Terrain*) terr
{
    rag.position = ship.ship.position; //inital ship wrck position
    //rag.orientation.y = [CommonHelpers RandomInRange:0 : M_PI : 10]; //step 0.1
    //orientation toward island center so end points can be adjusted
    GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(rag.position, terr.islandCircle.center));
    rag.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
    
    rag.enabled = false; //weather released already
    rag.moving = false; //floating towards island
    rag.visible = false; //dont show if not released
    
    [model  AssignBounds: &rag : 0];
    
    //parameters 
    release.current = 0;
    //release with last log
    release.max = env.dayLength * 60 * 7;//interval after which rag must be released
}

- (void) InitGeometry
{
    float ragScale = 1.5;
    model = [[ModelLoader alloc] initWithFileScale: @"rag.obj" : ragScale];
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so w    e ned only one actual object in array
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
    
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //64x64
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor:(Environment*) env: (Ocean*) ocean:(Terrain*) terr
{
    [self ReleaseRag:dt:env];
    
    [self MoveRags:dt:curTime:ocean:terr];
    
    //floating and laying on ground
    if(rag.visible)
    {
        rag.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, rag.position);
        rag.displaceMat = GLKMatrix4RotateY(rag.displaceMat, rag.orientation.y);
        
        if(!rag.moving)
        {
            //adjust to ground only when stopped
            rag.displaceMat = GLKMatrix4RotateX(rag.displaceMat, rag.orientation.x);
        }
    }
    self.effect.constantColor = daytimeColor;
}

- (void) Render
{
    [[SingleGraph sharedSingleGraph] SetCullFace: YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
    [[SingleGraph sharedSingleGraph] SetBlend: NO];
    
    //vertex buffer object is determined by global mesh in upper level class
    if(rag.visible)
    {
        self.effect.transform.modelviewMatrix = rag.displaceMat;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
    }
    
}

- (void) ResourceCleanUp;
{
    self.effect = nil;
    [model ResourceCleanUp];
}

#pragma mark - Rag Management

//release rag after given time interval from ship to island
- (void) ReleaseRag: (float) dt: (Environment*) env
{
    if(!rag.enabled)
    {
        release.current += dt;
        if(release.max < release.current)
        {
            //release
            rag.enabled = true;
            rag.moving = true;
            rag.visible = true;
            
            //move by wind
            //randomize movement a bit
            float movementAngleOffset = M_PI / 20.0;
            float rotAngle = [CommonHelpers RandomInRange:-movementAngleOffset :movementAngleOffset :100]; //step 0.01
            float speedFactor = 1;
            
            GLKVector3 movDir = GLKVector3MultiplyScalar(env.wind, speedFactor);
            [CommonHelpers RotateY: &movDir: rotAngle]; //rotate direction according to random offset
            rag.movementVector = movDir;
        }
    }
}


//move rag to island from ship
- (void) MoveRags: (float) dt: (float) curTime: (Ocean*) ocean: (Terrain*) terr
{
    //rag movement
    if(rag.moving) //released and moving
    {
        //move by wind
        GLKVector3 sV = GLKVector3MultiplyScalar(rag.movementVector, dt);
        rag.position  = GLKVector3Add(rag.position, sV);
        rag.position.y = [ocean GetHeightByPoint:rag.position];
        
        //check weather log has hit island
        float ragStopHeight = ocean.waterBaseHeight;
        if([terr GetHeightByPoint: &rag.position] > ragStopHeight)
        {
            rag.moving = false;
            
            //[self AdjustEndPoints: terr: &rag];
            [terr AdjustModelEndPoints:&rag :model];
        }
    }
}


#pragma mark - Touch functions

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    BOOL resultBool;
    
    if(rag.visible && !rag.moving)
    {
        //adjust AABB to current position
        // GLKVector3 AABBmin = GLKVector3Add(rag.position, rag.AABBmin);
        // GLKVector3 AABBmax = GLKVector3Add(rag.position, rag.AABBmax);
        // resultBool = [CommonHelpers IntersectLineAABB:charPos: pickedPos: AABBmin :AABBmax :pickDistance];
        
        resultBool = [CommonHelpers IntersectLineSphere: rag.position: model.bsRadius:
                                                         charPos: pickedPos: pickDistance];
        
        if(resultBool)
        {
            returnVal = 2;
            if([inv AddItemInstance:ITEM_RAG]) //succesfully added
            {
                returnVal = 1;
                rag.visible = false;
            }
        }
    }
    
    return returnVal;
}


//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct
{
    //weather object is placed in allowed terrain area
    if([self IsPlaceAllowed: placePos: terr: intct] && !rag.visible)
    {
        rag.position = placePos;
        //orientation maches user
        //GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
        //rag.orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect];
        
        //orientation toward island center so end points can be adjusted
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(rag.position, terr.islandCircle.center));
        rag.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
        
        rag.visible = true;
        
        //[self AdjustEndPoints: terr: &rag];
        [terr AdjustModelEndPoints: &rag : model];
        
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: ITEM_RAG : character.inventory.grabbedItem.previousSlot];
    }
}


//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    if(![terr IsBeach:placePos])
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
