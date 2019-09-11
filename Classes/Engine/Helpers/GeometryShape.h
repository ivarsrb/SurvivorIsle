//
//  GeometryShape.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Structure and helper functions to set Yp opengl geometry data, and pass to graphics addapter


#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"

@interface GeometryShape : NSObject
{
    enum enumVertexStruct vertStructType; //what typer of vertex strucure mesh will hold
    enum enumGeomDataSets dataSetType; //wether vertex only, or vertex/index set used
    enum enumDrawType drawType; //static or dynami draw buffers
    int vertexCount;
    int indexCount;
    //vertex structure 
    int vertStructSize;
    int positionStructSize;
    int colorStructSize;
    //draw usage
    GLenum drawUsage;
    GLenum drawUsagePosition;
    GLenum drawUsageColor;
    //interleived arrays
    SVertexColor *verticesC; //vertice variant wthout textures
    SVertexTex *verticesT; //vertice variant wthout color
    SVertexColorTex *vertices; //standard variant
    SVertexColorTex2 *vertices2; //standard variant + second texture stage
    //separate arrays
    GLKVector3 *position; //only position vertcies
    SColor *color; //only color
    
    GLushort *indices;
    
    GLKMatrix4 displaceMat; //modelview matrix for placing/animating movable objects
@public
    //opengl geometry store
    GLuint vertexArray;
    //for interlieved data
    GLuint vertexBuffer;
    //for separate data
    GLuint vertexBufferPosition;
    GLuint vertexBufferColor;
    
    GLuint indexBuffer;
}
@property (nonatomic) enum enumVertexStruct vertStructType;
@property (nonatomic) enum enumGeomDataSets dataSetType;
@property (nonatomic) enum enumDrawType drawType;

@property (nonatomic) int vertexCount;
@property (nonatomic) int indexCount;

@property (nonatomic) int vertStructSize;
@property (nonatomic) int positionStructSize;
@property (nonatomic) int colorStructSize;

@property (nonatomic) GLenum drawUsage;
@property (nonatomic) GLenum drawUsagePosition;
@property (nonatomic) GLenum drawUsageColor;

@property (nonatomic) SVertexColor *verticesC; 
@property (nonatomic) SVertexTex *verticesT;
@property (nonatomic) SVertexColorTex *vertices; 
@property (nonatomic) SVertexColorTex2 *vertices2; 
@property (nonatomic) GLKVector3 *position; 
@property (nonatomic) SColor *color;

@property (nonatomic) GLushort *indices;

@property (nonatomic) GLuint vertexArray;
@property (nonatomic) GLuint vertexBuffer;
@property (nonatomic) GLuint vertexBufferPosition;
@property (nonatomic) GLuint vertexBufferColor;
@property (nonatomic) GLuint indexBuffer;

@property (nonatomic) GLKMatrix4 displaceMat;

//these functions are not mandatory, if data is intialized manually
- (void) CreateVertexIndexArrays;
- (void) InitGeometryBeffers;
- (void) WriteAllToVertexBuffer;
//- (void) UpdateVertexBuffer:(int) startIndex:(int) vertCount;
- (void) ResourceCleanUp;

@end
