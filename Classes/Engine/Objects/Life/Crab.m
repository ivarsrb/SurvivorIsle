//
//  Crab.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "Crab.h"

@implementation Crab
@synthesize model, effect, collection, vertexCount, indexCount, actions, count;

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
- (void) ResetData: (Terrain*) terr
{
    SCircle crabCircle = terr.inlandCircle;
    crabCircle.radius += 10; //put crab on the beach, a bit off the beach/inliand line
    for (int i = 0; i < count; i++)
    {
        //[self StartMovement:&collection[i] :[CommonHelpers RandomOnCircleLine:crabCircle]];
        [actions  StartMovement: &collection[i] : [CommonHelpers RandomOnCircleLine: crabCircle]];
        [self SetUpAnimation: &collection[i]];
        [self StartAnimation: &collection[i]];
    }
    
    [self NillData];
}

//data that should be nilled every time game is eneterd from menu screen (no mater new or continued)
- (void) NillData
{
    //difficulty related
    //reset actions data
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_HARD)
    {
        actions.minObjTrapDistance = 10.0;
    }else
    {
        actions.minObjTrapDistance = 15.0;
    }
}


- (void) InitGeometry
{
    count = CRAB_COUNT;
    collection = malloc(count * sizeof(SModelRepresentation));

    float crabScale = 0.17;
    model = [[ModelLoader alloc] initWithFileScale: @"crab.obj" : crabScale];
    
    //texture array
    texID = malloc(model.materialCount * sizeof(GLuint));
    
    //determine bounding sphere radius
    for (int i = 0; i < count; i++) 
    {
        [model AssignBounds: &collection[i] : 0.0];
        //collection[i].bsRadius = model.bsRadius;
        //set scale for each collection item
        collection[i].scale = crabScale;
    }
    
    //vertex index count
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
    //actions set up
    actions = [[ObjectActions alloc] init];
    //set up action parameters
    actions.type = WT_CRAB;
    actions.normalSpeed = 1.0;
    actions.runawaySpeed = 10.0;
    actions.moveMaxTimeNormal = 3;
    actions.moveMaxTimeRunaway = 1;
    actions.minObjCharDistance = 15.0;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt: (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    int firstVertex = *vCnt;
    firstIndex = *iCnt;
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
        mesh.indices[*iCnt] =  model.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //load  textures
    for (int i = 0; i < model.materialCount; i++) 
    {
        texID[i] = [[SingleGraph sharedSingleGraph] AddTexture: [model.materials objectAtIndex:i]: YES]; //body - 128x128, leg - 32x32, claws - 32x32
    }
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Terrain*) terr : (Character*) character : (StickTrap*) traps
{
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            //if(collection[i].runaway)
            //    NSLog(@"%d",collection[i].runaway);
            
            //Update movement
            //trap check
            GLKVector3 trapPoint;
            BOOL isTrapNear = [self IsNearTrap: &collection[i] : traps : terr : &trapPoint]; //if object is in trap seeing area
            [actions UpdateMovement: &collection[i] : dt : terr : character : isTrapNear : trapPoint];
            [actions CollisionProcession: &collection[i] : dt : [self IsPathBlocked: &collection[i] : terr]];
            BOOL cought = !collection[i].marked && [traps CatchInTrap: &collection[i].position]; //marked = killed
            [actions ObjectCatchProcession: &collection[i] : cought];

            //body
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat,collection[i].movementAngle);
            
            [self UpdateAnimation: &collection[i] : dt];
        }
    }
    self.effect.constantColor = daytimeColor;
}

- (void) Render
{    
    //vertex buffer object is determined by global mesh in upper level class
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            //render all materials
            for (int m = 0; m < model.materialCount ; m++)
            {
                self.effect.texture2d0.name = texID[m];
                if(m == 1) //legs
                {
                    //for all legs
                    for (int l = 0; l < collection[i].legCount; l++) 
                    {
                        self.effect.transform.modelviewMatrix = collection[i].legs[l].rotMat;
                        [effect prepareToDraw];
                        
                        glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));
                    }
                }else //body
                {
                    self.effect.transform.modelviewMatrix = collection[i].displaceMat;
                    [effect prepareToDraw];
                
                    glDrawElements(GL_TRIANGLES, model.patches[m].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndex + model.patches[m].startIndex) * sizeof(GLushort)));
                }
            }
        }
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    [actions ResourceCleanUp];
    free(collection);
    free(texID);
}

#pragma mark - Movement helper Functions

//weather there is obstacle in path of given object, such as bounds of area or other objects
- (BOOL) IsPathBlocked: (SModelRepresentation*) c: (Terrain*) terr
{
    BOOL retVal = NO;
    
    //if is decided to put obstacle check, make sure it does not work when rat is moving to trap, so it wil not get tsuck
    
    //need to stay in beach (betwwn inland and non-island)
    if(![terr IsBeachOcean:c->position])
    {
        //[CommonHelpers Log: [NSString stringWithFormat: @"Crab IsPathBlocked (%f %f %f) ", c->position.x, c->position.y, c->position.z]];
        retVal = YES;
    }
    
    return retVal;
}

//weather trap is in area in which object can move (must be in movement area of object)
- (BOOL) IsTrapInArea: (GLKVector3) tposition: (Terrain*) terr
{
    BOOL retVal = NO;
    
    if([terr IsBeachOcean: tposition])
    {
        retVal = YES;
    }
    
    return retVal;
}


//checks and returns if object is close enaugh to trap to direct to it
//toPoint returns position of trap that object will approach if returned YES
- (BOOL) IsNearTrap: (SModelRepresentation*) c: (StickTrap*) traps: (Terrain*) terr: (GLKVector3*) toPoint
{
    BOOL retVal = NO;
    
    for (int i = 0; i < traps.count; i++)
    {
        if(traps.collection[i].visible && !c->runaway /*!traps.collection[i].runaway*/ && !traps.collection[i].marked && [self IsTrapInArea: traps.collection[i].position : terr]) //trap is visible but no yet anything cought in it
        {
            float distanceObjectTrap = GLKVector3Distance(c->position, traps.collection[i].position);
            
            //object has seen trap and starts approeaching it
            if(distanceObjectTrap < actions.minObjTrapDistance)
            {
                *toPoint = traps.collection[i].position;
                retVal = YES;
                break;
            }
        }
    }
    
    return retVal;
}

#pragma mark - Sceletal animation

- (void) SetUpAnimation: (SModelRepresentation*) c
{
    c->legCount = 8; //number of legs to one object
    
    c->legAnimation.enabled = NO;

    //leg positions relative to local space
    //NOTE: if changing crab model, adjust also the values
    float legSpacing = collection[0].scale / 4.0; //1.5;
    float crabWidth = model.AABBmax.z - model.AABBmin.z;
    float crabLegHeight = model.AABBmax.y - model.AABBmax.y / 2.4;

    //left side
    c->legs[0].position = GLKVector3Make(-2.0 * legSpacing, crabLegHeight, crabWidth / 8.0);
    c->legs[1].position = GLKVector3Make(-legSpacing,       crabLegHeight, crabWidth / 5.4);
    c->legs[2].position = GLKVector3Make(0.0,               crabLegHeight, crabWidth / 4.9);
    c->legs[3].position = GLKVector3Make(legSpacing,        crabLegHeight, crabWidth / 4.5);
    //right side
    c->legs[4].position = GLKVector3Make(c->legs[0].position.x, c->legs[0].position.y, -c->legs[0].position.z);
    c->legs[5].position = GLKVector3Make(c->legs[1].position.x, c->legs[1].position.y, -c->legs[1].position.z);
    c->legs[6].position = GLKVector3Make(c->legs[2].position.x, c->legs[2].position.y, -c->legs[2].position.z);
    c->legs[7].position = GLKVector3Make(c->legs[3].position.x, c->legs[3].position.y, -c->legs[3].position.z);
   
    //each object animation start time
    //left
    c->legs[0].etalonShift = 0.0;
    c->legs[1].etalonShift = 0.3;
    c->legs[2].etalonShift = 0.6;
    c->legs[3].etalonShift = 0.9;
    //right
    c->legs[4].etalonShift = 0.0;
    c->legs[5].etalonShift = 0.3;
    c->legs[6].etalonShift = 0.6;
    c->legs[7].etalonShift = 0.9;
    
    //leg y orientation (spreading)
    /*
    for (int i = 0; i < c->legCount; i++)
    {
        if(i < 4)
        {
            c->legs[i].angle.y = 0;
        }
        else
        {
            c->legs[i].angle.y = M_PI; //four legs on other side, so rotate them
        }
    }
     */
    
    c->legs[0].angle.y = -0.6;
    c->legs[1].angle.y = -0.3;
    c->legs[2].angle.y = 0.0;
    c->legs[3].angle.y = 0.5;
    
    c->legs[4].angle.y = M_PI - c->legs[0].angle.y;
    c->legs[5].angle.y = M_PI - c->legs[1].angle.y;
    c->legs[6].angle.y = M_PI - c->legs[2].angle.y;
    c->legs[7].angle.y = M_PI - c->legs[3].angle.y;
    
    
    //init etalon (all other leg movement will be according to this etalon, only shifted, in order to make sync movement)
    c->legEtalon.angle.x = 0;
    c->legEtalon.limitLower.x = -0.4;//-0.5;
    c->legEtalon.limitUpper.x = 0.4;//0.5;
    c->legEtalon.velocity.x = 5.5; // 5.5 //leg movement speed
    c->legEtalon.started = NO;
}

- (void) StartAnimation:(SModelRepresentation*) c
{
    c->legAnimation.enabled = YES;
   // c->legAnimation.timeInAction = 0;
}

- (void) EndAnimation:(SModelRepresentation*) c
{
    if(c->legAnimation.enabled)
    {
        c->legAnimation.enabled = NO;
        for (int i = 0; i < c->legCount; i++)
        {
            c->legs[i].started = NO;
            c->legs[i].angle.x = 0; //put legs in start position
        }
    }
}


- (void) UpdateAnimation:(SModelRepresentation*) c: (float) dt
{
    //to start animation leg
    /*
    if(c->legAnimation.enabled && c->legAnimation.timeInAction < c->legAnimation.actionTime)
    {
        c->legAnimation.timeInAction += dt;
    }
    */
    
    //c->legs[0].angle.y -= 0.1 * dt;
    
    [self AnimateLegEtalon: c : &c->legEtalon : dt];
    //for all legs
    for (int l = 0; l < c->legCount; l++) 
    {
        //move to crab position
        c->legs[l].rotMat =  GLKMatrix4TranslateWithVector3(c->displaceMat, c->legs[l].position);
        [self AnimateLeg: c : &c->legs[l] : dt];
        c->legs[l].rotMat =  GLKMatrix4RotateX(c->legs[l].rotMat, c->legs[l].angle.x);
        //rotate legs to spread out
        if(c->legs[l].angle.y != 0)
        {
            c->legs[l].rotMat =  GLKMatrix4RotateY(c->legs[l].rotMat, c->legs[l].angle.y);
        }
    }
    
    //if object is cought, stop animation
    if(c->marked)
    {
        [self EndAnimation:c];
    }
}

//animate etalon of legs
- (void) AnimateLegEtalon:(SModelRepresentation*) c: (SSceletalAnimation*) etalon: (float) dt
{
    if(c->legAnimation.enabled)
    {
        //start to animate etalon
        if(!etalon->started)
        {    
            etalon->started = YES;
        }
        
        if(etalon->started)
        {
            //change velocity
            if(etalon->angle.x >= etalon->limitUpper.x)
            {    
                etalon->angle.x = etalon->limitUpper.x;
                etalon->velocity.x = -1 * etalon->velocity.x; //change velocty sign
            }
            else
            if(etalon->angle.x <= etalon->limitLower.x)
            {
                etalon->angle.x = etalon->limitLower.x;
                etalon->velocity.x = -1 * etalon->velocity.x;
            }
            
            etalon->angle.x += etalon->velocity.x * dt;
        }
    }
}

//animation of leg
- (void) AnimateLeg:(SModelRepresentation*) c: (SSceletalAnimation*) leg: (float) dt
{
    if(c->legAnimation.enabled)
    {
        if(c->legEtalon.velocity.x > 0) //moving in positiove direction
        {
            float limiEtalonShiftDelta = c->legEtalon.limitLower.x + leg->etalonShift;
            
            if(c->legEtalon.angle.x < limiEtalonShiftDelta)//is etalon moving up and leg has to move down
            {
                //in this case move leg down, although etalon is moving up
                float distanceEtalonLimit = (c->legEtalon.limitLower.x - c->legEtalon.angle.x);
                leg->angle.x = c->legEtalon.limitLower.x + distanceEtalonLimit + leg->etalonShift; //simulate as if etalon moves over the limit
            }else
            {
                //normalm increment
                leg->angle.x = c->legEtalon.angle.x - leg->etalonShift;
            }
        }else //negative direction
        {
            float limiEtalonShiftDelta = c->legEtalon.limitUpper.x - leg->etalonShift;
            
            if(c->legEtalon.angle.x > limiEtalonShiftDelta) //is etalon moving down and leg has to move up
            {
                //in this case move leg up, although etalon is moving down
                float distanceEtalonLimit = (c->legEtalon.limitUpper.x - c->legEtalon.angle.x);
                leg->angle.x = c->legEtalon.limitUpper.x + distanceEtalonLimit - leg->etalonShift; //simulate as if etalon moves over the limit
            }else
            {
                //normal increment
                leg->angle.x = c->legEtalon.angle.x + leg->etalonShift;
            }
        }
    }
}

#pragma mark - Picking function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv 
{
    int returnVal = 0;
    
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible && collection[i].marked) //if object is in trap
        {
            resultBool = [CommonHelpers IntersectLineSphere: collection[i].position: collection[i].bsRadius: 
                                                    charPos: pickedPos: pickDistance];
            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance:ITEM_CRAB_RAW]) //succesfully added
                {
                    collection[i].visible = false;
                    returnVal = 1;
                }
                
                break;
            }
        }
    }
    
    return returnVal;
}


@end
