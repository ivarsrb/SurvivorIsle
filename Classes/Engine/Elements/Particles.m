//
//  Particles.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 27/04/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//

#import "Particles.h"

@implementation Particles
@synthesize splashPrt, splashBigPrt, splashDistantPrt, firePrt, drillSmokePrt, cookSmokePrt, groundSplashPrt,splashDropPrt,
             palmExplosionPrt, commonGroundAreaSplashPrt, smallPalmExplosionPrt, shineMediumPrt, shineSmallPrt, dustGroundPrt, smokeLargePrt, beeSwarmPrt;

- (id) init
{
    self = [super init];
    if(self != nil)
    {
        [self InitGeometry];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    [splashPrt End];
    [splashBigPrt End];
    [splashDistantPrt End];
    [splashDropPrt End];
    [firePrt End];
    [drillSmokePrt End];
    [cookSmokePrt End];
    [groundSplashPrt End];
    [palmExplosionPrt End];
    [commonGroundAreaSplashPrt End];
    [smallPalmExplosionPrt End];
    [shineMediumPrt End];
    [shineSmallPrt End];
    [dustGroundPrt End];
    [smokeLargePrt End];
    [beeSwarmPrt End];
}

- (void) InitGeometry
{
    //NOTE: parameters could be redefined at usage
 
    //small water splash (spear tip)
    SParticleEffect splashEffect;
    splashEffect.type = PT_SPLASH_OCEAN;
    splashEffect.prtSize.width = 0.07;
    splashEffect.prtSize.height = 0.07;
    splashEffect.maxCount = 15;
    splashEffect.triggerRadius = 0.05;
    splashEffect.prtclLifeMax = 0.25;
    splashEffect.prtclSpeedMax = 1.5; //initial is set automatically
    splashPrt = [[ParticleEffect alloc] initWithAttributes: &splashEffect];
    
    //[splashPrt TestFunc: &splashEffect : splashEffect];
    
    //big water splash (fish strike, raft)
    SParticleEffect bigSplashEffect;
    bigSplashEffect.type = PT_SPLASH_OCEAN;
    bigSplashEffect.prtSize.width = bigSplashEffect.prtSize.height = 0.2;//0.25;
    bigSplashEffect.maxCount = 30;
    bigSplashEffect.triggerRadius = 0.35;
    bigSplashEffect.prtclLifeMax = 0.70;
    bigSplashEffect.prtclSpeedMax = 2.0;//initial is set automatically
    splashBigPrt =  [[ParticleEffect alloc] initWithAttributes: &bigSplashEffect];
    
    //distant splash (dolphin jump)
    SParticleEffect distantSplashEffect;
    distantSplashEffect.type = PT_SPLASH_OCEAN;
    distantSplashEffect.prtSize.width = 1.0;
    distantSplashEffect.prtSize.height = 1.0;
    distantSplashEffect.maxCount = 20;
    distantSplashEffect.triggerRadius = 1.20;
    distantSplashEffect.prtclLifeMax = 1.20;
    distantSplashEffect.prtclSpeedMax = 3.0;//initial is set automatically
    splashDistantPrt =  [[ParticleEffect alloc] initWithAttributes: &distantSplashEffect];
    
    //drop water splash (object dropped in water)
    SParticleEffect splashDropEffect;
    splashDropEffect.type = PT_SPLASH_OCEAN;
    splashDropEffect.prtSize.width = 0.12;
    splashDropEffect.prtSize.height = 0.12;
    splashDropEffect.maxCount = 15;
    splashDropEffect.triggerRadius = 0.10;
    splashDropEffect.prtclLifeMax = 0.50;
    splashDropEffect.prtclSpeedMax = 1.5;//initial is set automatically
    splashDropPrt = [[ParticleEffect alloc] initWithAttributes: &splashDropEffect];
    
    //campfire particle
    SParticleEffect fireEffect;
    fireEffect.type = PT_FIRE;
    fireEffect.color = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    fireEffect.prtSize.width = 0.17;//0.2;
    fireEffect.prtSize.height = 0.35; //0.35;
    fireEffect.maxCount = 45;
    fireEffect.triggerRadius = 0.17;
    //for fire maximal particle lifetime is fixed
    //to lessen fire intensity, use particle speed
    fireEffect.prtclLifeMax = 0.25; //maximal default
    fireEffect.prtclSpeedMax = 3.0;//initial is set automatically
    firePrt = [[ParticleEffect alloc] initWithAttributes: &fireEffect];
    
    //fire drilling smoke
    SParticleEffect drillSmokeEffect;
    drillSmokeEffect.type = PT_SMOKE;
    drillSmokeEffect.prtSize.width = 0.12;//0.17;
    drillSmokeEffect.prtSize.height = 0.17;//0.22;
    drillSmokeEffect.maxCount = 20;
    drillSmokeEffect.triggerRadius = 0.05;
    drillSmokeEffect.prtclLifeMax = 0.25;
    drillSmokeEffect.prtclSpeedMax = 3.0;//initial is set automatically
    drillSmokePrt = [[ParticleEffect alloc] initWithAttributes: &drillSmokeEffect];
    
    //cooked item smoke
    SParticleEffect cookSmokeEffect;
    cookSmokeEffect.type = PT_SMOKE;
    cookSmokeEffect.prtSize.width = 0.30;
    cookSmokeEffect.prtSize.height = 0.40;
    cookSmokeEffect.maxCount = 8;
    cookSmokeEffect.triggerRadius = 0.15;
    cookSmokeEffect.prtclLifeMax = 1.00;
    cookSmokeEffect.prtclSpeedMax = 1.0;//initial is set automatically
    cookSmokePrt = [[ParticleEffect alloc] initWithAttributes: &cookSmokeEffect];
    
    //small ground splash
    SParticleEffect groundEffect;
    groundEffect.type = PT_SPLASH_GROUND;
    groundEffect.prtSize.width = 0.2;
    groundEffect.prtSize.height = 0.2;
    groundEffect.maxCount = 3;
    groundEffect.triggerRadius = 0.08;
    groundEffect.prtclLifeMax = 0.25;
    groundEffect.prtclSpeedMax = 2.0;//initial is set automatically
    groundSplashPrt = [[ParticleEffect alloc] initWithAttributes: &groundEffect];
    
    //palm crown explosion
    SParticleEffect palmExplosionEffect;
    palmExplosionEffect.type = PT_EXPLOSION;
    palmExplosionEffect.prtSize.width = 0.3;
    palmExplosionEffect.prtSize.height = 0.3;
    palmExplosionEffect.maxCount = 15;
    palmExplosionEffect.prtclLifeMax = 0.6;
    palmExplosionEffect.prtclSpeedMax = 5.0;//initial is set automatically
    palmExplosionPrt = [[ParticleEffect alloc] initWithAttributes: &palmExplosionEffect];
    
    //comon ground area splash
    SParticleEffect commonGroundAreaSplash;
    commonGroundAreaSplash.type = PT_SPLASH_GROUND;
    commonGroundAreaSplash.prtSize.width = 0.25;
    commonGroundAreaSplash.prtSize.height = 0.25;
    commonGroundAreaSplash.maxCount = 20;
    commonGroundAreaSplash.prtclLifeMax = 0.6;
    commonGroundAreaSplash.prtclSpeedMax = 2.0;//initial is set automatically
    commonGroundAreaSplashPrt = [[ParticleEffect alloc] initWithAttributes: &commonGroundAreaSplash];
    
    //small palm leaf explosion
    SParticleEffect smallPalmExplosionEffect;
    smallPalmExplosionEffect.type = PT_EXPLOSION;
    smallPalmExplosionEffect.prtSize.width = 0.08;
    smallPalmExplosionEffect.prtSize.height = 0.08;
    smallPalmExplosionEffect.maxCount = 20;
    smallPalmExplosionEffect.prtclLifeMax = 0.5;
    smallPalmExplosionEffect.prtclSpeedMax = 1.0;//initial is set automatically
    smallPalmExplosionPrt = [[ParticleEffect alloc] initWithAttributes: &smallPalmExplosionEffect];
    
    //shining glow particle used for knife on ground
    SParticleEffect shineMediumEffect;
    shineMediumEffect.type = PT_SINGLE_GLOW;
    shineMediumEffect.prtSize.width = 0.75;
    shineMediumEffect.prtSize.height = 0.75;
    shineMediumEffect.maxCount = 1;
    shineMediumEffect.prtclLifeMax = 1.5;
    //shinyGlowEffect.prtclSpeedInitial = shinyGlowEffect.prtclSpeedMax = 1.0;
    shineMediumPrt = [[ParticleEffect alloc] initWithAttributes: &shineMediumEffect];
    
    //shining glow particle used for knife tip in hand
    SParticleEffect shineSmallEffect;
    shineSmallEffect.type = PT_SINGLE_GLOW;
    shineSmallEffect.prtSize.width = 0.1;
    shineSmallEffect.prtSize.height = 0.1;
    shineSmallEffect.maxCount = 1;
    shineSmallEffect.prtclLifeMax = 0.6;
    //shinyGlowEffect.prtclSpeedInitial = shinyGlowEffect.prtclSpeedMax = 1.0;
    shineSmallPrt = [[ParticleEffect alloc] initWithAttributes: &shineSmallEffect];
    
    //comon ground area splash
    SParticleEffect dustGroundSplash;
    dustGroundSplash.type = PT_DUST_GROUND;
    //dustGroundSplash.prtSize.width = 0.25;
    //dustGroundSplash.prtSize.height = 0.25;
    dustGroundSplash.prtSize.width = 0.7;
    dustGroundSplash.prtSize.height = 0.7;
    //dustGroundSplash.count = 20;
    dustGroundSplash.maxCount = 10;
    dustGroundSplash.prtclLifeMax = 1.0;
    dustGroundSplash.prtclSpeedMax = 0.9;//initial is set automatically
    dustGroundPrt = [[ParticleEffect alloc] initWithAttributes: &dustGroundSplash];
    
    //sireplace smoke from blowing
    SParticleEffect largeSmokeEffect;
    largeSmokeEffect.type = PT_SMOKE;
    largeSmokeEffect.prtSize.width = 1.2; //0.60;
    largeSmokeEffect.prtSize.height = 1.2; //0.60;
    largeSmokeEffect.maxCount = 10;//20;
    largeSmokeEffect.triggerRadius = 0.25;
    largeSmokeEffect.prtclLifeMax = 3.0;
    largeSmokeEffect.prtclSpeedMax = 0.0; //initial is set automatically
    smokeLargePrt = [[ParticleEffect alloc] initWithAttributes: &largeSmokeEffect];
    
    //bee hive
    SParticleEffect beeSwarmEffect;
    beeSwarmEffect.type = PT_INSECT_SWARM;
    beeSwarmEffect.prtSize.width = 0.05;
    beeSwarmEffect.prtSize.height = 0.05;
    beeSwarmEffect.maxCount = PRTCL_BEE_COUNT;
    beeSwarmPrt = [[ParticleEffect alloc] initWithAttributes: &beeSwarmEffect];
}

- (void) SetupRendering
{
    [splashPrt SetupRendering: @"particle_stiff._png"];  //16x16
    [splashBigPrt SetupRendering: @"particle_smooth._png"]; //16x16
    [splashDistantPrt SetupRendering: @"particle_stiff._png"]; //16x16
    [splashDropPrt SetupRendering: @"particle_stiff._png"];  //16x16
    [firePrt SetupRendering: @"particle_smooth._png"];//16x16
    [drillSmokePrt SetupRendering: @"particle_light._png"]; //16x16
    [cookSmokePrt SetupRendering: @"particle_light._png"]; //16x16
    [groundSplashPrt SetupRendering: @"particle_ground._png"]; //16x16
    [palmExplosionPrt SetupRendering: @"particle_palm._png"]; //16x16
    [commonGroundAreaSplashPrt SetupRendering: @"particle_ground._png"]; //16x16
    [smallPalmExplosionPrt SetupRendering: @"particle_palm._png"]; //16x16
    [shineMediumPrt SetupRendering: @"particle_shine.png"]; //64x64
    [shineSmallPrt SetupRendering: @"particle_shine.png"]; //64x64
    [dustGroundPrt SetupRendering: @"particle_ground._png"]; //16x16
    [smokeLargePrt SetupRendering: @"particle_smooth._png"]; //16x16
    [beeSwarmPrt SetupRendering: @"insect.png"];  //16x16
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (Ocean*) ocean : (Terrain*) terrain
{
    [splashPrt Update: dt : curTime : modelviewMat : ocean.coloring.dayTime];
    [splashBigPrt Update: dt : curTime : modelviewMat : ocean.coloring.dayTime];
    [splashDistantPrt Update: dt : curTime : modelviewMat : ocean.coloring.dayTime];
    [splashDropPrt Update: dt : curTime : modelviewMat : ocean.coloring.dayTime];
    [firePrt Update: dt : curTime : modelviewMat : firePrt.attributes.color];
    [drillSmokePrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [cookSmokePrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [groundSplashPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [palmExplosionPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [commonGroundAreaSplashPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [smallPalmExplosionPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [shineMediumPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [shineSmallPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [dustGroundPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [smokeLargePrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
    [beeSwarmPrt Update: dt : curTime : modelviewMat : terrain.coloring.dayTime];
}

- (void) Render
{
    [splashPrt Render];
    [splashBigPrt Render];
    [splashDistantPrt Render];
    [splashDropPrt Render];
    [firePrt Render];
    [drillSmokePrt Render];
    [cookSmokePrt Render];
    [groundSplashPrt Render];
    [palmExplosionPrt Render];
    [commonGroundAreaSplashPrt Render];
    [smallPalmExplosionPrt Render];
    [shineMediumPrt Render];
    [shineSmallPrt Render];
    [dustGroundPrt Render];
    [smokeLargePrt Render];
    [beeSwarmPrt Render];
}
- (void) ResourceCleanUp
{
    [splashPrt ResourceCleanUp];
    [splashBigPrt ResourceCleanUp];
    [splashDistantPrt ResourceCleanUp];
    [splashDropPrt ResourceCleanUp];
    [firePrt ResourceCleanUp];
    [drillSmokePrt ResourceCleanUp];
    [cookSmokePrt ResourceCleanUp];
    [groundSplashPrt ResourceCleanUp];
    [palmExplosionPrt ResourceCleanUp];
    [commonGroundAreaSplashPrt ResourceCleanUp];
    [smallPalmExplosionPrt ResourceCleanUp];
    [shineMediumPrt ResourceCleanUp];
    [shineSmallPrt ResourceCleanUp];
    [dustGroundPrt ResourceCleanUp];
    [smokeLargePrt ResourceCleanUp];
    [beeSwarmPrt ResourceCleanUp];
}


@end
