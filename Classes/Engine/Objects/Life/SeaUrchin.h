//
//  SeaUrchin.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 15/09/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// solid, interactive object

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
#import "Character.h"

@interface SeaUrchin : NSObject
{
    int count;
    SModelRepresentation *collection;
    ModelLoader *model;
    
    //effect
    GLKBaseEffect *effect;
    
    //global index array flags
    SIndVertAttribs bufferAttribs;
    
    //character sting
    SBasicAnimation stingInterval; //varable to regulate character sting when stepping on urchin
}
@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;
@property (readonly, nonatomic) int count;

- (void) ResetData: (Terrain*) terr;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter : (Character*) character: (Interface*) intr;
- (void) Render;
- (void) ResourceCleanUp;
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

@end
