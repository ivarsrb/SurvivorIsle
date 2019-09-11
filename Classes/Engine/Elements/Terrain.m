//
//  Terrain.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Terrain.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

#import "Clouds.h"
#import "Character.h"
#import "SkyDome.h"

@implementation Terrain

@synthesize terrainMesh,hfWidth,scaleFactor,islandRect,inlandCircle,grassCircle,
            islandCircle,middleCircle,effectUnderplate,underplateMesh,oceanLineCircle,majorCircle,
            coloring;


- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        //vertice count of width and height
        hfWidth = HF_SIZE; //vertex count
        scaleFactor = HF_SCALE; //by default one vertex is 1m displaced, scale it by this parameter
        
        //height data is stored here
        scaleDownFactor = 115.0;   // scale down interval from 0 - 255
        heightField = malloc(hfWidth * sizeof(float *));
        for (int i = 0; i < hfWidth; i++)
        {
            heightField[i] = malloc(hfWidth * sizeof(float));
        }
        NSString *tfile = @"terrain";
        [self LoadHMFromFile: tfile];
        
        //extra properties

        //areas of island
        float reaWidth = hfWidth - 1;
        islandRect = CGRectMake(0, 0, reaWidth * scaleFactor, reaWidth * scaleFactor);
        islandCircle.center = GLKVector3Make((reaWidth*scaleFactor)/2., 0, (reaWidth*scaleFactor)/2.);
        islandCircle.radius = (reaWidth*scaleFactor) / 2.;
        
        //place where sand starts
        inlandCircle.center = islandCircle.center;
        inlandCircle.radius = islandCircle.radius - islandCircle.radius / 2.5;
        
        //place where grass ends
        float radiusShiftBack = 4.0; //dont put on bordering line
        grassCircle.center = inlandCircle.center;
        grassCircle.radius = inlandCircle.radius - radiusShiftBack;
        
        //half of grass land
        middleCircle.center = islandCircle.center;
        middleCircle.radius = inlandCircle.radius / 2.; //inside center of island (half of inland)

        //circle touches angles of island square
        majorCircle.center = islandCircle.center;
        majorCircle.radius = sqrt(2*islandCircle.radius*islandCircle.radius); //radius is hipotenuse
        
        //circle where ocean water starts (is not connected to visual ocean water line)
        oceanLineCircle = islandCircle;
        oceanLineCircle.radius -= 4.5; //empirically detected ( depends slightly on frame rate, because this number is hard to detect)
        
        //load shader programms and init attributes and uniforms
        [ShaderLoader loadShadersMixAlpha: uniformsMixAlpha : &programMixAlpha];
        
        [self InitGeometry];
    }
    return self;
}

- (void) InitGeometry
{
    terrainMesh = [[GeometryShape alloc] init];
    
    //underplate - rectangle under siland to make island look like it goes into ocean seamlessly
    underplateMesh = [[GeometryShape alloc] init];
    underplateMesh.dataSetType = VERTEX_INDEX_SET;
    underplateMesh.vertStructType = VERTEX_TEX_STR;
    
    //vertices
    //terrain
    terrainMesh.vertexCount = hfWidth * hfWidth;
    terrainMesh.indexCount = (hfWidth - 1) * hfWidth * 2 + (hfWidth - 2) * 2;
    [terrainMesh CreateVertexIndexArrays];
    //underplate
    int uplateWidth = 4;
    underplateMesh.vertexCount = uplateWidth * uplateWidth; //underplate, make it like a box, lift edges up, so we dont see unneeded
    underplateMesh.indexCount = (uplateWidth - 1) * uplateWidth * 2 + (uplateWidth - 2) * 2;;
    [underplateMesh CreateVertexIndexArrays];
    
    
    //fill vertices and alpha value for different terrain type
    for(int y = 0; y < hfWidth; y++)
	{
		for(int x = 0; x < hfWidth; x++)
		{
            terrainMesh.vertices[x+y*hfWidth].vertex = GLKVector3Make(x*scaleFactor,heightField[x][y],y*scaleFactor);
			float alpha = 1.0;
          
            //textures will be aplied by alpha, so lower parts are textured with sand
            //determine vertex alpha by distance
            float dist = GLKVector3Distance(terrainMesh.vertices[x+y*hfWidth].vertex, GLKVector3Make(islandCircle.center.x,heightField[x][y],islandCircle.center.z));
            float startShift = 5.0; //gradient start radius minus this
            float delta  = dist - (inlandCircle.radius - startShift); //start with offset
            float gradientDistance = 7.0; //gradient distance, distance in which moves from grass to sand
            if(delta > 0) 
            {
                //gradient
                if(delta <= gradientDistance)
                {
                    //make alpha change gradually
                    alpha = [CommonHelpers ValueInNewRange:0 :gradientDistance :1.0 :0.0 :delta];
                }
                //sand
                else
                {
                    alpha = 0;
                }
            }
            
            
            
            //determine grass color by paches
            GLKVector3 groundShade = GLKVector3Make(1.0, 1.0, 1.0); //default
            //grass shading
            if(delta < 0)
            {
                //make lower terrain parts draker
                float maximumHeight = 255 / scaleDownFactor;
                float maxDarkness = (dist / (inlandCircle.radius-7)); //minimal color component value depending on distance from center
                if(maxDarkness > 1.0) maxDarkness = 1.0;
                float hDiff = 0.35;//the smaller the number,the lower spots will be darker;
                float colComponent = [CommonHelpers ValueInNewRange:maximumHeight :maximumHeight - hDiff :1.0 :maxDarkness : heightField[x][y]];
                groundShade = GLKVector3Make(colComponent,colComponent,colComponent);//brownish
            }
            terrainMesh.vertices[x+y*hfWidth].color = [CommonHelpers UnNormalizeColor:GLKVector4Make(groundShade.r,groundShade.g,groundShade.b,alpha)];
			terrainMesh.vertices[x+y*hfWidth].tex = GLKVector2Make(x, y);
		}
	}
    
    //indices
    //fill indices as single triangle strip
    int cnt = 0;
    for(int y = 0; y < hfWidth-1; y++) //rows
	{
		for(int x = 0; x < hfWidth; x++)
		{
            terrainMesh.indices[cnt++] = x + y * hfWidth;
            terrainMesh.indices[cnt++] = x + (y+1) * hfWidth;
        }
        
        if(y < hfWidth-2) //the last time we dont need them
        {
            //degenerate triangles
            terrainMesh.indices[cnt++] = (hfWidth-1) + (y+1) * hfWidth;
            terrainMesh.indices[cnt++] = (y+1) * hfWidth;
        }

    }
    
    //-------------- underplate geometry
    //make like box with underplate and flaps on sides
    /*
    0 1            2 3
     ________________
   4|_|____________|_|
    | |            | |
    | |            | |
    | |            | |
    |_|____________|_|
    |_|____________|_|
     
     */
    float extraCover = 40;//120; //how much underplate that goes beyond terrain bounds
    float flapWidth = 30.0;//width of partthatis to be rased up
    float yVal = -0.03; //lower to avoid z-fighting with terrain
    float flapHeight = yVal + 0.65; //how much flaps will be raised up
    
    //vertices
    cnt = 0;
    float positiveSize = islandRect.size.width + extraCover + flapWidth; //maximum size of underplate from start of axis in positive direction
    float negativeSize = extraCover + flapWidth;//maximum size of underplate from start of axis in negative direction
    
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize, flapHeight, positiveSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize - flapWidth, flapHeight, positiveSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-extraCover, flapHeight, positiveSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-negativeSize, flapHeight, positiveSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    //--
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize, flapHeight, positiveSize-flapWidth);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize - flapHeight, yVal, positiveSize-flapWidth);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-extraCover, yVal, positiveSize-flapWidth);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 2*extraCover);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-negativeSize, flapHeight, positiveSize-flapWidth);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    //--
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize, flapHeight, -extraCover);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize - flapHeight, yVal, -extraCover);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(2*extraCover, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-extraCover, yVal, -extraCover);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(2*extraCover, 2*extraCover);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-negativeSize, flapHeight, -extraCover);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    //--
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize, flapHeight, -negativeSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(positiveSize - flapHeight, flapHeight, -negativeSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-extraCover, flapHeight, -negativeSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);
    cnt++;
    underplateMesh.verticesT[cnt].vertex = GLKVector3Make(-negativeSize, flapHeight, -negativeSize);
    underplateMesh.verticesT[cnt].tex = GLKVector2Make(0.0, 0.0);

    
    //indices
    cnt = 0;
    for(int y = 0; y < uplateWidth-1; y++) //rows
	{
		for(int x = 0; x < uplateWidth; x++)
		{
            underplateMesh.indices[cnt++] = x + y * uplateWidth;
            underplateMesh.indices[cnt++] = x + (y+1) * uplateWidth;
        }
        
        if(y < hfWidth-2) //the last time we dont need them
        {
            //degenerate triangles
            underplateMesh.indices[cnt++] = (uplateWidth-1) + (y+1) * uplateWidth;
            underplateMesh.indices[cnt++] = (y+1) * uplateWidth;
        }
    }
    
    
    //initialize daytime colors
    //NOTE: colors also used in Grass mnodule!
    /*
    middayColor =   GLKVector4Make(1.0,1.0,1.0,1.0);
    eveningColor =  GLKVector4Make(255/255.,210/255.,145/255.,1);
	nightColor =    GLKVector4Make(70/255.,130/255.,225/255.,1);
    morningColor =  GLKVector4Make(255/255.,230/255.,206/255.,1);
    */
    coloring.midday = GLKVector4Make(1.0,1.0,1.0,1.0);
    coloring.evening = GLKVector4Make(255/255.,210/255.,145/255.,1);
    coloring.night = GLKVector4Make(70/255.,130/255.,225/255.,1);
    coloring.morning = GLKVector4Make(255/255.,230/255.,206/255.,1);
}


- (void) SetupRendering
{
    [terrainMesh InitGeometryBeffers];
    [underplateMesh InitGeometryBeffers];
    
    self.effectUnderplate = [[GLKBaseEffect alloc] init];
    self.effectUnderplate.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //load textures
    //grass
    grassTexID = [[SingleGraph sharedSingleGraph] AddTexture:@"grass.png" :YES];  //64x64
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    //sand
    sandTexID = [[SingleGraph sharedSingleGraph] AddTexture:@"sand.png"  :YES];  //64x64
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    self.effectUnderplate.texture2d0.enabled = GL_TRUE;
    self.effectUnderplate.texture2d0.name = sandTexID;
    self.effectUnderplate.useConstantColor = GL_TRUE;
}

- (void) Update: (float) dt : (float)curTime : (GLKMatrix4*) modelviewMat : (Clouds*) clouds : (Character*) character : (SkyDome*) sky
{
    //get current terrain color
	//[CommonHelpers InterpolateDaytimeColor: &dayTimeColor : middayColor : eveningColor : nightColor : morningColor : curTime];
    [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : coloring.midday : coloring.evening : coloring.night : coloring.morning : curTime];
    
    //------------ lighting test    
    //[sky ModifyColoringByViewVector: &coloring.dayTime : character];
    //------------
    
    
    //in case of lightning illuminate everything in lightning ambient color #v1.1.
    if([clouds LightningInProximity: dt])
    {
        [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : clouds.lightningIllumination.midday : clouds.lightningIllumination.evening : clouds.lightningIllumination.night : clouds.lightningIllumination.morning : curTime];
        //dayTimeColor = clouds.lightningIllumination.night;
    }
    
    //underplate effect
    self.effectUnderplate.transform.modelviewMatrix = *modelviewMat;
    //coloring
    self.effectUnderplate.constantColor = coloring.dayTime;
}

- (void) Render: (float*) mvpMat
{
    [[SingleGraph sharedSingleGraph] SetCullFace:YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
    [[SingleGraph sharedSingleGraph] SetBlend:NO];
    
    
    //render terrain
    glUseProgram(programMixAlpha);
    glBindVertexArrayOES(terrainMesh.vertexArray);
    
    glUniformMatrix4fv(uniformsMixAlpha[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, mvpMat);
    glUniform4fv(uniformsMixAlpha[COMMON_COLOR], 1, coloring.dayTime.v); //daytime color
    glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, grassTexID);
    glUniform1i(uniformsMixAlpha[SAMPLER0_UF], 0);
    glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, sandTexID);
    glUniform1i(uniformsMixAlpha[SAMPLER1_UF], 1);
    
    glDrawElements(GL_TRIANGLE_STRIP, terrainMesh.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(0));
    
    //render underplate
    [self.effectUnderplate prepareToDraw];
    glBindVertexArrayOES(underplateMesh.vertexArray);
    glDrawElements(GL_TRIANGLE_STRIP, underplateMesh.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(0));
}

- (void) ResourceCleanUp
{
    [terrainMesh ResourceCleanUp];
    [underplateMesh ResourceCleanUp];
    for (int i = 0; i < hfWidth; i++) {
        free(heightField[i]);
    }
    free(heightField);
    
    self.effectUnderplate = nil;
    //shader
    if(programMixAlpha)
    {
        glDeleteProgram(programMixAlpha);
        programMixAlpha = 0;
    }
}

#pragma mark - Helpers

//read terrain vertex data from raw file and put in vertex array
- (void) LoadHMFromFile: (NSString*) filename
{
	//data read is in range from 0 - 255
	// 0 - black
	// 255 - white
	//Raw file should be same size as terrain!
	
	int fileWidth = hfWidth;
	int fileHeight = hfWidth;
	
	//will store byte data
	unsigned char *rawData;
	rawData = (unsigned char*) malloc (sizeof(unsigned char)*fileWidth*fileHeight);
	NSData *data;
	
	//NSString *file = [[NSString alloc]  initWithCString:filename encoding:NSASCIIStringEncoding];
	NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"raw"];  
	data = [NSData dataWithContentsOfFile:filePath];
	if(data == nil)
	{
		//NSLog(@"Terrain file error! \n");
        free(rawData);
		return;
	}
	[data getBytes:rawData]; //get all file data
	
	//fill heightmap
	int byteCounter = 0;
	
	for(int y = 0; y < hfWidth; y++)
	{
		for(int x = 0; x < hfWidth; x++)
		{
            heightField[x][y] = rawData[byteCounter++] / scaleDownFactor; //add byte by byte
            //NSLog(@"%d ", x);
		}
	}
	
	free(rawData);
}




//one index means 1 section in world  space
- (float) GetHeightByPoint: (GLKVector3 *) pos
{
    
    // we first get the height of four points of the quad underneath the point
    float height = 0.0; // default height
    float xScaledDown = (pos->x / scaleFactor);
    float zScaledDown = (pos->z / scaleFactor);
    int x = (int)xScaledDown;
    int z = (int)zScaledDown;
    int xPlusOne = x + 1;
    int zPlusOne = z + 1;
    
    //make shure indexes are not out of bounds
    if(pos->x >= 0 && pos->z >= 0 && 
       pos->x < (hfWidth-1) * scaleFactor && pos->z < (hfWidth-1) * scaleFactor)
    {        
        float triZ0 = heightField[x][z];
        float triZ1 = heightField[xPlusOne][z];
        float triZ2 = heightField[x][zPlusOne];
        float triZ3 = heightField[xPlusOne][zPlusOne];
        
        float sqX = xScaledDown - x;
        float sqZ = zScaledDown - z;
        if ((sqX + sqZ) < 1)
        {
            height = triZ0;
            height += (triZ1 - triZ0) * sqX;
            height += (triZ2 - triZ0) * sqZ;
        }
        else
        {
            height = triZ3;
            height += (triZ1 - triZ3) * (1.0f - sqZ);
            height += (triZ2 - triZ3) * (1.0f - sqX);
        }
    }
    
    return height;
}

//get height bu fiven point and assign to given point y
- (void) GetHeightByPointAssign: (GLKVector3 *) pos
{
   pos->y = [self GetHeightByPoint: pos];
}


//function to use when needed to adjust end poiints of given model to terrain height
//mainly m->orientation.x is determined, also endPoints
//pass model representation and model itself
- (void) AdjustModelEndPoints: (SModelRepresentation*) m: (ModelLoader*) model
{
    //determine end points to manipulate picking and rotate according to different heights
    m->endPoint1 = GLKVector3Add(model.AABBmin, m->position);
    m->endPoint2 = GLKVector3Add(model.AABBmax, m->position);
    m->endPoint2.y = m->endPoint1.y; //height is bottom for both
    //AABB is shifted to sides of model, but we need middle of model
    float mWidth = fabs(model.AABBmin.x) + fabs(model.AABBmax.x); //width of stick
    m->endPoint1.x += mWidth /  2;
    m->endPoint2.x -= mWidth / 2;
    
    //rotate them to current orientation
    [CommonHelpers RotateY:&m->endPoint1 :m->orientation.y: m->position];
    [CommonHelpers RotateY:&m->endPoint2 :m->orientation.y: m->position];
    
    //get height for end points
    m->endPoint1.y = [self GetHeightByPoint:&m->endPoint1];
    m->endPoint2.y = [self GetHeightByPoint:&m->endPoint2];
    //determine new middle position y, according to new end point position
    m->position.y = (m->endPoint1.y + m->endPoint2.y) / 2.0;
    
    //dteemrine angle to rotate about that rotation axis
    float pretkath = m->position.y - m->endPoint2.y;
    float hipoth = (model.AABBmax.z - model.AABBmin.z) / 2;
    m->orientation.x = asinf(pretkath / hipoth);
}


#pragma mark -  Island sectors


//check if position is in ineer part of island, where grass grows
- (BOOL) IsInland:(GLKVector3) position
{
    return [CommonHelpers PointInCircle: inlandCircle.center: inlandCircle.radius: position];
}

//check if position is in between inland (grass) area and oceanline area
- (BOOL) IsBeach:(GLKVector3) position
{
    return ![CommonHelpers PointInCircle: inlandCircle.center: inlandCircle.radius: position] &&
    [CommonHelpers PointInCircle: oceanLineCircle.center: oceanLineCircle.radius: position];
}
//check if position is after oceanline area
- (BOOL) IsOcean:(GLKVector3) position
{
    return ![CommonHelpers PointInCircle: oceanLineCircle.center: oceanLineCircle.radius: position];
}

//check if position is in between inland (grass) area and outer part of ocean (beach + some aprt of water)
- (BOOL) IsBeachOcean:(GLKVector3) position
{
    return ![CommonHelpers PointInCircle: inlandCircle.center: inlandCircle.radius: position] &&
    [CommonHelpers PointInCircle: majorCircle.center: majorCircle.radius: position];
}

#pragma mark -  Collision detection

//colided with ground (point is under ground)
- (BOOL) PointHitsGround: (GLKVector3) p1
{
    return p1.y <= [self GetHeightByPoint: &p1];
}

//object with additional radius collided with ground
- (BOOL) ObjectHitsGround: (GLKVector3) center : (float) radius
{
    return center.y - radius <= [self GetHeightByPoint: &center];
}


//determine an return approx collision position with terrain
//NOTE: shopuld be used after adding movement vector in this step, because uses previous and new added point
//p1 - point above terrain, last one before it hits ground
//p2 - point that has hit ground or is under it (current point after adding movement vector)
//returns caculated colision point with terrain (if terain is hit)
/*
 p1
 \
  \
   \
 --------------------- terrain
     \
      \
       \
        p2
*/
- (GLKVector3) GetCollisionPoint: (GLKVector3) p1 : (GLKVector3) p2
{
    GLKVector3 calculatedVector;
    float p2GroundHeight = [self GetHeightByPoint: &p2]; //ground heighth under p2 (current point after adding movement vector)
    float p1GroundHeight = [self GetHeightByPoint: &p1]; //ground height under previou step
    //get differences from pint y and ground
    float p1Delta = fabs(p1GroundHeight - p1.y); //difference between point 1 height and ground under it
    float p2Delta = fabs(p2GroundHeight - p2.y); //difference between point 2 height and ground under it
    
    //calculate wich point will be ending position
    float lerpVal = (1.0 / (p1Delta + p2Delta)) * p1Delta;
    calculatedVector = GLKVector3Lerp(p1, p2, lerpVal);
    [self GetHeightByPointAssign: &calculatedVector];
    
    return calculatedVector;
}


//determine an return approx collision position with terrain #v.1.1.
//NOTE: shopuld be used after adding movement vector in this step
//return true if p2 colided with ground (is under ground), false - if no collision was detected
//p1 - point above terrain, last one before it hits ground
//p2 - point that has hit ground or is under it (current point after adding movement vector)
//collisionPoint - returns caculated colision point with terrain (if terain is hit)
- (BOOL) HasCollided: (GLKVector3) p1 : (GLKVector3) p2 : (GLKVector3*) collisionPoint
{
    BOOL retVal = false;//collided

    if([self PointHitsGround: p2]) //current point has colided with ground
    {
        retVal = true;
        /*
        //get differences from pint y and ground
        float p1GroundHeight = [self GetHeightByPoint: &p1]; //ground height under previou step
        float p1Delta = fabs(p1GroundHeight - p1.y); //difference between point 1 height and ground under it
        float p2Delta = fabs(p2GroundHeight - p2.y); //difference between point 2 height and ground under it
        
        //calculate wich point will be ending position
        float lerpVal = (1.0 / (p1Delta + p2Delta)) * p1Delta;
        *collisionPoint = GLKVector3Lerp(p1, p2, lerpVal);
        [self GetHeightByPointAssign: collisionPoint];
        */
        *collisionPoint = [self GetCollisionPoint: p1 : p2];
    }
    
    return retVal;
}



@end
