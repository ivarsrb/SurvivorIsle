//
//  SingleGraph.h
//  Island survival
//
//  Created by Ivars Rusbergs on 3/6/13.
//
// Singleton for grpahics managament
// Texture managament and rendering state managament

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleDirector.h"

//depth func types used in app
enum _enumBlendFunc
{
    F_GL_UNKNOWN, //initially we dont know
    F_GL_ONE, //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    F_GL_SRC_ALPHA, //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    F_GL_SRC_ALPHA_ONE //glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    
};
typedef enum _enumBlendFunc enumBlendFunc;


@interface SingleGraph : NSObject
{
    SScreenCoordinates screen; //screen width and heighth in points and relative length
    
    //matrix
    GLKMatrix4 projMatrix; //3d
    GLKMatrix4 projMatrixOrtho; //2d
    
    
    NSMutableDictionary *textures; //all textiure objects stored here
    
    //state managament
    BOOL blendEnabled; //if blend mode is on
    BOOL depthTestEnabled; //if depth test is set
    BOOL cullFaceEnabled; //if cull face is set
    BOOL depthMaskEnabled; //if depth mask is set
    enumBlendFunc blendFunc; //type of current blend func
}
@property (readonly, nonatomic, strong) NSMutableDictionary *textures;
@property (readonly, nonatomic) SScreenCoordinates screen;
@property (readonly, nonatomic) GLKMatrix4 projMatrix;
@property (readonly, nonatomic) GLKMatrix4 projMatrixOrtho;

+ (SingleGraph *) sharedSingleGraph;
//screen
- (void) SetScreenParameters: (CGSize) boudSize;
- (void) SetUpProjectionMatrices;
//textures
- (GLuint) AddTexture:(NSString*) file : (BOOL) mipmaps : (BOOL) originBottLeft;
- (GLuint) AddTexture:(NSString*) file : (BOOL) mipmaps;
- (GLuint) TextureName:(NSString*) file;
//states
- (BOOL) SetBlend: (BOOL) state;
- (BOOL) SetDepthTest: (BOOL) state;
- (BOOL) SetCullFace: (BOOL) state;
- (BOOL) SetDepthMask: (BOOL) state;
- (void) SetDefaultBlendFunc: (enumBlendFunc) func;
- (BOOL) SetBlendFunc: (enumBlendFunc) func;

- (void) CleanUpGraph;



@end
