//
//  Objects.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Objects.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation Objects
@synthesize objectMesh,dynamicObjectMesh,cocos,palms,bushes,grass,campFire,handSpear,
            fishes,sticks,rainCatch,shells,crabs,raft,shipwreck,dryGrass,berryBush,leaves,flatRocks,deadfallTraps,
            rats,stickTraps,logs,rags,wildlife, stone, shelter, smallPalm, knife, handLeaf, beehive, seaUrchin, egg, bird, shark;

- (id) initWithObjects: (Terrain*) terr: (Ocean*) ocean
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry: terr: ocean];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData: (Terrain*) terr : (Interaction*) intr : (Environment*) env
{
    //pre reset data
    //data that needs to set before resetting data, like nilling object locations flag (so random locations detection work correctly)
    [palms PresetData];
    [bushes PresetData];
    [dryGrass PresetData];
    [berryBush PresetData];
    [leaves PresetData];
    [flatRocks PresetData];
    [sticks PresetData];
    [stone PresetData];
    [smallPalm PresetData];
    
    //reset data
    //terrain independent
    [handSpear ResetData];
    [CommonHelpers Log:@"handSpear reset"];
    [campFire ResetData];
    [CommonHelpers Log:@"campFire reset"];
    [rainCatch ResetData];
    [CommonHelpers Log:@"rainCatch reset"];
    [deadfallTraps ResetData];
    [CommonHelpers Log:@"deadfallTraps reset"];
    [stickTraps ResetData];
    [CommonHelpers Log:@"stickTraps reset"];
    [fishes ResetData];
    [CommonHelpers Log:@"fishes reset"];
    [crabs ResetData:terr];
    [CommonHelpers Log:@"crabs reset"];
    [rats ResetData:terr];
    [CommonHelpers Log:@"rats reset"];
    [shipwreck ResetData: terr : env];
    [CommonHelpers Log:@"shipwreck reset"];
    [logs ResetData:shipwreck: env];
    [CommonHelpers Log:@"logs reset"];
    [rags ResetData: shipwreck : env : terr];
    [CommonHelpers Log:@"rags reset"];
    [raft ResetData];
    [CommonHelpers Log:@"raft reset"];
    [shelter ResetData];
    [CommonHelpers Log:@"shelter reset"];
    [knife ResetData];
    [CommonHelpers Log:@"knife reset"];
    [handLeaf ResetData];
    [CommonHelpers Log:@"hand leaf reset"];
    [shark ResetData];
    [CommonHelpers Log:@"shark reset"];
    
    //terrain dependent (needs to place on terrain at satrtup so nothing is on top of something else)
    [palms ResetData: objectMesh : dynamicObjectMesh : terr : intr];
    [CommonHelpers Log:@"palms reset"];
    [smallPalm ResetData: terr : intr];
    [CommonHelpers Log:@"smallpalm reset"];
    [cocos ResetData: terr : palms];
    [CommonHelpers Log:@"cocos reset"];
    [bushes ResetData:objectMesh: terr : intr];
    [CommonHelpers Log:@"bushes reset"];
    [grass ResetData:objectMesh: terr : intr];
    [CommonHelpers Log:@"grass reset"];
    [dryGrass ResetData:dynamicObjectMesh: terr : intr];
    [CommonHelpers Log:@"dryGrass reset"];
    [berryBush ResetData: terr : intr];
    [CommonHelpers Log:@"berryBush reset"];
    [leaves ResetData:objectMesh: terr : intr];
    [CommonHelpers Log:@"leaves reset"];
    [flatRocks ResetData: terr : intr];
    [CommonHelpers Log:@"flatRocks reset"];
    [sticks ResetData: terr : intr : env];
    [CommonHelpers Log:@"sticks reset"];
    [shells ResetData: terr];
    [CommonHelpers Log:@"shells reset"];
    [wildlife ResetData: terr];
    [CommonHelpers Log:@"wildlife reset"];
    [stone ResetData: terr : intr];
    [CommonHelpers Log:@"stone reset"];
    [beehive ResetData: terr : palms];
    [CommonHelpers Log:@"beehive reset"];
    [seaUrchin ResetData: terr];
    [CommonHelpers Log:@"sea urchin reset"];
    [egg ResetData: leaves];
    [CommonHelpers Log:@"egg reset"];
    [bird ResetData: egg];
    [CommonHelpers Log:@"bird reset"];
    
    
    //write all geometry data to vertex buffers
    [objectMesh WriteAllToVertexBuffer];
    [dynamicObjectMesh WriteAllToVertexBuffer];
} 

- (void) InitGeometry:  (Terrain*) terr: (Ocean*) ocean
{
    //objects
    palms = [[PalmTree alloc] init];
    cocos = [[Cocos alloc] init];
    sticks = [[Stick alloc] init];
    fishes = [[Fish alloc] initWithParams:terr];
    bushes = [[Bush alloc] init];
    grass = [[Grass alloc] init];
    dryGrass = [[DryGrass alloc] init];
    berryBush = [[BerryBush alloc] init];
    leaves = [[Leaves alloc] init];
    shells = [[Shell alloc] init];
    crabs = [[Crab alloc] init];
    flatRocks = [[FlatRock alloc] init];
    handSpear = [[HandSpear alloc] init];
    rainCatch = [[RainCatch alloc] init];
    shipwreck = [[Shipwreck alloc] init];
    deadfallTraps = [[DeadfallTrap alloc] init];
    stickTraps = [[StickTrap alloc] init];
    rats = [[Rat alloc] init];
    logs = [[Log alloc] init];
    rags = [[Rag alloc] init];
    raft = [[Raft alloc] initWithObjects:ocean];
    campFire = [[CampFire alloc] init];
    wildlife = [[Wildlife alloc] init];
    stone = [[Stone alloc] init];
    shelter = [[Shelter alloc] init];
    smallPalm = [[SmallPalm alloc] init];
    knife = [[Knife alloc] init];
    handLeaf = [[HandLeaf alloc] init];
    beehive = [[Beehive alloc] init];
    seaUrchin = [[SeaUrchin alloc] init];
    egg = [[Egg alloc] init];
    bird = [[Bird alloc] init];
    shark = [[Shark alloc] initWithParams: terr : ocean];
    
    //global geometry mesh
    //STATIC OBJECTS
    objectMesh = [[GeometryShape alloc] init];
    objectMesh.vertStructType = VERTEX_TEX_STR;
    objectMesh.vertexCount = stickTraps.vertexCount + rats.vertexCount + deadfallTraps.vertexCount + flatRocks.vertexCount + leaves.vertexCount + 
                            shipwreck.vertexCount + logs.vertexCount + crabs.vertexCount + shells.vertexCount + sticks.vertexCount + handSpear.vertexCount + 
                            cocos.vertexCount + palms.vertexCount + bushes.vertexCount + grass.vertexCount + rags.vertexCount + raft.vertexCount + rainCatch.vertexCount +
                            berryBush.vertexCount + campFire.vertexCount + wildlife.dolphinMeshParams.vertexCount + stone.bufferAttribs.vertexCount + shelter.bufferAttribs.vertexCount +
                            smallPalm.bufferAttribsBranch.vertexCount + smallPalm.bufferAttribsTrunk.vertexCount + knife.bufferAttribs.vertexCount + handLeaf.bufferAttribs.vertexCount +
                            beehive.bufferAttribs.vertexCount + seaUrchin.bufferAttribs.vertexCount + egg.bufferAttribs.vertexCount + bird.bufferAttribs.vertexCount;
    
    objectMesh.indexCount = stickTraps.indexCount + rats.indexCount + deadfallTraps.indexCount + flatRocks.indexCount + leaves.indexCount +
                            shipwreck.indexCount + logs.indexCount + crabs.indexCount + shells.indexCount + sticks.indexCount + handSpear.indexCount + 
                            cocos.indexCount + palms.indexCount + bushes.indexCount + grass.indexCount + rags.indexCount + raft.indexCount + rainCatch.indexCount +
                            berryBush.indexCount + campFire.indexCount + wildlife.dolphinMeshParams.indexCount + stone.bufferAttribs.indexCount + shelter.bufferAttribs.indexCount +
                            smallPalm.bufferAttribsBranch.indexCount + smallPalm.bufferAttribsTrunk.indexCount + knife.bufferAttribs.indexCount + handLeaf.bufferAttribs.indexCount +
                            beehive.bufferAttribs.indexCount + seaUrchin.bufferAttribs.indexCount + egg.bufferAttribs.indexCount + bird.bufferAttribs.indexCount;
    
    [objectMesh CreateVertexIndexArrays];
    
    //DYNAMIC OBJECTS
    dynamicObjectMesh = [[GeometryShape alloc] init];
    dynamicObjectMesh.vertStructType = VERTEX_TEX_STR;
    dynamicObjectMesh.drawType = DYNAMIC_DRAW;
    dynamicObjectMesh.vertexCount = palms.vertexDynamicCount + dryGrass.vertexCount + rainCatch.vertexDynamicCount + fishes.vertexCount + raft.vertexDynamicCount +
                                    wildlife.bflyMeshParams.vertexCount + knife.bufferAttribs.vertexDynamicCount + shark.bufferAttribs.vertexCount;
    dynamicObjectMesh.indexCount = palms.indexDynamicCount + dryGrass.indexCount + rainCatch.indexDynamicCount + fishes.indexCount + raft.indexDynamicCount +
                                    wildlife.bflyMeshParams.indexCount + knife.bufferAttribs.indexDynamicCount + shark.bufferAttribs.indexCount;
    [dynamicObjectMesh CreateVertexIndexArrays];
    
    
    //STATIC OBJECTS
    int vCnt = 0,iCnt = 0; //global vertex and index counters
    //fill mesh
    [shipwreck FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [palms FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [cocos FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [bushes FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [leaves FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [shells FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [flatRocks FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [sticks FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [crabs FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [handSpear FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [deadfallTraps FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [rats FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [stickTraps FillGlobalMesh: objectMesh :&vCnt :&iCnt];
    [logs FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [rags FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [raft FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [rainCatch FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [grass FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [berryBush FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [campFire FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [wildlife FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [stone FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [shelter FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [smallPalm FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [knife FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [handLeaf FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [beehive FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [seaUrchin FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [egg FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    [bird FillGlobalMesh: objectMesh : &vCnt : &iCnt];
    
     //DYNAMIC OBJECTS
    vCnt = 0,iCnt = 0; //global vertex and index counters
    [fishes FillGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [palms FillDynamicGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [dryGrass FillGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [rainCatch FillDynamicGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [raft FillDynamicGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [wildlife FillDynamicGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [knife FillDynamicGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    [shark FillGlobalMesh: dynamicObjectMesh : &vCnt : &iCnt];
    
    //initialize daytime colors
    coloring.midday = GLKVector4Make(255/255.,255/255.,255/255.,1);
    coloring.evening = GLKVector4Make(255/255.,225/255.,145/255.,1);
    coloring.night = GLKVector4Make(70/255.,110/255.,225/255.,1);
    coloring.morning = GLKVector4Make(255/255.,245/255.,173/255.,1);
}

- (void) SetupRendering
{
    [objectMesh InitGeometryBeffers];
    [dynamicObjectMesh InitGeometryBeffers];
    
    [palms SetupRendering];
    [cocos SetupRendering];
    [bushes SetupRendering];
    [leaves SetupRendering];
    [shells SetupRendering];
    [flatRocks SetupRendering];
    [sticks SetupRendering];
    [fishes SetupRendering];
    [crabs SetupRendering];
    [campFire SetupRendering];
    [handSpear SetupRendering];
    [shipwreck SetupRendering];
    [deadfallTraps SetupRendering];
    [rats SetupRendering];
    [stickTraps SetupRendering];
    [logs SetupRendering];
    [rags SetupRendering];
    [raft SetupRendering];
    [rainCatch SetupRendering];
    [grass SetupRendering];
    [berryBush SetupRendering];
    [dryGrass SetupRendering];
    [wildlife SetupRendering];
    [stone SetupRendering];
    [shelter SetupRendering];
    [smallPalm SetupRendering];
    [knife SetupRendering];
    [handLeaf SetupRendering];
    [beehive SetupRendering];
    [seaUrchin SetupRendering];
    [egg SetupRendering];
    [bird SetupRendering];
    [shark SetupRendering];
}

- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (Terrain*) terr : (Character*) character : (Interface*) intr : (Environment*) env : (Ocean*) ocean : (Interaction*) interaction  : (Clouds*) clouds : (Particles*) particles : (SkyDome*) sky
{
    [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : coloring.midday : coloring.evening : coloring.night : coloring.morning : curTime];
    
    //------------ lighting test
    //[sky ModifyColoringByViewVector: &coloring.dayTime : character];
    //------------

    //fr special cases keep original lighting in case of lightning
    GLKVector4 nonAffectedLighting = coloring.dayTime;
    //in case of lightning illuminate everything in lightning ambient color #v1.1.
    if([clouds LightningInProximity : dt])
    {
        [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : clouds.lightningIllumination.midday : clouds.lightningIllumination.evening : clouds.lightningIllumination.night : clouds.lightningIllumination.morning : curTime];
    }
    
    
    [palms Update:dt : curTime : modelviewMat : coloring.dayTime : dynamicObjectMesh];
    [dryGrass Update:dt : curTime : modelviewMat:coloring.dayTime:dynamicObjectMesh];
    [wildlife Update:dt : curTime : modelviewMat : coloring.dayTime :dynamicObjectMesh : terr : env : ocean : particles];
    [berryBush Update:dt :curTime :modelviewMat:coloring.dayTime];
    [cocos Update:dt :curTime : modelviewMat : coloring.dayTime : terr : interaction : particles];
    [bushes Update:dt :curTime : modelviewMat : coloring.dayTime];
    [leaves Update:dt :curTime : modelviewMat:coloring.dayTime];
    [shells Update:dt :curTime :modelviewMat:coloring.dayTime : interaction];
    [flatRocks Update:dt :curTime :modelviewMat:coloring.dayTime : interaction];
    [grass Update:dt :curTime :modelviewMat:terr.coloring.dayTime];
    [sticks Update:dt :curTime :modelviewMat:coloring.dayTime:interaction];
    [fishes Update:dt :curTime :modelviewMat :coloring.dayTime :terr:handSpear.spearTip :intr :character:dynamicObjectMesh];
    [rainCatch Update:dt :curTime :modelviewMat:coloring.dayTime:env:dynamicObjectMesh : interaction];
    [shipwreck Update:dt :curTime :modelviewMat:coloring.dayTime];
    [deadfallTraps Update:dt :curTime :modelviewMat:coloring.dayTime : interaction];
    [stickTraps Update:dt :curTime :modelviewMat:coloring.dayTime : interaction];
    [crabs Update:dt :curTime :modelviewMat:coloring.dayTime:terr:character:stickTraps];
    [rats Update:dt :curTime :modelviewMat:coloring.dayTime:terr:character:deadfallTraps:interaction : particles];
    [logs Update: dt : curTime : modelviewMat : coloring.dayTime : env : ocean : terr : character : interaction];
    [rags Update: dt : curTime : modelviewMat : coloring.dayTime : env : ocean : terr];
    [raft Update: dt : curTime : modelviewMat : coloring.dayTime : character : intr : terr:ocean : env : dynamicObjectMesh : particles];
    [handSpear Update: dt : modelviewMat : character : fishes : coloring.dayTime : particles : ocean : shark];
    [campFire Update: dt : curTime : modelviewMat : coloring.dayTime : character : intr : particles];
    [stone Update: dt : curTime : modelviewMat : coloring.dayTime : character : terr : interaction : particles : ocean];
    [shelter Update: dt : curTime : modelviewMat : coloring.dayTime : nonAffectedLighting : character : terr : intr : interaction];
    [smallPalm Update: dt : curTime : modelviewMat : coloring.dayTime : env];
    [knife Update: dt : modelviewMat : character : coloring.dayTime : particles : smallPalm : interaction : dynamicObjectMesh];
    [handLeaf Update: dt : curTime : modelviewMat : coloring.dayTime : character : terr : interaction : particles : campFire : beehive];
    [beehive Update: dt : curTime : modelviewMat : coloring.dayTime : particles : character : intr];
    [seaUrchin Update:dt :curTime :modelviewMat:coloring.dayTime : interaction : character : intr];
    [egg Update: dt : curTime : modelviewMat : coloring.dayTime : character];
    [bird Update: dt : curTime : modelviewMat : coloring.dayTime : terr : character];
    [shark Update: dt : curTime : modelviewMat : coloring.dayTime : terr : character : dynamicObjectMesh];
    
    //update dynamic buffer after every frame
    [dynamicObjectMesh WriteAllToVertexBuffer];
}


//render all solid aobjects here
- (void) RenderSolid: (Character*) character
{
    glBindVertexArrayOES(objectMesh.vertexArray);
    
    [shipwreck Render];
    [palms Render];
    [cocos Render];
    [bushes Render];
    [leaves Render];
    [shells Render];
    [flatRocks Render];
    [sticks Render];
    [deadfallTraps Render];
    [stickTraps Render];
    [rats Render];
    [crabs Render];
    [logs Render: character];
    [rags Render];
    [raft Render];
    [handSpear Render: character];
    [rainCatch Render];
    [berryBush Render];
    [wildlife Render];
    [stone Render];
    [campFire Render];
    [shelter Render];
    [smallPalm Render];
    [knife Render];
    [handLeaf Render];
    [beehive Render];
    [seaUrchin Render];
    [egg Render];
    [bird Render];
    
    //alters VBO
}

//redner all transaprent objects here (last in scene)
- (void) RenderTransparent : (Character*) character
{
    glBindVertexArrayOES(objectMesh.vertexArray);
    
    [grass Render];
    [shelter RenderTransparent: character];
    [raft RenderTransparent];
    //alters VBO
}


//render solid dynamic objects
- (void) RenderDynamicSolid
{
    glBindVertexArrayOES(dynamicObjectMesh.vertexArray);
    
    //solid
    [fishes Render];
    [shark Render];
    [palms RenderDynamic];
    [raft RenderDynamic];
    [wildlife RenderDynamic];
    [knife RenderDynamic];
    
    //alters VBO
}

//render transp. dynamic objects
- (void) RenderDynamicTransparent:(Environment*) env
{
    glBindVertexArrayOES(dynamicObjectMesh.vertexArray);
    
    //transpaernt
    [rainCatch RenderDynamic:env.raining];
    [dryGrass RenderDynamic];
    
    //alters VBO
}


//redner solid objects that are on top of all other objects , except rain
/*
- (void) RenderSolidOnTop
{
    glBindVertexArrayOES(objectMesh.vertexArray);
    
    
    //alters VBO
}
*/


- (void) ResourceCleanUp
{
    [objectMesh ResourceCleanUp];
    [dynamicObjectMesh ResourceCleanUp];
    
    [cocos ResourceCleanUp];
    [fishes ResourceCleanUp];
    [handSpear ResourceCleanUp];
    [palms ResourceCleanUp];
    [bushes ResourceCleanUp];
    [grass ResourceCleanUp];
    [dryGrass ResourceCleanUp];
    [berryBush ResourceCleanUp];
    [leaves ResourceCleanUp];
    [shells ResourceCleanUp];
    [flatRocks ResourceCleanUp];
    [crabs ResourceCleanUp];
    [shipwreck ResourceCleanUp];
    [sticks ResourceCleanUp];
    [deadfallTraps ResourceCleanUp];
    [rats ResourceCleanUp];
    [stickTraps ResourceCleanUp];
    [logs ResourceCleanUp];
    [rags ResourceCleanUp];
    [rainCatch ResourceCleanUp];
    [campFire ResourceCleanUp];
    [raft ResourceCleanUp];
    [wildlife ResourceCleanUp];
    [stone ResourceCleanUp];
    [shelter ResourceCleanUp];
    [smallPalm ResourceCleanUp];
    [knife ResourceCleanUp];
    [handLeaf ResourceCleanUp];
    [beehive ResourceCleanUp];
    [seaUrchin ResourceCleanUp];
    [egg ResourceCleanUp];
    [bird ResourceCleanUp];
    [shark ResourceCleanUp];
}


@end
