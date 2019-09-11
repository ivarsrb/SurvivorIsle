//
//  ParticleEffect.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "ParticleEffect.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation ParticleEffect
@synthesize particleMesh, effectParticle, attributes, started, particles;

//--------------------------
// Previous error
// When structure was passed by value 'count' got random big number in it, passing by pointer fixed it
//
//--------------------------

- (id) initWithAttributes: (SParticleEffect*) attr
{
    self = [super init];
    if (self != nil) 
	{
        attributes = *attr;
        
        //automatically set some adjustable variables
        attributes.prtclSpeedInitial = attributes.prtclSpeedMax;
        attributes.currentCount = attributes.maxCount; //current count is particle count currently in use, max is maximal possible for this effect
        
        [self InitGeometry];
	}
    return self;
}
/*
- (void) TestFunc: (SParticleEffect*) attrPointer: (SParticleEffect) attr
{
    NSLog(@"1: %d", attrPointer->count);
    NSLog(@"2: %d", attr.count);
}
*/

- (void) InitGeometry
{
    //config default variables
    started = false;
    
    particles = malloc(attributes.maxCount * sizeof(SParticles));
    
    //geometry
    particleMesh = [[GeometryShape alloc] init]; 
    particleMesh.dataSetType = VERTEX_SET;
    particleMesh.vertStructType = VERTEX_TEX_STR;
    
    particleMesh.vertexCount = 4;
    [particleMesh CreateVertexIndexArrays];
        
    //initial position
    particleMesh.verticesT[0].vertex = GLKVector3Make(-attributes.prtSize.width/2, -attributes.prtSize.height/2, 0);
    particleMesh.verticesT[1].vertex = GLKVector3Make( attributes.prtSize.width/2, -attributes.prtSize.height/2, 0);
    particleMesh.verticesT[2].vertex = GLKVector3Make(-attributes.prtSize.width/2,  attributes.prtSize.height/2, 0);
    particleMesh.verticesT[3].vertex = GLKVector3Make( attributes.prtSize.width/2,  attributes.prtSize.height/2, 0);
    
    particleMesh.verticesT[0].tex = GLKVector2Make(0.0,0.0);
    particleMesh.verticesT[1].tex = GLKVector2Make(1.0,0.0);
    particleMesh.verticesT[2].tex = GLKVector2Make(0.0,1.0);
    particleMesh.verticesT[3].tex = GLKVector2Make(1.0,1.0);
    
}

//fileName - name of particle texture file
- (void) SetupRendering: (NSString*) fileName
{
    [particleMesh InitGeometryBeffers];
    
    self.effectParticle = [[GLKBaseEffect alloc] init];
    self.effectParticle.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //texture
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture: fileName: YES];
    
    //NSLog(@"++++++++++++     %d", texID);
    
    self.effectParticle.texture2d0.enabled = GL_TRUE;
    self.effectParticle.texture2d0.name = texID;
    self.effectParticle.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) color
{
    attributes.color = color; //this is set when particle is created but we need to update it constantly
    
    if(started)
    {
        for (int i = 0; i < attributes.maxCount; i++) //update al particles
        {
            [self MoveParticle: &particles[i]: dt];

            particles[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, particles[i].position);
                                                
            [CommonHelpers LoadSphereBillboard: particles[i].displaceMat.m];
        }
    
        if(attributes.type == PT_SPLASH_OCEAN || attributes.type == PT_SPLASH_GROUND ||
           attributes.type == PT_EXPLOSION || attributes.type == PT_SINGLE_GLOW ||
           attributes.type == PT_DUST_GROUND) //add self ending types here
        {
            //self ending checking, when all particles die, end effect
            BOOL timeToEnd = YES;
            for (int i = 0; i < attributes.currentCount; i++) //check ending only in visible paricles
            {
                if(particles[i].alive)
                {
                    timeToEnd = NO;
                    break;
                }
            }
            
            if(timeToEnd)
            {
                [self End];
            }
        }
    }
}


- (void) Render
{
    if(started)
    {
        glBindVertexArrayOES(particleMesh.vertexArray);
         
        [[SingleGraph sharedSingleGraph] SetCullFace:YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask:NO];
        [[SingleGraph sharedSingleGraph] SetBlend:YES];
        
        if(attributes.type == PT_SINGLE_GLOW)
        {
            [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_SRC_ALPHA_ONE];
        }else
        {
            [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_SRC_ALPHA];
        }
        for (int i = 0; i < attributes.currentCount; i++)
        {
            if(particles[i].active)
            {
                self.effectParticle.transform.modelviewMatrix = particles[i].displaceMat;
                self.effectParticle.constantColor = particles[i].color;
                [effectParticle prepareToDraw];
                glDrawArrays(GL_TRIANGLE_STRIP, 0, particleMesh.vertexCount);
            }
        }

    }
}

// F_GL_ONE:
// F_GL_SRC_ALPHA:
// F_GL_SRC_ALPHA_ONE:


- (void) ResourceCleanUp
{
    [particleMesh ResourceCleanUp];
    free(particles);
    self.effectParticle = nil;
}

#pragma mark - Effect functions

//start 
- (void) Start: (GLKVector3) initPos : (GLKVector3) direction
{
    if(!started)
    {
        started = true;
        attributes.initialPos = initPos; //inital position of the effect
        attributes.direction = direction; //direction of particles flow
        
        for (int i = 0; i < attributes.maxCount; i++) // start all particles, but show only current
        {
            [self CreateParticle:&particles[i]];
        }
    }
}

- (void) Start: (GLKVector3) initPos
{
    [self Start: initPos : GLKVector3Make(0.0, 0.0, 0.0)];
}


//end effect
- (void) End
{
    started = false;
}

#pragma mark - Particle functions

//set particle to its initial position and initial parameters
- (void) CreateParticle: (SParticles *) p
{
    float velY = 0, velX = 0, velZ = 0; //, randDisplaceX, randDisplaceZ;
    p->active = false;
    
    if(attributes.type == PT_EXPLOSION || attributes.type == PT_SINGLE_GLOW || attributes.type == PT_INSECT_SWARM) // starts from single point
    {
        p->position = attributes.initialPos;
    }else
    {
        p->position = [CommonHelpers RandomInCircle:attributes.initialPos :attributes.triggerRadius :attributes.initialPos.y]; //need to simulate round figure
    }
    
    p->lifetime.current = 0;
    
    //chose parameters depending on particle type
    if(attributes.type == PT_FIRE)
    {
        p->color = attributes.color;
        //for fire particle lifetime is from 0 to prtclLife
        p->lifetime.max = [CommonHelpers RandomInRange: 0.0 : attributes.prtclLifeMax : 1000];
        velY = attributes.prtclSpeedMax; //speed of particle Y
    }else
    if(attributes.type == PT_SMOKE)
    {
        p->color = attributes.color;
        p->lifetime.max = [CommonHelpers RandomInRange: 0.0 : attributes.prtclLifeMax : 1000];
        velY = attributes.prtclSpeedMax; //speed of particle
        velX = attributes.direction.x;
        velZ = attributes.direction.z;
    }else
    if(attributes.type == PT_SPLASH_OCEAN || attributes.type == PT_SPLASH_GROUND)
    {
        p->alive = true; //when all particles are dead, stop particle effect
        p->color = attributes.color;
        p->lifetime.max = attributes.prtclLifeMax; //how long particle lives
        velY = [CommonHelpers RandomInRange: 0 : attributes.prtclSpeedMax : 1000];
        velX = [CommonHelpers RandomFloat] / 2 - 0.25;
        velZ = [CommonHelpers RandomFloat] / 2 - 0.25;
    }else
    if(attributes.type == PT_EXPLOSION)
    {
        p->alive = true; //when all particles are dead, stop particle effect
        p->color = attributes.color;
        p->lifetime.max = attributes.prtclLifeMax; //how long particle lives
        velY = [CommonHelpers RandomInRange: -attributes.prtclSpeedMax : attributes.prtclSpeedMax : 1000];
        velX = [CommonHelpers RandomInRange: -attributes.prtclSpeedMax : attributes.prtclSpeedMax : 1000];
        velZ = [CommonHelpers RandomInRange: -attributes.prtclSpeedMax : attributes.prtclSpeedMax : 1000];
    }else
    if(attributes.type == PT_SINGLE_GLOW) //stationary glow particle
    {
        p->alive = true; //when all particles are dead, stop particle effect
        p->color = attributes.color;
        p->lifetime.max = attributes.prtclLifeMax; //how long particle lives
        velY = 0.0;
        velX = 0.0;
        velZ = 0.0;
    }else
    if(attributes.type == PT_DUST_GROUND)
    {
        p->alive = true; //when all particles are dead, stop particle effect
        p->color = attributes.color;
        p->lifetime.max = attributes.prtclLifeMax; //how long particle lives
        velY = [CommonHelpers RandomInRange: 0 : attributes.prtclSpeedMax : 1000];
        //velX = [CommonHelpers RandomFloat] / 2 - 0.25;
        //velZ = [CommonHelpers RandomFloat] / 2 - 0.25;
        velX = attributes.direction.x;
        velZ = attributes.direction.z;
    }else
    if(attributes.type == PT_INSECT_SWARM)
    {
        p->alive = true; 
        p->color = attributes.color;
        velY = 0.0;
        velX = 0.0;
        velZ = 0.0;
    }
    
    p->velocity = GLKVector3Make(velX, velY, velZ);
}                                                    

//advance particle movement
- (void) MoveParticle: (SParticles *) p: (float) dt
{
    if(!p->active)
        p->active = true; //activate particle
    
    p->lifetime.current += dt;
    p->position = GLKVector3Add(p->position, GLKVector3MultiplyScalar(p->velocity,dt));
    
   // NSLog(@"%f %f %f", p->position.x,p->position.y,p->position.z);
    
    //chose update depending on type
    if(attributes.type == PT_FIRE)
    {
        float lifeRatio = p->lifetime.current / p->lifetime.max;
        
        p->color.g = 1.0 - lifeRatio;
        p->color.b = 1.0 - lifeRatio * 5.0;
        if(p->color.b < 0)
        {
            p->color.b = 0;
        }
        
        p->color.a = 1.0 - lifeRatio;
        
        if(p->lifetime.current > p->lifetime.max)
        {
            [self CreateParticle:p];
        }
    }else
    if(attributes.type == PT_SMOKE)
    {
        p->color.a = 1.0 - p->lifetime.current / p->lifetime.max;
        
        if(p->lifetime.current > p->lifetime.max)
        {
            [self CreateParticle:p];
        }
    }else
    if(attributes.type == PT_SPLASH_OCEAN)
    {
        p->color.a = 1.0 - p->lifetime.current / p->lifetime.max;
        
        if(p->lifetime.current > p->lifetime.max)
        {
            p->alive = false; //particle died
        }
    }
    else
    if(attributes.type == PT_SPLASH_GROUND)
    {
        p->color.a = 1.0 - p->lifetime.current / p->lifetime.max;
        if(p->lifetime.current > p->lifetime.max)
        {
            p->alive = false; //particle died
        }
    }
    else
    if(attributes.type == PT_EXPLOSION)
    {
        p->color.a = 1.0 - p->lifetime.current / p->lifetime.max;
        if(p->lifetime.current > p->lifetime.max)
        {
            p->alive = false; //particle died
        }
    }
    else
    if(attributes.type == PT_SINGLE_GLOW)
    {
        p->color.a = sinf([CommonHelpers ValueInNewRange: 0.0 : p->lifetime.max : 0.0 : M_PI : p->lifetime.current ]); //glow up, glow out
        if(p->lifetime.current > p->lifetime.max)
        {
            p->alive = false; //particle died
        }
    }
    else
    if(attributes.type == PT_DUST_GROUND)
    {
        p->color.a = 1.0 - p->lifetime.current / p->lifetime.max;
        if(p->lifetime.current > p->lifetime.max)
        {
            p->alive = false; //particle died
        }
    }
    else
    if(attributes.type == PT_INSECT_SWARM)
    {
        //neverending (ends only when bees are off)
        if(p->lifetime.current >= PI_BY_2)
        {
            p->lifetime.current = p->lifetime.current - PI_BY_2;
        }
        p->color = attributes.color;
    }
}

#pragma mark - Helper functions

- (void) AssigneMaxParticleSpeed: (float) speed
{
    attributes.prtclSpeedMax = speed;
}

- (void) AssigneTriggerRadius: (float) radius
{
    attributes.triggerRadius = radius;
}

//change current (not initial) position of given particle
- (void) AssignPosition: (int) pIndex : (GLKVector3) position
{
    if(pIndex < attributes.maxCount)
    {
        particles[pIndex].position = position;
    }
}

//change  initial position of given particle effect (particles start out from here)
//usefull to use during of not-self ending particle run
- (void) AssignInitialPosition: (GLKVector3) position
{
    attributes.initialPos = position;
}

//assign direction of particle effect
//usefull to use during of not-self ending particle run
- (void) AssignDirection: (GLKVector3) direction
{
    attributes.direction = direction;
}

//set current count of particles in effect (0 <= currentCount <= maxCount)
- (void) AssignCurrentCount: (int) currCnt
{
    if(currCnt >= 0 && currCnt <= attributes.maxCount)
    {
        attributes.currentCount = currCnt;
    }
}

//assign velocity to particle index, value that will be multipleid by dt and added to position
- (void) AssignVelocity: (int) pIndex : (GLKVector3) velocity
{
    if(pIndex < attributes.maxCount)
    {
        particles[pIndex].velocity = velocity;
    }
}

@end
