//
//  Knife.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 02/06/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Status - 

#import "Knife.h"

@implementation Knife
@synthesize modelBlade, modelHandle, effectBlade, effectHandle, knife, bufferAttribs;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData 
{
    //knife starts in inventory, not on ground
    knife.visible = false; //item model visibility
    knife.marked = false; //if held in hand
    knife.enabled = false; //if currently in cutting mode (cut movement mode)
    knife.orientation = GLKVector3Make(0.0, 0.0, 0.0);
    
    [ObjectHelpers NillDropping: &knife];
}

- (void) InitGeometry
{
    //float scale = 0.5;
    float scale = 0.12;
    modelBlade = [[ModelLoader alloc] initWithFileScale: @"knife_blade.obj" : scale]; //in dynamic array to shange textures
    modelHandle = [[ModelLoader alloc] initWithFileScale: @"knife_handle.obj" : scale];
    
    //handle
    bufferAttribs.vertexCount = modelHandle.mesh.vertexCount;
    bufferAttribs.indexCount = modelHandle.mesh.indexCount;
    //blade
    bufferAttribs.vertexDynamicCount = modelBlade.mesh.vertexCount;
    bufferAttribs.indexDynamicCount = modelBlade.mesh.indexCount;
    

    //parameters
    //displace of knife in local space from character center
    initialDisplacePosition = GLKVector3Make(-0.15, -0.10, 0.32);
    //displace of knife tip in knife local space
    initialKnifeTip = GLKVector3Make(0.0, 0.0, modelBlade.AABBmax.z); //TODO check if knife tip is roght
    initialExtraAngleX = -M_PI_4; //knife angle around X axis (extra tilt)
    
    //bounds
    knife.boundToGround = fabs(modelBlade.AABBmax.z - modelHandle.AABBmin.z) / 2.0 - 0.04; //axtra space to ground, remove a bi so it stick in ground
    //[model  AssignBounds: &knife : 0];
    knife.crRadius = knife.bsRadius = modelBlade.AABBmax.z;
}

- (void) SetupRendering
{
    //load textures
    //blade
    GLuint texIDBlade = [[SingleGraph sharedSingleGraph] AddTexture:[modelBlade.materials objectAtIndex: 0] : YES];
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    //handle
    GLuint texIDHandle = [[SingleGraph sharedSingleGraph] AddTexture:[modelHandle.materials objectAtIndex: 0] : YES];
   // glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    //glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    //init shaders
    //blade
    self.effectBlade = [[GLKBaseEffect alloc] init];
    self.effectBlade.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectBlade.texture2d0.enabled = GL_TRUE;
    self.effectBlade.useConstantColor = GL_TRUE;
    self.effectBlade.texture2d0.name = texIDBlade;
    
    //handle
    self.effectHandle = [[GLKBaseEffect alloc] init];
    self.effectHandle.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectHandle.texture2d0.enabled = GL_TRUE;
    self.effectHandle.useConstantColor = GL_TRUE;
    self.effectHandle.texture2d0.name = texIDHandle;
}

//handle
//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    bufferAttribs.firstVertex = *vCnt;
    bufferAttribs.firstIndex = *iCnt;
    for (int n = 0; n < modelHandle.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelHandle.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelHandle.mesh.verticesT[n].tex;
        //mesh.verticesT[*vCnt].tex.s += 0.8;
        
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < modelHandle.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelHandle.mesh.indices[n] + bufferAttribs.firstVertex;
        *iCnt = *iCnt + 1;
    }
}

//blade, for dynamic texture

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    bufferAttribs.firstDynamicVertex = *vCnt;
    bufferAttribs.firstDynamicIndex = *iCnt;
    for (int n = 0; n < modelBlade.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelBlade.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelBlade.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < modelBlade.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelBlade.mesh.indices[n] + bufferAttribs.firstDynamicVertex;
        *iCnt = *iCnt + 1;
    }
}


- (void) Update: (float) dt : (GLKMatrix4*) modelviewMat : (Character*) character : (GLKVector4) daytimeColor : (Particles*) particles : (SmallPalm*) smallpalms : (Interaction*) inter: (GeometryShape*) meshDynamic
{
    [ObjectHelpers UpdateDropping: &knife : dt : inter : -1 : -1];
    
    //when removed from hand, return in basic state
    if(knife.visible && knife.marked && character.handItem.ID != ITEM_KNIFE)
    {
        knife.marked = false; //not in hand
        knife.visible = false; //not anywhere but inventory
        knife.enabled = false; //stop cut movement
        
        [particles.shineSmallPrt End];
    }
    
    BOOL justPutInHand = false;
    //show knife when it is put in hand
    if(!knife.visible && !knife.marked && character.handItem.ID == ITEM_KNIFE)
    {
        knife.visible = true; //item model visibility
        knife.marked = true; //if held in hand
        knife.enabled = false; //stop cut movement
        
        justPutInHand = true;
    }

    if(knife.visible)
    {
        GLKVector3 extraRotation = GLKVector3Make(initialExtraAngleX, 0.0, 0.0); //extra rotation of knife around x and y axis
        if(knife.marked) //in hand
        {
            GLKVector3 displacePosition = initialDisplacePosition; //knife position displace (relative space)
            
            if(knife.enabled) //cut motion
            {
                //update pareameters of knife positiona and angle during cut
                [self UpdateCut: dt : character : &displacePosition : &extraRotation];
            }
            
            //displace of knife in hand
            [CommonHelpers RotateX: &displacePosition : -character.camera.xAngle]; //displacement should always match rotation
            [CommonHelpers RotateY: &displacePosition : character.camera.yAngle]; //displacement should always match rotation
            //parameters to determine knife position and orientation
            knife.orientation.x = -character.camera.xAngle + extraRotation.x; //always face camera +  extra tilt
            knife.orientation.y = character.camera.yAngle; //always face camera
            knife.position = GLKVector3Add(character.camera.position, displacePosition);
            
            if(knife.enabled) //cut motion
            {
                //update also knife tip
                GLKVector3 knifeTip = [self GetKnifeTip:-extraRotation.y];
                
                //cutting check here
                GLKVector3 cutObjOrigin;
                if(!somethingCut && [smallpalms CheckBranchCutting: knifeTip : &cutObjOrigin])
                {
                    [particles.smallPalmExplosionPrt Start: cutObjOrigin]; //self ending, does not rquire ending
                    somethingCut = true; //allow to cut only one thing at a time
                }
            }
            
            //move knife tip shining particle together with kife if character moves
            if(particles.shineSmallPrt.started)
            {
                int particleIndex = 0;
                [particles.shineSmallPrt AssignPosition: particleIndex : [self GetKnifeTip: -extraRotation.y]];
            }
            
            //when knife is just put in hand
            if(justPutInHand)
            {
                //set initial backup
                backupPosition = knife.position;
                //shine the knife tip
                [particles.shineSmallPrt Start: [self GetKnifeTip: -extraRotation.y]];
            }
            
            //update dynamic vertex buffer for texture coordintes
            [self UpdateDynamicVertexArray:  meshDynamic];
            
            //update knife previous poition
            backupPosition = knife.position;
        }else //om ground
        {
            //gournd glow while walking
            if([character IsMoving])
            {
                [particles.shineMediumPrt Start: knife.position]; //self ending, does not rquire ending
            }
        }
        
        //matrix
        knife.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, knife.position);
        knife.displaceMat = GLKMatrix4RotateY(knife.displaceMat, knife.orientation.y);
        knife.displaceMat = GLKMatrix4RotateX(knife.displaceMat, knife.orientation.x);
        knife.displaceMat = GLKMatrix4RotateY(knife.displaceMat, -extraRotation.y);
        
        self.effectBlade.constantColor = daytimeColor;
        self.effectHandle.constantColor = daytimeColor;
    }
}


//handle
- (void) Render
{
    if(knife.visible)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace:NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
        [[SingleGraph sharedSingleGraph] SetBlend:NO];
        
        self.effectHandle.transform.modelviewMatrix = knife.displaceMat;
        [self.effectHandle prepareToDraw];
    
        glDrawElements(GL_TRIANGLES, modelHandle.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + modelHandle.patches[0].startIndex) * sizeof(GLushort)));
    }
}

//blade dynamic texture coordinates
- (void) RenderDynamic
{
    if(knife.visible)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace:NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
        [[SingleGraph sharedSingleGraph] SetBlend:NO];
        
        self.effectBlade.transform.modelviewMatrix = knife.displaceMat;
        [self.effectBlade prepareToDraw];
        
        glDrawElements(GL_TRIANGLES, modelBlade.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstDynamicIndex + modelBlade.patches[0].startIndex) * sizeof(GLushort)));
    }
}


- (void) ResourceCleanUp
{
    self.effectHandle = nil;
    self.effectBlade = nil;
    [modelHandle ResourceCleanUp];
    [modelBlade ResourceCleanUp];
}

#pragma mark - Action functions

//cut action with a knife
- (void) StartCut
{
    if(!knife.enabled) // not cutting
    {
        knife.enabled = true; //set start of cut motion
        knife.moveTime = 0.4; //time of cut
        knife.timeInMove = 0;
        somethingCut = false;
    }
}

//update cut function (self ending)
//calculated and returned following  variables
//displacePosition - position of knife
//motionAngle - extra angle around x and y angles
- (void) UpdateCut: (float) dt : (Character*) character : (GLKVector3*) displacePosition : (GLKVector3*) motionAngle
{
    if(knife.enabled) //in motion
    {
        //use sin so actions seem smoothe
        float lerpValueSinPi = sinf([CommonHelpers ValueInNewRange: 0.0 : knife.moveTime : 0.0 : M_PI : knife.timeInMove]);
        float lerpValueSin2Pi = sinf([CommonHelpers ValueInNewRange: 0.0 : knife.moveTime : 0.0 : 2*M_PI : knife.timeInMove]);
        
        //-move knife forward and back
        float strikeDistZ = 0.35; //0.4;
        //use sin to simulate forward and back movement, because we need value going from 0 to 1 to 0
        displacePosition->z = [CommonHelpers Lerp: initialDisplacePosition.z :initialDisplacePosition.z + strikeDistZ :lerpValueSinPi];
        
        //-move knife sideways and back
        float strikeDistX = 0.2;
        //use sin to simulate left and right movement
        displacePosition->x = [CommonHelpers Lerp: initialDisplacePosition.x :initialDisplacePosition.x - strikeDistX :lerpValueSin2Pi];
        
        //-straighten knife when cutting, modify X angle
        motionAngle->x = [CommonHelpers Lerp: initialExtraAngleX : 0.0 :lerpValueSinPi];
        
        //-turn knife around y while cutting
        float offsetYAngleMax = 0.7;
        motionAngle->y = [CommonHelpers Lerp: 0.0 : offsetYAngleMax : lerpValueSin2Pi];
        
        knife.timeInMove += dt;
        if(knife.timeInMove > knife.moveTime)
        {
            knife.enabled = false; //set end of cut motion
        }
    }
}

//get knife tip position
- (GLKVector3) GetKnifeTip: (float) extraOrientationY
{
    GLKVector3 knifeTip = initialKnifeTip;; //point against to check for cutting during cutting
    [CommonHelpers RotateY: &knifeTip : extraOrientationY];
    [CommonHelpers RotateX: &knifeTip : knife.orientation.x];
    [CommonHelpers RotateY: &knifeTip : knife.orientation.y];
    return GLKVector3Add(knife.position, knifeTip);
}


//update knife texture coordinates
- (void) UpdateDynamicVertexArray: (GeometryShape*) mesh
{
    int vCnt = bufferAttribs.firstDynamicVertex;

    if(knife.visible)
    {
        //make movement vetor and tur it to bas eposition for us to read components
        GLKVector3 knifeMovementVector = GLKVector3Subtract(knife.position, backupPosition);
        [CommonHelpers RotateY: &knifeMovementVector : -knife.orientation.y];

        for (int n = 0; n < modelBlade.mesh.vertexCount; n++)
        {
            //update textures to knife rotation angle
            mesh.verticesT[vCnt].tex.t -= knifeMovementVector.z / 15.0;
            mesh.verticesT[vCnt].tex.s += knifeMovementVector.x;
            
            vCnt++;
        }
    }
}

#pragma mark - Picking / Dropping function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter : (Particles*) particles
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    
    if(knife.visible && !knife.marked)
    {
        resultBool = [CommonHelpers IntersectLineSphere: knife.position: knife.bsRadius:
                                                charPos: pickedPos: pickDistance];
        
        if(resultBool)
        {
            returnVal = 2;
            //it can be held in hand so first try to put in hand
            if([character PickItemHand: inter : ITEM_KNIFE])
            {
                returnVal = 1;
                knife.visible = false;
                [particles.shineMediumPrt End];
            }else
            {
                //if hand was not empty, try adding to inventory
                if([character.inventory AddItemInstance: ITEM_KNIFE]) //succesfully added
                {
                    returnVal = 1;
                    knife.visible = false;
                    [particles.shineMediumPrt End];
                }
            }
        }
    }
    
    return returnVal;
}


//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos : (Terrain*) terr : (Character*) character : (Interaction*) intct  : (Interface*) inter
{
    if([self IsPlaceAllowed: placePos: terr: intct])
    {
        //find some already picked item, assign coords and make visible
        if(!knife.visible)
        {
            knife.position = placePos;
            knife.position.y += knife.boundToGround;
            knife.visible = true;
            
            //orientation maches user
            GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
            knife.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
            knife.orientation.x = M_PI_2;
            knife.orientation.z = 0;
            //[terr AdjustModelEndPoints: &knife: model];
            
            //this should be called after AdjustModelEndPoints because in that function position.y is altered
            [ObjectHelpers StartDropping: &knife];
            
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
        }
       
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        if(![character.inventory PutItemInstance: ITEM_KNIFE : character.inventory.grabbedItem.previousSlot])
        {
            //this case happens when spear was in hand, inventory full and tried to place spear on ground where not allowed
            [character PickItemHand: inter : ITEM_KNIFE];
        }
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct
{
    if(![intct FreeToDrop: placePos])
    {
        return NO;
    }
    
    return YES;
}


#pragma mark - Touch functions

- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character
{
    BOOL retVal = NO;
    
    if([intr IsKnifeButtTouched: tpos] && !knife.enabled)
    {
        //in this case action button is for action
        Button *actionButt = [intr.overlays.interfaceObjs objectAtIndex: INT_ACTION_BUTT];
        [actionButt PressBegin: touch];
    
        if(knife.marked)
        {
            [self StartCut];
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_SPEAR];
        }
        
        retVal = YES;
    }
    
    return retVal;
}

@end
