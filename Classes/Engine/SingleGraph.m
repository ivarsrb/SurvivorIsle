//
//  SingleGraph.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/6/13.
//
// STATUS: OK

#import "SingleGraph.h"

@implementation SingleGraph

@synthesize textures, screen, projMatrix, projMatrixOrtho;

SINGLETON_GCD(SingleGraph);

- (id) init
{
    if ((self = [super init]))
    {
        textures = [[NSMutableDictionary alloc] init];
        
        //default states
        blendEnabled = NO;
        depthTestEnabled = NO; //must be enabled in opengl setup routine
        cullFaceEnabled = NO;
        depthMaskEnabled = YES;
        
        blendFunc = F_GL_UNKNOWN;
    }
    return self;
}

#pragma mark -  Screen, projection parameters

//set screen relative and screen points size
- (void) SetScreenParameters: (CGSize) boudSize
{
    //determine screen parameters
    screen.points.size = boudSize;
    screen.relative.size.width = fabsf(screen.points.size.width / (float) screen.points.size.height );
    screen.relative.size.height = 1.0;    
}

//sets up projection matrices - ortho and perspective
//NOTE: set this before initializing scenes and afer screen parameters are set
- (void) SetUpProjectionMatrices
{
    float aspect = screen.relative.size.width;
    
    float fieldOfViewY;
    //field of view could be different onm each device
    switch ([[SingleDirector sharedSingleDirector] deviceType])
    {
        case DEVICE_IPHONE_CLASSIC:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPHONE_RETINA:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPHONE_5:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPAD_CLASSIC:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPAD_RETINA:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPHONE_6:
            fieldOfViewY = 60.0;
            break;
        case DEVICE_IPHONE_6_PLUS:
            fieldOfViewY = 60.0;
            break;
        default:
            fieldOfViewY = 60.0; //defauilt degrees
            break;
    }
    
    //cosest and Farthest visible distances
    float closestVis = 0.01;
    float farthestVis = 500.0;
    
    projMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fieldOfViewY), aspect, closestVis, farthestVis);
    //(left,right, bottom,top,near far)
    projMatrixOrtho = GLKMatrix4MakeOrtho(0, aspect, 1, 0, 0, 1);
}


#pragma mark -  Texture management


//Add texture. Add only if texture with name does not exist
//file - full filename, mipmaps - lYES-if mipmaps needed
//returns ID (name) of added texture, or existing texture if already existed
//NOTE: options are not compared when comparing textures
- (GLuint) AddTexture:(NSString*) file: (BOOL) mipmaps: (BOOL) originBottLeft
{
    //texture already exists
    if([textures objectForKey:file])
    {
       // NSLog(@"texture reused %@", file);
        return [self TextureName:file];
    }else
    {
        //add new texture
        
        NSArray *fileParts = [file componentsSeparatedByString:@"."];
        NSString* filePath = [[NSBundle mainBundle] pathForResource:[fileParts objectAtIndex:0] ofType:[fileParts objectAtIndex:1]];
        
        //loading options
        NSError *error;
        NSDictionary *options = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                     [NSNumber numberWithBool:originBottLeft],
                                                                     [NSNumber numberWithBool:mipmaps],
                                                                     
                                                                     //to get correct transaprency on simulator
                                                                     //needs to be YES, but for clouds - NO
                                                                    // [NSNumber numberWithBool:  !([file caseInsensitiveCompare:@"cloud_atlas._png"] == NSOrderedSame)  ],
                                                                     
                                                                     nil]
                                                            forKeys:[NSArray arrayWithObjects:
                                                                     GLKTextureLoaderOriginBottomLeft,
                                                                     GLKTextureLoaderGenerateMipmaps,
                                                                    
                                                                     //GLKTextureLoaderApplyPremultiplication,
                                                                    
                                                                     nil]];
        //NSLog(@"%@", file);
        
        //load        
        GLKTextureInfo *tempTex = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:&error];
        
        if (error) {
            //NSLog(@"Error loading texture : %@",error);
        }
        
        //add to array
        [textures setObject:tempTex forKey:file];
        
        return tempTex.name;
    }
}

//when default bottom left origin is YES
- (GLuint) AddTexture:(NSString*) file: (BOOL) mipmaps
{
    return [self AddTexture:file :mipmaps :YES];
}

//return texture identifier
- (GLuint) TextureName:(NSString*) file
{
    GLKTextureInfo *tempTex = [textures objectForKey:file];
    return tempTex.name;
}

//delete texture
/*
#NOTE: untested
- (void) DeleteTexture:(NSString*) file
{
    GLuint name = [self TextureName:file];
    glDeleteTextures(1, &name);
    [textures removeObjectForKey:file];
}
*/

#pragma mark -  State management

//set state before every drawing, it will automatically check and set when needed

//assign "state", if already is in this mode - skip and return false
//if YES is passed, blend function also must be determined there
- (BOOL) SetBlend: (BOOL) state
{
    //return true;
    
    if(blendEnabled != state)
    {
        blendEnabled = state;
        
        if(blendEnabled)
        {
            glEnable(GL_BLEND);
        }else
        {
            glDisable(GL_BLEND);
        }
        
        //NSLog(@"Blending changed %d", blendEnabled);
        
        return YES;
    }else
    {
        return NO;
    }
}

//assign "state", if already is in this mode - skip and return false 
- (BOOL) SetDepthTest: (BOOL) state
{
    //return YES;
    
    if(depthTestEnabled != state)
    {
        depthTestEnabled = state;
        
        if(depthTestEnabled)
        {
            glEnable(GL_DEPTH_TEST);
        }else
        {
            glDisable(GL_DEPTH_TEST);
        }
        
        //NSLog(@"Depth test changed %d",depthTestEnabled);
        
        return YES;
    }else
    {
        return NO;
    }
}


//assign "state", if already is in this mode - skip and return false
- (BOOL) SetCullFace: (BOOL) state
{
    //return true;
    
    if(cullFaceEnabled != state)
    {
        cullFaceEnabled = state;
        
        if(cullFaceEnabled)
        {
            glEnable(GL_CULL_FACE);
        }else
        {
            glDisable(GL_CULL_FACE);
        }
        
        //NSLog(@"Cull face changed %d",cullFaceEnabled);
        
        return YES;
    }else
    {
        return NO;
    }
}


//assign "state", if already is in this mode - skip and return false
- (BOOL) SetDepthMask: (BOOL) state
{
    //return true;
    
    if(depthMaskEnabled != state)
    {
        depthMaskEnabled = state;
        
        if(depthMaskEnabled)
        {
            glDepthMask(GL_TRUE);
        }else
        {
            glDepthMask(GL_FALSE);
        }
        
        //NSLog(@"Depth mask changed %d",depthMaskEnabled);
        
        return YES;
    }else
    {
        return NO;
    }
}

//set default blend function, it must be set before anything else is drawn
- (void) SetDefaultBlendFunc: (enumBlendFunc) func
{
    switch (func) {
        case F_GL_ONE:
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case F_GL_SRC_ALPHA:
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case F_GL_SRC_ALPHA_ONE:
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            break;
        default:
            break;
    }
    
    blendFunc = func;
}

//set blend func, will set only if not already in this function. return yes if changed
- (BOOL) SetBlendFunc: (enumBlendFunc) func
{
    if(blendFunc != func)
    {
        [self SetDefaultBlendFunc:func];
        
        return YES;
    }else
    {
        return NO;
    }
}


- (void) CleanUpGraph
{
    
}

@end
