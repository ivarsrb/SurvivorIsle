//
//  Raft.h
//  Island survival
//
//  Created by Ivars Rusbergs on 7/4/13.
//
// Excape raft management

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "Terrain.h"
#import "Log.h"
#import "Character.h"
#import "Interface.h"
#import "Ocean.h"
#import "Environment.h"
#import "Particles.h"

@interface Raft : NSObject
{
    SModelRepresentation raft;
    
    ModelLoader *raftModel;
    ModelLoader *sailModel;
    
    //effect
    GLKBaseEffect *effect;
    
    //texture
    GLuint *texIDsRaft;
    GLuint texIDSail;
    GLuint ghostTex;
    //objects
    NSMutableArray *objectIDs; //store object names and their numbers (separated by _)
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int vertexDynamicCount; //how many vertixes are stored from this class into global dynamic array
    int indexDynamicCount;
    
    int firstIndexRaft;
    int firstIndexSail;
    
    int firstVertexSail;
    
    //parameters
    enumRaftStates state; 
    SLimitedInt logCount;//how many logs are attached to raft at this moment and maximal value
    BOOL floating; //if raft is pushed into ocean and floating
    BOOL pushedInWater;// is set to true, whan raft is pushed in water
    float gameEndingDistance; //how far from island raft gow until game is automatically ended
    float sailSwayTime; //used to add swaying time for sail
    GLKVector3 mastOrigin; //place where sail will be attached to 
    
    //for splashing (splashing is in ocean module)
    GLKVector3 leftSplashPoint;
    GLKVector3 rightSplashPoint;
}

@property (readonly, nonatomic) SModelRepresentation raft;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) ModelLoader *sailModel;
@property (strong, nonatomic) ModelLoader *raftModel;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int vertexDynamicCount;
@property (readonly, nonatomic) int indexDynamicCount;
@property (readonly, nonatomic) enumRaftStates state;
@property (readonly, nonatomic) NSMutableArray *objectIDs;
@property (readonly, nonatomic) BOOL floating;
@property (readonly, nonatomic) BOOL pushedInWater;
@property (readonly, nonatomic) GLKVector3 leftSplashPoint;
@property (readonly, nonatomic) GLKVector3 rightSplashPoint;

- (id) initWithObjects: (Ocean*) ocean;
- (void) ResetData;
- (void) InitGeometry: (Ocean*) ocean;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) UpdateDynamicVertexArray:(GeometryShape*) mesh : (float) dt;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Interface*) intr : (Terrain*) terr : (Ocean*) ocean : (Environment*) env : (GeometryShape*) meshDynamic : (Particles*) particles;
- (void) Render;
- (void) RenderDynamic;
- (void) RenderTransparent;
- (void) ResourceCleanUp;

- (void) AddLog: (Log*) logs : (Particles*) particles;
- (void) AddSail : (Particles*) particles;
- (BOOL) PointOnRaft: (GLKVector3) point;
- (BOOL) ObjectVisible:(int) i;
- (BOOL) ObjectVisibleAsGhost: (int) i;
- (BOOL) PuttingLogsAllowed:(GLKVector3) point;
- (BOOL) PuttingSailAllowed:(GLKVector3) point;
- (void) AdjustEndPointsOcean: (Ocean*) ocean : (SModelRepresentation*) m;
- (GLKVector3) GetMastOrigin;

- (void) StartFloating;
- (void) UpdateFloating:(float) dt :(Ocean*) ocean : (Terrain*) terr : (Environment*) env : (Character*) character;

- (void) UpdateRaftInterface:(Character*) character : (Interface*) intr : (Terrain*) terr;

- (BOOL) TouchBegin:(UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (Terrain*) terr : (Log*) logs : (Particles*) particles;

@end
