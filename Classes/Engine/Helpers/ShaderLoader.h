//
//  ShaderLoader.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//  Loads and validates shader programms. Fills uniform values and sets attributes
//  Dedicated loading function for each shader
//  Works as class methods

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"

@interface ShaderLoader : NSObject

+ (BOOL)loadShadersMixAlpha: (GLint*) uniforms : (GLuint*) program;

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
+ (BOOL)linkProgram:(GLuint)prog;
+ (BOOL)validateProgram:(GLuint)prog;

@end
