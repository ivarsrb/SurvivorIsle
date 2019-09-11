//
//  Particles.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 27/04/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Particle engine elements render and control function

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "CommonHelpers.h"
#import "ParticleEffect.h"
#import "Ocean.h"
#import "Terrain.h"

@interface Particles : NSObject
{
    ParticleEffect *splashPrt;
    ParticleEffect *splashBigPrt; 
    ParticleEffect *splashDistantPrt;
    ParticleEffect *firePrt;
    ParticleEffect *drillSmokePrt;
    ParticleEffect *cookSmokePrt;
    ParticleEffect *splashDropPrt;
    ParticleEffect *groundSplashPrt;
    ParticleEffect *palmExplosionPrt;
    ParticleEffect *commonGroundAreaSplashPrt;
    ParticleEffect *smallPalmExplosionPrt;
    ParticleEffect *shineMediumPrt;
    ParticleEffect *shineSmallPrt;
    ParticleEffect *dustGroundPrt;
    ParticleEffect *smokeLargePrt;
    ParticleEffect *beeSwarmPrt;
}

@property (strong, nonatomic) ParticleEffect *splashPrt;
@property (strong, nonatomic) ParticleEffect *splashBigPrt;
@property (strong, nonatomic) ParticleEffect *splashDistantPrt;
@property (strong, nonatomic) ParticleEffect *firePrt;
@property (strong, nonatomic) ParticleEffect *drillSmokePrt;
@property (strong, nonatomic) ParticleEffect *cookSmokePrt;
@property (strong, nonatomic) ParticleEffect *splashDropPrt;
@property (strong, nonatomic) ParticleEffect *groundSplashPrt;
@property (strong, nonatomic) ParticleEffect *palmExplosionPrt;
@property (strong, nonatomic) ParticleEffect *commonGroundAreaSplashPrt;
@property (strong, nonatomic) ParticleEffect *smallPalmExplosionPrt;
@property (strong, nonatomic) ParticleEffect *shineMediumPrt;
@property (strong, nonatomic) ParticleEffect *shineSmallPrt;
@property (strong, nonatomic) ParticleEffect *dustGroundPrt;
@property (strong, nonatomic) ParticleEffect *smokeLargePrt;
@property (strong, nonatomic) ParticleEffect *beeSwarmPrt;

- (void) ResetData;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (Ocean*) ocean : (Terrain*) terrain;
- (void) Render;
- (void) ResourceCleanUp;

@end
