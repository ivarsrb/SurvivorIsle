//
//  Ocean.m
//  Island survival
//
//  Created by Ivars Rusbergs on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 

#import "Ocean.h"
#import "Raft.h"
#import "Wildlife.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation Ocean
@synthesize oceanMesh, effectOcean, oceanBase, waterBaseHeight, oceanWidth, scaleFactor, coloring;

- (id) initWithObjects: (Terrain*) terr
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry:terr];
    }
    return self;
}

//data that changes fom game to game
- (void) ResetData: (Environment*) env
{
    waveTime = 0;
    [self RotateOceanField: env]; //rotate in direction of wind
}

- (void) InitGeometry:(Terrain*) terr
{
    //ocean parameters
    //ocean mesh centre point and y = base height of water
    waterBaseHeight = 1.0; //1.2
    oceanBase = GLKVector3Make(terr.islandCircle.center.x, waterBaseHeight, terr.islandCircle.center.z);
    
    scaleFactor = 9; //scale of single quad
    side = 15; //width of end side
    oceanWidth = 41; //witdh and height of quad (not actual shape)
    //oceanWidth - vertexStep = MUST be even
    verticesPerRow = malloc(oceanWidth * sizeof(int));
    shiftBack.x = (oceanWidth * scaleFactor) / 2. - oceanBase.x; 
    shiftBack.y = (oceanWidth * scaleFactor) / 2. - oceanBase.z;
    //vertex index count
    [self GetVertexIndexCount: &vertexCount : &indexCount];
    //texture shift
    textureCoords = malloc(vertexCount * sizeof(GLKVector2));
    //colorings
    distanceShading = malloc(vertexCount * sizeof(GLKVector4));//water color depending on distance from center
    //variable that advances wave movement
    waveTime = 0;
    waveDirAngle = 0; //stores current direction of wind angle to base vector Z
    //store wave height in2d array to easier get ocean height at some point
    waveHeightMap = malloc(oceanWidth * sizeof(float *));
    for (int i = 0; i < oceanWidth; i++) 
    {
        waveHeightMap[i] = malloc(oceanWidth * sizeof(float));
    }
    
    // NSLog(@"calculated : %d", indexCount);
    
    //geometry
    oceanMesh = [[GeometryShape alloc] init];
    oceanMesh.drawType = DYNAMIC_DRAW;
    oceanMesh.vertexCount = vertexCount; //together with waves
    oceanMesh.indexCount = indexCount;
    [oceanMesh CreateVertexIndexArrays];
    
    
    [self InitVertexIndexArray: terr];
    
    //initialize daytime colors
    /*
    middayColor = GLKVector4Make(255/255.,255/255.,255/255.,1);
    eveningColor = GLKVector4Make(255/255.,222/255.,214/255.,1);
    nightColor = GLKVector4Make(154/255.,184/255.,188/255.,1);
    morningColor =  GLKVector4Make(255/255.,255/255.,215/255.,1);
    */
    
    coloring.midday = GLKVector4Make(252/255.,255/255.,255/255.,1);
    coloring.evening = GLKVector4Make(240/255.,255/255.,239/255.,1);
    coloring.night = GLKVector4Make(193/255.,218/255.,218/255.,1);
    coloring.morning = GLKVector4Make(255/255.,247/255.,241/255.,1);
}


- (void) SetupRendering
{
    //init shaders
    self.effectOcean = [[GLKBaseEffect alloc] init];
    self.effectOcean.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];

    [oceanMesh InitGeometryBeffers];
    
    //load textures
    //water
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture: @"ocean.png" : YES]; //64x64
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    self.effectOcean.texture2d0.enabled = GL_TRUE;
    self.effectOcean.texture2d0.name = texID;
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (SkyDome*) sky : (Character*) character
{
    self.effectOcean.transform.modelviewMatrix = *modelviewMat;

    //get current ocean color
	//[CommonHelpers InterpolateDaytimeColor: &dayTimeColor : middayColor : eveningColor : nightColor : morningColor : curTime];
    [CommonHelpers InterpolateDaytimeColor: &coloring.dayTime : coloring.midday : coloring.evening : coloring.night : coloring.morning : curTime];
    
    [self UpdateVertices: dt : curTime : coloring.dayTime : sky : character];
    //update wave time
    waveTime += dt;
    if(waveTime >= PI_BY_2)
    {
        waveTime = waveTime - PI_BY_2;
    }
}

- (void) Render
{
    [[SingleGraph sharedSingleGraph] SetCullFace: YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
    [[SingleGraph sharedSingleGraph] SetDepthMask: NO]; //waves to show equally everywhere when transparent
    [[SingleGraph sharedSingleGraph] SetBlend: YES];
    [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_SRC_ALPHA];
    
	glBindVertexArrayOES(oceanMesh.vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, oceanMesh.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, oceanMesh.vertexCount * sizeof(SVertexColorTex), oceanMesh.vertices, GL_DYNAMIC_DRAW);
    
    //ocean
    [self.effectOcean prepareToDraw];
    glDrawElements(GL_TRIANGLE_STRIP, indexCount, GL_UNSIGNED_SHORT , BUFFER_OFFSET(0));
}


- (void) ResourceCleanUp
{
    [oceanMesh ResourceCleanUp];
    self.effectOcean = nil;
    free(verticesPerRow);
    free(distanceShading);
    free(textureCoords);
    for (int i = 0; i < oceanWidth; i++) {
        free(waveHeightMap[i]);
    }
    free(waveHeightMap);
}


#pragma mark - Helpers

//return calculated vertex and index count for ocean mesh
- (void) GetVertexIndexCount:(int*) vCount: (int*) iCount
{
    *vCount = 0;
    *iCount = 0;
    
    const int MIDDLE_ROW = oceanWidth/2 + 1;
    int vertInRow = side-2;
    int countFlag = 1;
    
    for (int y = 0; y < oceanWidth; y++) 
    {
        if(vertInRow != oceanWidth || countFlag >= side)
        {        
            if(y < MIDDLE_ROW)
            {
                vertInRow += 2;
            }
            else 
            {   
                vertInRow -= 2;
            }
        }else 
        {
            countFlag++;
        }
        //vertices
        
        *vCount += vertInRow;
        verticesPerRow[y] = vertInRow;
        
        //indices
        if(countFlag != side-1)//skip last longest row
        {
            int degenerateIndex = 2;
            if(y == 0 || y == oceanWidth - 2) //for first and last row
            {
                degenerateIndex = 1;
            }
            *iCount += vertInRow * 2 + degenerateIndex;
        }
        
        //NSLog(@"calculated ind in row %d", *iCount);
    }
}

//init vertex and index arrays
- (void) InitVertexIndexArray:(Terrain*) terr
{
    /*
     Shape of ocean
     side
     _______
     _|
     _|
     |
     |
     |
     */
    //alpha determine radius
    float startRadius = terr.oceanLineCircle.radius; //25 after which start increasing alpha value
 //   float extraGap = 10; //add to island circle width to make look more realistic
    float hideRadius = ((oceanWidth-1)/2. * scaleFactor)/2.0 - 3.0; //(last number is empirical to hide error at the end) after which water becomes opaque (must be greater than startRadius)
    
    //init ocean gemotry
    int vertInRow = 0;

    int n = 0;
    //int indn = 0;
    for (int y = 0; y < oceanWidth; y++) 
    {
        vertInRow = verticesPerRow[y];
        
        //determine bounds of each row
        int minBound = (oceanWidth - vertInRow) / 2;
        int maxBound = minBound + vertInRow;
      
        for (int x = 0; x < oceanWidth; x++) 
        {
            waveHeightMap[x][y] = oceanBase.y;//fill wave heigt map
            //interested only in rounded parts
            if(x >= minBound && x < maxBound)
            {
                //vertices
                oceanMesh.vertices[n].vertex = GLKVector3Make(x*scaleFactor - shiftBack.x,
                                                              oceanBase.y,
                                                              y*scaleFactor - shiftBack.y);
                
                //alpha
                float distanceFromBase = GLKVector3Distance(oceanBase, oceanMesh.vertices[n].vertex);
                float alpha;
                float minAlpha = 50; //water transparency alphas
                float maxAlpha = 255;
                
                //fetermine alpha
                if(distanceFromBase <= hideRadius && distanceFromBase >= startRadius)
                {
                    alpha = [CommonHelpers ValueInNewRange:startRadius :hideRadius :minAlpha :maxAlpha :distanceFromBase];
                }else
                {
                    if(distanceFromBase > hideRadius)
                    {
                        alpha = maxAlpha;
                    }else
                    {
                        alpha = minAlpha;
                    }
                }
                
                oceanMesh.vertices[n].color = SColorMake(0, 0, 0, alpha);
                //textures
                oceanMesh.vertices[n].tex = GLKVector2Make(x, y);
                textureCoords[n] = oceanMesh.vertices[n].tex;
                
                //precalculation
                //color
                //close to center - white, far away dark blue
                //GLKVector3 farColor = GLKVector3Make(0.8, 0.9, 0.9);
                GLKVector3 farColor = GLKVector3Make(0.88, 0.93, 0.93);
                
                distanceShading[n].r = fabs([CommonHelpers ValueInNewRange:0 :((oceanWidth-1)/2. * scaleFactor) :1.0 :farColor.r :distanceFromBase]);
                distanceShading[n].g = fabs([CommonHelpers ValueInNewRange:0 :((oceanWidth-1)/2. * scaleFactor) :1.0 :farColor.g :distanceFromBase]);
                distanceShading[n].b = fabs([CommonHelpers ValueInNewRange:0 :((oceanWidth-1)/2. * scaleFactor) :1.0 :farColor.b :distanceFromBase]);
                distanceShading[n].a = 1.0;
                
                n++;
            }
        }        
    }
    
    //fill indices
    int indn = 0;
    int startVertex = 0;
    for (int y = 0; y < oceanWidth-1; y++) 
    {
        vertInRow = verticesPerRow[y];
        
        int shiftUpper = 0;
        int vertexShiftLower = 1;
        int indexLength = vertInRow;
        if(verticesPerRow[y+1] < vertInRow)
        {
            shiftUpper = 1;
            vertexShiftLower = 0;
            indexLength = indexLength - 2;
        }else 
        if(verticesPerRow[y+1] == vertInRow)
        {
            shiftUpper = 0;
            vertexShiftLower = 0;
        }
        
        for (int x = 0; x < indexLength; x++) 
        {
            //add degenerate indexes
            //opening
            if(y > 0 && x == 0)
                oceanMesh.indices[indn++] = startVertex + x + shiftUpper;
            
            //normal indixes
            oceanMesh.indices[indn++] = startVertex + x + shiftUpper;
            oceanMesh.indices[indn++] = startVertex + vertInRow + x + vertexShiftLower ;
           
            //add degenerate indexes
            //closing
            if(y != oceanWidth - 2 && x == indexLength - 1)
                oceanMesh.indices[indn++] = startVertex + vertInRow + x + vertexShiftLower ;
        }
        //NSLog(@"y = %d , actual ind in row %d",y, indn-1);
        startVertex += vertInRow;
    }
    //NSLog(@"actual %d", indn-1);
    

}

//update vertice array
- (void) UpdateVertices:(float) dt: (float) curTime: (GLKVector4) dtColor: (SkyDome*) sky: (Character*) character
{
    //init ocean gemotry
    int vertInRow = 0;
    GLKVector4 col;
    int n = 0;
    float tspeed = 0.2; //wave speed texture shift
    tspeed *= dt;
    
    //change sun position to followe character
    GLKVector3 sunPosition = GLKVector3Add(sky.sun.position, character.camera.position);
    sunPosition.y = sky.sun.position.y;// preserve y
    
    //int indn = 0;
    for (int y = 0; y < oceanWidth; y++) 
    {
        vertInRow = verticesPerRow[y];
        
        //determine bounds of each row
        int minBound = (oceanWidth - vertInRow) / 2;
        int maxBound = minBound + vertInRow;
        for (int x = 0; x < oceanWidth; x++) 
        {
            //interested only in rounded parts
            if(x >= minBound && x < maxBound)
            {
                //position
                //do not swing waves at the horizon
                if( y > 1 && y < oceanWidth - 2 && x > minBound + 1 && x < maxBound - 2)
                {
                    oceanMesh.vertices[n].vertex.y = [self GetWaveHeight:  x:  y: oceanBase.y];
                    waveHeightMap[x][y] = oceanMesh.vertices[n].vertex.y; //for easier access later
                }
                
                
                //textures
                int whileNum = 10;//10 is random whole number
                oceanMesh.vertices[n].tex.t -= tspeed; //by default move in positive Z direction
                if(textureCoords[n].t - oceanMesh.vertices[n].tex.t >= whileNum) //10 is random whole number
                {
                    //take into account gap, so it does not look like jumping
                    oceanMesh.vertices[n].tex.t = textureCoords[n].t - (textureCoords[n].t - oceanMesh.vertices[n].tex.t - whileNum);
                }
                
                //color
                col = dtColor; //to preserve dtColor
                
                //darken color by distance
                col = GLKVector4Multiply(dtColor, distanceShading[n]);
                
                //ocean brightness by sun distance
                [self MixWithSunlight:&col :sunPosition :oceanMesh.vertices[n].vertex];

                //wave hight highlighting
                int sideD = 10;//wave lighting side dsitance
                if(y > sideD && y < oceanWidth - (sideD+1) && x > minBound + sideD && x < maxBound - (sideD+1)) //dont need to change sides
                {
                    [self MixWithWaveHeight:&col :oceanMesh.vertices[n].vertex];
                }
                
                SColor dColor = [CommonHelpers UnNormalizeColor:col]; //from 1.0 to 255
                oceanMesh.vertices[n].color = SColorMake(dColor.r, dColor.g, dColor.b, oceanMesh.vertices[n].color.a);
               
                n++;
            }
        }        
    }
    
}

//make given color brighter when waves are higher
- (void) MixWithWaveHeight:(GLKVector4*) color: (GLKVector3) vertex
{
    //top of the waves made brighter
    if(vertex.y  > oceanBase.y)
    {
        float h = vertex.y  - oceanBase.y;
        *color = GLKVector4AddScalar(*color, h / 10);
        [CommonHelpers TrimColor:color];
    }
    
}


//moix given color with sunlight brightness for given vertex
//can only make color brighter
- (void) MixWithSunlight:(GLKVector4*) color: (GLKVector3) sunPosition: (GLKVector3) vertex
{
    //sunPosition = [CommonHelpers PointOnLine:GLKVector3Make(0,0,0) :sunPosition :20];
    
    //add white closer to sun
    float dist = GLKVector3Distance(sunPosition,  vertex);
    //float whitener = 0.5 - dist / 250; //first param chages light intenisty(0.0-1.0), second - how far from sun takes effect
    float whitener = 0.5 - dist / 250; //first param chages light intenisty(0.0-1.0), second - how far from sun takes effect
    if(whitener > 0)
    {
        *color = GLKVector4Make(color->r + whitener, color->g + whitener, color->b + whitener, 1);
        [CommonHelpers TrimColor:color];
    }
}


//rotate ocean field in he direction of wind
- (void) RotateOceanField:(Environment*) env
{
    //take into account old angle if new game is strted, and rotate only delta between old and new angle
    float angle, delta;
    angle = env.windAngle;//[CommonHelpers AngleBetweenVectorAndZ:GLKVector3Negate(GLKVector3Normalize(env.wind))];
    delta = angle - waveDirAngle; //delta
    waveDirAngle = angle; //real angle
    
    int vertInRow = 0;
    
    int n = 0;
    //int indn = 0;
    for (int y = 0; y < oceanWidth; y++) 
    {
        vertInRow = verticesPerRow[y];
        
        //determine bounds of each row
        int minBound = (oceanWidth - vertInRow) / 2;
        int maxBound = minBound + vertInRow;
        for (int x = 0; x < oceanWidth; x++) 
        {
            //interested only in rounded parts
            if(x >= minBound && x < maxBound)
            {
                //rotate ocean to wind direction
               
                [CommonHelpers RotateY: &oceanMesh.vertices[n].vertex:delta: oceanBase];
                
                n++;
            }
        }        
    }
}

#pragma mark - Helpers

//get height of wave from given place
- (float) GetHeightByPoint: (GLKVector3) pos
{
    //[CommonHelpers RotateY: &pos: waveDirAngle: oceanBase];
    // we first get the height of four points of the quad underneath the point
    float height = -1.0f;
    
    [CommonHelpers RotateY: &pos: -waveDirAngle: oceanBase];//adjust to rotation of ocean
    
    float xPlace = (pos.x+shiftBack.x) / scaleFactor;
    float zPlace = (pos.z+shiftBack.y) / scaleFactor;
    
    int x = (int)xPlace;      
    int z = (int)zPlace;      
    int xPlusOne = x + 1;
    int zPlusOne = z + 1;
    
    //make shore indexes are not out of bounds
    if(x >= 0 && z >= 0 && xPlusOne <  oceanWidth &&  zPlusOne <  oceanWidth)
       //x + z * oceanWidth > 0 && xPlusOne + zPlusOne * oceanWidth < vertexCount)
    {
        float triZ0 = waveHeightMap[x][z];
        float triZ1 = waveHeightMap[xPlusOne][z];
        float triZ2 = waveHeightMap[x][zPlusOne];
        float triZ3 = waveHeightMap[xPlusOne][zPlusOne];
        
        
        float sqX = xPlace - x;
        float sqZ = zPlace - z;
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

//get wave hight at given point in array space
- (float) GetWaveHeight: (float) x: (float) y: (float) baseH
{
    float 
    a = 0.4, //vawe height
    b = -1,  //relative dirrection and spacing by x
    c = 3;   //relative dirrection and spacing by y

    return  a * sin(b * x + c * y + waveTime) + baseH;
}

@end
