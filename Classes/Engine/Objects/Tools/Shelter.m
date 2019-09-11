//
//  Shelter.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 06/05/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Status - 

#import "Shelter.h"

@implementation Shelter
@synthesize model, effect, shelter, bufferAttribs, objectIDs, state, entranceCrircle;


- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}


//data that changes from game to game
- (void) ResetData
{
    state = SS_NONE;
    shelter.position = GLKVector3Make(0, 0, 0);
    leafCount.current = 0;
    stickCount.current = 0;
    shelter.visible = false; //this is ghost visibility npot shelter visibility
    shelter.speed = 0.0; //indicator rotation variable
}


- (void) InitGeometry
{
    float scale = 1.2;
    model = [[ModelLoader alloc] initWithFileScalePatchType: @"shelter.obj" : scale : GROUP_BY_OBJECT];
    
    bufferAttribs.vertexCount = model.mesh.vertexCount;
    bufferAttribs.indexCount = model.mesh.indexCount;
    
    //NOTE: textures are not uniue in this array but respective to each object
    textures = malloc(model.objectCount * sizeof(GLuint));
    //allocate for object ids
    objectIDs = [[NSMutableArray alloc] init];
    
    //parameters
    shelter.crRadius = model.crRadius;
    leafCount.max = 7;
    stickCount.max = 3;
    entranceCrircle.radius = model.crRadius / 2.0; //circle where entrance to shelter will be, cnter is set upon placing shelter
}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    
    //---------- fill
    bufferAttribs.firstVertex = *vCnt;
    bufferAttribs.firstIndex = *iCnt;
    for (int n = 0; n < model.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = model.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  model.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < model.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  model.mesh.indices[n] + bufferAttribs.firstVertex;
        *iCnt = *iCnt + 1;
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //NOTE: textures are not uniue in this array but respective to each object
    for (int i = 0; i < model.objectCount; i++)
    {
        textures[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.matToTex objectAtIndex:i]: YES]; //rock, stick, smallpalm leaf
       // glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
       // glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
        
        //bed texture - noise, wind horizontal and vertical, spread (remove this after done)
        
        //get object names and numbers
        //divide whole name by _ , because object and numbers are separated, and after that everyuthing that is not important
        //template: <objName>_<objNum>_<everythingElse>
        //order of object should remain
        NSArray *nameParts = [[model.objects objectAtIndex:i] componentsSeparatedByString:@"_"];
        [objectIDs addObject:nameParts];
    }
    
    ghostTex = [[SingleGraph sharedSingleGraph] AddTexture: @"ghost.png" : YES]; //8x8
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}


- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (GLKVector4) nonAffectedDaytimeColor : (Character*) character : (Terrain*) terr : (Interface*) intr : (Interaction*) interaction
{
    [self UpdateShelterInterface: character : intr : terr : interaction];
    [self EnterShelter: character : intr];
    //[character.camera UpdateDirectAction: dt];
    
    if(state != SS_NONE)
    {
        //check ghost visibility
        if(state != SS_DONE)
        {
            float ghostVisibilityDistance = PICK_DISTANCE;
            //this is ghost visibility, not shelter visibility
            shelter.visible = (GLKVector3Distance(shelter.position, character.camera.position) <= ghostVisibilityDistance);
        }
        
        shelter.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, shelter.position);
        shelter.displaceMat = GLKMatrix4RotateY(shelter.displaceMat, shelter.orientation.y);
        
        //indicator rotation
        if(character.health < 1.0) //if character is injured
        {
            float rotationTempo = 4.0;
            shelter.speed  += rotationTempo * dt;
            indicatorRotMat = GLKMatrix4RotateY(shelter.displaceMat, shelter.speed);
            //must be from no 0 to 2 * PI
            if(shelter.speed >= PI_BY_2)
            {
                shelter.speed = shelter.speed - PI_BY_2;
            }
        }
        
        
        //coloring
        if(character.state == CS_SHELTER_RESTING || (character.state == CS_DEAD && character.prevStateInformative == CS_SHELTER_RESTING)) //also when died in shelter
        {
            self.effect.constantColor = nonAffectedDaytimeColor;
        }else
        {
            self.effect.constantColor = daytimeColor;
        }
    }
}


- (void) Render
{
    //#OPTI - if objects are ordered by texture in file, it will be less switches between textures
    if(state != SS_NONE)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace: NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        effect.transform.modelviewMatrix = shelter.displaceMat;
        //raft
        for (int i = 0; i < model.objectCount; i++) //render by material
        {
            if([self ObjectVisible:i])
            {
                effect.texture2d0.name = textures[i];
                [effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[i].startIndex)  * sizeof(GLushort)));
            }
        }
    }
}

- (void) RenderTransparent : (Character*) character
{
    //indicator
    if(state == SS_DONE && character.health < 1.0) //character injured
    {
        //render ghost
        [[SingleGraph sharedSingleGraph] SetCullFace: NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: YES];
        [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_ONE];
        
        for (int i = 0; i < model.objectCount; i++) //render by material
        {
            if([self ObjectVisibleIndicator: i])
            {
                effect.texture2d0.name = textures[i];
                effect.transform.modelviewMatrix =  indicatorRotMat;
                [effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[i].startIndex)  * sizeof(GLushort)));
                
                break;
            }
        }
    }
    
    //ghost
    if(state != SS_NONE && state != SS_DONE && shelter.visible)  //shelter.visible - ghost visibility not shelter
    {
        //render ghost
        [[SingleGraph sharedSingleGraph] SetCullFace: NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        
        for (int i = 0; i < model.objectCount; i++) //render by material
        {
            if([self ObjectVisibleAsGhost: i])
            {
                [[SingleGraph sharedSingleGraph] SetBlend: YES];
                [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_ONE];
                
                effect.texture2d0.name = ghostTex;
                effect.transform.modelviewMatrix = shelter.displaceMat;
                [effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, model.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((bufferAttribs.firstIndex + model.patches[i].startIndex)  * sizeof(GLushort)));
                
                break;
            }
        }
    }
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    free(textures);
    [model ResourceCleanUp];
}

#pragma mark - Functionality

//determine what objects are ready to be drawn at current stage
//index represents object in array
//should be used only when state > SS_NONE
- (BOOL) ObjectVisible: (int) i
{
    //object names
    NSArray *nameParts = [objectIDs objectAtIndex:i];
    //in array 1st - object name
    //         2end - object number
    //names - stick, leaf, bed
 
    //draw everything, but not indicator, indicator is draw in transparent
    if(state == SS_DONE && ![[nameParts objectAtIndex:0] isEqualToString: @"indicator"])
    {
        return YES;
    }
    
    //bed always when started
    if([[nameParts objectAtIndex:0] isEqualToString: @"bed"])
    {
        return YES;
    }
    
    //draw sticks
    if([[nameParts objectAtIndex:1] intValue] <= stickCount.current && [[nameParts objectAtIndex:0] isEqualToString: @"stick"]  )
    {
        return YES;
    }
    
    //leafs
    if([[nameParts objectAtIndex:1] intValue] <= leafCount.current && [[nameParts objectAtIndex:0] isEqualToString:  @"leaf"])
    {
        return YES;
    }
    
    return NO;
}

//determine if current object is ghost (object that should be added in next step)
//index represents object in array
//should be used only when state > SS_NONE
- (BOOL) ObjectVisibleAsGhost: (int) i
{
    if(state == SS_DONE)
    {
        return NO;
    }
    
    //object names
    NSArray *nameParts = [objectIDs objectAtIndex:i];
    //in array 1st - object name
    //         2end - object number
    //names - stick, leaf, bed
    
    //if not all stick are attached, means that ghost should be next stick
    if(stickCount.current < stickCount.max)
    {
        if([[nameParts objectAtIndex:0] isEqualToString: @"stick"] && [[nameParts objectAtIndex:1] intValue] == stickCount.current + 1)
        {
            return YES;
        }
        
    }else
    //if not all leaves are added
    if(leafCount.current < leafCount.max)
    {
        if([[nameParts objectAtIndex:0] isEqualToString: @"leaf"] && [[nameParts objectAtIndex:1] intValue] == leafCount.current + 1)
        {
            return YES;
        }
    }
    
    
    return NO;
}

//determine if current object is indicator
//index represents object in array
- (BOOL) ObjectVisibleIndicator: (int) i
{
    if(state == SS_DONE)
    {
        //object names
        NSArray *nameParts = [objectIDs objectAtIndex:i];
        //in array 1st - object name
        //         2end - object number
        //names - stick, leaf, bed
        
        //indicator
        if([[nameParts objectAtIndex:0] isEqualToString: @"indicator"])
        {
            return YES;
        }
    }

    return NO;
}

//get place in fron of camera where shelter will be located
- (GLKVector3) GetPotentialShelterPlace: (Character*) character
{
    float safetyDist = 0.1; //so we dont get tsuck after putting shelter down. Must not be greater than entering circle radius!
    float distanceFromCharacter = shelter.crRadius + safetyDist; //place shalter this distance in fron of character
    return [character.camera PointInFrontOfCamera: distanceFromCharacter];
}


//enter shelter from entering circle
- (void) EnterShelter: (Character*) character : (Interface*) intr
{
    if(state == SS_DONE && character.state == CS_BASIC)
    {
        float directionAngleDelta = M_PI / 8.0; //what angle is considred a viewing direction toward shelter entrance
        
        if([CommonHelpers PointInCircle: entranceCrircle.center : entranceCrircle.radius: character.camera.position] && //stand in entrance circle
            //character should be looking in direction of shelter
           [character.camera HorAngleBetweenViewAndVector: [CommonHelpers GetVectorFrom2Points: character.camera.position :shelter.position :YES]] < directionAngleDelta
           )
        {
            [character setState: CS_SHELTER_RESTING];
            [intr SetRestingInterface];
            
            //slide action (sitting down in shelter)
            float timeOfCloseup = 1.0;
            GLKVector3 seatPosition = shelter.position;
            seatPosition.y += character.sitHeight;
            GLKVector3 viewVector = [CommonHelpers GetVectorFrom2Points: shelter.position : entranceCrircle.center : YES]; //view out of dors
            [character.camera StartDirectAction: seatPosition : viewVector : timeOfCloseup];
        }
    }
}

//leave shelter
//used in with caharcter joystick touch
- (void) LeaveShelter: (Character*) character : (Interface*) intr : (Interaction*) interaction
{
    if(character.state == CS_SHELTER_RESTING)
    {
        //[character.camera RestoreVectorsWithViewAt: [CommonHelpers PointOnLine: shelter.position : entranceCrircle.center : 1.0]];
        //position at entrance
        [character.camera PositionCamera: entranceCrircle.center : [CommonHelpers GetVectorFrom2Points: shelter.position : entranceCrircle.center : YES] :  character.camera.upVector];
        float eyeHeight = [interaction GetHeightByPoint: character.camera.position] + character.height;
        [character.camera LiftCamera: eyeHeight];
         
        [character SetPreviousState: intr];
    }
}

#pragma mark - Constructing shelter

//if stick can be added to shelter
- (BOOL) PuttingSticksAllowed: (GLKVector3) point
{
    return state == SS_BUILDING && stickCount.current < stickCount.max && [CommonHelpers PointInCircle: shelter.position : shelter.crRadius: point];
}
//if leaf can be added to shelter
- (BOOL) PuttingLeavesAllowed: (GLKVector3) point
{
    return state == SS_BUILDING && stickCount.current == stickCount.max && leafCount.current < leafCount.max && [CommonHelpers PointInCircle: shelter.position : shelter.crRadius: point];
}

//add log to shelter
- (void) AddStick: (Particles*) particles
{
    if(state == SS_BUILDING && stickCount.current < stickCount.max)
    {
        stickCount.current++;
        
        //particles
        [particles.commonGroundAreaSplashPrt AssigneTriggerRadius:shelter.crRadius];
        [particles.commonGroundAreaSplashPrt Start: shelter.position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
    }
}

//add leave to shelter
- (void) AddLeave: (Particles*) particles
{
    if(state == SS_BUILDING && stickCount.current == stickCount.max && leafCount.current < leafCount.max)
    {
        leafCount.current++;
        
        if(leafCount.current == leafCount.max)
        {
            state = SS_DONE;
        }
        
        //particles
        [particles.commonGroundAreaSplashPrt AssigneTriggerRadius:shelter.crRadius];
        [particles.commonGroundAreaSplashPrt Start: shelter.position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
    }
}

#pragma mark - Interface elemnt management

//update interface buttons visibility
- (void) UpdateShelterInterface: (Character*) character : (Interface*) intr : (Terrain*) terr : (Interaction*) interaction
{
    //button - start bulding shelter
    if(character.state == CS_BASIC && state == SS_NONE)
    {
        //need to assign to position here to IsPlaceOccupied function work, this position will be redifeined in touch begin
        shelter.position = [self GetPotentialShelterPlace: character];
        //allowwd to build only on beach line
        if([terr IsInland: shelter.position] && ![interaction PlaceOccupied: shelter.position : shelter.crRadius])
        {
            [intr.overlays SetInterfaceVisibility: INT_SHELTER_BEGIN_BUTT : YES];
        }else
        {
            //when moved out of beach
            [intr.overlays SetInterfaceVisibility: INT_SHELTER_BEGIN_BUTT : NO];
        }
    }
    
    //remove button when pressed to start building
    if(state > SS_NONE && [intr.overlays IsVisible: INT_SHELTER_BEGIN_BUTT])
    {
        Button *startShelterButt = [intr.overlays.interfaceObjs objectAtIndex: INT_SHELTER_BEGIN_BUTT];
        if(![startShelterButt AutoButtonInAction]) //let automatic button end its action befoe hiding
        {
            [intr.overlays SetInterfaceVisibility: INT_SHELTER_BEGIN_BUTT : NO];
        }
    }
}

#pragma mark - Touch functions

- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (Terrain*) terr : (Interaction*) interaction : (Particles*) particles
{
    BOOL retVal = NO;
    
    //begin build raft press
    if(state == SS_NONE && [intr IsBeginShelterButtTouched: tpos])
    {
        //position shelter
        shelter.position = [self GetPotentialShelterPlace: character];
        //if allowed in this place
        if(![interaction PlaceOccupied: shelter.position : shelter.crRadius])
        {
            Button *startShelterButt = [intr.overlays.interfaceObjs objectAtIndex: INT_SHELTER_BEGIN_BUTT];
            [startShelterButt PressBegin: touch];
            
            //begin build
            //state = SS_DONE;
            state = SS_BUILDING;
            stickCount.current = 0;
            leafCount.current = 0;
            
            //additional positioning
            [terr GetHeightByPointAssign: &shelter.position];
            //raft orientation should be out of terrain center to ocean
            GLKVector3 pVect = [CommonHelpers GetVectorFrom2Points: shelter.position : character.camera.position : YES];//GLKVector3Normalize(GLKVector3Subtract(shelter.position, character.camera.position));
            shelter.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
            
            //determine entering circle coordinates
            entranceCrircle.center = character.camera.position;
            [terr GetHeightByPointAssign: &entranceCrircle.center];
            
            //particles
            [particles.commonGroundAreaSplashPrt AssigneTriggerRadius: shelter.crRadius];
            [particles.commonGroundAreaSplashPrt Start: shelter.position]; //self ending, does not rquire ending
            
            //sound
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
            
            retVal = YES;
        }
    }
    
    return retVal;
}
@end
