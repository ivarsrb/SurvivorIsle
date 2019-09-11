//
//  Button.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Button and icon class ment for 2D interface

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "SingleDirector.h"
#import "GeometryShape.h"
#import "CommonHelpers.h"

@interface Button : NSObject
{
@public
    enumButtonType type;
    
    GLKBaseEffect *effect;
    
    BOOL visible; //weather button shows (if YES)
    BOOL selected; //weather button is in selected state (or pressed)
    BOOL blendNeeded; //if true, blend function is applied to button
    BOOL manualDraw;//if set to YES, button wont be drawn in loop - have to draw manually, default is FALSE
    BOOL rotatedTexturing; //if set YES, teture coordinates will be rotated 90 degrees
    BOOL flag; //use this to any task that is not specific to all button - use as you like
    SBasicAnimation autoButtParams; //parameters to manage automatic button release
    
    int indexStart; //start index/vertex for button geometry in index/vertex array
    int indexCount; //index/vertex count in buffer
    
    GLKVector4 backColor; //constant color of vertcxies
    
    //textures
    NSString *iconFile; //file name of icon
    NSString *selectedIconFile; //selected file name of icon
    GLuint textureID; //texture of icon ansd primary button
    GLuint selectedTextureID; //selected button texture
    
    //touch
    UITouch *actionTouch; //to ber able catch current touch and compare it later
    
    //positioning
    SScreenCoordinates rect; //screen coordinates of button , origin is set as if modelview matrix is identity matrix
    GLKVector2 rePosition; //offset of original text.origin coordinates
    GLKMatrix4 modelviewMat; //matrix that is identity by default, if rePosition is set, change this matrix
    
    //animation
    SButtonMovement movement; //slide
    SButtonMovement scrolling;
    SButtonFlicker flicker;
    SButtonScaling scaling;
}

@property (strong, nonatomic) GLKBaseEffect *effect;
@property (nonatomic) enumButtonType type;
@property (nonatomic) SScreenCoordinates rect;
@property (nonatomic) GLKVector2 rePosition;
@property (nonatomic) GLKMatrix4 modelviewMat;
@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL blendNeeded;
@property (nonatomic) BOOL manualDraw;
@property (nonatomic) BOOL rotatedTexturing;
@property (nonatomic) BOOL flag;
@property (nonatomic) int indexStart;
@property (nonatomic) int indexCount;
@property (nonatomic) GLKVector4 backColor;
@property (strong, nonatomic) NSString *iconFile;
@property (strong, nonatomic) NSString *selectedIconFile;
@property (nonatomic) GLuint textureID;
@property (nonatomic) GLuint selectedTextureID;
@property (strong, nonatomic) UITouch *actionTouch;
@property (nonatomic) SButtonFlicker flicker;
@property (nonatomic) SButtonMovement movement;
@property (nonatomic) SButtonMovement scrolling;
@property (nonatomic) SButtonScaling scaling;

- (void) NillBUtton;

- (void) Update: (float) dt;
- (void) Draw;
- (int) InitGeometry: (GeometryShape*) mesh : (int) startIndex;
- (void) LoadTextures;
- (void) ResourceCleanUp;

- (BOOL) RectContains: (CGPoint) posScrPoints;
- (void) CalcScrPointsFromRelative: (CGSize) screenSizeInPoints;
- (void) SetMatrixToIdentity;
- (CGPoint) CenterPointPoints;
- (float) HalfWidthPoints;
- (float) HalfHeightPoints;
- (CGPoint) CenterPointRelative;
- (float) HalfWidthRelative;
- (float) HalfHeightRelative;

- (void) PressBegin: (UITouch*) touch;
- (BOOL) IsPressedByTouch: (UITouch*) touch;
- (BOOL) IsPressed;
- (void) PressEnd;
- (BOOL) IsButtonPressed: (CGPoint) touchLocation;

- (void) AssignTextureNamesFull: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameiPhone5 :
                                 (NSString*) nameIpad : (NSString*) nameIpadRetina : (NSString*) nameiPhone6 : (NSString*) nameiPhone6plus;
- (void) AssignTextureNames: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameTall :
                             (NSString*) nameIpad : (NSString*) nameIpadRetina;
- (void) AssignTextureName: (NSString*) name;
- (void) AssignTextureDouble: (NSString*) nameNormal : (NSString*) nameHigh;
//- (void) AssignTextureTriple: (NSString*) nameNonRetina : (NSString*) nameRetina : (NSString*) nameIpad;

- (void) AssignSelectedTextureNamesFull: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameiPhone5 :
                                         (NSString*) nameIpad : (NSString*) nameIpadRetina : (NSString*) nameiPhone6 : (NSString*) nameiPhone6plus;
- (void) AssignSelectedTextureNames: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameTall :
                                     (NSString*) nameIpad : (NSString*) nameIpadRetina;
- (void) AssignSelectedTextureName: (NSString*) name;
- (void) AssignSelectedTextureDouble: (NSString*) nameNormal : (NSString*) nameHigh;
//- (void) AssignSelectedTextureTriple: (NSString*) nameNonRetina : (NSString*) nameRetina : (NSString*) nameIpad;

- (NSString*) ChoseNameFromDevice:  (NSString*) nameClassic : //old iphone
                                    (NSString*) nameRetina : //standrad retina iphone/ipod
                                    (NSString*) nameiPhone5 : //iphone 5
                                    (NSString*) nameIpad : //old ipads, mini
                                    (NSString*) nameIpadRetina : //newer ipads
                                    (NSString*) nameiPhone6 : //iphone 6
                                    (NSString*) nameiPhone6plus;  //iphone 6 plus

- (void) UpdateAutoButton: (float) dt;
- (BOOL) AutoButtonInAction;

- (void) StartSlide:(int) direction : (float) actionTime;
- (void) StopSlide;
- (void) UpdateSlide: (float) dt;

- (void) StartScrolling;
- (void) StopScrolling;
- (void) UpdateScrolling: (float) diffY;

- (void) StartFlicker;
- (void) EndFlicker;
- (void) UpdateFlicker: (float) dt;

- (void) StartScaling;
- (void) EndScaling;
- (void) UpdateScaling: (float) dt;
@end
