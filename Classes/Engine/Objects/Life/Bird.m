//
//  Bird.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 28/09/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// NOTE: bird is attached to egg and nest, currently works only with bird count = 1
// STATUS - OK

#import "Bird.h"

@implementation Bird
@synthesize count, collection, model, effect, bufferAttribs;


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
- (void) ResetData: (Egg*) egg
{
    for (int i = 0; i < count; i++)
    {
        //put in first leave
        collection[i].position = egg.collection[i].position;
        collection[i].orientation.y = egg.collection[i].orientation.y;
        collection[i].orientation.x = 0.0;//basic tilt
        collection[i].visible = true;
        collection[i].boundToGround = 0.0; //axtra space to ground for dropping function
        [model  AssignBounds: &collection[i] : 0.0];
        
        //movement of bird
        [self ResetMovement: &collection[i]];
        //wing animation
        [self SetUpAnimation: &collection[i]];
    }
}

- (void) InitGeometry
{
    //NOTE: should not be geater than egg count
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.5;
    /*
     NOTE: when writing textures in obj file delete extra usemtl _none_bird_wing materials in two places right below usemtl _none
     */
    //float scale = 1.5;
    model = [[ModelLoader alloc] initWithFileScalePatchType: @"bird.obj" : scale : GROUP_BY_OBJECT];
    
    bufferAttribs.vertexCount = model.mesh.vertexCount;
    bufferAttribs.indexCount = model.mesh.indexCount;
    
    //texture array
    //NOTE: textures are not uniue in this array but respective to each object
    texIDs = malloc(model.objectCount * sizeof(GLuint));
    
    //parameters
    flightHeight = 20.0;
    flightRadius = 100.0;
    wingFlapSpeed = 0.0; //changed during movement
}

- (void) SetupRendering
{
    //load textures
    //NOTE: textures are not uniue in this array but respective to each object
    //OPTI: wing texture could be 64x32
    for (int i = 0; i < model.objectCount; i++)
    {
        texIDs[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.matToTex objectAtIndex: i]: YES]; //bird body - 64x64, wing - 64x64, head - 64x64
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

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (Character*) character
{
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            [self ScanForStartMovement: &collection[i] : character]; //start condition inside
            [self UpdateMovement: dt : &collection[i] : terr];
            
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
            collection[i].displaceMat = GLKMatrix4RotateX(collection[i].displaceMat, collection[i].orientation.x);
            
            //below because displace mat  used
            [self UpdateAnimation: &collection[i] : dt]; //wing flapping
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
            [[SingleGraph sharedSingleGraph] SetCullFace: NO];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
           /*
            for (int m = 0; m < model.materialCount; m++)
            {
                self.effect.texture2d0.name = texIDs[m];
                
                if(m == 0) //wings (2 wings one material)
                {
                    for (int j = 0; j < collection[i].legCount; j++)
                    {
                        self.effect.transform.modelviewMatrix = collection[i].legs[j].rotMat;
                        [self.effect prepareToDraw];
                        glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));

                    }
                }else //body
                {
                    self.effect.transform.modelviewMatrix = collection[i].displaceMat;
                    [self.effect prepareToDraw];
                    glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));
                }
            }
          */
            
            for (int m = 0; m < model.objectCount; m++)
            {
                if(m == 0 || m == 1) //wings
                {
                    if(!collection[i].enabled) //show only wings when started flying
                    {
                        continue;
                    }
                    
                    //NOTE: works only when indexes are 0 or 1
                    self.effect.transform.modelviewMatrix = collection[i].legs[m].rotMat;
                }else //body
                {
                    self.effect.transform.modelviewMatrix = collection[i].displaceMat;
                }
                self.effect.texture2d0.name = texIDs[m];
                [self.effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));

            }
        }
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
    free(texIDs);
}


#pragma mark - Flight movement

//reset movement parameters
- (void) ResetMovement: (SModelRepresentation*) c
{
    c->enabled = false; //not started flying
}

//check weather it is time to start movement
- (void) ScanForStartMovement: (SModelRepresentation*) c : (Character*) character
{
    if(!c->enabled)
    {
        float maxApproachDist = 10.0; //closest distance before bird flies away
        //float maxApproachDist = 0.0;
        float distFromCharToBird = GLKVector3Distance(c->position, character.camera.position);
        
        if(distFromCharToBird < maxApproachDist)
        {
            [self StartMovement: c : character];
        }
    }
}

//start flying
- (void) StartMovement: (SModelRepresentation*) c : (Character*) character
{
    c->enabled = true; //fly away
    
    //calculat escape point of burd
    float escapeDist = 25.0;
    GLKVector3 escapePoint = [CommonHelpers PointOnLine: character.camera.position : c->position : escapeDist];
    escapePoint.y = flightHeight;
    [self InitiateMove: c : escapePoint];
    
    //start falpping wings
    [self StartAnimation: c];
}



/*
 NOTE :Point to point based movement is used
 In object actions movement vector is used to deterine movement,
 here destination point is set and position is lerped accordingly
 */

- (void) UpdateMovement: (float) dt : (SModelRepresentation*) c : (Terrain*) terr
{
    if(c->enabled)
    {
        //c->position = GLKVector3Add(c->position, GLKVector3MultiplyScalar(c->movementVector, dt));
        c->timeInMove += dt;
        float lerpVal = c->timeInMove / c->moveTime;
        c->position = GLKVector3Lerp(c->moveStartPoint, c->moveEndPoint, lerpVal);
        
        if(lerpVal >= 1.0) //move ended
        {
            //c->enabled = false;
            GLKVector3 movePoint = [CommonHelpers RandomInCircle: terr.islandCircle.center : flightRadius : flightHeight];
            [self InitiateMove: c : movePoint];
        }
    }
}

//start to new move (from current point to destination point)
- (void) InitiateMove: (SModelRepresentation*) c : (GLKVector3) destPoint
{
    c->timeInMove = 0;
    c->moveStartPoint = c->position;
    c->moveEndPoint = destPoint;
    float moveDist = GLKVector3Distance(c->moveStartPoint, c->moveEndPoint);
    float movementSpeed = 12.0; //m/s
    c->moveTime = moveDist / movementSpeed; //t = s / v
    if(c->moveTime == 0.0) c->moveTime = 0.1; //just in case
    //movementVector is ised to calculate model rotation angles
    c->movementVector = [CommonHelpers GetVectorFrom2Points: c->moveStartPoint : c->moveEndPoint : NO];
    c->orientation.x = [CommonHelpers AngleBetweenVectorAndHorizontalPlane: c->movementVector];
    c->orientation.y = [CommonHelpers AngleBetweenVectorAndZ: c->movementVector] + M_PI;
    
    //caculate wing flap speed depending on flight distance
    float maxWingFlap = 7.0;
    float moveDistPercent = moveDist / (2*flightRadius); //1.0 - all the way across(flap fast), close to 0 - small distance, no flapping
    wingFlapSpeed = moveDistPercent * maxWingFlap;
    //extra conditions:
    if(moveDist < 50.0) //if distance is small, simply glide
    {
        wingFlapSpeed = 0.0;
    }
    if(c->moveStartPoint.y < (flightHeight - 0.1)) //if bird is rising, make it flap fast
    {
        wingFlapSpeed = maxWingFlap;
    }
    c->legAnimation.timeInAction = 0; //reset animation time
}

#pragma mark - Wing animation


//set up wing animation
//leg = wing in this case
- (void) SetUpAnimation: (SModelRepresentation*) c
{
    c->legCount = 2; //number of wings
    
    c->legAnimation.enabled = NO; //wing are not flapping by deault
    
    //leg positions relative to local space
    float wingHeight = model.AABBmax.y / 2.0;
    c->legs[0].position = GLKVector3Make(0.0, wingHeight, 0.0);
    c->legs[1].position = GLKVector3Make(0.0, wingHeight, 0.0);
    
    //ininitial rotation flap angle angle
    c->legs[0].angle.z = 0.0;
    c->legs[1].angle.z = 0.0;
    
    c->legAnimation.timeInAction = 0.0; //used as sin argument
}


- (void) StartAnimation: (SModelRepresentation*) c
{
    c->legAnimation.enabled = YES;
}


- (void) UpdateAnimation: (SModelRepresentation*) c : (float) dt
{
    if(c->legAnimation.enabled)
    {
        //for all wings
        for (int w = 0; w < c->legCount; w++)
        {
            //move to bird position
            c->legAnimation.timeInAction += wingFlapSpeed * dt;
            if(c->legAnimation.timeInAction >= PI_BY_2)
            {
                c->legAnimation.timeInAction = c->legAnimation.timeInAction - PI_BY_2;
            }
            
            //each fling flaps on their own direction
            int multiplier = 1;
            if(w == 1)
            {
                multiplier = -1;
            }
            c->legs[w].angle.z = sinf(multiplier * c->legAnimation.timeInAction); //flap winghs
            c->legs[w].rotMat =  GLKMatrix4TranslateWithVector3(c->displaceMat, c->legs[w].position);
            c->legs[w].rotMat =  GLKMatrix4RotateZ(c->legs[w].rotMat, c->legs[w].angle.z);
        }
    }
}

@end
