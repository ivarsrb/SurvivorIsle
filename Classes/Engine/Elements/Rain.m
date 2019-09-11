//
//  Rain.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "Rain.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation Rain
@synthesize enabled, mesh, effect;

- (id) initWithParams: (Character*) character
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry: character];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    enabled = NO;
}

- (void) InitGeometry: (Character*) character
{
    //parameters
    enabled = NO;
    position = GLKVector3Make(0, 1, 0); //y - above head
    lowerBound = -character.height;  //when to hide patch
    
    numberOfPatches = 9;//8;
    dropsPerSide = 12;//10; //rain area number of drops per side, #ENHANCE if enough resources add this number
    rainDropSize = 0.10;
    leftPosition = 0.8;//1.0; //rain area sides width
    rainPatches = malloc(sizeof(SObjectPatch) * numberOfPatches);
    //geometry
    mesh = [[GeometryShape alloc] init];
    mesh.vertStructType = VERTEX_TEX_STR;
    mesh.dataSetType = VERTEX_SET;
    mesh.vertexCount = numberOfPatches * dropsPerSide * dropsPerSide * 3;
    [mesh CreateVertexIndexArrays];

    float spaceDrops = (2 * leftPosition) / dropsPerSide; //spacing between drops

    int n = 0;
    for (int p = 0; p < numberOfPatches; p++) 
    {
        //init rain patches
        rainPatches[p].startIndex = n;
        rainPatches[p].indexCount = dropsPerSide * dropsPerSide * 3;
        rainPatches[p].position = position;
        [self SetVelocity: &rainPatches[p]];
        //rainPatches[p].velocity = GLKVector3Make(0, -1 * ([CommonHelpers RandomFloat]*3+1), 0); //dset inital rain to be more diverse
        
        //rain drop triangle
        float dropHalfSize = rainDropSize / 45; //width of drop
        float awayFromEyes = 0.22; //how far away from eyes closes drop will be
        for(int i = 0; i < dropsPerSide; i++) //rows
        {
            for(int j = 0; j < dropsPerSide; j++) //columns
            {
                //random displacement
                float yd = [CommonHelpers RandomFloat] * 2;
                float xd = [CommonHelpers RandomFloat] / 2 - 0.25;
                float zd = [CommonHelpers RandomFloat] / 3;
                
                mesh.verticesT[n].vertex = GLKVector3Make((leftPosition - i * spaceDrops) + xd,
                                                          -rainDropSize + yd,
                                                          j * spaceDrops + zd + awayFromEyes);
                mesh.verticesT[n].tex = GLKVector2Make(0.0,0.0);
                n++;
                mesh.verticesT[n].vertex = GLKVector3Make((leftPosition - i * spaceDrops) - dropHalfSize + xd,
                                                          yd,
                                                          j * spaceDrops + zd + awayFromEyes);
                mesh.verticesT[n].tex = GLKVector2Make(0.0,1.0);
               
                n++;
                mesh.verticesT[n].vertex = GLKVector3Make((leftPosition - i * spaceDrops) + dropHalfSize + xd,
                                                          yd,
                                                          j * spaceDrops + zd + awayFromEyes);
                mesh.verticesT[n].tex = GLKVector2Make(1.0,0.0);
                
                n++;
            }
        }
    }
    
    //daytime coloring
    /*
    middayColor = GLKVector4Make(252/255.,255/255.,255/255.,1);
    eveningColor = GLKVector4Make(240/255.,255/255.,239/255.,1);
    nightColor = GLKVector4Make(193/255.,218/255.,218/255.,1);
	morningColor =  GLKVector4Make(255/255.,247/255.,241/255.,1);
    */
    
    coloring.midday = GLKVector4Make(252/255.,255/255.,255/255.,1);
   // coloring.midday = GLKVector4Make(210/255.,210/255.,210/255.,1);
    coloring.evening = GLKVector4Make(240/255.,255/255.,239/255.,1);
    coloring.night = GLKVector4Make(193/255.,218/255.,218/255.,1);
    coloring.morning = GLKVector4Make(255/255.,247/255.,241/255.,1);
}

- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    [mesh InitGeometryBeffers];
    
    GLuint texID  = [[SingleGraph sharedSingleGraph] AddTexture:@"particle_rain.png"  : YES]; //8x8
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update: (float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (Character*) character: (Environment*) env : (Shelter*) shelter
{
    //switch rain on/off
    if(env.raining && !enabled)
    {
        enabled = YES;
    }else
    if(!env.raining && enabled)
    {
        enabled = NO;
    }
    
    //-------
    //enabled = YES;
    //-------
    
    if(enabled)
    {
        //get cloud color
        [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : coloring.midday : coloring.evening : coloring.night : coloring.morning : curTime];

        //globalTransMat = *modelviewMat;
        globalTransMat = GLKMatrix4TranslateWithVector3(*modelviewMat, character.camera.position);
        //rotate it always facing the camera
        globalTransMat = GLKMatrix4RotateY(globalTransMat, character.camera.yAngle);
        
        
        //update patches
        for(int p = 0; p < numberOfPatches; p++) 
        {
            if(rainPatches[p].position.y > lowerBound)
            {
                //move patch
                rainPatches[p].position = GLKVector3Add(rainPatches[p].position, GLKVector3MultiplyScalar(rainPatches[p].velocity,dt));
            }
            else
            {
                //start patch from begining
                rainPatches[p].position = position;
                
                [self SetVelocity: &rainPatches[p]];
            }
            
            //special case - when in shelter move further away from view
            if(character.state == CS_SHELTER_RESTING || (character.state == CS_DEAD && character.prevStateInformative == CS_SHELTER_RESTING)) //also when died while sitting in shelter
            {
                rainPatches[p].position.z = position.z + shelter.shelter.crRadius / 2.0;
            }
            
            rainPatches[p].translationMat = GLKMatrix4TranslateWithVector3(globalTransMat, rainPatches[p].position);
        }
        self.effect.constantColor = coloring.dayTime;
        //self.effect.constantColor = GLKVector4Make(0.8, 0.8, 1, 1);
    }
}

- (void) Render
{
    if(enabled)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace:YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
        [[SingleGraph sharedSingleGraph] SetBlend:YES];
        [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
        
        glBindVertexArrayOES(mesh.vertexArray);
        //render patches
        for (int p = 0; p < numberOfPatches; p++) 
        {
            self.effect.transform.modelviewMatrix = rainPatches[p].translationMat;
            [self.effect prepareToDraw];
            glDrawArrays(GL_TRIANGLES, rainPatches[p].startIndex, rainPatches[p].indexCount);
        }
    }
}

- (void) ResourceCleanUp
{
    [mesh ResourceCleanUp];
    self.effect = nil;
    free(rainPatches);
}

//set rain blank velocity
- (void) SetVelocity: (SObjectPatch*) p
{
    //rain drop speed
    float dropSpeedLow = 3.0; //2.0;
    float dropSpeedHIgh = 5.0; //4.0;
    p->velocity = GLKVector3Make(0, - [CommonHelpers RandomInRange:dropSpeedLow :dropSpeedHIgh: 100], 0);
}

- (void) Start
{
    enabled = YES;
}


- (void) Stop
{
    enabled = NO;
}

@end
