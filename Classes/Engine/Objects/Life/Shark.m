//
//  Shark.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/10/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// ----------------------------
// Shark functioning:
// - Float around island in circle in one direction
// - Shark attack stages
//    a) attack begins when character is in water in relativly close area of shark
//    b) initially aproach at increased speed
//    c) when shark is close slow down to not run into character (collision detection problem)
//    d) when character moves while being attacked, move shark in the same speed as character moves so shark follows smoothly
// - Shark attack is canceled if character either steps on soil or is scared away with spear strike
// ----------------------------
//
// Status - 

#import "Shark.h"


@implementation Shark
@synthesize count, collection, model, effect, bufferAttribs;

- (id) initWithParams: (Terrain*) terr : (Ocean*) ocean
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry: terr : ocean];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    for (int i = 0; i < count; i++)
    {
        [self ResetShark: &collection[i] : i];
        
        [model AssignBounds: &collection[i] : 0];
    }
}

- (void) InitGeometry: (Terrain*) terr : (Ocean*) ocean
{
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    float scale = 2.5;
    model = [[ModelLoader alloc] initWithFileScale: @"dolphin.obj" : scale]; //Z-Based model, head to positive
    
    bufferAttribs.vertexCount = model.mesh.vertexCount * count;
    bufferAttribs.indexCount = model.mesh.indexCount * count;
    
    //parameters
    //shark constant swiming circle
    sharkCr = terr.majorCircle;
    //float height of shark
    floatHeight = ocean.waterBaseHeight;
    
    //determine rotation factors for model vertices depending on disatnce from front
    rotationFactor = malloc(model.mesh.vertexCount * sizeof(float));
    for (int n = 0; n < model.mesh.vertexCount; n++)
    {
        //determine factor of vertex farness from center
        rotationFactor[n] = fabs(model.mesh.verticesT[n].vertex.z) / model.bsRadius;
    }
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    bufferAttribs.firstVertex = *vCnt;
    bufferAttribs.firstIndex = *iCnt;
    
    for (int i = 0; i < count; i++)
    {
        for (int n = 0; n < model.mesh.vertexCount; n++)
        {
            //vertices
            mesh.verticesT[*vCnt].vertex = model.mesh.verticesT[n].vertex;
            mesh.verticesT[*vCnt].tex = model.mesh.verticesT[n].tex;
            *vCnt = *vCnt + 1;
        }
        
        for (int n = 0; n < model.mesh.indexCount; n++)
        {
            //indices
            mesh.indices[*iCnt] = model.mesh.indices[n] + bufferAttribs.firstVertex + (i * model.mesh.vertexCount);
            *iCnt = *iCnt + 1;
        }
    }
}

/*
//fill vertex array with new values
- (void) UpdateVertexArray: (GeometryShape*) mesh
{
    //load model into external geometry mesh
    int vCnt = bufferAttribs.firstVertex;
 
    for (int i = 0; i < count; i++)
    {
        for (int n = 0; n < model.mesh.vertexCount; n++)
        {
            if(collection[i].visible)
            {
                mesh.verticesT[vCnt].vertex = GLKVector3Add(model.mesh.verticesT[n].vertex, collection[i].position);
                //[CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex : collection[i].movementAngle : collection[i].position];
                [CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex : collection[i].smoothTurnAngle.current : collection[i].position];
            }else
            {
                //if fish is not visible, put all vertices in one point
                mesh.verticesT[vCnt].vertex = GLKVector3Make(0, 0, 0);
            }
            vCnt = vCnt + 1;
        }
    }
}
*/

//fill vertex array with new values
- (void) UpdateVertexArray: (GeometryShape*) mesh
{
    //load model into external geometry mesh
    int vCnt = bufferAttribs.firstVertex;
    
    float angle;
    float headAngle;
    
    for (int i = 0; i < count; i++)
    {
        headAngle = /*collection[i].movementAngle*/ collection[i].smoothTurnAngle.current + (collection[i].taleAnimation.angle.y / -6.0); //head moves in oposite to tail
        
        for (int n = 0; n < model.mesh.vertexCount; n++)
        {
            if(collection[i].visible)
            {
                //tail
                if(model.mesh.verticesT[n].vertex.z < 0)
                {
                    //the further away vertex is from center, the more rotated vertex will be
                    angle = /*collection[i].movementAngle*/collection[i].smoothTurnAngle.current + (collection[i].taleAnimation.angle.y * rotationFactor[n]);
                }
                //head
                else
                {
                    angle = headAngle;
                }
               
                //NSLog(@"-------     %f ",rotationFactor[n]);
                mesh.verticesT[vCnt].vertex = GLKVector3Add(model.mesh.verticesT[n].vertex, collection[i].position);
                [CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex: angle: collection[i].position];
                //NSLog(@"=======   %f", mesh.verticesT[vCnt].vertex.x);
            }else
            {
                //if fish is not visible, put all vertices in one point
                mesh.verticesT[vCnt].vertex = GLKVector3Make(0, 0, 0);
            }
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
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0] : YES]; 
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID;
    self.effect.useConstantColor = GL_TRUE;
}


- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (Character*) character : (GeometryShape*) mesh
{
    self.effect.transform.modelviewMatrix = *modelviewMat;
    self.effect.constantColor = daytimeColor;
    
    for (int i = 0; i < count; i++)
    {
        SModelRepresentation *c = &collection[i];
        if(c->visible)
        {
            [self UpdateShark: c : dt : terr : character];
            
            [self CalculateTurnAngle: &collection[i]]; //for smooth turning (smoothTurnAngle.current angle is used outside)
        }
    }
    
    [self UpdateVertexArray: mesh];
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    [self.effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, bufferAttribs.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bufferAttribs.firstIndex * sizeof(GLushort)));

}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
    free(rotationFactor);
}


#pragma mark - Additional function

//spearing check
- (BOOL) StrikeSharkCheck: (GLKVector3) spearPos
{
    bool resultBool = false;
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible && collection[i].enabled && !collection[i].runaway)
        {
            //spear strikes shark
            resultBool = [CommonHelpers PointInSphere: collection[i].position : collection[i].bsRadius : spearPos];
            
            if(resultBool)
            {
                [self ForceRunaway: &collection[i]];
                return resultBool;
            }
        }
    }
    
    return resultBool;
}

//calculate current angle of model roattion for transition to look smooth, current angle is used to rotate model vertices
//LOGIC: angle at this moment is constant movement from angle in previous step to current destination angle
- (void) CalculateTurnAngle: (SModelRepresentation*) c
{
    //1. Assign destination angle we are always thriving for
    c->smoothTurnAngle.destination = c->movementAngle; //transform movement angle to (0 - 2*PI) range in case it goes out of that range
    
    //2. Assign and calculate source and destination angles
    //transform movement angle to (0 - 2*PI) range in case it goes out of that range
    float angleFrom = [CommonHelpers ConvertToNormalRadians: c->smoothTurnAngle.previous];
    float angleTo = [CommonHelpers ConvertToNormalRadians: c->smoothTurnAngle.destination];
    
    //if turn is about to happen through 0 point of angle (like tunring from 1 degree to (2*PI - 1))
    //Normally we would spin through longest path, but we modify angle 2 to make turn the shorter path and go it out of bounds
    if(fabsf(angleFrom - angleTo) > M_PI)
    {
        //in case start angle is in the first quadrant
        if(angleFrom < angleTo)
        {
            angleTo = angleTo - PI_BY_2; //movement will go in negative direction
        }else
        //if start angle is in 4th quadrant
        if(angleFrom > angleTo)
        {
            angleTo = angleTo + PI_BY_2; //movement will go in positive direction above 2PI
        }
    }
    
    //3. Calculate current model turning angle
    c->smoothTurnAngle.current = [CommonHelpers LinearInterpolation: angleFrom : angleTo : 0.0 : 1.0 : 0.3];
    /*
    if(c->smoothTurnAngle.current > PI_BY_2)
    {
        NSLog(@"sssssssssss %f", c->smoothTurnAngle.current);
    }
    */
   // NSLog(@"sssssssssss %f", c->smoothTurnAngle.current);
    //4. Assign previous angle as current for the nex step
    //transform movement angle to (0 - 2*PI) range in case it goes out of that range
    //c->smoothTurnAngle.current = [CommonHelpers ConvertToNormalRadians: c->smoothTurnAngle.current];
    c->smoothTurnAngle.previous = c->smoothTurnAngle.current;
    
    //NSLog(@"!!!!!!!! %f %f ", c->smoothTurnAngle.previous, c->smoothTurnAngle.destination);
}


#pragma mark - Movement helper Functions


//reset shark to new random location on map
- (void)  ResetShark: (SModelRepresentation*) c: (int) i
{
    //set shark at base wiming circle
    c->position = [CommonHelpers RandomOnCircleLine: sharkCr];
    c->position.y = floatHeight;
    c->movementAngle = 0; //[CommonHelpers RandomInRange: 0 : PI_BY_2 : 100];
    c->visible = true;
    //c->moving = false;
    c->enabled = false; //attack
    c->runaway = false; //runs away
   // c->timeInMove = 0;
    c->smoothTurnAngle.previous = 0;
    c->smoothTurnAngle.current = 0;
}

//set shark in runaway mode
- (void) ForceRunaway: (SModelRepresentation*) c
{
    c->enabled = false;
    c->runaway = true;
}

//update shark movement
- (void) UpdateShark: (SModelRepresentation*) c : (float) dt : (Terrain*) terr : (Character*) character
{
    //TODO - what about when in raft
    
    float sharkAttackDist = 30.0;
    //determine wethaer character is in ocean and weather is close enaugh to be attacked by the shark
    if(GLKVector3Distance(c->position, character.camera.position) < sharkAttackDist &&
       [terr IsOcean: character.camera.position] //????? needed if attack distance is short
       )
    {
        c->enabled = true; //attack
    }else
    {
        c->enabled = false; //cancel attack
    }
    
    //------------------------------------------
    
    float speed = 0.0; //shark movement speed
    //normal circle movement
    if(!c->enabled && !c->runaway)
    {
        float offsetTurnAngle;
        float sharkOffsetFromCircle;
        
        //how far shark has gone inside or outside of float circle
        sharkOffsetFromCircle = GLKVector3Distance(sharkCr.center, c->position) - sharkCr.radius;
        float turnAngleLimit = 2.0;
        offsetTurnAngle = [CommonHelpers ValueInNewRangeLimited: -sharkCr.radius : sharkCr.radius : -turnAngleLimit : turnAngleLimit : sharkOffsetFromCircle];
        
        speed = 15.0;
        GLKVector3 pVect = [CommonHelpers GetVectorFrom2Points: terr.islandCircle.center : c->position : true];
        c->movementAngle = [CommonHelpers AngleBetweenVectorAndZ: pVect] + M_PI_2 + offsetTurnAngle; //[CommonHelpers AngleBetweenVectorAndZ: pVect] + offsetTurnAngle;
    }
    
    //attack movement
    if(c->enabled)
    {
        speed = 20.0;
        GLKVector3 attacDirection = [CommonHelpers GetVectorFrom2Points: c->position:  character.camera.position : true];
        c->movementAngle = [CommonHelpers AngleBetweenVectorAndZ: attacDirection];
        
        //shark bites character area
       /*
        if([CommonHelpers PointInCircle: c->position : model.crRadius : character.camera.position])
        {
            speed = -character.movementV.z;   //0.0; //-10.0;//put movement speed here????????
        }
        else
        {
         */
        float approachAreaExtraRadius = 1.0;
            //check for bigger shark radius to slow down, so shark doesnt run through character at high speed
            if([CommonHelpers PointInCircle: c->position : model.crRadius + approachAreaExtraRadius : character.camera.position])
            {
                //speed when character is standing still and shark is approaching in slowed down speed (to not to run into character)
                //speed = 1.0;
                speed = 0.0;
                
                //stop when ran into character
                if([CommonHelpers PointInCircle: c->position : model.crRadius : character.camera.position])
                {
                    speed = 0.0;
                }
                
                //if character moves back/forth adjust shark speed acordingly
                if(fabs(character.movementV.z) > 0.01)
                {
                    //speed = -character.movementV.z;
                    speed = fabs(character.movementV.z);
                }
                
                //NSLog(@"inside");
            }else
            {
               // NSLog(@"out");
            }
       // }
        
        NSLog(@"dist   %f", [CommonHelpers DistanceInHorizPLane:c->position :character.camera.position]);
     
        if(fabs(character.movementV.z) != fabs(speed))
        {
            NSLog(@"speed----------- %f %f", character.movementV.z, speed);
        }
        
      //  NSLog(@"------------------");
    }
    
    //runs away (hit by something)
    if(c->runaway)
    {
        speed = 10.0;
        GLKVector3 runawayDirection = [CommonHelpers GetVectorFrom2Points: character.camera.position:  c->position : true];
        c->movementAngle = [CommonHelpers AngleBetweenVectorAndZ: runawayDirection];
        
        //when stepped back a bit attack again
        float runawayDist = 10.0; //how far runs away from chaacter
        if(GLKVector3Distance(character.camera.position, c->position) > runawayDist ||
           ![terr IsOcean: c->position]) //also make sure hark is not forced on island
        {
            c->runaway = false;
        }
    }
    
    //transform movement angle to (0 - 2*PI) range in case it goes out of that range (needed for model smooth rotation)
//    c->movementAngle = [CommonHelpers ConvertToNormalRadians: c->movementAngle];
    
    //calculate movement
    //NSLog(@"speeds  %f %f", character.movementV.z, speed);

    
    c->movementVector = GLKVector3Make(0.0, 0.0, speed);
    [CommonHelpers RotateY: &c->movementVector : c->movementAngle];
    c->position = GLKVector3Add(c->position, GLKVector3MultiplyScalar(c->movementVector, dt));
    
    
    //---- TEST
    static float taleAngle = 0;
    taleAngle += 5 * dt;
    c->taleAnimation.angle.y = sinf(taleAngle);
}



@end
