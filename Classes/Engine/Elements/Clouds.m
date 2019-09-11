//
//  Clouds.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Clouds.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation Clouds
@synthesize cloudMesh, effectClouds, collection, effectLightning, lightningStrike,
            lightning, count, radius, effectIlumination, lightningIllumination;

- (id) init
{
    self = [super init];
    if(self != nil) 
    {
        [self InitGeometry];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData
{
    [self InitCloudParams];
    [self InitLightningParams];
}


- (void) InitGeometry
{
    //visCounter = 0;
    count = 60; //100;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    //cloud layer shape
    cloudMesh = [[GeometryShape alloc] init];
    cloudMesh.dataSetType = VERTEX_SET;
    cloudMesh.vertStructType = VERTEX_COLOR_TEX_STR;
    cloudMesh.drawType = DYNAMIC_DRAW;
    
    //initialize cloud parameters
    radius = 140; //around origin
    cloudHeight = 12; //cloud height on top
    
    //init vertices
    cloudVertexCount = count * 4 + 2 * (count - 1); //4 vertices for each triangle strip + 2 vertcies fro degenerate triangles after all but the last
    lightningVertexCount = 4;   //for lightning quad
    iluminationVertexCount = 4; //for lightning ilumination
    cloudMesh.vertexCount = cloudVertexCount + lightningVertexCount + iluminationVertexCount;
    
    [cloudMesh CreateVertexIndexArrays];
    
    //coordinates fro atlas
    [self InitTeztureAtlas];
    
    //lightning
    [self InitLightningGeometry];
    
    //daytime coloring
    /*
    middayColor =   GLKVector4Make(255/255.,255/255.,255/255.,1);
    eveningColor =  GLKVector4Make(255/255.,164/255.,166/255.,1);
    nightColor =    GLKVector4Make(99/ 255. ,98/255.,127/255.,1);
	morningColor =  GLKVector4Make(244/255.,255/255.,117/255.,1);
    */
     
    coloring.midday = GLKVector4Make(255/255.,255/255.,255/255.,1);
    coloring.evening = GLKVector4Make(255/255.,164/255.,166/255.,1);
    coloring.night = GLKVector4Make(99/ 255. ,98/255.,127/255.,1);
    coloring.morning = GLKVector4Make(244/255.,255/255.,117/255.,1);
    
    
}

- (void) SetupRendering
{
    //init shaders
    self.effectClouds = [[GLKBaseEffect alloc] init];
    self.effectClouds.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectLightning = [[GLKBaseEffect alloc] init];
    self.effectLightning.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    self.effectIlumination = [[GLKBaseEffect alloc] init];
    self.effectIlumination.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    [cloudMesh InitGeometryBeffers];
    
    //load textures
    GLuint cloudTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"cloud_atlas._png"   : YES];  //256x256
    GLuint lightningTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"lightning.png"  : YES];  //64x128
    GLuint iluminationTexID  = [[SingleGraph sharedSingleGraph] AddTexture: @"sun.png"     : YES];  //32x32
    
    //clouds
    self.effectClouds.texture2d0.enabled = GL_TRUE;
    self.effectClouds.texture2d0.name = cloudTexID;
    //lighting
    self.effectLightning.texture2d0.enabled = GL_TRUE;
    self.effectLightning.texture2d0.name = lightningTexID;
    //ilumination
    self.effectIlumination.texture2d0.enabled = GL_TRUE;
    self.effectIlumination.texture2d0.name = iluminationTexID;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (Character*) character: (Environment*) env
{
    //get cloud color
	//[CommonHelpers InterpolateDaytimeColor:&dayTimeColor: middayColor:eveningColor:nightColor:morningColor: curTime];
    [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : coloring.midday : coloring.evening : coloring.night : coloring.morning : curTime];

    
    [self UpdateClouds: dt : env];
    [self UpdateLightning: dt];
    
    //update translation matrices
    transMat = GLKMatrix4MakeTranslation(character.camera.position.x, character.camera.position.y - character.height, character.camera.position.z);
    globalTransMat = GLKMatrix4Multiply(*modelviewMat, transMat);
    self.effectClouds.transform.modelviewMatrix = globalTransMat;
    //lightning
    if(lightningStrike.enabled)
    {
        lightning.displaceMat = GLKMatrix4Multiply(globalTransMat,lightning.displaceMat);
        self.effectIlumination.transform.modelviewMatrix = lightning.displaceMat;
        //billboard lighting itself
        [CommonHelpers LoadSphereBillboard: lightning.displaceMat.m];
        self.effectLightning.transform.modelviewMatrix = lightning.displaceMat;
    }
}

- (void) Render
{
    glBindVertexArrayOES(cloudMesh.vertexArray);
    
    [[SingleGraph sharedSingleGraph] SetCullFace:  YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest: NO];
    [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
    [[SingleGraph sharedSingleGraph] SetBlend: YES];
    //this mode workls only for non-premultiplied
    [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_SRC_ALPHA];
    
    [self.effectClouds prepareToDraw];
    //update clouds
    glBindBuffer(GL_ARRAY_BUFFER, cloudMesh.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, cloudMesh.vertexCount * sizeof(SVertexColorTex), cloudMesh.vertices, GL_DYNAMIC_DRAW);
    //render clouds
    glDrawArrays(GL_TRIANGLE_STRIP, 0, cloudVertexCount);
    
    if(lightningStrike.enabled)
    {
        [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_ONE];
       // [[SingleGraph sharedSingleGraph] SetBlendFunc:F_GL_SRC_ALPHA_ONE];
        
        //render ilumination
        [self.effectIlumination prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, cloudVertexCount+lightningVertexCount, iluminationVertexCount);

        //render lightning
        [self.effectLightning prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, cloudVertexCount, lightningVertexCount);
    }
}

- (void) ResourceCleanUp
{
    free(collection);
    [cloudMesh ResourceCleanUp];
    self.effectClouds = nil;
    self.effectLightning = nil;
    self.effectIlumination = nil;
}

#pragma mark - Cloud management

//first-time initialization of cloud params
- (void) InitCloudParams
{
    for (int i = 0; i < count; i++) 
    {
        collection[i].type = CT_BASIC;
        collection[i].visible = true;
        //storm couds
        if(i == 0 || i == 1) //!!!! if these indexes are changed, need to change in lightningUpdate function !!!!!
        {
            collection[i].type = CT_STORM;
            collection[i].marked = false; //true means that this storm currently produces rain
        }
        
        if(collection[i].type == CT_BASIC)
        {
            //random size (half)
            float lowSize = 6;
            float highSize = 9;
            collection[i].size = [CommonHelpers RandomInRange:lowSize :highSize]; //size from center to cloud rect side
        }else 
        {
            //storm size (half)
            collection[i].size = 25;
        }
        
        collection[i].position = [CommonHelpers RandomInCircle: GLKVector3Make(0, 0, 0) :radius :cloudHeight];
    }
    
    for (int i = 0; i < count; i++) 
    {
        [self HideOverLappedClouds:i]; //hide if overlapps with storm
    }
    
    //init cloud geometry
    [self UpdateVertexBuffer:YES];
}


//update clouds
- (void) UpdateClouds:(float)dt:(Environment*) env
{
    float windMultFactor = 0.55 * dt; //cloud movement speed relative to wind speed
    //wind movement vector
    GLKVector3 movementV = GLKVector3MultiplyScalar(env.wind, windMultFactor);
    
    for (int i = 0; i < count; i++) 
    {
        collection[i].position = GLKVector3Add(collection[i].position, movementV);
        
        float distance;
        collection[i].position.y = [self GetHeightOnCloudSphere:collection[i].position: &distance];
        
        //update rain from storm cloud
        if(collection[i].type == CT_STORM)
        {
            //determine storm cloud rain area
            float rainAreaDecr = 5.0; //by how much rain area side will be smaller than cloud
            float rainAreaHalf = collection[i].size - rainAreaDecr; //make rain area a bit msaller than cloud
            CGRect stormArea = CGRectMake(collection[i].position.x - rainAreaHalf, collection[i].position.z - rainAreaHalf,
                                          rainAreaHalf * 2, rainAreaHalf * 2);

            if(!env.raining) //not raining (switch on rain)
            {
                if(CGRectContainsPoint(stormArea, CGPointMake(0, 0)))
                {
                    env.raining = YES;
                    collection[i].marked = true; //this cloud currently produces rain
                }
            }else //raining (switch off rain)
            {
                if(collection[i].marked) //interested only in rain producing cloud
                {
                    if(!CGRectContainsPoint(stormArea, CGPointMake(0, 0)))
                    {
                        env.raining = NO;
                        collection[i].marked = false;
                    }
                }
            }
        }
        //----
        
        //when cloud dissapers behind horizon, make it appear back on other side
        //renew cloud in start position
        float extrRadius = 0; //in order for clouds not to dissapear within vieiwng distance os user, make radius larger
        if(distance > radius + extrRadius)
        {
            //find opoiste direction of wind and reset cloud randomly across the oposite direction
            float angle = M_PI + env.windAngle; //[CommonHelpers AngleBetweenVectorAndZ:GLKVector3Negate(GLKVector3Normalize(movementV))];
            float angleShift; //randge almost 180 degrees that need to be for clouds to appear randomly accross horizon
            if(collection[i].type == CT_STORM)
            {
                //strom clouds should apear closer to center so rain is more often
                angleShift = GLKMathDegreesToRadians([CommonHelpers RandomInRange:-35 :35]);
            }else 
            {
                angleShift = GLKMathDegreesToRadians([CommonHelpers RandomInRange:-50 :50]);
            }
            
            angle += angleShift;
            
            collection[i].position.x = radius * sinf(angle);
            collection[i].position.z = radius * cosf(angle);
            
            //check weather cloud should be hidden (hide it inside function)
            [self ShowHiddenCloud: &collection[i]];
            [self HideOverLappedClouds: i];
        }
    }
    
    
    [self UpdateVertexBuffer:NO];
}


//update vertices depending on collection positions
//firsTime - if this function is called on intialize or in runtime
- (void) UpdateVertexBuffer:(BOOL) firstTime
{
    /*
     //vertex order in sinle cloud quad
     //view from buttom
     x
     -------------|z
                  |
     1----3
     |   /|
     |  / |
     | /  |
     |/__ |
     2    4
    */

    int n = 0;
    for (int i = 0; i < count; i++) 
    {
        GLKVector3 pos = collection[i].position;
        float size = collection[i].size;
        float distance; //used in finction GetHeightOnCloudSphere

        //hide if not visible
        if(!collection[i].visible)
            size = 0;
        //determine texture for eaxh quad
        int textureID;
        int textureDirection;
        if(firstTime)
        {
            if(collection[i].type == CT_BASIC)
            {
                textureID = [CommonHelpers RandomInRange:0 :2];
            }else 
            {
                textureID = 3; //for storm cloud
            }
            textureDirection = [CommonHelpers RandomInRange:0 :1]; //change texture orientation ranodmly on some clouds, so they lok more random
        }
            
        //dteremine transperancy of cloud depending on distance
        distance = GLKVector3Distance(GLKVector3Make(collection[i].position.x, 0, collection[i].position.z), GLKVector3Make(0, 0, 0));
        coloring.dayTime.a = [CommonHelpers ValueInNewRange: radius: 0: 0.0: 1.0: distance];
        SColor vertexCol = [CommonHelpers UnNormalizeColor: coloring.dayTime];
        
        //set vertex data
        cloudMesh.vertices[n].vertex = GLKVector3Make(pos.x + size, pos.y,pos.z - size);
        cloudMesh.vertices[n].vertex.y = [self GetHeightOnCloudSphere:cloudMesh.vertices[n].vertex: &distance];
        cloudMesh.vertices[n].color = vertexCol;
        if(firstTime)
        {
            if(textureDirection == 0)
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex0;
            else
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex3;
        }
    
        n++;
        cloudMesh.vertices[n].vertex = GLKVector3Make(pos.x + size, pos.y,pos.z + size);
        cloudMesh.vertices[n].vertex.y = [self GetHeightOnCloudSphere:cloudMesh.vertices[n].vertex: &distance];
        cloudMesh.vertices[n].color = vertexCol;
        if(firstTime)
        {
            if(textureDirection == 0)
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex1;
            else
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex2;
        }
      
        n++;
        cloudMesh.vertices[n].vertex = GLKVector3Make(pos.x - size, pos.y,pos.z - size);
        cloudMesh.vertices[n].vertex.y = [self GetHeightOnCloudSphere:cloudMesh.vertices[n].vertex: &distance];
        cloudMesh.vertices[n].color = vertexCol;
        if(firstTime)
        {
            if(textureDirection == 0)
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex2;
            else
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex1;
        }
        n++;
        cloudMesh.vertices[n].vertex = GLKVector3Make(pos.x - size, pos.y,pos.z + size);
        cloudMesh.vertices[n].vertex.y = [self GetHeightOnCloudSphere:cloudMesh.vertices[n].vertex: &distance];
        cloudMesh.vertices[n].color = vertexCol;
        if(firstTime)
        {
            if(textureDirection == 0)
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex3;
            else
                cloudMesh.vertices[n].tex = textureAtlas[textureID].tex0;
        }
        n++;
        
        //add degenerate triangles
        if(i < count - 1) //dont need degenerate triangle for the last vertice
        {
            //same as previous quads last vertice
            cloudMesh.vertices[n].vertex = cloudMesh.vertices[n-1].vertex;
            n++;
            //same as nex quad first vertice
            GLKVector3 nextPos = collection[i+1].position;
            float nextSize = collection[i+1].size;
            //hide if not visible
            if(!collection[i+1].visible)
                nextSize = 0;
            cloudMesh.vertices[n].vertex = GLKVector3Make(nextPos.x + nextSize, nextPos.y, nextPos.z - nextSize);
            cloudMesh.vertices[n].vertex.y = [self GetHeightOnCloudSphere:cloudMesh.vertices[n].vertex: &distance];
            n++;
        }
    }
}


//hide white basic clouds that overlap strom cloud
- (void) HideOverLappedClouds: (int) currCloud
{
    CGRect cloudArea = CGRectMake(collection[currCloud].position.x - collection[currCloud].size,collection[currCloud].position.z - collection[currCloud].size, 
                                  collection[currCloud].size * 2, collection[currCloud].size * 2);
    
    if( collection[currCloud].type == CT_BASIC && collection[currCloud].visible) //for basic cloud check self cicibility
    {
        for(int i = 0; i < count; i++) 
        {
            if(collection[i].visible && i != currCloud)
            {
                CGRect checkArea = CGRectMake(collection[i].position.x - collection[i].size, collection[i].position.z - collection[i].size,
                                              collection[i].size * 2, collection[i].size * 2);
                //check overlapping clouds
                if(CGRectIntersectsRect(cloudArea,checkArea))
                {
                    collection[currCloud].visible = false;
                    break;
                }
            }
        }
    }else 
    if(collection[currCloud].type == CT_STORM)//for storm cloud check if is overlapping any white clouds
    {
        for (int i = 0; i < count; i++) 
        {
            if(collection[i].type == CT_BASIC && collection[i].visible) //check basic storm clouds
            {
                CGRect checkArea = CGRectMake(collection[i].position.x - collection[i].size, collection[i].position.z - collection[i].size,
                                              collection[i].size * 2, collection[i].size * 2);
                if(CGRectIntersectsRect(cloudArea, checkArea))
                {
                    //hide if it is overlapping
                    collection[i].visible = false;
                }
            }
        }
    }
 

}

//if cloud is hiddent, but no more overlapped wih storm cloud, show it
- (void) ShowHiddenCloud: (SModelRepresentation*) c
{
    c->visible = YES;
}


//get height of cloud speher in given position
- (float) GetHeightOnCloudSphere: (GLKVector3) pos: (float*) distance
{
    //if ditance is further away from origin, then height is closer to 0
    *distance = GLKVector3Distance(GLKVector3Make(pos.x, 0, pos.z), GLKVector3Make(0, 0, 0));
    float relVal = [CommonHelpers ValueInNewRange: radius: 0: 0: 1: *distance];
    return cloudHeight * relVal;
}

//determine coordinates for texture atlas
- (void) InitTeztureAtlas
{
    int i = 0;
    textureAtlas[i].lowerBound = GLKVector2Make(0, 0);
    textureAtlas[i].upperBound = GLKVector2Make(0.5, 0.5);
    textureAtlas[i].tex0 = textureAtlas[i].lowerBound;
    textureAtlas[i].tex1 = GLKVector2Make(textureAtlas[i].lowerBound.s,textureAtlas[i].upperBound.t);
    textureAtlas[i].tex2 = GLKVector2Make(textureAtlas[i].upperBound.s,textureAtlas[i].lowerBound.t);
    textureAtlas[i].tex3 = textureAtlas[i].upperBound;
    i = 1;
    textureAtlas[i].lowerBound = GLKVector2Make(0, 0.5);
    textureAtlas[i].upperBound = GLKVector2Make(0.5, 1.0);
    textureAtlas[i].tex0 = textureAtlas[i].lowerBound;
    textureAtlas[i].tex1 = GLKVector2Make(textureAtlas[i].lowerBound.s,textureAtlas[i].upperBound.t);
    textureAtlas[i].tex2 = GLKVector2Make(textureAtlas[i].upperBound.s,textureAtlas[i].lowerBound.t);
    textureAtlas[i].tex3 = textureAtlas[i].upperBound;
    i = 2;
    textureAtlas[i].lowerBound = GLKVector2Make(0.5, 0.5);
    textureAtlas[i].upperBound = GLKVector2Make(1.0, 1.0);
    textureAtlas[i].tex0 = textureAtlas[i].lowerBound;
    textureAtlas[i].tex1 = GLKVector2Make(textureAtlas[i].lowerBound.s,textureAtlas[i].upperBound.t);
    textureAtlas[i].tex2 = GLKVector2Make(textureAtlas[i].upperBound.s,textureAtlas[i].lowerBound.t);
    textureAtlas[i].tex3 = textureAtlas[i].upperBound;
    i = 3;
    textureAtlas[i].lowerBound = GLKVector2Make(0.5, 0);
    textureAtlas[i].upperBound = GLKVector2Make(1.0, 0.5);
    textureAtlas[i].tex0 = textureAtlas[i].lowerBound;
    textureAtlas[i].tex1 = GLKVector2Make(textureAtlas[i].lowerBound.s,textureAtlas[i].upperBound.t);
    textureAtlas[i].tex2 = GLKVector2Make(textureAtlas[i].upperBound.s,textureAtlas[i].lowerBound.t);
    textureAtlas[i].tex3 = textureAtlas[i].upperBound;
}


#pragma mark - Lightning

- (void) InitLightningParams
{
    //lightning
    lightning.time = 0;
    lightningStrike.enabled  = false;
    lightningStrike.actionTime = 5; //seconds before first strike
    lightningStrike.timeInAction = 0;
    //surrounding illumination
    lightningIllumination.night = GLKVector4Make(150/255.,230/255.,255/255.,1.0); //looks like day color
    lightningIllumination.midday = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    lightningIllumination.evening = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    lightningIllumination.morning = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
}

- (void) InitLightningGeometry
{    
    CGSize lightningSize = CGSizeMake(3.0, 10.0); //size of lightning quad
    float iluminationHalf = 9; //half size of ilumination
    //init into initial position, translation will be achieved with matrixes
    int n = cloudVertexCount;
    //lightning
    cloudMesh.vertices[n].vertex = GLKVector3Make(-lightningSize.width/2, 0.0, 0);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(1, 1);
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(-lightningSize.width/2, -lightningSize.height, 0);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(0, 1); 
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(lightningSize.width/2, 0, 0);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(1, 0); 
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(lightningSize.width/2, -lightningSize.height, 0);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(0, 0);
    n++;
    
    //ilumination
    cloudMesh.vertices[n].vertex = GLKVector3Make(-iluminationHalf, -0.01, -iluminationHalf);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(0, 0);
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(iluminationHalf, -0.01, -iluminationHalf);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(0, 1);
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(-iluminationHalf, -0.01, iluminationHalf);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(1, 0);
    n++;
    cloudMesh.vertices[n].vertex = GLKVector3Make(iluminationHalf, -0.01, iluminationHalf);
    cloudMesh.vertices[n].color = SColorMake(255, 255, 255, 255);
    cloudMesh.vertices[n].tex = GLKVector2Make(1, 1);
}

- (void) UpdateLightning: (float) dt
{
    float lightningLength = 0.3; //seconds of lightning length
    
    //count to next strike
    lightningStrike.timeInAction += dt;
    //determine next strike or disabling of lightning
    if(lightningStrike.timeInAction > lightningStrike.actionTime)
    {
        lightningStrike.enabled = !lightningStrike.enabled;
        
        if(lightningStrike.enabled)
        {
            lightningStrike.actionTime = lightningLength; //this shows how long lightning should be seen
        }else 
        {
            lightningStrike.actionTime = [CommonHelpers RandomInRange: 2 : 7]; //: 2 : 7 //when next strike will be
        }
        lightningStrike.timeInAction = 0;
        //to which cloud this lightning is attached
        lightning.type = [CommonHelpers RandomInRange:0 : 1]; //!!!!! must mach indexes for storm clouds !!!!
        //do not show in clouds that are currently raining
        if(collection[0].marked) lightning.type = 1;
        if(collection[1].marked) lightning.type = 0;
    }
    
    //determine transaltion matrix of next strike
    //lightningStrike.enabled = true;
    if(lightningStrike.enabled)
    {
        float randomDisplaceZ = 0, randomDisplaceX = 0;
        for (int i = 0; i < count; i++)
        {
            //check only storm clouds, and the cloud that we need to atach lightning
            if(i == lightning.type && collection[i].type == CT_STORM)            
            {
                lightning.time += dt;
                float shimerInterval = 0.03;
                if(lightning.time > shimerInterval) //shimering to sides interval
                {
                    randomDisplaceX = [CommonHelpers RandomInRange:-2 :2] / 2.;
                    randomDisplaceZ = [CommonHelpers RandomInRange:-2 :2] / 2.;
                    lightning.time = 0;
                }
                lightning.displaceMat = GLKMatrix4MakeTranslation(collection[i].position.x + randomDisplaceX, collection[i].position.y, collection[i].position.z + randomDisplaceZ);
                break;
            }
        }
    }
}

//weather lightning is close enaugh to lighten area #v1.1.
- (BOOL) LightningInProximity: (float) dt
{
    float illuminationDistance = 60.0; //maximal distance from origin after which illumination is not displayed
    
    if(lightningStrike.enabled &&
       (lightningStrike.timeInAction < lightningStrike.actionTime * 0.33 || lightningStrike.timeInAction > lightningStrike.actionTime * 0.66)) //if currently lightning is striking, second argument is ment for illumination to shimer
    {
        for (int i = 0; i < count; i++)
        {
            //check only storm clouds, and the cloud that is currently lightning
            if(i == lightning.type && collection[i].type == CT_STORM)
            {
                if(GLKVector3Distance(GLKVector3Make(collection[i].position.x, 0.0, collection[i].position.z), GLKVector3Make(0.0, 0.0, 0.0)) <= illuminationDistance)
                {
                    return YES;
                }
            }
        }
    }
    return NO;
    
}


@end
