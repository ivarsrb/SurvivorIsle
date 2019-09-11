//
//  SmallPalm.m
//  SurvivorIsle
//
//  Created by Ivars Rusbergs on 26/05/15.
//  Copyright (c) 2015 Ivars Rusbergs. All rights reserved.
//
// Status -
// -------------
// NOTE: leaf object is used in 3 places with 3 different models - here, shelter leaves and leaf in hand
// Picked up leaf and leaves that are put un ground are rpocessed in HandLeaf module not here, here is only when on palm and just cut down
// -------------
#import "SmallPalm.h"

@implementation SmallPalm
@synthesize count, collection, brancheCollection, modelTrunk, modelBranch, effectTrunk, effectBranch, bufferAttribsTrunk, bufferAttribsBranch;


- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}

//data that needs to set before resetting data, like nilling object locations (so random locations detection work correctly)
- (void) PresetData
{
    for (int i = 0; i < count; i++)
    {
        collection[i].located = false;
    }
}

//data that changes from game to game
- (void) ResetData: (Terrain*) terr : (Interaction*) intr
{
    int bCnt = 0; //branch count
    for (int i = 0; i < count; i++)
    {
        //trunk/smallpalm
        collection[i].orientation.y = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 10];
        collection[i].crRadius = modelTrunk.crRadius * 3.0; //used for movement check, placing check and placing at satrtup or picking (modified in function)
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircle : terr.middleCircle.center : terr.middleCircle.radius : 0];
            
            //[modelBranch  AssignBounds: &collection[i] : 0];
            
            if(![intr IsPlaceOccupiedOnStartup: &collection[i]])
            {
                break;
            }
        }
        
        collection[i].located = true;
        collection[i].position.y = [terr GetHeightByPoint: &collection[i].position];
        collection[i].visible = true;
        
        //branch
        for (int j = 0; j < branchesPerPalm; j++)
        {
            float branchOriginHeight = modelTrunk.AABBmax.y - modelTrunk.AABBmax.y * 0.07;//modelTrunk.AABBmax.y * 0.15;
            brancheCollection[bCnt].position = collection[i].position;
            brancheCollection[bCnt].position.y += branchOriginHeight;
            brancheCollection[bCnt].orientation.y = j * M_PI_2 + collection[i].orientation.y;
            brancheCollection[bCnt].orientation.x = M_PI / 3.0;

            [modelBranch AssignBounds: &brancheCollection[bCnt] : 0];
            
            //parameters
            brancheCollection[bCnt].visible = true;
            brancheCollection[bCnt].marked = false; //cut down ready to be pcked up
            brancheCollection[bCnt].moving = false; //started to fall down
            
            //bsRadius is used as leaf cutting radius to check against knife
            brancheCollection[bCnt].bsRadius = brancheCollection[bCnt].crRadius / 8.0; //brancheCollection[bCnt].crRadius / 8.0;
            bCnt++;
        }
        
    }
    
    swingTime = 0; //branch swing time, used in sine
}


- (void) InitGeometry
{
    //NOTE: if leave number is changed, change also in hand leaf module
    count = 2; //number of smallpalms
    branchesPerPalm = 4;
    brancheCount = count * branchesPerPalm; //Total number of leaves
    
    collection = malloc(count * sizeof(SModelRepresentation));
    brancheCollection = malloc(brancheCount * sizeof(SModelRepresentation));
    //brancheAnim = malloc(brancheCount * sizeof(SBranchAnimation));
    
    float scaleTrunk = 0.4;
    modelTrunk = [[ModelLoader alloc] initWithFileScale: @"smallpalm_trunk.obj" : scaleTrunk];
    float scaleBranch = 1.2;
    modelBranch = [[ModelLoader alloc] initWithFileScale: @"smallpalm_leaf.obj" : scaleBranch];
    
    bufferAttribsTrunk.vertexCount = modelTrunk.mesh.vertexCount;
    bufferAttribsTrunk.indexCount = modelTrunk.mesh.indexCount;
   
    bufferAttribsBranch.vertexCount = modelBranch.mesh.vertexCount;
    bufferAttribsBranch.indexCount = modelBranch.mesh.indexCount;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    //object will be movable, so we ned only one actual object in array
    
    //trunk
    bufferAttribsTrunk.firstVertex = *vCnt;
    bufferAttribsTrunk.firstIndex = *iCnt;
    for (int n = 0; n < modelTrunk.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelTrunk.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelTrunk.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < modelTrunk.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelTrunk.mesh.indices[n] + bufferAttribsTrunk.firstVertex;
        *iCnt = *iCnt + 1;
    }
    
    //smallpalm branch
    bufferAttribsBranch.firstVertex = *vCnt;
    bufferAttribsBranch.firstIndex = *iCnt;
    for (int n = 0; n < modelBranch.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = modelBranch.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  modelBranch.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    for (int n = 0; n < modelBranch.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  modelBranch.mesh.indices[n] + bufferAttribsBranch.firstVertex;
        *iCnt = *iCnt + 1;
    }
}

- (void) SetupRendering
{
    //textures
    GLuint texIDTrunk = [[SingleGraph sharedSingleGraph] AddTexture: [modelTrunk.materials objectAtIndex:0] : YES]; //64x128
    GLuint texIDBranch = [[SingleGraph sharedSingleGraph] AddTexture: [modelBranch.materials objectAtIndex:0] : YES]; //64x54
    
    //init shaders
    //trunk
    self.effectTrunk = [[GLKBaseEffect alloc] init];
    self.effectTrunk.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectTrunk.texture2d0.enabled = GL_TRUE;
    self.effectTrunk.texture2d0.name = texIDTrunk;
    self.effectTrunk.useConstantColor = GL_TRUE;
    //branch
    self.effectBranch = [[GLKBaseEffect alloc] init];
    self.effectBranch.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectBranch.texture2d0.enabled = GL_TRUE;
    self.effectBranch.texture2d0.name = texIDBranch;
    self.effectBranch.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Environment*) env
{
    self.effectTrunk.constantColor = daytimeColor;
    self.effectBranch.constantColor = daytimeColor;
    
    //trunks
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
        }
    }
    
    //branches
    [self UpdateBranchesSway: dt : env.raining];
    
    //branches
    for (int i = 0; i < brancheCount; i++)
    {
       // NSLog(@"%f", brancheCollection[i].movementAngle);
        if(brancheCollection[i].visible)
        {
            [self UpdateBrancheFalling: i : dt];
            
            brancheCollection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, brancheCollection[i].position);
            //NOTE: if there is something added to angles here, add also to GetPointAboveLeafOrigin function
            brancheCollection[i].displaceMat = GLKMatrix4RotateY(brancheCollection[i].displaceMat, brancheCollection[i].orientation.y + brancheCollection[i].movementAngle);
            brancheCollection[i].displaceMat = GLKMatrix4RotateX(brancheCollection[i].displaceMat, brancheCollection[i].orientation.x + brancheCollection[i].movementAngle);
        }
    }
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    //trunks
    for (int i = 0; i < count; i++)
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace: YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
            self.effectTrunk.transform.modelviewMatrix = collection[i].displaceMat;
            [effectTrunk prepareToDraw];
            glDrawElements(GL_TRIANGLES, modelTrunk.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bufferAttribsTrunk.firstIndex * sizeof(GLushort)));

        }
    }
    
    //branches
    for (int i = 0; i < brancheCount; i++)
    {
        if(brancheCollection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace: NO];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
            self.effectBranch.transform.modelviewMatrix = brancheCollection[i].displaceMat;
            [effectBranch prepareToDraw];
            glDrawElements(GL_TRIANGLES, modelBranch.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(bufferAttribsBranch.firstIndex * sizeof(GLushort)));
            
        }
    }
}


- (void) ResourceCleanUp
{
    self.effectTrunk = nil;
    self.effectBranch = nil;
    [modelTrunk ResourceCleanUp];
    [modelBranch ResourceCleanUp];
    free(collection);
    free(brancheCollection);
}

#pragma mark - Additional function

//update brach swinging
//#TODO =- think about storm
- (void) UpdateBranchesSway: (float) dt : (BOOL) storm
{
    float swingAplitude = 0.05; //how heavy branchis swing
    float swaySpeed = 2.0; //* sinf(swingTime);
    
    swingTime += dt;
    for (int i = 0; i < brancheCount; i++)
    {
        if(brancheCollection[i].visible && !brancheCollection[i].marked && !brancheCollection[i].moving)
        {
            brancheCollection[i].movementAngle = sinf(swingTime * swaySpeed + i) * swingAplitude;
        }
    }
    
    //nil swing value
    //must be from no 0 to 2 * PI
    if(swingTime >= PI_BY_2)
    {
        swingTime = swingTime - PI_BY_2;
    }
}


//functions checks branches cutting taking in knife point and calculating which leaf has been cut
//branchOrigin - return origin of cuted branch
- (BOOL) CheckBranchCutting: (GLKVector3) knifePoint : (GLKVector3*) branchOrigin
{
    //branches
    for (int i = 0; i < brancheCount; i++)
    {
        
        if(brancheCollection[i].visible && !brancheCollection[i].marked && !brancheCollection[i].moving)
        {
            //in order for branches to cut off one-by-one beautifully
            //we need to set new bounding sphere center that is above origin and rotate in order to
            //put it correct place
            GLKVector3 cutCenter = [self GetPointAboveLeafOrigin: i : 0.22];
            
            //check for cutting
            if([CommonHelpers PointInSphere: cutCenter :brancheCollection[i].bsRadius :knifePoint])
            {
                [self CutBranch: i];
                *branchOrigin = cutCenter;//brancheCollection[i].position;
                //[[SingleSound sharedSingleSound]  PlaySound: SOUND_SPEAR];
                return true;
            }
        }
    }
    
    return false;
}


//cut down given leaf/branch
- (void) CutBranch: (int) branchInd
{
    //if(brancheCollection[branchInd].visible && !brancheCollection[branchInd].marked && !brancheCollection[branchInd].moving)
   // {
    brancheCollection[branchInd].moving = true; //leaf falling start
   // }
}


//after leaf/branch is cut, update happens in this function
- (void) UpdateBrancheFalling: (int) branchInd : (float) dt
{
    if(brancheCollection[branchInd].moving)
    {
        float fallSpeed = 1.1; //speed at which cut leaf falls
        brancheCollection[branchInd].orientation.x -= fallSpeed * dt;
        
        //if(brancheCollection[branchInd].timeInMove >= brancheCollection[branchInd].moveTime)
        float fallDownAngle = -M_PI_4 / 3.6;
        if(brancheCollection[branchInd].orientation.x <= fallDownAngle)
        {
            brancheCollection[branchInd].moving = false;
            brancheCollection[branchInd].marked = true; //laf is cut and ready to be picked up
        }
    }
}

//weather given trunk is stripped of all branches
- (BOOL) IsTrunkEmpty: (int) trunkId
{
    if(trunkId >= 0 && trunkId < count) //not out of bounds
    {
        for (int i = (trunkId * branchesPerPalm); i < ((trunkId + 1) * branchesPerPalm); i++) //brahces ar added by 4 to each truunk
        {
            if(brancheCollection[i].visible) //at least one branch is visible
            {
                return false;
            }
        }
        
        return true;
    }
    return false;
}

//return point on a rotated leaf that is aboveOrigin above origin
//ot is rotated inside taking swaying into acount
- (GLKVector3) GetPointAboveLeafOrigin: (int) leafIndex : (float) aboveOrigin
{
    GLKVector3 center = brancheCollection[leafIndex].position;
    center.y += aboveOrigin; //above origin
    //rotate point
    //-M_PI_2 is needed because originally leaf is horizontal (in model) bet here we asuma that it is vertical
    [CommonHelpers RotateX: &center : -M_PI_2 + brancheCollection[leafIndex].orientation.x + brancheCollection[leafIndex].movementAngle : brancheCollection[leafIndex].position]; //displacement should always match rotation
    [CommonHelpers RotateY: &center : brancheCollection[leafIndex].orientation.y + brancheCollection[leafIndex].movementAngle : brancheCollection[leafIndex].position]; //displacement should always match rotation
    return center;
}


#pragma mark - Picking function

//check if object is picked, and add to inventory
//return 0 - has not picked, 1 - picked, 2 - invenotry was full, not able to pick
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Character*) character : (Interface*) inter
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    //bool resultBool;
    for (int i = 0; i < brancheCount; i++)
    {
        if(brancheCollection[i].marked && brancheCollection[i].visible)
        {
            //move pick checking sphere center along leaf further from origin to pick more naturally
            /*
            GLKVector3 pickCenter1 = [self GetPointAboveLeafOrigin: i : 0.22];
            bool resultBool1 = [CommonHelpers IntersectLineSphere: pickCenter1 : brancheCollection[i].bsRadius : charPos : pickedPos : pickDistance];
            
            //move pick checking sphere center along leaf further from origin to pick more naturally
            GLKVector3 pickCenter2 = [self GetPointAboveLeafOrigin: i : 1.0];
            bool resultBool2 = [CommonHelpers IntersectLineSphere: pickCenter2 : brancheCollection[i].bsRadius : charPos : pickedPos : pickDistance];
            */
            //if(resultBool1 || resultBool2)
            
            BOOL resultBool = [CommonHelpers IntersectLineSphere: brancheCollection[i].position : brancheCollection[i].crRadius : charPos : pickedPos : pickDistance];
            
            /*
            if(resultBool)
            {
                returnVal = 2;
                if([character.inventory AddItemInstance: ITEM_SMALLPALM_LEAF]) //succesfully added
                {
                    brancheCollection[i].visible = false;
                    
                    //remove trunk when all leaves are gone
                    for (int n = 0; n < count; n++)
                    {
                        if(collection[n].visible && [self IsTrunkEmpty: n])
                        {
                            collection[n].visible = false;
                            break;
                        }
                    }
                    
                    returnVal = 1;
                }
                
                break;
            }
            */
            
            
            if(resultBool)
            {
                returnVal = 2;
                //it can be held in hand so first try to put in hand
                if([character PickItemHand: inter : ITEM_SMALLPALM_LEAF])
                {
                    returnVal = 1;
                }else
                {
                    //if hand was not empty, try adding to inventory
                    if([character.inventory AddItemInstance: ITEM_SMALLPALM_LEAF]) //succesfully added
                    {
                        returnVal = 1;
                    }
                }
                
                //process picking
                if(returnVal == 1)
                {
                    brancheCollection[i].visible = false;
                    
                    //remove trunk when all leaves are gone
                    for (int n = 0; n < count; n++)
                    {
                        if(collection[n].visible && [self IsTrunkEmpty: n])
                        {
                            collection[n].visible = false;
                            break;
                        }
                    }
                }
                
                break;
            }
        }
    }
    
    return returnVal;
}

//--------------
// Leaf dropping and holding in hand is in HandLeaf module
//--------------
@end
