//
//  Raft.m
//  Island survival
//
//  Created by Ivars Rusbergs on 7/4/13.
//
// STATUS: - OK

#import "Raft.h"

@implementation Raft
@synthesize  raft,effect,sailModel,raftModel,vertexCount,indexCount,state,objectIDs,floating,pushedInWater,
             leftSplashPoint,rightSplashPoint,vertexDynamicCount,indexDynamicCount;

- (id) initWithObjects: (Ocean*) ocean
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry:ocean];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    state = RS_NONE;
    logCount.current = 0;
    raft.position = GLKVector3Make(0, 0, 0);
    floating = NO;
    pushedInWater = NO;
    sailSwayTime = 0;
    raft.visible = false; //this is ghost visibility not raft visibility
}

- (void) InitGeometry: (Ocean*) ocean
{
    float raftScale = 2.0; //should match log scale
    float sailScale = 1.0;
    
    //order : under stick, under stick, 7 logs, mast
    raftModel = [[ModelLoader alloc] initWithFileScalePatchType: @"raft.obj": raftScale: GROUP_BY_OBJECT];
    sailModel = [[ModelLoader alloc] initWithFileScale: @"sail.obj": sailScale];
    
    vertexCount = raftModel.mesh.vertexCount;
    indexCount = raftModel.mesh.indexCount;
    
    vertexDynamicCount = sailModel.mesh.vertexCount;
    indexDynamicCount = sailModel.mesh.indexCount;
    
    //texture array loading
    //NOTE: textures are not uniue in this array but respective to each object
    texIDsRaft = malloc(raftModel.objectCount * sizeof(GLuint));
    //allocate for object ids
    objectIDs = [[NSMutableArray alloc] init];
    
    //set parameters
    logCount.max = 7; //number of logs on full raft
    raft.speed = 3.0; //relative moveent speed of raft
    gameEndingDistance = (ocean.oceanWidth * ocean.scaleFactor) / 3.1;  //how far from island raft gow until game is automatically ended, should depend on some scales
}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    
    //---------- fill raft
    int firstVertex = *vCnt;
    firstIndexRaft = *iCnt;
    for (int n = 0; n < raftModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = raftModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  raftModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < raftModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  raftModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
}

//sail filling
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    firstVertexSail = *vCnt;
    firstIndexSail = *iCnt;
    for (int n = 0; n < sailModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = sailModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  sailModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < sailModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  sailModel.mesh.indices[n] + firstVertexSail;
        *iCnt = *iCnt + 1;
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //NOTE: textures are not uniue in this array but respective to each object
    for (int i = 0; i < raftModel.objectCount; i++)
    {
        texIDsRaft[i] = [[SingleGraph sharedSingleGraph] AddTexture: [raftModel.matToTex objectAtIndex:i]: YES]; //log, rag
        
        //get object names and numbers
        //divide whole name by _ , because object and numbers are separated, and after that everyuthing that is not important
        //template: <objName>_<objNum>_<everythingElse>
        //order of object should remain
        NSArray *nameParts = [[raftModel.objects objectAtIndex:i] componentsSeparatedByString:@"_"];
        [objectIDs addObject:nameParts];
        //NSLog(@"%@", nameParts);
    }
    
    texIDSail = [[SingleGraph sharedSingleGraph] AddTexture: [sailModel.materials objectAtIndex:0]: YES]; //sail - 64x64
    
    ghostTex = [[SingleGraph sharedSingleGraph] AddTexture: @"ghost.png" : YES]; //8x8
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
    
    mastOrigin = [self GetMastOrigin];
}

- (void) Update:(float)dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Interface*) intr : (Terrain*) terr : (Ocean*) ocean : (Environment*) env : (GeometryShape*) meshDynamic : (Particles*) particles
{
    [self UpdateRaftInterface:character :intr :terr];
    
    if(state != RS_NONE)
    {
        raft.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, raft.position);
        raft.displaceMat = GLKMatrix4RotateY(raft.displaceMat, raft.orientation.y);
        raft.displaceMat = GLKMatrix4RotateX(raft.displaceMat, raft.orientation.x);
        
        self.effect.transform.modelviewMatrix = raft.displaceMat;
        /*
        //color raft to know that item is dropped on raft
        if((character.inventory.grabbedItem.type == ITEM_RAFT_LOG && state == RS_PUT_LOG) ||
           (character.inventory.grabbedItem.type == ITEM_SAIL && state == RS_PUT_SAIL))
        {
            //mark raft
            self.effect.constantColor = GLKVector4Make(0.0, 1.0, 0.0, 1.0);
        }else
        {
            self.effect.constantColor = daytimeColor;
        }
        */
        self.effect.constantColor = daytimeColor;
        
        //when sitting down on raft
        //[character.camera UpdateSlideAction: dt];
        
        //raft floating update
        //put after matrix update, or movement will be jerky
        [self UpdateFloating: dt : ocean : terr : env : character];
        
        //update sail
        if(state == RS_DONE || (state == RS_PUT_SAIL && raft.visible)) //update also when ghost is showm (raft.visible - ghost visibility, not raft visibility)
        {
            [self UpdateDynamicVertexArray: meshDynamic : dt];
        }
        
        
        //check ghost visibility
        if(state != RS_DONE)
        {
            float ghostVisibilityDistance = PICK_DISTANCE;
            //this is ghost visibility, not raft visibility
            raft.visible = (GLKVector3Distance(raft.position, character.camera.position) <= ghostVisibilityDistance);
        }
        
        //particles
        if(floating && pushedInWater)
        {
            //randomize splash points
            GLKVector3 splashPoints[3];
            splashPoints[0] = rightSplashPoint;
            splashPoints[1] = leftSplashPoint;
            splashPoints[2] = raft.endPoint2;
            
            int splashIndex = [CommonHelpers RandomInRangeInt: 0 : 2];
            [particles.splashBigPrt Start: splashPoints[splashIndex]]; //self ending, does not rquire ending
        }
    }
}

- (void) Render
{
    if(state != RS_NONE)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace: YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        //raft
        for (int i = 0; i < raftModel.objectCount; i++) //render by material
        {
            if([self ObjectVisible:i])
            {
                effect.texture2d0.name = texIDsRaft[i];
                [effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, raftModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexRaft + raftModel.patches[i].startIndex)  * sizeof(GLushort)));
            }
        }
    }
}

- (void) RenderDynamic
{
    //sail
    if(state == RS_DONE || (state == RS_PUT_SAIL && raft.visible)) //also show ghost (raft.visible - ghost visibility, not raft visibility)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace: NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        if(state == RS_DONE)
        {
            effect.texture2d0.name = texIDSail;
        }else
        {
            effect.texture2d0.name = ghostTex;
        }
        
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sailModel.patches[0].indexCount,
                       GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndexSail  * sizeof(GLushort)));
    }
}


- (void) RenderTransparent
{
    //ghost
    if(state != RS_NONE && state != RS_DONE  && raft.visible)  //raft.visible - ghost visibility not raft vis.
    {
        //render ghost
        [[SingleGraph sharedSingleGraph] SetCullFace: NO];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        
        for (int i = 0; i < raftModel.objectCount; i++) //render by material
        {
            if([self ObjectVisibleAsGhost: i])
            {
                [[SingleGraph sharedSingleGraph] SetBlend: YES];
                [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_ONE];
                
                effect.texture2d0.name = ghostTex;
                [effect prepareToDraw];
                glDrawElements(GL_TRIANGLES, raftModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexRaft + raftModel.patches[i].startIndex)  * sizeof(GLushort)));
                
                break;
            }
        }
    }
}


- (void) ResourceCleanUp
{
    self.effect = nil;
    
    free(texIDsRaft);
    
    [sailModel ResourceCleanUp];
    [raftModel ResourceCleanUp];
}

#pragma mark - Sail

// update sail swaing in wind
- (void) UpdateDynamicVertexArray:(GeometryShape*) mesh: (float) dt
{
    int vCnt = firstVertexSail;
    float angle; //every vertex swaing angle around ail origin
    float vdist; //distance fo vertex from sail local origin
    float swaySpeed = 5.0; //relative swaying speed
    float angleDivision = 3.0; //since sin() = (-1 to 1), to reduce angle,  divide sin by angleDivision
   
    sailSwayTime += swaySpeed * dt;

    for (int n = 0; n < sailModel.mesh.vertexCount; n++)
    {
        //dont swing last vertice because it is tie rope
        if(sailModel.mesh.verticesT[n].vertex.z != sailModel.AABBmin.z) 
        {
            //#OPTI - may be using transaltion matrix would be faster than add (in that case rotation here should be around 0,1,0)
            mesh.verticesT[vCnt].vertex = GLKVector3Add(sailModel.mesh.verticesT[n].vertex, mastOrigin);
            
            //#OPTI - distance can be precalculated and put in array
            //      - and dont rotate vertices that are at origin (x = 0, z = 0)
            
            //calculate distance from vertex to local origin
            vdist = GLKVector3Distance(sailModel.mesh.verticesT[n].vertex, GLKVector3Make(0,0,0));
            
            //swaing depends on how far vertex is from local point of origin
            angle = sinf(sailSwayTime + vdist) / angleDivision;
            
            //vertex rotated around local origin
            [CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex: angle: GLKVector3Make(mastOrigin.x, 1, mastOrigin.z)];
        }else
        {
            //put tie rope at end of raft
            mesh.verticesT[vCnt].vertex = GLKVector3Make(0.0, sailModel.mesh.verticesT[n].vertex.y, raftModel.AABBmin.z);
        }
        
        vCnt++;
    }
    
    //nil sway value
    //must be from no 0 to 2 * PI
    if(sailSwayTime >= PI_BY_2)
    {
        sailSwayTime = sailSwayTime - PI_BY_2;
    }
}


#pragma mark - Raft  management

//determine if given object is visible
//index represents object in array
//should be used only when state > RS_NONE
- (BOOL) ObjectVisible: (int) i
{
    //draw everything
    if(state == RS_DONE)
    {
        return YES;
    }
    
    //object names
    NSArray *nameParts = [objectIDs objectAtIndex:i];
    //in array 1st - object name
    //         2end - object number
    //names - log, under (sticks that hold together raft), mast
    
    //draw log holders always
    if([[nameParts objectAtIndex:0] isEqualToString:@"under"])
    {
        return YES;
    }
    
    //logs
    if([[nameParts objectAtIndex:0] isEqualToString:@"log"] &&
       (state == RS_PUT_SAIL || [[nameParts objectAtIndex:1] intValue] <= logCount.current))
    {
        return YES;
    }
    
    return NO;
}

//determine if current object is ghost (object that should be added in next step)
//index represents object in array
//should be used only when state > RS_NONE
- (BOOL) ObjectVisibleAsGhost: (int) i
{
    //dont draw ghost when done
    if(state == RS_DONE)
    {
        return NO;
    }
    
    //object names
    NSArray *nameParts = [objectIDs objectAtIndex:i];
    //in array 1st - object name
    //         2end - object number
    //names - log, under (sticks that hold together raft), mast
    

    //logs
    if(state == RS_PUT_LOG && [[nameParts objectAtIndex:0] isEqualToString:@"log"] && [[nameParts objectAtIndex:1] intValue] == (logCount.current + 1))
    {
        return YES;
    }
    
    if(state == RS_PUT_SAIL && [[nameParts objectAtIndex:0] isEqualToString:@"mast"])
    {
        return YES;
    }
     
    return NO;
}


//add log to raft
- (void) AddLog: (Log*) logs : (Particles*) particles
{
    if(state == RS_PUT_LOG)
    {
        logCount.current++;
        
        //remove log from hand visually
        [logs HideLogInHand];
        
        //switch to next state
        if(logCount.current == logCount.max)
        {
            state = RS_PUT_SAIL;
        }
        
        //particles
        [particles.commonGroundAreaSplashPrt AssigneTriggerRadius: raftModel.crRadius];
        [particles.commonGroundAreaSplashPrt Start: raft.position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
    }
}


//add sail to raft
- (void) AddSail: (Particles*) particles
{
    if(state == RS_PUT_SAIL)
    {
        state = RS_DONE;
        
        //particles
        [particles.commonGroundAreaSplashPrt AssigneTriggerRadius: raftModel.crRadius];
        [particles.commonGroundAreaSplashPrt Start: raft.position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
    }
}

//weather given point is on raft (y not checked)
- (BOOL) PointOnRaft: (GLKVector3) point
{
    //make two boudning circles, it is more precise for detecting bounds
    //add some extra to half radius, to make smaller gaps between those two circles
    float radius = raftModel.crRadius / 2.0 + raftModel.crRadius / 6.0  /*+ raftModel.crRadius / 8.0*/;
    float lerpVal1 = 0.333;
    GLKVector3 sphereCenter1 = GLKVector3Lerp(raft.endPoint1, raft.endPoint2, lerpVal1);
    float lerpVal2 = 0.666;
    GLKVector3 sphereCenter2 = GLKVector3Lerp(raft.endPoint1, raft.endPoint2, lerpVal2);
    
    return [CommonHelpers PointInCircle: sphereCenter1 : radius : point] || [CommonHelpers PointInCircle: sphereCenter2 : radius : point];
}

//if items can be added to raft while it is building 
- (BOOL) PuttingLogsAllowed: (GLKVector3) point
{
    return state == RS_PUT_LOG && [self PointOnRaft: point];
}
- (BOOL) PuttingSailAllowed: (GLKVector3) point
{
    return state == RS_PUT_SAIL && [self PointOnRaft: point];
}

//adjust raft over ocean, determine splash positions
- (void) AdjustEndPointsOcean: (Ocean*) ocean: (SModelRepresentation*) m
{
    //determine end points to manipulate picking and rotate according to different heights
    m->endPoint1 = GLKVector3Add(raftModel.AABBmin, m->position);
    m->endPoint2 = GLKVector3Add(raftModel.AABBmax, m->position);
    m->endPoint2.y = m->endPoint1.y; //height is bottom for both
    
    //for splash
    float offsetX = 0.3; //move splash closer to middle
    leftSplashPoint = m->endPoint2;
    leftSplashPoint.x -= offsetX;
    rightSplashPoint = m->endPoint2;
    rightSplashPoint.x = m->endPoint1.x + offsetX;
    
    //AABB is shifted to sides of model, but we need middle of model
    //width of raft
    float mhWidth = (fabs(raftModel.AABBmin.x) + fabs(raftModel.AABBmax.x)) / 2.0;
    m->endPoint1.x += mhWidth;
    m->endPoint2.x -= mhWidth;
    
    //rotate them to current orientation
    [CommonHelpers RotateY: &m->endPoint1 : m->orientation.y : m->position];
    [CommonHelpers RotateY: &m->endPoint2 : m->orientation.y : m->position];
   
    //for splash
    [CommonHelpers RotateY: &leftSplashPoint : m->orientation.y : m->position];
    [CommonHelpers RotateY: &rightSplashPoint : m->orientation.y : m->position];
    
    //get height for end points
    float sinkFactor = 0.10; //how much raft sinks in water
    m->endPoint1.y = [ocean GetHeightByPoint:m->endPoint1] - sinkFactor;
    m->endPoint2.y = [ocean GetHeightByPoint:m->endPoint2] - sinkFactor;
    //determine new middle position y, according to new end point position
    m->position.y = (m->endPoint1.y + m->endPoint2.y) / 2.0;
    
    //dteemrine angle to rotate about that rotation axis
    float pretkath = m->position.y - m->endPoint2.y;
    float hipoth = (raftModel.AABBmax.z - raftModel.AABBmin.z) / 2;
    m->orientation.x = asinf(pretkath / hipoth);
}

//get origin of the mast vertex
- (GLKVector3) GetMastOrigin
{
    GLKVector3 origin;
    
    for (int i = 0; i < raftModel.objectCount; i++) //render by material
    {
        //object names
        NSArray *nameParts = [objectIDs objectAtIndex:i];
        
        //we look for mast veretx
        if([[nameParts objectAtIndex:0] isEqualToString: @"mast"]) 
        {
            // take some vertex from mast model and set to 0 height
            // NOTE - it is not determined what vertex exactly so it waries from model to model and may shift sail a bit to one side
            int vertexNumber = raftModel.mesh.indices[raftModel.patches[i].startIndex];
            
            origin = raftModel.mesh.verticesT[vertexNumber].vertex;
            origin.y = 0.0; //set to lowest model value, position of sail is not determioned by this height
            break;
        }
    }
    
    return origin;
}

#pragma mark - Floating fun ctions

//start floating
- (void) StartFloating
{
    if(state == RS_DONE)
    {
        floating = true;
        
        //set initial direction forward, this is used when raft is pushed into water
        raft.movementVector = GLKVector3Make(0, 0, raft.speed);
        [CommonHelpers RotateY: &raft.movementVector: raft.orientation.y];
    }
}

//update raft floating
- (void) UpdateFloating:(float) dt: (Ocean*) ocean: (Terrain*) terr: (Environment*) env: (Character*) character
{
    if(floating && !character.camera.actionSlide.enabled) //after came ir closed up on like sitting
    {
        //when raft is pushed in water start turning it in direction of wind
        //change movement vector
        //boat turns and adjust wind direction
        if(pushedInWater &&
           fabs(raft.orientation.y - env.windAngle) > 0.002) // if this is removed, raft will be jerking because it will calculate orientation all the time
        {
            float turningSpeed = 0.14; //the lower value, the larger turn
            
            //turning
            if(raft.orientation.y > env.windAngle)
            {
                if(raft.orientation.y - env.windAngle < M_PI)
                {
                    raft.orientation.y -= turningSpeed * dt;
                }else
                {
                    raft.orientation.y += turningSpeed * dt;
                }
            }else
            if(raft.orientation.y < env.windAngle)
            {
                if(env.windAngle - raft.orientation.y > M_PI)
                {
                    raft.orientation.y -= turningSpeed * dt;
                }else
                {
                    raft.orientation.y += turningSpeed * dt;
                }
            }
            
            //bounds check
            if(raft.orientation.y >= PI_BY_2)
            {
                raft.orientation.y = 0;
            }else
            if(raft.orientation.y < 0)
            {
                raft.orientation.y = PI_BY_2;
            }
            
            //rotate movement vector to calculated orientation
            raft.movementVector = GLKVector3Make(0, 0, raft.speed);
            [CommonHelpers RotateY: &raft.movementVector: raft.orientation.y];
        }
        
        
        //add movement forward
        GLKVector3 sV = GLKVector3MultiplyScalar(raft.movementVector, dt);
        raft.position = GLKVector3Add(raft.position, sV);
        
        //calculate raft position height 
        if(!pushedInWater) //if boat is not pushed in water
        {
            float oceanHeight = [ocean GetHeightByPoint:raft.position];
            float landHeight = [terr GetHeightByPoint:&raft.position];
            
            //pushed in water is when ground height is lower than water height
            if(landHeight > oceanHeight)
            {
                //pushed on land
                raft.position.y = landHeight;
                //[terr AdjustModelEndPoints: &raft: raftModel];
            }else
            {
                //pushed into water, no land should be touched afterward
                pushedInWater = true;
                [self AdjustEndPointsOcean:ocean :&raft];
            }
        }else //raft floating
        {
            [self AdjustEndPointsOcean:ocean :&raft];
        }
        
        //move character with raft
        [character.camera AddVectorFixedY: sV: raft.position.y + character.sitHeight];

        //game ending when raft has flown distance form island
        float distanceFromIsland = GLKVector3Distance(terr.islandCircle.center, character.camera.position);
        if(distanceFromIsland > gameEndingDistance)
        {
            //end game
            //[[SingleSound sharedSingleSound]  StopAllSounds];
            
            [[SingleDirector sharedSingleDirector] setGameScene:SC_MAIN_MENU];
        }
    }
}


#pragma mark - Interface elemnt management

//update interface buttons visibility
- (void) UpdateRaftInterface:(Character*) character: (Interface*) intr: (Terrain*) terr
{
    //button - start bulding raft
    if(character.state == CS_BASIC && state == RS_NONE && character.handItem.ID == ITEM_RAFT_LOG)
    {
        //allowwd to build only on beach line
        if([terr IsBeach: character.camera.position])
        {
            [intr.overlays SetInterfaceVisibility: INT_RAFT_BEGIN_BUTT : YES];
        }else
        {
            //when moved out of beach
            [intr.overlays SetInterfaceVisibility: INT_RAFT_BEGIN_BUTT : NO];
        }
    }
    
    //remove button when log is thrown out
    if(character.handItem.ID != ITEM_RAFT_LOG &&  [intr.overlays IsVisible: INT_RAFT_BEGIN_BUTT])
    {
        Button *startRaftButt = [intr.overlays.interfaceObjs objectAtIndex: INT_RAFT_BEGIN_BUTT];
        if(![startRaftButt AutoButtonInAction]) //let automatic button end its action befoe hiding
        {
            [intr.overlays SetInterfaceVisibility: INT_RAFT_BEGIN_BUTT : NO];
        }
    }
    
    //check when ready to float
    if(character.state == CS_BASIC && state == RS_DONE && !floating)
    {
        if(![intr.overlays IsVisible: INT_RAFT_FLOAT_BUTT] && [self PointOnRaft:character.camera.position])
        {
            [intr.overlays SetInterfaceVisibility: INT_RAFT_FLOAT_BUTT : YES];
        }
        else
        if([intr.overlays IsVisible: INT_RAFT_FLOAT_BUTT] && ![self PointOnRaft:character.camera.position])
        {
            [intr.overlays SetInterfaceVisibility: INT_RAFT_FLOAT_BUTT : NO];
        }
    }
    
    //hide float raft button after starting to float on the raft
    if(character.state == CS_RAFT && [intr.overlays IsVisible: INT_RAFT_FLOAT_BUTT])
    {
        Button *floatRaftButt = [intr.overlays.interfaceObjs objectAtIndex: INT_RAFT_FLOAT_BUTT];
        if(![floatRaftButt AutoButtonInAction])
        {
            [intr.overlays SetInterfaceVisibility: INT_RAFT_FLOAT_BUTT : NO];
        }
    }
}

#pragma mark - Touch functions

- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character : (Terrain*) terr : (Log*) logs : (Particles*) particles
{
    BOOL retVal = NO;
    
    //begin build raft press
    if(state == RS_NONE && [intr IsBeginRaftButtTouched: tpos])
    {
        Button *startRaftButt = [intr.overlays.interfaceObjs objectAtIndex: INT_RAFT_BEGIN_BUTT];
        [startRaftButt PressBegin:touch];
        
        //begin build
        state = RS_PUT_LOG; //RS_DONE
        logCount.current = 1;
        
        //empty hand item
        [character ClearHand]; //only interface is affected
        
        //remove log from hand visually
        [logs HideLogInHand];
        
        //position raft
        raft.position = character.camera.position; //will be center of raft
        [terr GetHeightByPointAssign: &raft.position];
        //raft orientation should be out of terrain center to ocean
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(raft.position, terr.islandCircle.center));
        raft.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
        //[self AdjustEndPoints: terr: &raft];
        [terr AdjustModelEndPoints: &raft : raftModel];
        
        //particles
        [particles.commonGroundAreaSplashPrt AssigneTriggerRadius: raftModel.crRadius];
        [particles.commonGroundAreaSplashPrt Start: raft.position]; //self ending, does not rquire ending
        //sound
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CONTRUCTION];
        
        retVal = YES;
    }
    
    //start floating raft
    if(state == RS_DONE && [intr IsFloatRaftButtTouched:tpos])
    {
        Button *floatRaftButt = [intr.overlays.interfaceObjs objectAtIndex: INT_RAFT_FLOAT_BUTT];
        [floatRaftButt PressBegin: touch];
        
        [self StartFloating];
        
        [character setState: CS_RAFT];
        
        [intr SetRaftInterface];
        
        [character ClearHand]; //just in case something was in hand
        
        //slide action (sitting down on raft)
        float timeOfCloseup = 1.0;
        GLKVector3 seatPosition = raft.position;
        seatPosition.y += character.sitHeight;
        [character.camera StartSlideAction: seatPosition : timeOfCloseup];
        
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_CLICK];
        
        retVal = YES;
    }
    
    return retVal;
}



@end
