//
//  Button.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Button.h"

@implementation Button
@synthesize effect, type, rect, visible, flag, selected, rotatedTexturing, indexStart, indexCount, iconFile,blendNeeded,scrolling,
            textureID ,selectedTextureID, backColor, actionTouch, flicker,manualDraw,selectedIconFile,movement,rePosition, modelviewMat, scaling;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        //effect
        //init shaders
        self.effect = [[GLKBaseEffect alloc] init];
        self.effect.useConstantColor = GL_TRUE;
        self.effect.texture2d0.enabled = GL_TRUE;
        self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrixOrtho];
        self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
        
        //set defaults
        visible = YES;
        selected = NO;
        blendNeeded = YES;
        manualDraw = NO;
        rotatedTexturing = NO;
        type = BT_ICON;
        flag = NO;
        
        //color
        backColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        
        //touch
        actionTouch = nil;
        
        //auto button
        autoButtParams.enabled = NO; //goes 'YES' after button is pressed
        autoButtParams.actionTime = 0.2; //after what time button is released
        autoButtParams.timeInAction = 0;
        
        //position to beginning
        [self SetMatrixToIdentity];
        
        //DEFAULTS
        //Maybe put in separate functions?
        //movement (from one spot to another)
        movement.actionTime = 0;
        movement.timeInAction = 0;
        movement.started = NO;
        
        //scrolling
        scrolling.started = NO;
        
        //flicker
        flicker.started = NO;
        flicker.actionTime = 0.5; //default blink duration - 0.5 seconds
        flicker.timeInAction = 0;
        flicker.type = BF_SINGLE_BLINK;
        flicker.flickerCount = 0;
        flicker.direction = YES; //default makes invisible button visible, when flickering. Put false if want to set otherwise
        
        //scaling
        scaling.started = NO;
        scaling.actionTime = 0.5; //default scaling duration - 0.5 seconds
        scaling.timeInAction = 0.0;
        scaling.maxScale = 1.0; //basic scale nothing will be scaled
    }
    return self;
}

#pragma mark - Geometry/draw functions

//initialize Button geometry, place in global array starting with startIndex
//returns number of final index in array
- (int) InitGeometry: (GeometryShape*) mesh: (int) startIndex
{
    if(type != BT_AREA)
    {
        float x = self->rect.relative.origin.x;
        float y = self->rect.relative.origin.y;
        float height = self->rect.relative.size.height;
        float width = self->rect.relative.size.width;
        
        self->indexStart = startIndex;

        
        //vertices
        mesh.verticesT[startIndex].vertex = GLKVector3Make(x, y, interZval);
        mesh.verticesT[startIndex+1].vertex = GLKVector3Make(x, y + height, interZval);
        mesh.verticesT[startIndex+2].vertex = GLKVector3Make(x + width, y, interZval);
        mesh.verticesT[startIndex+3].vertex = GLKVector3Make(x + width, y + height, interZval);
        
        //texture coords
        if(!self.rotatedTexturing)
        {
            //not rotated texture coordinates (starts left top)
            mesh.verticesT[startIndex].tex = GLKVector2Make(0.0, 0.0);
            mesh.verticesT[startIndex+1].tex = GLKVector2Make(0.0, 1.0);
            mesh.verticesT[startIndex+2].tex = GLKVector2Make(1.0, 0.0);
            mesh.verticesT[startIndex+3].tex = GLKVector2Make(1.0, 1.0);
        }else
        {
            //90 degrees to right rotated texture
            mesh.verticesT[startIndex].tex = GLKVector2Make(0.0, 1.0);
            mesh.verticesT[startIndex+1].tex = GLKVector2Make(1.0, 1.0);
            mesh.verticesT[startIndex+2].tex = GLKVector2Make(0.0, 0.0);
            mesh.verticesT[startIndex+3].tex = GLKVector2Make(1.0, 0.0);
        }
        
        startIndex += 4;
        
        self->indexCount = startIndex - self->indexStart;
    }
    return startIndex;
}

//load texture and assign ID
//texture origin will be top left
- (void) LoadTextures
{
    if(type != BT_AREA)
    {
        self.textureID = [[SingleGraph sharedSingleGraph] AddTexture: self.iconFile: NO: NO];
        
        if(type == BT_BUTTON || type == BT_BUTTON_CUSTOM || type == BT_BUTTON_AUTO) //must be set selectedIconFile for these types
        {
            self.selectedTextureID = [[SingleGraph sharedSingleGraph] AddTexture: self.selectedIconFile: NO: NO];
        }
    }
}

//put this function always in upper class update function.
//Here all updates are made whenever needed inside function
- (void) Update: (float) dt
{
    //one that is needed will be picked automatically
    [self UpdateFlicker:dt];
    [self UpdateSlide:dt];
    [self UpdateAutoButton:dt];
    [self UpdateScaling:dt];
    //update scrolling is not here because it is not time dependant
}

//render button or Icon
- (void) Draw
{
    if(type != BT_AREA && visible && !manualDraw)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace:YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest:NO];
        [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
        [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];

        //blending
        if(blendNeeded)
        {
            [[SingleGraph sharedSingleGraph] SetBlend:YES];
        }else
        {
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
        }
        
        //texturing
        if(!selected)
        {
            self.effect.texture2d0.name = textureID;
        }else
        {
            self.effect.texture2d0.name = selectedTextureID;
        }
        
       // NSLog(@"draw id %d , %d %d", self.effect.texture2d0.name, indexStart, indexCount); //121
        
        //color
        self.effect.constantColor = backColor;
        
        //matrix
        //if we use moveemnt, use it's translation matrix instead of identity
        if(movement.started)
        {
            self.effect.transform.modelviewMatrix = movement.translation; //this transaltion is translated against modelviewMat
        }
        else if(scaling.started)
        {
            self.effect.transform.modelviewMatrix = scaling.scalingMat; //this scaling is scale against modelviewMat
        }
        else
        {
            self.effect.transform.modelviewMatrix = modelviewMat;
        }
        
        //212 4 , 124 4
        
        [self.effect prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, indexStart, indexCount);
    }
}


- (void) ResourceCleanUp
{
    self.effect = nil;
}


#pragma mark - Management functions

//if button use this to nill it in code
- (void) NillBUtton
{
    //actionTouch = nil;
    
    [self EndFlicker];
    [self StopScrolling];
    [self PressEnd];
    [self EndScaling];
}


#pragma mark - Helper functions


//weather given point (in screen points) is contained in button rect
- (BOOL) RectContains: (CGPoint) posScrPoints
{
    return CGRectContainsPoint(self.rect.points, posScrPoints);
}

//get screen point coordinates from relative coordinates
//NOTE: relative coordinates must be set before
- (void) CalcScrPointsFromRelative: (CGSize) screenSizeInPoints
{    
    rect.points = [CommonHelpers CGRRelativeToPoints:rect.relative:screenSizeInPoints];
}

//nill modelview matrix and offset position in order to be draw like is set in rect.origin
- (void) SetMatrixToIdentity
{
    //positioning, default is identity , if rePosition is set, set also modelview matrix with translation from identity
    //rect.origin is set as if identity matrix is used as modelview matrix
    //if needed to manuely move icon, use reposition and set new matrix
    //when sliding is activated, these are not used, instead matrix in slide structure is used
    rePosition = GLKVector2Make(0.0, 0.0);
    modelviewMat = GLKMatrix4Identity;
}


#pragma mark - Touhing functions

//functions to handle button press and release actions
- (void) PressBegin: (UITouch*) touch
{
    self.actionTouch = touch;
    
    //selection changes
    if(type == BT_BUTTON)
    {
        selected = YES;
    }
    
    if(type == BT_BUTTON_AUTO)
    {
        selected = YES;
        //it will be released automatically
        //fir this type, there is no need to manually call pressend (other than nilling)
        //put game actions at TouchBegin
        autoButtParams.enabled = YES;
        autoButtParams.timeInAction = 0;
    }
}

//if given touch pressed the button
- (BOOL) IsPressedByTouch: (UITouch*) touch
{
    return  (self.actionTouch != nil && [touch isEqual:self.actionTouch]);
}

//determine if button is pressed at all without comparing touch
- (BOOL) IsPressed
{
    return  self.actionTouch != nil;
}

- (void) PressEnd
{
    self.actionTouch = nil;
    //selection changes
    if(type == BT_BUTTON)
    {
        selected = NO;
    }
    
    //this is released over time or when initializing
    if(type == BT_BUTTON_AUTO)
    {
        selected = NO;
        autoButtParams.enabled = NO;
    }
}

//in single function, check if regular button is allowed to press and touched on it
- (BOOL) IsButtonPressed: (CGPoint) touchLocation
{
    return (visible  && !movement.started && ![self IsPressed] && [self RectContains: touchLocation]);
}

//points
//return center point of icon
- (CGPoint) CenterPointPoints
{
    return CGPointMake(rect.points.origin.x + [self HalfWidthPoints],rect.points.origin.y + [self HalfHeightPoints]);
}
//half sizes
- (float) HalfWidthPoints
{
    return rect.points.size.width / 2.0;
}
- (float) HalfHeightPoints
{
    return rect.points.size.height / 2.0;
}
//relative
//return center point of icon
- (CGPoint) CenterPointRelative
{
    return CGPointMake(rect.relative.origin.x + [self HalfWidthRelative],rect.relative.origin.y + [self HalfHeightRelative]);
}
//half sizes
- (float) HalfWidthRelative
{
    return rect.relative.size.width / 2.0;
}
- (float) HalfHeightRelative
{
    return rect.relative.size.height / 2.0;
}


#pragma mark - Texture assignement

/*
iPad's uses ipad textures, iPhone iphone textures
iPhone 5 and iPhone 6 use inventory board different than iphone or ipad because of long screen
Exceptions: iPhone 6 plus uses ipad retina textures except launch screen and inventory board icon
*/
 

//for regular file
//full names selection
- (void) AssignTextureNamesFull: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameiPhone5 :
                                 (NSString*) nameIpad : (NSString*) nameIpadRetina : (NSString*) nameiPhone6 : (NSString*) nameiPhone6plus
{
    self.iconFile = [self ChoseNameFromDevice: nameClassic : nameRetina : nameiPhone5 : nameIpad : nameIpadRetina : nameiPhone6 : nameiPhone6plus];
}

//commoly used older versoun without iphone 6 /6 plus selection (iphone 6 plus is set as ipad retina, iphone 6 to iphone 5 textures)
- (void) AssignTextureNames: (NSString*) nameClassic : (NSString*) nameRetina : (NSString*) nameTall :
                             (NSString*) nameIpad : (NSString*) nameIpadRetina
{
    //self.iconFile = [self ChoseNameFromDevice: nameClassic : nameRetina : nameTall : nameIpad : nameIpadRetina : nameIpadRetina];
    [self AssignTextureNamesFull: nameClassic : nameRetina : nameTall : nameIpad : nameIpadRetina : nameTall : nameIpadRetina];
}

//add single texture for every device
- (void) AssignTextureName: (NSString*) name
{
    [self AssignTextureNames: name : name : name : name : name];
}

//name of two texture where nameNormal is noprmal quality and nameHigh is double quality of that image for ipad high
//what texture assigns to what device is determined within function
- (void) AssignTextureDouble: (NSString*) nameNormal : (NSString*) nameHigh
{
    [self AssignTextureNames: nameNormal : nameNormal : nameNormal : nameHigh : nameHigh];
}
 
//3 diffrent file resolutions
//nameNonRetina - for non-retina iphone. nameRetina - iPhone and iPod etina, nameIpad - iPad (question if iPad non-retina here or in nameRetina)
/*
- (void) AssignTextureTriple: (NSString*) nameNonRetina : (NSString*) nameRetina : (NSString*) nameIpad
{
    [self AssignTextureNames: nameNonRetina : nameRetina : nameRetina : nameRetina : nameIpad];
}
*/

//--------- for selected file

//full names selection
- (void) AssignSelectedTextureNamesFull: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameiPhone5 :
                                         (NSString*) nameIpad : (NSString*) nameIpadRetina : (NSString*) nameiPhone6 : (NSString*) nameiPhone6plus
{
    self.selectedIconFile = [self ChoseNameFromDevice: nameClassic : nameRetina : nameiPhone5 : nameIpad : nameIpadRetina : nameiPhone6 : nameiPhone6plus];
}

//add textures according to device, correct file name for device picked inside
- (void) AssignSelectedTextureNames: (NSString*) nameClassic :  (NSString*) nameRetina : (NSString*) nameTall :
                                     (NSString*) nameIpad : (NSString*) nameIpadRetina
{
    //self.selectedIconFile = [self ChoseNameFromDevice: nameClassic : nameRetina : nameTall : nameIpad : nameIpadRetina];
    [self AssignSelectedTextureNamesFull: nameClassic : nameRetina : nameTall : nameIpad : nameIpadRetina : nameTall : nameIpadRetina];
}

//add single texture for every device
- (void) AssignSelectedTextureName: (NSString*) name
{
    [self AssignSelectedTextureNames: name : name : name : name : name];
}

//name of two texture where nameNormal is normal quality and nameHigh is double quality of that image for ipad high
//what texture assigns to what device is determined within function
- (void) AssignSelectedTextureDouble: (NSString*) nameNormal : (NSString*) nameHigh
{
    [self AssignSelectedTextureNames: nameNormal : nameNormal : nameNormal : nameHigh : nameHigh];
}

//3 diffrent file resolutions
//nameNonRetina - for non-retina iphone. nameRetina - iPhone and iPod etina, nameIpad - iPad (question if iPad non-retina here or in nameRetina)
/*
- (void) AssignSelectedTextureTriple: (NSString*) nameNonRetina : (NSString*) nameRetina : (NSString*) nameIpad
{
    [self AssignSelectedTextureNames: nameNonRetina : nameRetina : nameRetina : nameRetina : nameIpad];
}
*/

//get correct file name depending on device
- (NSString*) ChoseNameFromDevice: (NSString*) nameClassic : //old iphone
                                   (NSString*) nameRetina : //standrad retina iphone/ipod
                                   (NSString*) nameiPhone5 : //iphone 5
                                   (NSString*) nameIpad : //old ipads, mini
                                   (NSString*) nameIpadRetina : //newer ipads
                                   (NSString*) nameiPhone6 : //iphone 6
                                   (NSString*) nameiPhone6plus  //iphone 6 plus
{
    NSString* retName; 
    
    switch ([[SingleDirector sharedSingleDirector] deviceType])
    {
        case DEVICE_IPHONE_CLASSIC:
            retName = nameClassic;
            break;
        case DEVICE_IPHONE_RETINA:
            retName  = nameRetina;
            break;
        case DEVICE_IPHONE_5:
            retName  = nameiPhone5;
            break;
        case DEVICE_IPAD_CLASSIC:
            retName  = nameIpad;
            break;
        case DEVICE_IPAD_RETINA:
            retName  = nameIpadRetina;
            break;
        case DEVICE_IPHONE_6:
            retName  = nameiPhone6;
            break;
        case DEVICE_IPHONE_6_PLUS:
            retName  = nameiPhone6plus;
            break;
        default:
            break;
    }
    
    return retName;
}

#pragma mark - Button automatization

//Is activated after pressbegin for automatic button.
//sets back non-selected state after some time, is automatically included in update
- (void) UpdateAutoButton: (float) dt
{
    if(autoButtParams.enabled)
    {
        autoButtParams.timeInAction += dt;
        
        if(autoButtParams.timeInAction >= autoButtParams.actionTime)
        {
            [self PressEnd];
        }
    }
}

//determine weather automatically pressed button is currenlty in action - is pressed and waiting to return to basic state
- (BOOL) AutoButtonInAction
{
    return autoButtParams.enabled;
}

#pragma mark - Movement

//slide movement
//slide movement is when button slides from its position to analogue position in other screen
//direction - direction from what to what slide happens, actionTime - how long slide happens,
- (void) StartSlide:(int) direction : (float) actionTime
{
    movement.started = YES;
    movement.actionTime = actionTime;
    movement.timeInAction = 0;
    movement.type = direction;
    
    switch (movement.type)
    {
        case BS_TOP_DOWN_TO_VISIBLE:
            //MOTE: potential problems with visible, what if button need to hide after moevemtn
            visible = YES; //make visible when moving to visible area
            movement.initPos = GLKVector2Make(0, -[[SingleGraph sharedSingleGraph] screen].relative.size.height); //from here
            movement.destPos = GLKVector2Make(0, 0); //to where (offset from identity)
            break;
        case BS_RIGHT_LEFT_TO_HIDE:
            movement.initPos = GLKVector2Make(0, 0);
            movement.destPos = GLKVector2Make(-[[SingleGraph sharedSingleGraph] screen].relative.size.width, 0);
            break;
        case BS_RIGHT_LEFT_TO_VISIBLE:
            visible = YES;
            movement.initPos = GLKVector2Make([[SingleGraph sharedSingleGraph] screen].relative.size.width, 0);
            movement.destPos = GLKVector2Make(0, 0);
            break;
        case BS_LEFT_RIGHT_TO_HIDE:
            movement.initPos = GLKVector2Make(0, 0);
            movement.destPos = GLKVector2Make([[SingleGraph sharedSingleGraph] screen].relative.size.width, 0);
            break;
        case BS_LEFT_RIGHT_TO_VISIBLE:
            visible = YES; 
            movement.initPos = GLKVector2Make(-[[SingleGraph sharedSingleGraph] screen].relative.size.width, 0);
            movement.destPos = GLKVector2Make(0, 0);
            break;
        default:
            break;
    }
    //initial translation matrix when moving
    //movement.translation = GLKMatrix4MakeTranslation(movement.initPos.x, movement.initPos.y, 0);
    movement.translation =  GLKMatrix4Translate(modelviewMat, movement.initPos.x, movement.initPos.y, 0);
}

- (void) StopSlide
{
    movement.started = NO;
    
    //hide for those  gone behind
    if(movement.type == BS_RIGHT_LEFT_TO_HIDE || movement.type == BS_LEFT_RIGHT_TO_HIDE)
    {
        visible = NO;
    }
}

- (void) UpdateSlide: (float) dt
{
    if(movement.started)
    {
        float rate = 1.0 / movement.actionTime; //movement rate (from 0 to 1)
        movement.timeInAction += rate * dt;
        
        if(movement.timeInAction < 1.0)
        {
            //move
            GLKVector2 trans = GLKVector2Lerp(movement.initPos, movement.destPos, movement.timeInAction);
            //modelview matrix that is offset from identity matrix
            movement.translation =  GLKMatrix4Translate(modelviewMat, trans.x, trans.y, 0);
        }else
        {
            [self StopSlide];
        }
    }
}

#pragma mark - Scrolling

//start object scrolling
- (void) StartScrolling
{
    scrolling.started = YES;
}

- (void) StopScrolling
{
    scrolling.started = NO;
}

//NOTE: not time dependant
- (void) UpdateScrolling: (float) diffY
{
    if(scrolling.started)
    {
        //when scrolling change modelview matrix of icon
        rePosition.y += diffY;
        
        //check bounds
        float upperBound = 0;
        float lowerBound = -rect.relative.size.height + [[SingleGraph sharedSingleGraph] screen].relative.size.height;
        if(rePosition.y > upperBound) //upper limit
        {
            rePosition.y = 0;
        }else
        if(rePosition.y < lowerBound) //lower limit
        {
            rePosition.y = lowerBound;
        }
        
        modelviewMat = GLKMatrix4MakeTranslation(0, rePosition.y, 0);
    }
}


#pragma mark - Flicker action

//set button parameters to satrt blink
- (void) StartFlicker
{
    if(!flicker.started)
    {
        flicker.started = true;
        flicker.timeInAction = 0;
        visible = flicker.direction;
    }
}


//end flickering (it ends on its own, but this way can be ended force fully)
- (void) EndFlicker
{
    if(flicker.started)
    {
        flicker.started = false;
        visible = !flicker.direction;
    }
}

- (void) UpdateFlicker: (float) dt
{
    if(flicker.started)
    {
        flicker.timeInAction += dt;
        
        if(flicker.timeInAction >= flicker.actionTime)
        {
            if(flicker.type == BF_SINGLE_BLINK)
            {
                [self EndFlicker];
            }else 
            if(flicker.type == BF_DOUBLE_BLINK)
            {
                flicker.flickerCount++;
                
                //3 flickers
                //from visible to invisible
                if(flicker.flickerCount == 1)
                {
                    visible = !flicker.direction;
                    flicker.timeInAction = 0;
                }else
                //from invisible to visible
                if(flicker.flickerCount == 2)
                {
                    visible = flicker.direction;
                    flicker.timeInAction = 0;
                }else
                if(flicker.flickerCount == 3) //end flickering
                {
                    flicker.flickerCount = 0;
                    [self EndFlicker];
                }
            }else
            if(flicker.type == BF_CONTINUOUS_BLINK) //will continue to blink until EndFlicker will be called
            {
                visible = !visible;
                flicker.timeInAction = 0;
            }
        }
    }
}


#pragma mark - Scale action

//sdcaling = icon changes it scale
//set button parameters to start scaling
- (void) StartScaling
{
    if(!scaling.started)
    {
        scaling.started = true;
        scaling.timeInAction = 0;
        visible = true;
    }
}

//end scaling (it ends on its own, but this way can be ended force fully)
- (void) EndScaling
{
    if(scaling.started)
    {
        scaling.started = false;
        visible = false;
    }
}

//motion scaling from 1.0 to maxScale around center of image
- (void) UpdateScaling: (float) dt
{
    if(scaling.started)
    {
        scaling.timeInAction += dt;
        
        float baseScale = 1.0; //base scale is 1.0 no 0.0
        //continuous scale over time
        float currentScale = [CommonHelpers ValueInNewRange: 0.0 : scaling.actionTime : baseScale : scaling.maxScale : scaling.timeInAction];
        
        //we need to offset origin of icon because scaling also affects it
        float xOffset = -rect.relative.origin.x * (currentScale - baseScale); //by scaling origin is also moved so we need to shift back
        xOffset -= (rect.relative.size.width / 2.0) * (currentScale - baseScale); //we also need to shift back half size of icon while scaling
    
        float yOffset = -rect.relative.origin.y * (currentScale - baseScale);
        yOffset -= (rect.relative.size.height / 2.0) * (currentScale - baseScale);
        
        scaling.scalingMat = GLKMatrix4Translate(modelviewMat, xOffset, yOffset , 0.0); //offset origin because it shift during scaling
        scaling.scalingMat = GLKMatrix4Scale(scaling.scalingMat, currentScale, currentScale, 1.0); //scale
        
        if(scaling.timeInAction >= scaling.actionTime)
        {
            [self EndScaling];
        }
    }
}


@end
