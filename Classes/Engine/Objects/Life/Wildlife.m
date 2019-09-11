//
//  Wildlife.m
//  The Survivor
//
//  Created by Ivars Rusbergs on 3/6/14.
//  Copyright (c) 2014 Ivars Rusbergs. All rights reserved.
//
// STATUS: - OK
//
//IMPORTANT:
//  Butterflies are one object drawn as multiple instances, always in constant wing flaping state



#import "Wildlife.h"

@implementation Wildlife

@synthesize bflyModel, bflyEffect, bflyCollection, bflyMeshParams, dolphinModel, dolphinEffect,
            dolphin, dolphinMeshParams;


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
- (void) ResetData: (Terrain*) terr
{
    //buttefly
    bflyEtalonWingsAngle = 0;
    for (int i = 0; i < bflyCount; i++)
    {
        [self ResetBfly: &bflyCollection[i] : i : terr];
    }
    
    //dolphin
    [self ResetDolphin: &dolphin :  terr];
}

- (void) InitGeometry
{
    //butterfly
    bflyCount = 3;
    bflyCollection = malloc(bflyCount * sizeof(SModelRepresentation));
    //dolphin
    //dolphinCollection = malloc(dolphinCount * sizeof(SModelRepresentation));
    
    //butterfly
    float bflyScale = 0.15; //0.1
    bflyModel = [[ModelLoader alloc] initWithFileScale: @"butterfly.obj" : bflyScale]; //Z-Based model, head to positive
    bflyMeshParams.vertexCount = bflyModel.mesh.vertexCount;
    bflyMeshParams.indexCount = bflyModel.mesh.indexCount;
    
    //dolphin
    float dolphinScale = 3.0;
    dolphinModel = [[ModelLoader alloc] initWithFileScale: @"dolphin.obj" : dolphinScale]; //Z-Based model, head to positive
    dolphinMeshParams.vertexCount = dolphinModel.mesh.vertexCount;
    dolphinMeshParams.indexCount = dolphinModel.mesh.indexCount;

    //texture array
    //bfly
    //NOTE: each butterfly has 1 teture, but we want to use 3 different ones
    int bflyTextureCcount = 3;
    bflyTexID = malloc(bflyTextureCcount * sizeof(GLuint));
}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //butterfly
    bflyMeshParams.firstVertex = *vCnt;
    bflyMeshParams.firstIndex = *iCnt;
    
    for (int n = 0; n < bflyModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = bflyModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex = bflyModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < bflyModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] = bflyModel.mesh.indices[n] + bflyMeshParams.firstVertex;
        *iCnt = *iCnt + 1;
    }
}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //dolphin
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    dolphinMeshParams.firstVertex = *vCnt;
    dolphinMeshParams.firstIndex = *iCnt;
    for (int n = 0; n < dolphinModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = dolphinModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  dolphinModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < dolphinModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  dolphinModel.mesh.indices[n] + dolphinMeshParams.firstVertex;
        *iCnt = *iCnt + 1;
    }
}


//fill dynamic vertex array with new values
- (void) UpdateVertexArray: (GeometryShape*) mesh
{
    //butterfly
    int vCnt = bflyMeshParams.firstVertex;
    //wing flap only one isntance and draw it later in different places
    for (int n = 0; n < bflyModel.mesh.vertexCount; n++)
    {
        if(bflyModel.mesh.verticesT[n].vertex.x != 0.0) //dont rotate middle axis vertices
        {
            //wing flap direction
            int sign = 1;
            if(bflyModel.mesh.verticesT[n].vertex.x < 0.0)
            {
                sign = -1;
            }
            
            mesh.verticesT[vCnt].vertex = [CommonHelpers RotateZRet: bflyModel.mesh.verticesT[n].vertex : (sign * bflyEtalonWingsAngle)];
        }
        
        vCnt++;
    }
}

- (void) SetupRendering
{
    //butterfly
    self.bflyEffect = [[GLKBaseEffect alloc] init];
    self.bflyEffect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //3type of bfly textures
    bflyTexID[0] = [[SingleGraph sharedSingleGraph] AddTexture:[bflyModel.materials objectAtIndex:0] : YES]; //4x4
    bflyTexID[1] = [[SingleGraph sharedSingleGraph] AddTexture:@"butterfly_yellow.png" : YES];  //4x4
    bflyTexID[2] = [[SingleGraph sharedSingleGraph] AddTexture:@"butterfly_blue.png" : YES]; //4x4
    
    self.bflyEffect.texture2d0.enabled = GL_TRUE;
    self.bflyEffect.useConstantColor = GL_TRUE;
    
    //dolphin
    self.dolphinEffect = [[GLKBaseEffect alloc] init];
    self.dolphinEffect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    dolphinTexID = [[SingleGraph sharedSingleGraph] AddTexture: [dolphinModel.materials objectAtIndex:0] : YES]; //64x64

    self.dolphinEffect.texture2d0.enabled = GL_TRUE;
    self.dolphinEffect.texture2d0.name = dolphinTexID;
    self.dolphinEffect.useConstantColor = GL_TRUE;
}

- (void) Update: (float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (GeometryShape*) meshDynamic : (Terrain*) terr : (Environment*) env : (Ocean*) ocean : (Particles*) particles
{
    //buttterfly
    self.bflyEffect.constantColor = daytimeColor;
    for (int i = 0; i < bflyCount; i++)
    {
        SModelRepresentation *c = &bflyCollection[i];
        
        [self UpdateBfly: c : dt :  terr:  env];
        
        if(c->visible)
        {
            c->displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, c->position);
            c->displaceMat = GLKMatrix4RotateY(c->displaceMat,c->movementAngle);
        }
    }
    [self UpdateBflyEtalon: dt];
    
    //dolphin
    self.dolphinEffect.constantColor = daytimeColor;

    [self UpdateDolphin: &dolphin : dt : terr : ocean];

    if(dolphin.visible)
    {
        dolphin.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, dolphin.position);
        dolphin.displaceMat = GLKMatrix4RotateY(dolphin.displaceMat, dolphin.movementAngle);
        dolphin.displaceMat = GLKMatrix4RotateX(dolphin.displaceMat, dolphin.orientation.x);
    }
    
    
    //update dynamic mesh
    [self UpdateVertexArray: meshDynamic];
    
    //particles
    //dolphin jump splash 
    float splashUnderSurface = 0.1; //by how much splash should start under water surface level
    if(dolphin.type == DM_JUMP && dolphin.position.y < (ocean.oceanBase.y - splashUnderSurface) && dolphin.orientation.x > 0) //during jump, when landing
    {
        [particles.splashDistantPrt Start: dolphin.position];
    }
}

- (void) Render
{
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    //vertex buffer object is determined by global mesh in upper level class
    //dolphin
    if(dolphin.visible)
    {
        self.dolphinEffect.transform.modelviewMatrix = dolphin.displaceMat;
        [self.dolphinEffect prepareToDraw];
        glDrawElements(GL_TRIANGLES, dolphinMeshParams.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(dolphinMeshParams.firstIndex * sizeof(GLushort)));
    }
}


- (void) RenderDynamic
{
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    //vertex buffer object is determined by global mesh in upper level class
    //butterfly
    for (int i = 0; i < bflyCount; i++)
    {
        if(bflyCollection[i].visible)
        {
            self.bflyEffect.texture2d0.name = bflyTexID[i % 3];
            self.bflyEffect.transform.modelviewMatrix = bflyCollection[i].displaceMat;
            [bflyEffect prepareToDraw];
            glDrawElements(GL_TRIANGLES, bflyMeshParams.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bflyMeshParams.firstIndex * sizeof(GLushort)));
        }
    }
}

- (void) ResourceCleanUp
{
    //butterfly
    self.bflyEffect = nil;
    [bflyModel ResourceCleanUp];
    free(bflyCollection);
    free(bflyTexID);
    
    //dolphin
    self.dolphinEffect = nil;
    [dolphinModel ResourceCleanUp];
}

#pragma mark - Dolphin

//reset dolphins
- (void)  ResetDolphin: (SModelRepresentation*) c : (Terrain*) terr
{
    dolphinInitialY = -dolphinModel.AABBmax.y; // from what height all raises start (should apper under sand)
    
    [self InitNewDolphinMove: c : terr];
}

//start new dolphin move
// Type 0 - sit still do nothing
// Type 1 - slide along water level only fin and back visible
// Type 2 - jump out of water and in water, like arch
- (void) InitNewDolphinMove: (SModelRepresentation*) object  : (Terrain*) terr
{
    float maxMoveTime = 0;
    float movementSpeed = 0;
    float distanceFromCenter = SHIP_DIST - 20.0;
    
    //determine type of move
    object->type = [CommonHelpers RandomInRange: 0 : NUM_DOLPHIN_MOVE_TYPES];
    //object->type=DM_JUMP;
    switch (object->type) {
        //do nothing
        case DM_NONE:
            maxMoveTime = 1; //random long intervals when no dolphin appears
            movementSpeed = 0.0;
            object->visible = NO;
        break;
        //fin slide
        case DM_FIN_SLIDE:
            maxMoveTime = 9;
            movementSpeed = 7.0;
            object->visible = YES;
        break;
        //jump
        case DM_JUMP:
            maxMoveTime = 2;
            movementSpeed = 2.0;
            object->visible = YES;
        break;
    }
    //remember that doing nothing is also type of move
    object->moveTime = maxMoveTime;
    object->timeInMove = 0;
    
    if(object->type != DM_NONE)
    {
        //position randomly
        SCircle dolphinCircle = terr.islandCircle;
        dolphinCircle.radius = distanceFromCenter; //how far from land center
        //put randomly around island
        float randomAngle = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 100];
        object->position = [CommonHelpers PointOnCircle: dolphinCircle : randomAngle];
        object->position.y = dolphinInitialY;
        object->orientation.x = 0.0; //tilt of head us used when jumping
        
        //set movement direction
        int randomDirection = [CommonHelpers RandomInRange: 0 : 1]; //clockwise or anticlocwise swim
        object->movementAngle = -randomAngle + (randomDirection * M_PI); //floats perpedicular to island in left or right directions
        object->movementVector = GLKVector3Make(0.0, 0.0, movementSpeed); ///movement speed
        [CommonHelpers RotateY: &object->movementVector : object->movementAngle];
    }
}

//update individual dolphin movement
- (void) UpdateDolphin: (SModelRepresentation*) object : (float) dt : (Terrain*) terr : (Ocean*) ocean
{
    //these parameters should be updates here because these are for each individual case when more than one dolphin is present
    float raiseHeight = 0; //maximum raise/jump height relative to y=0 (baseHeight will be added later after sin is caculated)
    float headTilt = 0; //half tilt of head in radians when jumping out or falling back
    if(object->type == DM_FIN_SLIDE) //fin slide
    {
        float slidHeightUnderWaterSurface = -dolphinModel.AABBmax.y * 0.60; //part of body below water surface
        raiseHeight = ocean.waterBaseHeight - dolphinInitialY + slidHeightUnderWaterSurface;
        headTilt = 0.2;
    }else
    if(object->type == DM_JUMP) //jump
    {
        float jumpHeightOverWaterSurface = 3.0;
        raiseHeight = ocean.waterBaseHeight - dolphinInitialY + jumpHeightOverWaterSurface;
        headTilt = 0.6;
    }
    
    //types of action
    if(object->type != DM_NONE) //fin slide/jump
    {
        //movement happens in sin arch.
        //Movement speed (horizontal) tells how fast and far, during arch, dolphin wil get.
        //Movement time tells how quick the full arch will be traveled
        //Raise height tells how high will the arch be
        
        //to get arch we need sin argument interval from 0 - PI
        float angleForSin = [CommonHelpers ValueInNewRange: 0 : object->moveTime : 0 : M_PI : object->timeInMove];
        object->position.y = dolphinInitialY + sinf(angleForSin) * raiseHeight;
        //tilt of head
        object->orientation.x = [CommonHelpers ValueInNewRange: 0 : object->moveTime : -headTilt : headTilt : object->timeInMove];
    }

    object->timeInMove += dt;
    //move forward
    object->position = GLKVector3Add(object->position, GLKVector3MultiplyScalar(object->movementVector, dt));
    
    //time for new move when "nothing" state expired
    if(object->timeInMove > object->moveTime)
    {
        [self InitNewDolphinMove: object : terr];
    }
    
    //#DECIDE - if we hide dolphins when raft starts. If hide, add raft parmeter to function and put visible = false here on raft.floating param
}

#pragma mark - Butterfly

//butterfly etalon. Since there is only one butterfly that is draw in different places,
// all wings will flap simoultaniously
// this functions update etalon, not butterflies themselves
//etalon
- (void)  UpdateBflyEtalon: (float) dt
{
    float flapAmplitude = 1.2; //wing flapping aplitude
    float flapSpeed = 40.0;
    bflyEtalonWingsTime += flapSpeed * dt;
    bflyEtalonWingsAngle = sinf(bflyEtalonWingsTime) * flapAmplitude;
    
    //nil swing value
    //must be from no 0 to 2 * PI
    if(bflyEtalonWingsTime >= PI_BY_2)
    {
        bflyEtalonWingsTime = bflyEtalonWingsTime - PI_BY_2;
    }
}

//reset butterfly to initial position
//individual instances
- (void)  ResetBfly: (SModelRepresentation*) c : (int) i : (Terrain*) terr
{
    float initialHeight = 3.0; //initial height IMPORTANT: must be between upper and lower bounds in UpdateBfly function
    c->visible = true; //during night when ground is hit hide butterflies
    c->position = [CommonHelpers RandomInCircle: terr.inlandCircle.center : terr.inlandCircle.radius : initialHeight];
    
    [self InitNewBflyMove: c : terr];
}

//start new butterfly move
- (void) InitNewBflyMove: (SModelRepresentation*) object  : (Terrain*) terr
{
    float upperMoveTime = 2;
    //movement speed
    float movementSpeed = 3.0;
    //height change speed
    float heightSpeedLimit = 1.5; //negative and positive limit of speed for height change
    float heightSpeed = [CommonHelpers RandomInRange: -heightSpeedLimit : heightSpeedLimit];;   //ascending and descending speed of bfly
    
    object->movementAngle = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 100];
    object->moveTime = [CommonHelpers RandomInRange: 1 :upperMoveTime];
    object->timeInMove = 0;
    //set movement direction
    object->movementVector = GLKVector3Make(0.0, heightSpeed, movementSpeed); ///movement speed
    [CommonHelpers RotateY: &object->movementVector : object->movementAngle];
}


//update individual vutterfly movement
- (void) UpdateBfly: (SModelRepresentation*) object : (float) dt : (Terrain*) terr : (Environment*) env
{
    //NOTE: these values are absolute, not above terrain, but above 0.0
    float upperBorder = 5.0; //maximal height for butterfly to fly
    //float lowerBorder = 2.0; //minimal height for butterfly to fly
    float terrainHeightUnderBfly = [terr GetHeightByPoint: &object->position];
    //during night butterflies don't fly, so when time is night and butterfly hits ground, hide it and show only when sunrise
    float bedTime = 18 * 60;
    float wakeupTime = 6 * 60;
    
    if(object->visible) //important to not move whn invisible, so butterfly starts in the morning from same position
    {
        object->timeInMove += dt;
        //move forward
        object->position = GLKVector3Add(object->position, GLKVector3MultiplyScalar(object->movementVector, dt));
    }
    
    //out of borders - trace back and set new move
    if(object->position.y > upperBorder || object->position.y < terrainHeightUnderBfly ||
       ![CommonHelpers PointInCircle: terr.inlandCircle.center : terr.inlandCircle.radius : object->position])
    {
        //special case, when during night, hide the butterfly when it taps ground
        if((env.time > bedTime || env.time < wakeupTime) && object->position.y < terrainHeightUnderBfly)
        {
            object->visible = NO;
            //after this init new move that will be used once butterfly turn visible
        }
        
        object->position = GLKVector3Subtract(object->position, GLKVector3MultiplyScalar(object->movementVector, dt));
        [self InitNewBflyMove: object : terr];
    }
    
    //time for new move
    if(object->timeInMove > object->moveTime)
    {
        [self InitNewBflyMove: object : terr];
    }
    
    //wake up in morning from invisible state
    if(!object->visible && (env.time < bedTime && env.time > wakeupTime) )
    {
        object->visible = YES;
    }
}



@end
