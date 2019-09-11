//
//  GeometryShape.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "GeometryShape.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation GeometryShape
@synthesize vertStructType, drawType, dataSetType, vertexCount,verticesC,vertices, verticesT, vertices2, 
indexCount,indices, vertexArray, vertexBuffer, indexBuffer, displaceMat,position,color,vertexBufferPosition,vertexBufferColor,
vertStructSize,positionStructSize,colorStructSize,drawUsage,drawUsagePosition,drawUsageColor;


- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        //set confuguration defaults
        vertStructType = VERTEX_COLOR_TEX_STR;
        dataSetType = VERTEX_INDEX_SET;
        drawType = STATIC_DRAW;
    }
    return self;
}

//allocate vertex and index array (not mandatory)
//vertex and index count must be set before calling this method!!
- (void) CreateVertexIndexArrays;
{
    switch (vertStructType) //shoose vertex array structure type
    {
        case VERTEX_COLOR_STR:
            verticesC = malloc(vertexCount * sizeof(SVertexColor));
            break;
        case VERTEX_TEX_STR:
            verticesT = malloc(vertexCount * sizeof(SVertexTex));
            break;            
        case VERTEX_COLOR_TEX_STR:
            vertices = malloc(vertexCount * sizeof(SVertexColorTex));
            break;   
        case VERTEX_COLOR_TEX_2_STR:
            vertices2 = malloc(vertexCount * sizeof(SVertexColorTex2));
            break;       
        case VERTEX_COLOR_SEPARATE_STR:
            position = malloc(vertexCount * sizeof(GLKVector3));
            color = malloc(vertexCount * sizeof(SColor));
            break; 
    }
    if(dataSetType == VERTEX_INDEX_SET)
    {
        indices = malloc(indexCount * sizeof(GLushort)); 
    }
}

//set and fill oepngl geometry buffers (not mandatory)
- (void) InitGeometryBeffers
{
    //vertex array state collector
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);

    
    switch (vertStructType) 
    {
        case VERTEX_COLOR_STR:
            vertStructSize = sizeof(SVertexColor);
            break;
        case VERTEX_TEX_STR:
            vertStructSize = sizeof(SVertexTex);
            break;    
        case VERTEX_COLOR_TEX_STR:
            vertStructSize = sizeof(SVertexColorTex);
            break;   
        case VERTEX_COLOR_TEX_2_STR:
            vertStructSize = sizeof(SVertexColorTex2);
            break;       
        case VERTEX_COLOR_SEPARATE_STR:
            positionStructSize = sizeof(GLKVector3);
            colorStructSize = sizeof(SColor);
            break; 
    }
    
    switch (drawType)
    {
        case STATIC_DRAW:
            drawUsage = GL_STATIC_DRAW;
            break;
        case DYNAMIC_DRAW:
            drawUsage = GL_DYNAMIC_DRAW;
            break; 
        case COLOR_DYNAMIC_DRAW:
            drawUsagePosition = GL_STATIC_DRAW;
            drawUsageColor = GL_DYNAMIC_DRAW;
            break; 
    }
    
    //VBO
    if(vertStructType == VERTEX_COLOR_SEPARATE_STR) 
    {
        //separate buffers
        glGenBuffers(1, &vertexBufferPosition);
        glGenBuffers(1, &vertexBufferColor);
    }else 
    {   //for interlieved buffer
        glGenBuffers(1, &vertexBuffer);
    }

    [self WriteAllToVertexBuffer];
    
    //GLKIT to manual attribute
    //GLKVertexAttribPosition - ATTRIB_VERTEX
    //GLKVertexAttribColor - ATTRIB_COLOR
    //GLKVertexAttribTexCoord0 - ATTRIB_TEX0
    //GLKVertexAttribTexCoord1 - ATTRIB_TEX1
    //attributes

    switch (vertStructType) {
        case VERTEX_COLOR_STR:
            /*
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(0));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, BUFFER_OFFSET(sizeof(GLKVector3)));
            */
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColor, vertex));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, (const GLvoid *)offsetof(SVertexColor, color));
            
            break;
        case VERTEX_TEX_STR:
            /*
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(0));
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(sizeof(GLKVector3)));
            */
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexTex, vertex));
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexTex, tex));
            
            break;
        case VERTEX_COLOR_TEX_STR:
            /*
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(0));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, BUFFER_OFFSET(sizeof(GLKVector3))); 
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(sizeof(SVertexColor)));
            */
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex, vertex));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex, color));
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex, tex));
            
            break;
        case VERTEX_COLOR_TEX_2_STR:
           /*
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(0));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, BUFFER_OFFSET(sizeof(GLKVector3))); 
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(sizeof(SVertexColor)));   
            glEnableVertexAttribArray(ATTRIB_TEX1);
            glVertexAttribPointer(ATTRIB_TEX1, 2, GL_FLOAT, GL_FALSE, vertStructSize, BUFFER_OFFSET(sizeof(SVertexColorTex)));   
        */
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex2, vertex));
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex2, color));
            glEnableVertexAttribArray(ATTRIB_TEX0);
            glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex2, tex));
            glEnableVertexAttribArray(ATTRIB_TEX1);
            glVertexAttribPointer(ATTRIB_TEX1, 2, GL_FLOAT, GL_FALSE, vertStructSize, (const GLvoid *)offsetof(SVertexColorTex2, tex2));
            break;
 
        case VERTEX_COLOR_SEPARATE_STR:
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferPosition);
            glEnableVertexAttribArray(ATTRIB_VERTEX);
            glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, positionStructSize, BUFFER_OFFSET(0));
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferColor);
            glEnableVertexAttribArray(ATTRIB_COLOR);
            glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, colorStructSize, BUFFER_OFFSET(0));
            break;
    }
    
    
    if(dataSetType == VERTEX_INDEX_SET)
    {
        //IBO
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexCount * sizeof(GLushort), indices, GL_STATIC_DRAW);
        /*
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexCount * sizeof(GLushort), 0, drawUsage);
        GLvoid* vboBuffer = glMapBufferOES(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY_OES); // transfer the vertex data to the VBO 
        memcpy(vboBuffer, indices,  indexCount * sizeof(GLushort));
        glUnmapBufferOES(GL_ELEMENT_ARRAY_BUFFER); 
        */
        
        //NSLog(@"%lu",indexCount * sizeof(GLushort));
    }
    glBindVertexArrayOES(0);
}

//updates only part of vertex buffer and writes to it
//!!!! Works only with interlieved arrays
/*
- (void) UpdateVertexBuffer:(int) startIndex:(int) vertCount: somedataparam
{
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

    switch (vertStructType) 
    {
        case VERTEX_COLOR_STR:
            glBufferSubData(GL_ARRAY_BUFFER, startIndex * vertStructSize, vertCount * vertStructSize, verticesC);
            break;
        case VERTEX_TEX_STR:
            glBufferSubData(GL_ARRAY_BUFFER, startIndex * vertStructSize, vertCount * vertStructSize, verticesT);
            break;
        case VERTEX_COLOR_TEX_STR:
            glBufferSubData(GL_ARRAY_BUFFER, startIndex * vertStructSize, vertCount * vertStructSize, vertices);
            break;  
        case VERTEX_COLOR_TEX_2_STR:
            glBufferSubData(GL_ARRAY_BUFFER, startIndex * vertStructSize, vertCount * vertStructSize, vertices2);
            break;      
        default:
            break;
    }
}
*/

//rewrites all data that currently are in vertex array to vertex buffer
- (void) WriteAllToVertexBuffer
{
    if(vertStructType != VERTEX_COLOR_SEPARATE_STR)
    {
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    }
    
    switch (vertStructType) 
    {
        case VERTEX_COLOR_STR:
            glBufferData(GL_ARRAY_BUFFER, vertexCount * vertStructSize, verticesC, drawUsage);
            break;
        case VERTEX_TEX_STR:
            glBufferData(GL_ARRAY_BUFFER, vertexCount * vertStructSize, verticesT, drawUsage);
            break;
        case VERTEX_COLOR_TEX_STR:
            glBufferData(GL_ARRAY_BUFFER, vertexCount * vertStructSize, vertices, drawUsage);
            break;  
        case VERTEX_COLOR_TEX_2_STR:
            glBufferData(GL_ARRAY_BUFFER, vertexCount * vertStructSize, vertices2, drawUsage);
            break;      
        case VERTEX_COLOR_SEPARATE_STR:
            //position
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferPosition);
            glBufferData(GL_ARRAY_BUFFER, vertexCount * positionStructSize, position, drawUsagePosition);
            //color
            glBindBuffer(GL_ARRAY_BUFFER, vertexBufferColor);
            glBufferData(GL_ARRAY_BUFFER, vertexCount * colorStructSize, color, drawUsageColor);
            break; 
    }
}


//cleans up all possibly allocable resources in this class (not mandatory)
- (void) ResourceCleanUp
{
    //free opengl objects
    glDeleteVertexArraysOES(1, &vertexArray);
    
    if(vertStructType == VERTEX_COLOR_SEPARATE_STR)
    {
        glDeleteBuffers(1, &vertexBufferPosition);
        glDeleteBuffers(1, &vertexBufferColor);
    }else 
    {
        glDeleteBuffers(1, &vertexBuffer);
    }
    
    if(dataSetType == VERTEX_INDEX_SET)
    {
        glDeleteBuffers(1, &indexBuffer);
    }
    
    //free arrays
    switch (vertStructType) 
    {
        case VERTEX_COLOR_STR:
            free(verticesC);
            break;
        case VERTEX_TEX_STR:
            free(verticesT);
            break;
        case VERTEX_COLOR_TEX_STR:
            free(vertices);
            break;   
        case VERTEX_COLOR_TEX_2_STR:
            free(vertices2);
            break;  
        case VERTEX_COLOR_SEPARATE_STR:
            free(position);
            free(color);
            break;      
    }
    if(dataSetType == VERTEX_INDEX_SET)
    {
        free(indices);
    }
}


@end
