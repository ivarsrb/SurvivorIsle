//
//  PalmTree.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "PalmTree.h"

@implementation PalmTree
@synthesize modelTrunk,effectTrunk,collection,
            vertexCount,indexCount,count,modelTrunk2, modelBranch , effectBranch,
            vertexDynamicCount,indexDynamicCount,palmHeight, trunkBounds;

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
- (void) ResetData: (GeometryShape*) mesh : (GeometryShape*) meshDynamic : (Terrain*) terr : (Interaction*) intr
{
    //recalculate positions and update vertex buffer
    for (int i = 0; i < count; i++) 
    {
        
        while (YES) //reselect location until free space found
        {
            collection[i].position = [CommonHelpers RandomInCircleSector: terr.inlandCircle.center : terr.middleCircle.radius : terr.inlandCircle.radius : 0];
            
            //boudning trunk circles (is multiplied for positioning in interaction moudule)
            float extraRadius;
            switch (collection[i].type)
            {
                case TT_STRAIGHT:
                    extraRadius = 0.2;
                    collection[i].crRadius = modelTrunk2.crRadius + extraRadius;
                    break;
                case TT_BENDED:
                    extraRadius = -0.3;
                    collection[i].crRadius = modelTrunk.crRadius + extraRadius;
                    //NSLog(@"%f", collection[i].crRadius);
                    break;
            }
            
            if(![intr IsPlaceOccupiedOnStartup: &collection[i]])
            {
                break;
            }
            
            //NSLog(@"In palmtree");
        }
        
        //if place is free, set it
        collection[i].located = true;
        //torn so bended palms are headed outward from island
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(collection[i].position, terr.islandCircle.center));
        collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ: pVect];
        collection[i].position.y = [terr GetHeightByPoint: &collection[i].position];
        collection[i].num = 0; //no attached cocos
    }
    
    
    //init branch parameters
    int bcnt = 0;
    for (int i = 0; i < count; i++)
    {
        for (int j = 0; j < brachesPerTree; j++)
        {
            //rotation point, position
            branches[bcnt].position = collection[i].position;
            branches[bcnt].position.y = collection[i].position.y + palmHeight;
            //initial orientation
            //float orientationY = [CommonHelpers RandomInRange:0 :2*M_PI :5]; //directions of branch
            float orientationY = [CommonHelpers ValueInNewRange: 0 : brachesPerTree : 0 : PI_BY_2 : j]; //directions of branch
            //make one leaf up - one down - one up - one down....
            float angle = [CommonHelpers RandomInRange: 0 : M_PI_4 : 100];
            if(j % 2 == 0)
            {
                angle *= -1;
            }
            float orientationX = angle; //[CommonHelpers RandomInRange:-M_PI/4. :M_PI/4. :100]; //up down orienatation
            branches[bcnt].angle = GLKVector3Make(orientationX, orientationY, 0);
            //offset (swaying) angle
            branches[bcnt].offsetAngle = GLKVector3Make(0, 0, 0); //branchis will sway when x or y are not 0

            bcnt++;
        }
    }
    swingTime = 0; //branch swing time, used in sine
    
    //assign turnk bounds
    [self AssignTrunkBounds];
    
    [self UpdateVertexArray: mesh];
    [self UpdateDynamicVertexArray: meshDynamic : YES];
}

- (void) InitGeometry
{
    //palm type count
    straightCount = 2;
    bendedCount = 3;
    count = straightCount + bendedCount;
    brachesPerTree = 15;
    bracheCount = count * brachesPerTree;
    
    collection = malloc(count * sizeof(SModelRepresentation));
    branches = malloc(bracheCount * sizeof(SBranchAnimation));
    trunkBounds = malloc(count * sizeof(SPalmBounds));
    
    //set scale and types
    float trunkScale = 1.0;
    for (int i = 0; i < count; i++)
    {
        //collection[i].scale = trunkScale;
        
        //detremine palmtree types
        if(i < straightCount) //half of trees are straight
        {
            collection[i].type = TT_STRAIGHT;
        }
        else
        {
            collection[i].type = TT_BENDED;
        }
    }
    
    //models
    modelTrunk = [[ModelLoader alloc] initWithFileScale: @"palmtree.obj" : trunkScale]; //bended
    modelTrunk2 = [[ModelLoader alloc] initWithFileScale: @"palmtree2.obj" : trunkScale]; //straight
    float branchScale = 2.3; //2.0;
    modelBranch = [[ModelLoader alloc] initWithFileScale: @"palm_branch.obj": branchScale]; //branch
    
    //set palm height
    //NOTE! assuming every palm have identical scale and size
    palmHeight = modelTrunk.AABBmax.y;
    
    //vertex and index counts in both palm trunks must match
    //trunk
    vertexCount = bendedCount*modelTrunk.mesh.vertexCount + straightCount*modelTrunk2.mesh.vertexCount;
    indexCount = bendedCount*modelTrunk.mesh.indexCount + straightCount*modelTrunk2.mesh.indexCount;
    
    //branch
    vertexDynamicCount = modelBranch.mesh.vertexCount * bracheCount;
    indexDynamicCount = modelBranch.mesh.indexCount * bracheCount;
    
   // NSLog(@"%d %d",modelBranch.mesh.vertexCount, modelBranch.mesh.indexCount ); //34 108
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
//fill indices and fill empty vertex data to reserve space for later filling
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    firstVertexTrunk = *vCnt;
    firstIndexTrunk = *iCnt;
    //trunk
    for (int i = 0; i < count; i++) 
    {
        for (int n = 0; n < modelTrunk.mesh.vertexCount; n++) 
        {
            //vertices 
            //dummy
            mesh.verticesT[*vCnt].vertex = GLKVector3Make(0, 0, 0);
            mesh.verticesT[*vCnt].tex = GLKVector2Make(0, 0);
            *vCnt = *vCnt + 1;
        }
        for (int n = 0; n < modelTrunk.mesh.indexCount; n++) 
        {
            //indices
            switch (collection[i].type) 
            {
                case TT_STRAIGHT:
                    mesh.indices[*iCnt] =  modelTrunk2.mesh.indices[n] + firstVertexTrunk + (i * modelTrunk2.mesh.vertexCount);
                    break;
                case TT_BENDED:
                    mesh.indices[*iCnt] =  modelTrunk.mesh.indices[n] + firstVertexTrunk + (i * modelTrunk.mesh.vertexCount);
                    break;                
            }
           
            *iCnt = *iCnt + 1;
        }
    }
    
   // NSLog(@"%d %d %d %d %d   cnti %d  cntv %d", bendedCount,modelTrunk.mesh.indexCount, straightCount,
   //                          modelTrunk2.mesh.indexCount, firstIndexTrunk, *iCnt, *vCnt);

}


//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
//fill indices and fill empty vertex data to reserve space for later filling
- (void) FillDynamicGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //branch
    firstVertexBranch = *vCnt;
    firstIndexBranch = *iCnt;
    for (int i = 0; i < bracheCount; i++)
    {
        for (int n = 0; n < modelBranch.mesh.vertexCount; n++)
        {
            //vertices
            //dummy
            mesh.verticesT[*vCnt].vertex = GLKVector3Make(0, 0, 0);
            mesh.verticesT[*vCnt].tex = GLKVector2Make(0, 0);
            *vCnt = *vCnt + 1;
        }
        
        for (int n = 0; n < modelBranch.mesh.indexCount; n++)
        {
            //indices
            mesh.indices[*iCnt] =  modelBranch.mesh.indices[n] + firstVertexBranch + (i*modelBranch.mesh.vertexCount);
            *iCnt = *iCnt + 1;
        }
    }
}

//fill vertex array with new values
- (void) UpdateVertexArray:(GeometryShape*) mesh
{
    //load model into external geometry mesh
    int vCnt = firstVertexTrunk;
    
    //trunk
    for (int i = 0; i < count; i++) 
    {
        for (int n = 0; n < modelTrunk.mesh.vertexCount; n++) 
        {
            //vertices 
            switch (collection[i].type) 
            {
                case TT_STRAIGHT:
                    mesh.verticesT[vCnt].vertex.x = modelTrunk2.mesh.verticesT[n].vertex.x + collection[i].position.x;
                    mesh.verticesT[vCnt].vertex.y = modelTrunk2.mesh.verticesT[n].vertex.y + collection[i].position.y;
                    mesh.verticesT[vCnt].vertex.z = modelTrunk2.mesh.verticesT[n].vertex.z + collection[i].position.z;
                    mesh.verticesT[vCnt].tex =  modelTrunk2.mesh.verticesT[n].tex;                  
                    break;
                case TT_BENDED:
                    mesh.verticesT[vCnt].vertex.x = modelTrunk.mesh.verticesT[n].vertex.x + collection[i].position.x;
                    mesh.verticesT[vCnt].vertex.y = modelTrunk.mesh.verticesT[n].vertex.y + collection[i].position.y;
                    mesh.verticesT[vCnt].vertex.z = modelTrunk.mesh.verticesT[n].vertex.z + collection[i].position.z;
                    mesh.verticesT[vCnt].tex =  modelTrunk.mesh.verticesT[n].tex;
                    break;
            }
            //rotate to orientation
            [CommonHelpers RotateY: &mesh.verticesT[vCnt].vertex : collection[i].orientation.y : collection[i].position];
            
            vCnt = vCnt + 1;
        }
        
        //NSLog(@"palm %d",i);
    }
}

//fill vertex array with new values
- (void) UpdateDynamicVertexArray: (GeometryShape*) mesh : (BOOL) start
{
    //load model into external geometry mesh
    int vCnt = firstVertexBranch;
    //branch
    int bCnt = 0; //branch cound
    for (int i = 0; i < count; i++)
    {
        for (int b = 0; b < brachesPerTree; b++)
        {
            if(start) //statically init vertices
            {
                for (int n = 0; n < modelBranch.mesh.vertexCount; n++)
                {
                    //vertices
                    mesh.verticesT[vCnt].vertex.x = (modelBranch.mesh.verticesT[n].vertex.x + branches[bCnt].position.x);
                    mesh.verticesT[vCnt].vertex.y = (modelBranch.mesh.verticesT[n].vertex.y + branches[bCnt].position.y);
                    mesh.verticesT[vCnt].vertex.z = (modelBranch.mesh.verticesT[n].vertex.z + branches[bCnt].position.z);
                    mesh.verticesT[vCnt].tex =  modelBranch.mesh.verticesT[n].tex;
                    
                    //rotate to orientation
                    [CommonHelpers RotateX:&mesh.verticesT[vCnt].vertex :branches[bCnt].angle.x: branches[bCnt].position];
                    [CommonHelpers RotateY:&mesh.verticesT[vCnt].vertex :branches[bCnt].angle.y: branches[bCnt].position];

                    vCnt = vCnt + 1;
                }
            }else  //dynamic updating
            {
                for (int n = 0; n < modelBranch.mesh.vertexCount; n++)
                {
                    [CommonHelpers RotateX:&mesh.verticesT[vCnt].vertex :branches[bCnt].offsetAngle.x: branches[bCnt].position];
                    
                    //[CommonHelpers RotateXFast:&mesh.verticesT[vCnt].vertex :branches[bCnt].offsetAngle.x: branches[bCnt].position];
                    
                    vCnt = vCnt + 1;
                }
            }
        
            bCnt++;
        }
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effectTrunk = [[GLKBaseEffect alloc] init];
    self.effectTrunk.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectBranch = [[GLKBaseEffect alloc] init];
    self.effectBranch.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];

    //load model textures
    GLuint texIDtrunk = [[SingleGraph sharedSingleGraph] AddTexture:[modelTrunk.materials objectAtIndex:0]  : YES]; //128x128
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    GLuint texIDbranch = [[SingleGraph sharedSingleGraph] AddTexture:[modelBranch.materials objectAtIndex:0]  : YES]; //64x64
    
    self.effectTrunk.texture2d0.enabled = GL_TRUE;
    self.effectTrunk.texture2d0.name = texIDtrunk; 
    self.effectBranch.texture2d0.enabled = GL_TRUE;
    self.effectBranch.texture2d0.name = texIDbranch;
    
    self.effectTrunk.useConstantColor = GL_TRUE;
    self.effectBranch.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor:(GeometryShape*) meshDynamic
{
    //dont swing for older devices
    if([[SingleDirector sharedSingleDirector] deviceType] != DEVICE_IPHONE_CLASSIC)
    {
        [self UpdateBranches:dt];
        [self UpdateDynamicVertexArray:meshDynamic:NO];
    }
    
    self.effectTrunk.transform.modelviewMatrix = *modelviewMat;
    self.effectTrunk.constantColor = daytimeColor;
    self.effectBranch.transform.modelviewMatrix = *modelviewMat;
    self.effectBranch.constantColor = daytimeColor;
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    //palm trunk
    [[SingleGraph sharedSingleGraph] SetCullFace:YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    [self.effectTrunk prepareToDraw];
    
    //NSLog(@"%d %d %d %d | %d ", bendedCount, modelTrunk.mesh.indexCount, straightCount, modelTrunk2.mesh.indexCount,firstIndexTrunk);
    
    glDrawElements(GL_TRIANGLES, bendedCount * modelTrunk.mesh.indexCount + straightCount * modelTrunk2.mesh.indexCount,
                   GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndexTrunk * sizeof(GLushort)));
}

- (void) RenderDynamic
{
    //vertex buffer object is determined by global mesh in upper level class
    [[SingleGraph sharedSingleGraph] SetCullFace:NO];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    //palm branch
    [self.effectBranch prepareToDraw];
    glDrawElements(GL_TRIANGLES, modelBranch.mesh.indexCount * bracheCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndexBranch * sizeof(GLushort)));
}


- (void) ResourceCleanUp
{
    self.effectTrunk = nil;
    self.effectBranch = nil;
    [modelTrunk ResourceCleanUp];
    [modelTrunk2 ResourceCleanUp];
    [modelBranch ResourceCleanUp];
    free(collection);
    free(branches);
    free(trunkBounds);
}

#pragma mark - Additional functions

//update brach parameters
- (void) UpdateBranches:(float) dt
{
    float swingAplitude = 0.004; //how heavy branchis swing
    
    swingTime += dt;
    
    for (int i = 0; i < bracheCount; i++)
    {
        branches[i].offsetAngle.x = sinf(swingTime + i) * swingAplitude;
    }
    
    //nil swing value
    //must be from no 0 to 2 * PI
    if(swingTime >= PI_BY_2)
    {
        swingTime = swingTime - PI_BY_2;
    }
}

#pragma mark - Cocos related functions

//#v.1.1.
//return place for coconuts on random palmtree, return number of palm to which it was attached
//each palm can store max 4 cocos pointed in 4 direction
//cocos.num - number of palm that cocos is attached
//palm.num - represent the number how many cocoses are attached to certain palm, should be 0 - 4, 0=no cocos, 1 - cocos in north, 2 - cocos at east, etc
- (void) PlaceOnPalmtree: (SModelRepresentation*) c;
{
    float radiusMultiplier = 1.5;
    float topLower = c->bsRadius * 1.5; //by how much lower than palm top
    SCircle rcircle;
    float angle = 0.0; //cocos location angle
    
    //randomly pick a palm
    //NOTE: if cocos count is > palm_c * 4, it will get stuck
    while (true)
    {
        int palmId = [CommonHelpers RandomInRange: 0 : count - 1];
        if(collection[palmId].num < 4) //it means there is still some place left in current palm
        {
            c->num = palmId;
            rcircle.center = collection[c->num].position;
            rcircle.radius = c->bsRadius * radiusMultiplier;
            //place cocos on palm in the side starting from north (relative north, we dont care where, they should not touch each other)
            switch (collection[palmId].num)
            {
                case 0: //north
                    angle = 0.0;
                    collection[palmId].num++;
                    break;
                case 1: //east
                    angle = M_PI_2;
                    collection[palmId].num++;
                    break;
                case 2: //south
                    angle = M_PI;
                    collection[palmId].num++;
                    break;
                case 3: //west
                    angle = M_PI + M_PI_2;
                    collection[palmId].num++;
                    break;
                default:
                    break;
            };
            
            break;
        }
        //NSLog(@"a");
    }

    angle += (c->num * (M_PI / 6.0)); //add extra pffset for a palm so not all look ponted in the same dirrection
    //c->movementAngle = angle; //store so we can use it to direct a fall down (about Y axis)
    
    c->position = [CommonHelpers PointOnCircle: rcircle : -angle + M_PI_2]; //add this to angle because PointOnCircle is -x based
    c->position.y = collection[c->num].position.y + palmHeight - topLower;
    
    //-env.windAngle - M_PI_2;
}


#pragma mark - Trunk bounds for collision

//calculate and fill trunk bounds
/*
    For each palm joint, its centroid and radius is calculated, those circles are used for colision detection.
    When later checking for collision detection pair of joints is determined between whick the object lies,
     centroid and radius is interpolated to detemrine if collision accured agaoinst interpolated (lerped) joint circle
*/
- (void) AssignTrunkBounds
{
    //fill verties for each join for each palm
    for (int i = 0; i < count; i++) //pam count
    {
        for (int j = 0; j < PALM_JOINT_COUNT; j++)
        {
            float previousY = FLT_MIN;
            if(j > 0)
            {
                previousY = trunkBounds[i].center[j - 1].y;
            }
            float jointY = [self GetLowestYInPalm: i : previousY];
            
            GLKVector3 vertexMass = GLKVector3Make(0, 0, 0);
            int vCount = 0;
            for (int n = 0; n < modelTrunk.mesh.vertexCount; n++)
            {
                GLKVector3 vertex;
                //determine vertex
                switch (collection[i].type)
                {
                    case TT_STRAIGHT:
                        vertex = GLKVector3Add(modelTrunk2.mesh.verticesT[n].vertex, collection[i].position);
                        break;
                    case TT_BENDED:
                        vertex = GLKVector3Add(modelTrunk.mesh.verticesT[n].vertex, collection[i].position);
                        break;
                }

                if(vertex.y == jointY)
                {
                    //rotate to orientation
                    [CommonHelpers RotateY: &vertex : collection[i].orientation.y : collection[i].position];
                    //determine vertex mass to calculate centroid
                    vertexMass = GLKVector3Add(vertexMass, vertex);
                    //store only one - first vertice for joint to determine radious
                    if(vCount == 0)
                    {
                        trunkBounds[i].vertice[j]= vertex;
                        vCount++;
                    }
                }
            }
            vertexMass = GLKVector3DivideScalar(vertexMass, VERTEX_PER_JOINT);
            //joint centroid
            trunkBounds[i].center[j] = GLKVector3Make(vertexMass.x, jointY, vertexMass.z); //centroid
            //joint radius, since all vertex radiuses is very close, take only first vertice to determine radius
            trunkBounds[i].radius[j] = GLKVector3Distance(trunkBounds[i].vertice[j],trunkBounds[i].center[j]);
            /*
            //calculated longest radius
            trunkBounds[i].radius[j] = FLT_MIN;
            for (int n = 0; n < VERTEX_PER_JOINT; n++)
            {
                float dist = GLKVector3Distance(trunkBounds[i].vertices[j][n],trunkBounds[i].center[j]);
                if(dist > trunkBounds[i].radius[j])
                {
                    trunkBounds[i].radius[j] = dist;
                }
            }
            */
           // NSLog(@"%f %f %f", trunkBounds[i].center[j].x, trunkBounds[i].center[j].y, trunkBounds[i].center[j].z);
        }
    }
}

// go through the palm and find its lowest joiny y value, except not lower than/equal to passed value (needed for sorting)
//pass FLT_MIN for notLowerEqualThan if the first needed
- (float) GetLowestYInPalm: (int) palmIndex : (float) notLowerEqualThan
{
    float lowestY = FLT_MAX;
    //find the lowest height vertices and assign as index 0, repeat for all joints increasing index
    for (int n = 0; n < modelTrunk.mesh.vertexCount; n++)
    {
        float currentLowerY=FLT_MIN;
        //vertices
        switch (collection[palmIndex].type)
        {
            case TT_STRAIGHT:
                currentLowerY = modelTrunk2.mesh.verticesT[n].vertex.y + collection[palmIndex].position.y;
                break;
            case TT_BENDED:
                currentLowerY = modelTrunk.mesh.verticesT[n].vertex.y + collection[palmIndex].position.y;
                break;
            //NOTE: no rotation is performed here
        }
        if(currentLowerY > notLowerEqualThan) //exclude the ones we dont need
        {
            lowestY = fminf(lowestY, currentLowerY);
        }

    }
    
    return lowestY;
}
/*
//recieve palm index and height value, find to which joint it is closer
- (int) GetPalmJointIndexByY: (int) palmIndex : (float) height
{
    int jointIndex = 0;
    
    float hDelta = FLT_MAX;
    
    //check current and previous differences between position and a joint, if it gets bigger it is time to stop
    for (int j = 0; j < PALM_JOINT_COUNT; j++)
    {
        float thishDelta = fabs(trunkBounds[palmIndex].center[j].y - height);
        if(thishDelta > hDelta) //distance gets bigger so we stop
        {
            break;
        }
        hDelta = thishDelta;
        jointIndex = j;
    }
    
    return jointIndex;
}
*/

//calculate between what indexes of joints the current y is placed (return through params), if lower tha palm or higher, return false
//height - y position of checkable object
- (BOOL) GetUpDownJointsByY: (int) palmIndex : (float) height : (int*) lowerJoint : (int*) upperJoint
{
    BOOL isBetweenJonts = false;
    *lowerJoint = -1;
    *upperJoint = -1;
    
    for (int j = 0; j < PALM_JOINT_COUNT; j++)
    {
        if(height > trunkBounds[palmIndex].center[j].y && j < PALM_JOINT_COUNT - 1)
        {
            if(height <= trunkBounds[palmIndex].center[j+1].y)
            {
                *lowerJoint = j;
                *upperJoint = j + 1;
                isBetweenJonts = true;
                break;
            }
        }
    }
    
    return isBetweenJonts;
}


@end
