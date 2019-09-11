//
//  HandSpear.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "HandSpear.h"
#import "Fish.h"
#import "Shark.h"

@implementation HandSpear
@synthesize model,effect,vertexCount,indexCount,spearTip,striking,strikeDown,fishStruck;


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
- (void) ResetData
{
    striking = NO;
    fishStruck = NO;
}

- (void) InitGeometry
{
    float scale = 0.14;
    model = [[ModelLoader alloc] initWithFileScale: @"spear.obj" : scale];
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
    //configure spear parameters
    spearTip = GLKVector3Make(0.0, 0.0, 0.0);
    distanceFromChar = 0.5; 
    downFromEyes = 0.3; 
    sideAngle = -0.2; //spear is shifted to side -0.2
    tiltAngleBase = tiltAngle = GLKMathDegreesToRadians(-55); //spear is initially tilted about x Axis   -50
    strikeTime = 0.25;
    strikeDistance = 2.25; //2.2; //strike distance from spear initial tip to strike point
    //strike
    striking = NO;
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
    
    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0]: YES]; //128x64

    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (GLKMatrix4*) modelviewMat : (Character*) character : (Fish*) fishes : (GLKVector4) daytimeColor : (Particles*) particles : (Ocean*) ocean : (Shark*) shark
{
    if(character.handItem.ID == ITEM_SPEAR)
    {
        //adjust spear tip position, by translating and rotating
        GLKVector3 viewPoint = [character.camera GetLookAtPoint]; //GLKVector3Add(character.camera.position, character.camera.viewVector);
        GLKVector3  posViewDelta = GLKVector3Subtract(character.camera.position, GLKVector3Make(viewPoint.x, character.camera.position.y-downFromEyes, viewPoint.z));
        spearTip = GLKVector3Subtract(character.camera.position, GLKVector3MultiplyScalar(posViewDelta, distanceFromChar));
        
        //turn spear to side
        [CommonHelpers RotateY: &spearTip :sideAngle :character.camera.position];
        
        //move spear tip
        mdvMatrix = *modelviewMat;
        mdvMatrix = GLKMatrix4TranslateWithVector3(mdvMatrix, spearTip);
        
        //strike action
        if(striking)
        {
            //move strike point together with character while moving
            strikePoint = GLKVector3Add(character.camera.position,distFromCharToStrike);
            [CommonHelpers RotateY: &strikePoint: character.camera.yAngle - angleYAtStrike: character.camera.position];

            //strike DOWN
            if(strikeDown)
            {
                if(![self TranslateBetweenPoints:spearTip :strikePoint :strikeTime :&timeStruck :dt: false: &strikeMovement])
                {
                    strikeDown = NO;
                    timeStruck = 0;
                }
            }else //UP
            {
                float strikeUpTime = strikeTime;
                //if fish is struck, make spear upstriking longer
                if(fishStruck)
                {
                    strikeUpTime = strikeTime * 4;
                }
                
                if(![self TranslateBetweenPoints:spearTip: strikePoint :strikeUpTime :&timeStruck :dt: true :&strikeMovement])
                {
                    [self Stop];
                    tiltAngle = tiltAngleBase;
                    fishStruck = NO;
                }
            }
            
            spearTip = GLKVector3Add(spearTip, strikeMovement);
            mdvMatrix = GLKMatrix4TranslateWithVector3(mdvMatrix, strikeMovement);
        }
        
        //check for fish strike, when spearing
        if(strikeDown && !fishStruck)
        {
            fishStruck = [fishes StrikeFishCheck: spearTip];
        }
        
        //check shark strike
        if(strikeDown)
        {
            [shark StrikeSharkCheck: spearTip];
        }
        
        
        mdvMatrix = GLKMatrix4RotateY(mdvMatrix, character.camera.yAngle);//rotate model, so it faces character all the time
        mdvMatrix = GLKMatrix4RotateX(mdvMatrix, tiltAngle); //tilt space
        
        self.effect.transform.modelviewMatrix = mdvMatrix;
        self.effect.constantColor = daytimeColor;
        
        //particles
        if(strikeDown)
        {
            //if spear is under water
            if([ocean GetHeightByPoint: spearTip] >= spearTip.y)
            {
                [particles.splashPrt Start: spearTip]; //self ending, does not rquire ending
            }
        }else
        {
            if(fishStruck && /*[ocean GetHeightByPoint: spearTip]*/ ocean.oceanBase.y < spearTip.y)
            {
                [particles.splashPrt End];
                [particles.splashBigPrt Start: spearTip]; //self ending, does not rquire ending
            }
        }
    }
}

- (void) Render: (Character*) character
{
    if(character.handItem.ID == ITEM_SPEAR)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace:YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
        [[SingleGraph sharedSingleGraph] SetBlend:NO];
        
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
}


//strike a spear
- (void) Strike:(Character*) character: (GLKVector3) strikePos
{
    if(!striking)
    {    
        //init strike
        striking = YES;
        strikeDown = YES;
        timeStruck = 0;
        strikeMovement = GLKVector3Make(0, 0, 0);
        
        strikePoint = [CommonHelpers PointOnLine: character.camera.position : strikePos : strikeDistance];
        float strikeUpperLimit = 0.2;
        if(strikePoint.y > character.camera.position.y - strikeUpperLimit) strikePoint.y = character.camera.position.y - strikeUpperLimit; //dont allow to strike overhead
        distFromCharToStrike = GLKVector3Subtract(strikePoint,character.camera.position);//used only to help move speartip together with char movement while striking
        angleYAtStrike = character.camera.yAngle; //[CommonHelpers AngleBetweenVectorAndZ: [character.camera GetViewVector]];//used only to change striking point when rotating view about y axis
        //determine tilt angle while spearing
        GLKVector3 p3 = GLKVector3Normalize(GLKVector3Subtract(strikePoint,spearTip));
        tiltAngleDest = -acosf(GLKVector3DotProduct(p3, GLKVector3Make(0, -1, 0)));
    }
}

//stop strike
- (void) Stop
{
    striking = NO;
}

//return delta from startPoint (can be used in stranslation)
//return true while action is in process, false if ends
- (BOOL) TranslateBetweenPoints:(GLKVector3) stPoint:(GLKVector3) endPoint: (float) actionTime: (float*) timeInAction: (float) dt: (bool) backWard :(GLKVector3*) result
{
    float rate = 1.0 / actionTime; //movement rate
   
    if(*timeInAction <= 1.0) 
    {
        float interpValue = fabs(((int)backWard) - *timeInAction);
        GLKVector3 lerpedV = GLKVector3Lerp(stPoint, endPoint, interpValue);
        *result = GLKVector3Subtract(lerpedV, stPoint);
        
        //interpolate base angle to destination tilt angle of spear while striking
        //0 - 0.3 means that we reach destination angle already on the needle of the strike move
        tiltAngle = [CommonHelpers LinearInterpolation:tiltAngleBase :tiltAngleDest :0 :0.3 :interpValue];
        if(tiltAngleDest < tiltAngleBase) //striking further tha spear tip (normally)
        {
            //let it interpolate only to destination
            if(fabs(tiltAngle) > fabs(tiltAngleDest)) 
            {
                tiltAngle = tiltAngleDest;
            }
        }else  //striking below spear tips, striking near the foot
        {
            if(fabs(tiltAngle) < fabs(tiltAngleDest)) 
            {
                tiltAngle = tiltAngleDest;
            }
        }

        *timeInAction += dt * rate;
        return YES;
    }else
        return  NO;
}


#pragma mark - Touch functions

- (BOOL) TouchBegin:(UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (GLKMatrix4*) modvMat : (int*) viewpParams
{
    BOOL retVal = NO;
    
    if([intr IsStrikeButtTouched:tpos] && !striking)
    {
        //in this case action button is for spear strike
        Button *actionButt = [intr.overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
        [actionButt PressBegin: touch];
        
        //middle of screen
        GLKVector3 windowStrikePoint = GLKVector3Make([[SingleGraph sharedSingleGraph] screen].points.size.width / 2.0,
                                                      [[SingleGraph sharedSingleGraph] screen].points.size.height / 2.0, 0);
        //point that is touched on Znear plane
        bool error;
        GLKVector3 spacePoint = GLKMathUnproject(windowStrikePoint, *modvMat,[[SingleGraph sharedSingleGraph] projMatrix], viewpParams, &error);
        [self Strike: character: spacePoint];
        
        retVal = YES;
    }
    
    return retVal;
}


@end
