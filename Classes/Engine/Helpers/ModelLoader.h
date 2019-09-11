//
//  ModelLoader.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Loading models from obj file. 
// Loads vertex data, index data, texture coordinates

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "GeometryShape.h"

@interface ModelLoader : NSObject
{
    enumModelPatchTypes patchType; //default is BY_MATERIAL
    
    //with porperties
    GeometryShape *mesh;
    
    //patches are interpreted depending on patchType
    /*BY_MATERIAL- indices in patch are sorted by unique textures(materials), so patch count matches
                   count of unique textuire names
      BY_OBJECT-    indices in patch are sorted by object. Patch count matches number of objects in model */
    
    int materialCount; //number of unique textures in model
    NSMutableArray *materials; //unique texture names in model
    SModelPatch *patches; //interpreted by patch type
    
    //used when BY_OBJECT type is set
    int objectCount;
    NSMutableArray *objects; //object names from model
    NSMutableArray *matToTex; //corresponding texture names for objects (used together with *objects)
    
    //bounding
    float geomScaleFactor; //scale model geometry
    float bsRadius; //value that can be used as radius for bounding sphere (clculated by getting highest scalar vertex value)
    float crRadius; //value that is same as bsRadius, only in flat 2d plane (x and z)
    GLKVector3 AABBmin; //minimums vertice for axis-aligned bounding box
    GLKVector3 AABBmax; //maximum vertice
}

@property (readonly, nonatomic) GeometryShape *mesh;
@property (readonly, nonatomic) int materialCount;
@property (readonly, nonatomic) NSMutableArray *materials;
@property (readonly, nonatomic) SModelPatch *patches;
@property (readonly, nonatomic) int objectCount;
@property (readonly, nonatomic) NSMutableArray *objects;
@property (readonly, nonatomic) NSMutableArray *matToTex;
@property (readonly, nonatomic) float bsRadius;
@property (readonly, nonatomic) float crRadius;
@property (readonly, nonatomic) GLKVector3 AABBmin;
@property (readonly, nonatomic) GLKVector3 AABBmax;

- (id) initWithFile:(NSString*) file;
- (id) initWithFileScale:(NSString*) file : (float) scale;
- (id) initWithFileScalePatchType:(NSString*) file : (float) scale : (enumModelPatchTypes) ptype;
- (void) LoadModel:(NSString*) file;
- (void) AssignBounds: (SModelRepresentation*) instance : (float) AABBscale;
- (void) ResourceCleanUp;
@end
