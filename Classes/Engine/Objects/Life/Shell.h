//
//  Shell.h
//  Island survival
//
//  Created by Ivars Rusbergs on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Object - shell managament
// Solid, interactive, movable object

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "Terrain.h"
#import "Inventory.h"
#import "Interaction.h"
#import "ObjectHelpers.h"


@interface Shell : NSObject
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
    
}
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int firstIndex;
@property (readonly, nonatomic) int count;

- (void) ResetData:(Terrain*) terr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter;
- (void) Render;
- (void) ResourceCleanUp;
- (void) MakeSquareAABB: (GLKVector3*) AABBmin : (GLKVector3*) AABBmax;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

@end
