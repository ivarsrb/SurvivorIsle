//
//  Beehive.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 15/07/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// STATUS -

#import "Beehive.h"

@implementation Beehive
@synthesize model, effect, hive, bufferAttribs, insects, beeswarm;

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
- (void) ResetData: (Terrain*) terr : (PalmTree*) palms
{
    float height = 2.0; //above ground
    //point on palm center
    GLKVector3 palmCenter = palms.collection[0].position;
    palmCenter.y += height;
    
    //point in middle of island
    GLKVector3 islandCenter = terr.islandCircle.center;
    islandCenter.y += height;
    
    //hive position
    float extraShift = hive.bsRadius / 3.0; //slightly move outward
    float distFromPalmCenter = -hive.bsRadius - extraShift;
    hive.position = [CommonHelpers PointOnLine: islandCenter : palmCenter : distFromPalmCenter];
    //torn hive so it always faces inward
    GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(hive.position, terr.islandCircle.center));
    hive.orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
    
    //parameters
    hive.visible = true; //honey picked or not
    hive.marked = false; //weather honey is pickable (swarm no longer guards it)
    beeswarm.moving = false; //movement of whole swarm, not movement of individual insects
    stingInterval.timeInAction = 0.0; //this variable helps to make gap between bee stings
}

- (void) InitGeometry
{
    float scale = 0.25;
    model = [[ModelLoader alloc] initWithFileScale: @"beehive.obj": scale];
    
    bufferAttribs.vertexCount = model.mesh.vertexCount;
    bufferAttribs.indexCount = model.mesh.indexCount;
    
    hive.bsRadius = model.bsRadius;
    
    [self InitBeeMovementVectors];
    
    //parameters
    stingInterval.actionTime = 1.0; //interval between bee bites in seconds (when bee swarm is on character)
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
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
    
    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0] : YES]; 
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID;
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update :(float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Particles*) particles : (Character*) character :  (Interface*) intr
{
    self.effect.constantColor = daytimeColor;
    
    //start bee swarm particle
    if(!particles.beeSwarmPrt.started && hive.visible && !hive.marked)
    {
        beeswarm.position = hive.position; //initial insect swarm position
        [particles.beeSwarmPrt Start: beeswarm.position]; //ends only when bees flie off
    }
    
    //update bee swarm
    [self UpdateBeeMovement: dt : particles : character : intr];
    
    if(hive.visible)
    {
        hive.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, hive.position);
        hive.displaceMat = GLKMatrix4RotateY(hive.displaceMat, hive.orientation.y);
    }
}

- (void) Render
{
    if(hive.visible)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace: YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        self.effect.transform.modelviewMatrix = hive.displaceMat;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bufferAttribs.firstIndex * sizeof(GLushort)));
    }
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(insects);
}

#pragma mark - Bee particle movement

//init bee movement vectors in all direction
- (void) InitBeeMovementVectors
{
    int partCount = PRTCL_BEE_COUNT;
    //used to dfifferentate movement of each bee
    insects = malloc(partCount * sizeof(SModelRepresentation));
    for (int i = 0; i < partCount; i++)
    {
         //moveemnt vector is used to give each bee diferent rotation angle
        insects[i].movementVector = GLKVector3Make(1.0, 0.0, 0.0);
        //set random rotation values for each bee
        [CommonHelpers RotateZ: &insects[i].movementVector : [CommonHelpers RandomInRange: 0.0 : PI_BY_2 : 1000]];
        [CommonHelpers RotateY: &insects[i].movementVector : [CommonHelpers RandomInRange: 0.0 : PI_BY_2 : 1000]];
        //[CommonHelpers RotateY: &insects[i].movementVector : i * (PI_BY_2 / partCount)];
        //[CommonHelpers RotateZ: &insects[i].movementVector : i * (PI_BY_2 / partCount)];
    }
}

//bee movement
- (void) UpdateBeeMovement: (float) dt : (Particles*) particles : (Character*) character :  (Interface*) intr
{
    float swarmRadius = 0.7; //how large bee swarm is
    
    //when bees are scared off by smoke, move them away and end
    if(particles.beeSwarmPrt.started && hive.marked)
    {
        float swarmFleeingSpeed = 1;
        float swarmFleeingMaxHeight = 15; //height after which bee swarm idssapears
        
        //fly up
        beeswarm.position.y += swarmFleeingSpeed * dt;
        //beeswarm.position.x += sinf(particles.beeSwarmPrt.particles[0].lifetime.current * 10);
        //jump randomly around in panic
        beeswarm.position.x += [CommonHelpers RandomInRange: -0.2 : 0.2 : 1000];
        beeswarm.position.z += [CommonHelpers RandomInRange: -0.2 : 0.2 : 1000];
        
        if(beeswarm.position.y >= swarmFleeingMaxHeight)
        {
            //hide bees
            [particles.beeSwarmPrt End];
        }
    }

    //update bee movement guarding honey, when it is still not smoked
    if(particles.beeSwarmPrt.started && hive.visible && !hive.marked)
    {
        float minimalAttackDist = 4.0; //disatnce after what bees well attack you
        float distFromCharToHive = GLKVector3Distance(hive.position, character.camera.position);

        //in bee teritorry - attack character
        if(distFromCharToHive <= minimalAttackDist && character.state == CS_BASIC) //only character in basic mode, otherwise bees will atack while fire drilling or in shelter
        {
            beeswarm.moving = true; //mark that swarm s out of hive
            beeswarm.timeInMove = 0.0; //time that bees are in movement (0 because wee need this time only for return movement, not this)
            
            float approachSpeed = 2.0 * dt; //this value is percentage of distance from bees to character in each step (frp, 0.0 to 1.0)
            //move bees toward player
            beeswarm.position = GLKVector3Lerp(beeswarm.position, character.camera.position, approachSpeed);
            
            beeswarm.endPoint1 = beeswarm.position;//this is place from where swarm will return home
            
            //check bee sting the character
            if([CommonHelpers PointInSphere: beeswarm.position : swarmRadius : character.camera.position])
            {
                if(fequal(stingInterval.timeInAction, 0.0)) //interval between stings
                {
                    float healtDecrement = 0.5;
                    [character DecreaseHealth: healtDecrement : intr : JT_BEE_STING];
                }
                
                //wait seconds before making next sting
                stingInterval.timeInAction += dt;
                if(stingInterval.timeInAction > stingInterval.actionTime)
                {
                    stingInterval.timeInAction = 0.0;
                }
            }else
            {
                stingInterval.timeInAction = 0.0; //nill sting time when character moves out of bee swarm, but not out of attack range
            }
        }
        //out of bee territrry, fly back to hive
        else if(beeswarm.moving)
        {
            stingInterval.timeInAction = 0.0; //nill sting time when character moves out of bee attack range
            
            beeswarm.timeInMove += dt;
            
            float timeOfReturn = 2.0; //seconds to return to hive
            float movementLerpVal = beeswarm.timeInMove / timeOfReturn;  //from 0.0 to 1.0

            //move bees back to hive
            beeswarm.position = GLKVector3Lerp(beeswarm.endPoint1, hive.position, movementLerpVal);
            //if returned to hive
            if(movementLerpVal >= 1.0)
            {
                beeswarm.position = hive.position;
                beeswarm.moving = false;
            }
        }
    }
    
    //update bee insect movement and add position to beeswarm
    if(particles.beeSwarmPrt.started && hive.visible)
    {
        for (int i = 0; i < particles.beeSwarmPrt.attributes.maxCount; i++) //for al insects
        {
            float flyingSpeed = 5.0; //how fast bee fly
            float timeArgument = particles.beeSwarmPrt.particles[i].lifetime.current * flyingSpeed + i;
            float sinVal = sinf(timeArgument);
            float cosVal = cosf(timeArgument);
            
            GLKVector3 insectPosition;
            //by default t is elpise. But multiplaying it by random movementVector gives it different trajectories
            insectPosition.x = swarmRadius * cosVal;
            insectPosition.z = swarmRadius * sinVal;
            insectPosition.y = swarmRadius * sinVal;
            
            insectPosition = GLKVector3Multiply(insectPosition,  insects[i].movementVector); //make each bee trahectory individual

            //set bee position
            insectPosition = GLKVector3Add(insectPosition, beeswarm.position);
            [particles.beeSwarmPrt AssignPosition: i : insectPosition];
        }
    }
}

#pragma mark - Helper

//get rid of bees and enable honey for picking
- (void) SmokeBeehive
{
    if(!beeswarm.moving) //if bees are flown out to attack character, dont allow to smoke
    {
        hive.marked = true;
    }
}


#pragma mark - Picking

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Inventory*) inv
{
    bool resultBool;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    int returnVal = 0;
    
    if(hive.visible && hive.marked)
    {
        resultBool = [CommonHelpers IntersectLineSphere: hive.position : hive.bsRadius : charPos : pickedPos : pickDistance];;
        
        if(resultBool)
        {
            returnVal = 2;
            if([inv AddItemInstance: ITEM_HONEYCOMB]) //succesfully added
            {
                returnVal = 1;
                hive.visible = false;
            }
        }
    }

    return returnVal;
}
@end
