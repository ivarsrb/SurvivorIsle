//
//  ParticleEffect.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Particle effect class, for fire splashes and other efects

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"
#import "SingleGraph.h"


@interface ParticleEffect : NSObject
{
    bool started; //weather is strated or not
    SParticleEffect attributes;
    
    SParticles *particles;
    GeometryShape *particleMesh;
    GLKBaseEffect *effectParticle;
}

@property (strong, nonatomic) GeometryShape *particleMesh;
@property (strong, nonatomic) GLKBaseEffect *effectParticle;
@property (readonly, nonatomic) SParticleEffect attributes;
@property (readonly, nonatomic) bool started;
@property (readonly, nonatomic) SParticles *particles;
//- (void) TestFunc: (SParticleEffect*) attrPointer: (SParticleEffect) attr;

- (id) initWithAttributes: (SParticleEffect*) attr;
- (void) InitGeometry;
- (void) SetupRendering: (NSString*) fileName;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) color;
- (void) Render;
- (void) ResourceCleanUp;

- (void) CreateParticle: (SParticles *) p;
- (void) Start: (GLKVector3) initPos;
- (void) Start: (GLKVector3) initPos : (GLKVector3) direction;
- (void) End;
- (void) MoveParticle: (SParticles *) p : (float) dt;

- (void) AssigneMaxParticleSpeed: (float) speed;
- (void) AssigneTriggerRadius: (float) radius;
- (void) AssignPosition: (int) pIndex : (GLKVector3) poition;
- (void) AssignInitialPosition: (GLKVector3) position;
- (void) AssignDirection: (GLKVector3) direction;
- (void) AssignCurrentCount: (int) currCnt;
- (void) AssignVelocity: (int) pIndex : (GLKVector3) velocity;
@end
