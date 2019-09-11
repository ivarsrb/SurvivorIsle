//
//  Fish.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Ocean fish model
// Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "GeometryShape.h"
#import "Inventory.h"
#import "Terrain.h"
#import "Environment.h"
#import "Interface.h"
#import "Character.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "CampFire.h"

@interface Fish : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    //textures
    GLuint texID[NUM_FISH_TYPES];
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    int firstVertex;
    int numberOfIndexesperHalf;
    
    //parameters
    float floatSpeedFast;
    float wagSpeedFast;
    int uppertTimeFast;
    
    //fish area circles
    SCircle fishOuterCr;
    float fishTerrainMaxHeight;
    
    float *rotationFactor; //for vertices
}
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) float floatSpeedFast;
@property (readonly, nonatomic) float wagSpeedFast;
@property (readonly, nonatomic) int uppertTimeFast;

- (id) initWithParams:(Terrain*) terr;
- (void) ResetData;
- (void) InitGeometry:(Terrain*) terr;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) UpdateVertexArray:(GeometryShape*) mesh;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor: (Terrain*) terr:(GLKVector3) spearPos: (Interface*) inter: (Character*) character: (GeometryShape*) mesh;
- (void) Render;
- (void) ResourceCleanUp;
- (void) ResetFish: (SModelRepresentation*) c: (int) i;
- (BOOL) StrikeFishCheck: (GLKVector3) spearPos;
- (void) WagTale: (SModelRepresentation*) object: (float) wagAmplitude: (float) dt;
- (void) UpdateFish: (SModelRepresentation*) object :(float) dt:(Terrain*) terr: (Character*) character;
- (void) InitNewFishMove: (SModelRepresentation*) object: (float) speed: (float) wagSpeed: (int) upperTime;
- (void) StartRunaway: (SModelRepresentation*) object : (GLKVector3) threatPosition : (float) speed: (float) wagSpeed: (int) upperTime;
- (BOOL) AnyFishAlive:(int) fishType;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (int) droppedItemType;
- (void) PlaceObjectRawFish: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*) intct : (CampFire*) cmpFire : (int) droppedItemType;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr;
- (BOOL) IsPlaceAllowedRawFish: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;
@end
