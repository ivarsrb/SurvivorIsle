//
//  Log.h
//  Island survival
//
//  Created by Ivars Rusbergs on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "Shipwreck.h"
#import "Environment.h"
#import "Ocean.h"
#import "Terrain.h"
#import "Character.h"
#import "ObjectHelpers.h"

@interface Log : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;

    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object

    //log parameters
    SLimitedFloat release; //release of log structure
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) int firstIndex;

- (void) ResetData:(Shipwreck*) ship :(Environment*) env;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Environment*) env : (Ocean*) ocean :(Terrain*) terr : (Character*) character : (Interaction*) inter;
- (void) Render: (Character*) character;
- (void) ResourceCleanUp;

- (void) ReleaseLog:(float) dt : (Environment*) env;
- (void) MoveLogs:(float) dt : (float) curTime: (Ocean*) ocean: (Terrain*) terr;
- (void) HideLogInHand;

- (int) PickObject: (GLKVector3) charPos :(GLKVector3) pickedPos : (Character*) character: (Interface*) inter;
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*)intct : (Interface*) inter;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct;
@end
