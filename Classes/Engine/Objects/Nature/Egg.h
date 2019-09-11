//
//  Egg.h
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 22/09/15.
//  Copyright © 2015 Ivars Rusbergs. All rights reserved.
//
// Solid interactive object
// NOTE: nest also included here

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleSound.h"
#import "ModelLoader.h"
#import "CommonHelpers.h"
#import "Leaves.h"
#import "Character.h"

@interface Egg : NSObject
{
    int count;
    SModelRepresentation *collection;
    //egg/ nest model
    ModelLoader *model;
    //effect
    GLKBaseEffect *effect;
    //textures
    GLuint *texIDs;
    
    SIndVertAttribs bufferAttribs;
}

@property (strong, nonatomic) ModelLoader *model;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) SIndVertAttribs bufferAttribs;
@property (readonly, nonatomic) SModelRepresentation *collection;
@property (readonly, nonatomic) int count;


- (void) ResetData: (Leaves*) leaves;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character;
- (void) Render;
- (void) ResourceCleanUp;

- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos :  (Inventory*) inv;
@end
