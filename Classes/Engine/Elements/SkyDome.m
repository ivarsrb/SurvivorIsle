//
//  SkyDome.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "SkyDome.h"
#import <OpenGLES/ES2/glext.h> //to remove warning

@implementation SkyDome
@synthesize skyMesh, lightsMesh, effectSkyDome, effectSun, effectMoon, effectMiddSun,effectStar,effectMeteor, sun;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        [self InitGeometry];
    }
    return self;
}

//data that changes fom game to game #v1.1
- (void) ResetData: (Environment*) env
{
    sun.visible = NO;
    moon.visible = NO;
    //stars.visible = NO;
    for (int i = 0; i <  starCount; i++)
    {
        starCollection[i].visible = NO; //visible only with moon
    }
    meteor.visible = NO;
    meteor.timeInMove = 0;
}


- (void) InitGeometry
{
    [self InitSkyGeometry];
    [self InitLightsGeometry];
}

- (void) SetupRendering
{
    //init shaders
    self.effectSkyDome = [[GLKBaseEffect alloc] init];
    self.effectSkyDome.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    self.effectSun = [[GLKBaseEffect alloc] init];
    self.effectSun.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    self.effectMiddSun = [[GLKBaseEffect alloc] init];
    self.effectMiddSun.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];

    self.effectMoon = [[GLKBaseEffect alloc] init];
    self.effectMoon.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    self.effectStar = [[GLKBaseEffect alloc] init];
    self.effectStar.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //#v1.1
    self.effectMeteor = [[GLKBaseEffect alloc] init];
    self.effectMeteor.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //Sky dome
    [skyMesh InitGeometryBeffers];
    
    //Sun, moon, star, meteor
    [lightsMesh InitGeometryBeffers];
    
    //load textures
    GLuint sunTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"sun.png" : YES];             //32x32
    GLuint sunInnerTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"sun_inner.png" : YES];  //32x32
    GLuint moonTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"moon.png" : YES];           //128x128
    GLuint starTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"particle_shine.png" : YES]; //64x64
    GLuint meteorTexID = [[SingleGraph sharedSingleGraph] AddTexture: @"meteor.png" : YES];       //128x128 
    
    //sun
    self.effectSun.texture2d0.enabled = GL_TRUE;
    self.effectSun.texture2d0.name = sunTexID;
    self.effectSun.useConstantColor = GL_TRUE;
    self.effectMiddSun.texture2d0.enabled = GL_TRUE;
    self.effectMiddSun.texture2d0.name = sunInnerTexID;
    self.effectMiddSun.useConstantColor = GL_TRUE;
    self.effectMiddSun.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    //moon
    self.effectMoon.texture2d0.enabled = GL_TRUE;
    self.effectMoon.texture2d0.name = moonTexID;
    self.effectMoon.useConstantColor = GL_TRUE;
    self.effectMoon.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    //stars
    self.effectStar.texture2d0.enabled = GL_TRUE;
    self.effectStar.texture2d0.name = starTexID;
    self.effectStar.useConstantColor = GL_TRUE;
    self.effectStar.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    //meteor //#v1.1
    self.effectMeteor.texture2d0.enabled = GL_TRUE;
    self.effectMeteor.texture2d0.name = meteorTexID;
    self.effectMeteor.useConstantColor = GL_TRUE;
    self.effectMeteor.constantColor = GLKVector4Make(1, 1, 1, 1);
}

- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (Character*) character
{
    [self UpdateSky: curTime];
    [self UpdateSun: curTime];
    [self UpdateMoon: curTime];
    [self UpdateStars: dt];
    [self UpdateMeteor: curTime : dt]; //#v1.1
    
    //update translation matrices
    //sky dome translation matrix, so always follows user
    transMat = GLKMatrix4MakeTranslation(character.camera.position.x, character.camera.position.y - character.height, character.camera.position.z);
    globalTransMat = GLKMatrix4Multiply(*modelviewMat, transMat);
    
    //sun matrices
    if(sun.visible)
    {
        sun.displaceMat = GLKMatrix4MakeTranslation(sun.position.x, sun.position.y, sun.position.z); //move sun
        sun.displaceMat = GLKMatrix4Multiply(globalTransMat, sun.displaceMat); //move also together with sky
        [CommonHelpers LoadSphereBillboard: sun.displaceMat.m]; //make sun face user all the time
    }
    
    //soon matrices
    if(moon.visible)
    {
        moon.displaceMat = GLKMatrix4MakeTranslation(moon.position.x, moon.position.y, moon.position.z); //move sun
        moon.displaceMat = GLKMatrix4Multiply(globalTransMat, moon.displaceMat); //move also together with sky
        [CommonHelpers LoadSphereBillboard: moon.displaceMat.m]; //make to face user all the time
    }
    //star matrices
    for(int i = 0; i < starCount; i++)
    {
        if(starCollection[i].visible)
        {
            starCollection[i].displaceMat = GLKMatrix4MakeTranslation(starCollection[i].position.x, starCollection[i].position.y, starCollection[i].position.z); //move sun
            starCollection[i].displaceMat = GLKMatrix4Multiply(globalTransMat, starCollection[i].displaceMat); //move also together with sky
            [CommonHelpers LoadSphereBillboard: starCollection[i].displaceMat.m]; //make to face user all the time
        }
    }
    //meteor matrices //#v1.1
    if(meteor.visible)
    {
        //meteor.displaceMat = GLKMatrix4RotateY(globalTransMat, M_PI);
        meteor.displaceMat = GLKMatrix4TranslateWithVector3(globalTransMat, meteor.position);
        //meteor.displaceMat = GLKMatrix4RotateY(meteor.displaceMat, M_PI);
        
        [CommonHelpers LoadSphereBillboard: meteor.displaceMat.m]; //make to face user all the time
    }
    
    //matrices
    self.effectSkyDome.transform.modelviewMatrix = globalTransMat;
    self.effectSun.transform.modelviewMatrix = sun.displaceMat;
    self.effectMiddSun.transform.modelviewMatrix = sun.displaceMat;
    self.effectMoon.transform.modelviewMatrix = moon.displaceMat;
    self.effectMeteor.transform.modelviewMatrix = meteor.displaceMat;
}

- (void) Render
{
    [[SingleGraph sharedSingleGraph] SetCullFace: YES];
    [[SingleGraph sharedSingleGraph] SetDepthTest: NO];
    [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
    [[SingleGraph sharedSingleGraph] SetBlend: NO];
  
    //Render sky
    glBindVertexArrayOES(skyMesh.vertexArray);
    //update dynamic buffer
    //color (changing)
    glBindBuffer(GL_ARRAY_BUFFER, skyMesh.vertexBufferColor);
    glBufferData(GL_ARRAY_BUFFER, skyMesh.vertexCount * sizeof(SColor), skyMesh.color, GL_DYNAMIC_DRAW);
    //draw skydome
    [self.effectSkyDome prepareToDraw];
    glDrawElements(GL_TRIANGLE_STRIP, skyMesh.indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(0));

    //lights objects
    if(sun.visible || moon.visible)
    {
        glBindVertexArrayOES(lightsMesh.vertexArray);
        
        [[SingleGraph sharedSingleGraph] SetBlend: YES];
        [[SingleGraph sharedSingleGraph] SetBlendFunc: F_GL_ONE];

        //render sun
        float objectInArray; //numerb for object in array, to easyer change later
        if(sun.visible)
        {
            objectInArray = OO_SUN_OUTER;//whick object in geomtry array
            [self.effectSun prepareToDraw];
            glDrawArrays(GL_TRIANGLE_STRIP, objectInArray * 4, 4); //big circle
            objectInArray = OO_SUN_INNER;//whick object in geomtry array
            [self.effectMiddSun prepareToDraw];
            glDrawArrays(GL_TRIANGLE_STRIP, objectInArray * 4, 4); //middle circle
        }
        
        //render stars
        objectInArray = OO_STARS;//whick object in geomtry array
        for (int i = 0; i <  starCount; i++)
        {
            if(starCollection[i].visible)
            {
                self.effectStar.transform.modelviewMatrix = starCollection[i].displaceMat;
                [self.effectStar prepareToDraw];
                glDrawArrays(GL_TRIANGLE_STRIP, objectInArray * 4, 4);
            }
        }
        
        //render moon
        if(moon.visible)
        {
            objectInArray = OO_MOON;//whick object in geomtry array
            [self.effectMoon prepareToDraw];
            glDrawArrays(GL_TRIANGLE_STRIP, objectInArray * 4, 4);
        }
        
        //render meteor #v1.1
        if(meteor.visible)
        {
            if(meteor.type == MT_LEFT)
            {
                objectInArray = OO_METEOR_LEFT;
            }else
            {
                objectInArray = OO_METEOR_RIGHT;
            }
            
            [self.effectMeteor prepareToDraw];
            glDrawArrays(GL_TRIANGLE_STRIP, objectInArray * 4, 4);
        }
        
        
    }
}

#pragma mark -  Sky

- (void) InitSkyGeometry
{
    skyMesh = [[GeometryShape alloc] init];
    skyMesh.dataSetType = VERTEX_INDEX_SET;
    //seprate buffers
    skyMesh.vertStructType = VERTEX_COLOR_SEPARATE_STR; //vertex buffer leaved static unchanged, color buffer dynamic changed
    skyMesh.drawType = COLOR_DYNAMIC_DRAW;
    radius = 100;	
    dtheta = 15;
    dphi = 5;
    float topAngle = 45; //angle from top to the buttom of skydome
	float baseY = 71; //by how much lower the skydome
	
	skyMesh.vertexCount = (int)((360/dtheta+1)*(topAngle/dphi+1)); //sky dome vertice number
	skyMesh.indexCount = (int)((360/dtheta+1)*(topAngle/dphi) * 2 + ((topAngle/dphi)-1) * 2); //sky dome index number
    
    [skyMesh CreateVertexIndexArrays];
    
    //verteices
	int n=0;
	for(int phi = 0; phi <= topAngle; phi+=(int)dphi) 
	{
		for(int theta = 0; theta <= 360; theta+=(int)dtheta) 
		{
            float phiRad = GLKMathDegreesToRadians(phi);
            float thetaRad = GLKMathDegreesToRadians(theta);
            
            skyMesh.position[n].x = radius * sinf(phiRad) * cosf(thetaRad);
			skyMesh.position[n].z = radius * sinf(phiRad) * sinf(thetaRad);
			skyMesh.position[n].y = radius * cosf(phiRad) - baseY;
            n++;
		}
	}
    
    //indices
    n=0;
    int columnCount = 360 / dtheta + 1;
    int x = 0, y = 0;
    for(int phi = 0; phi <= topAngle - dphi ; phi+=(int)dphi) 
	{
        for(int theta = 0; theta <= 360; theta+=(int)dtheta) 
		{
            skyMesh.indices[n++] = x + y * columnCount;
            skyMesh.indices[n++] = x + (y+1) * columnCount;
            x++;
		}
        if(phi < topAngle - dphi) //the last time we dont need them
        {
            //degenerate triangles
            skyMesh.indices[n++] = (x-1) + (y+1) * columnCount;
            skyMesh.indices[n++] = (y+1) * columnCount;
        }
        y++;
        x = 0;
	}

    [self InitSkyColors];
}

- (void) UpdateSky:(float) curTime
{
    float topAngle = 45; //angle from top to the buttom of skydome
    //update sky dome colors
	GLKVector4 skyPlt[10];
	
	//get resulting color
	for (int i = 0; i < 10; i++) 
	{
		[CommonHelpers InterpolateDaytimeColor: &skyPlt[i] : middayPlt[i] : eveningPlt[i] : nightPlt[i] : morningPlt[i] : curTime];
	}
    
	int n = 0;
	int pIndex = 0;
    //calculate changed color (depending on sun position)
    for(int phi = 0; phi <= topAngle; phi+=(int)dphi) 
	{
        for(int theta = 0; theta <= 360; theta+=(int)dtheta) 
		{
            //calculate how much we add to our base color, depending on sun's distance
            float dist = GLKVector3Distance(sun.position ,skyMesh.position[n]); 
            //float dist = [CommonHelpers DistanceBetween: sunPosition :skyMesh.verticesC[n].vertex]; 
            //0.5 250
           // dist = 0.6 - dist / 200; //first param chages light intenisty(0.0-1.0), second changes how far from sun effect will be seen
            dist = 0.6 - dist / 200; 
            if(dist < 0) dist = 0;
            
            GLKVector4 addedColor = GLKVector4Make(dist, dist,dist, 1);
            //add base color to color that is expected sky color
            skyMesh.color[n] = [CommonHelpers UnNormalizeColor:[self ChangeColor: skyPlt[pIndex]: addedColor]];
            
            n++;
		}
        
		pIndex++;
	}
    
    
}
//change color by goven change color
- (GLKVector4) ChangeColor:(GLKVector4) col:  (GLKVector4) change
{
    GLKVector4 v;

    v.r = col.r + change.r;
    v.g = col.g + change.g;
    v.b = col.b + change.b;
    v.a = col.a;
    
    if(v.r > 1.0) v.r = 1.0;
    if(v.g > 1.0) v.g = 1.0;
    if(v.b > 1.0) v.b = 1.0;


    return v;
}


//set up sky color palettes for different parts of the day
- (void) InitSkyColors
{
    //---- midday
    GLKVector3 middayTop = GLKVector3Make(47,165,235);
    GLKVector3 middayBottom = GLKVector3Make(222,255,255);
    //GLKVector3 middayBottom = GLKVector3Make(190,234,255);
    int pCount = 10;
    for (int i = 0; i < pCount; i++)
    {
        float rVal = [CommonHelpers ParabolicInterpolationUp: middayTop.r : middayBottom.r : 0 : pCount-1 : i];
        float gVal = [CommonHelpers ParabolicInterpolationUp: middayTop.g : middayBottom.g : 0 : pCount-1 : i];
        float bVal = [CommonHelpers ParabolicInterpolationUp: middayTop.b : middayBottom.b : 0 : pCount-1 : i];
  
        middayPlt[i] = GLKVector4Make(rVal,gVal,bVal,255);
    }
    
    //---- evening
    //oiginal template
    eveningPlt[0] = GLKVector4Make(28,44,78,255);
    eveningPlt[1] = GLKVector4Make(28,44,78,255);
    eveningPlt[2] = GLKVector4Make(38,66,106,255);
    eveningPlt[3] = GLKVector4Make(42,93,138,255);
    eveningPlt[4] = GLKVector4Make(41,122,167,255);
    eveningPlt[5] = GLKVector4Make(40,166,195,255);
    eveningPlt[6] = GLKVector4Make(93,188,206,255);
    eveningPlt[7] = GLKVector4Make(172,205,196,255);
    eveningPlt[8] = GLKVector4Make(250,210,161,255);
    eveningPlt[9] = GLKVector4Make(215,139,103,255);
    
    
    //programmatical coloring
    /*
    GLKVector3 eveningTop = GLKVector3Make(28,44,78);
    GLKVector3 eveningBottom = GLKVector3Make(245,201,179);
    pCount = 10;
    for (int i = 0; i < pCount; i++)
    {
        float rVal = [CommonHelpers ParabolicInterpolationUp:eveningTop.r :eveningBottom.r :0 :pCount-1 :i];
        float gVal = [CommonHelpers ParabolicInterpolationUp:eveningTop.g :eveningBottom.g :0 :pCount-1 :i];
        float bVal = [CommonHelpers ParabolicInterpolationUp:eveningTop.b :eveningBottom.b :0 :pCount-1 :i];
        
        eveningPlt[i] = GLKVector4Make(rVal,gVal,bVal,255);
    }
    */
    
    //---- night
    //night template 1
   
    nightPlt[0] = GLKVector4Make(2,10,22,255);
	nightPlt[1] = GLKVector4Make(2,10,22,255);
	nightPlt[2] = GLKVector4Make(3,15,29,255);
	nightPlt[3] = GLKVector4Make(7,23,39,255);
	nightPlt[4] = GLKVector4Make(10,30,48,255);
	nightPlt[5] = GLKVector4Make(10,36,58,255);
	nightPlt[6] = GLKVector4Make(13,41,67,255);
	nightPlt[7] = GLKVector4Make(19,48,74,255);
	nightPlt[8] = GLKVector4Make(29,56,85,255);
	nightPlt[9] = GLKVector4Make(32,60,89,255);
   
    //---- morning
    //original template

    //morning template 1
    morningPlt[0] = GLKVector4Make(177,204,251,255);
	morningPlt[1] = GLKVector4Make(189,210,253,255);
	morningPlt[2] = GLKVector4Make(205,221,253,255);
	morningPlt[3] = GLKVector4Make(217,232,253,255);
	morningPlt[4] = GLKVector4Make(231,240,250,255);
	morningPlt[5] = GLKVector4Make(246,248,245,255);
	morningPlt[6] = GLKVector4Make(253,251,232,255);
	morningPlt[7] = GLKVector4Make(254,251,209,255);
	morningPlt[8] = GLKVector4Make(253,252,177,255);
	morningPlt[9] = GLKVector4Make(252,247,147,255);
     
    //convert from 0-255 color indexing to 0.0-1.0
    for (int i = 0 ; i < 10; i++) 
    {
        middayPlt[i] = GLKVector4DivideScalar(middayPlt[i],255);
        eveningPlt[i] = GLKVector4DivideScalar(eveningPlt[i],255);
        nightPlt[i] = GLKVector4DivideScalar(nightPlt[i],255);
        morningPlt[i] = GLKVector4DivideScalar(morningPlt[i],255);
    }
}

#pragma mark -  Light objects

//create sun, moon vertcies
-(void) InitLightsGeometry
{
    lightsMesh = [[GeometryShape alloc] init];
    lightsMesh.dataSetType = VERTEX_SET;
    lightsMesh.vertStructType = VERTEX_TEX_STR;
    
	float sunHalf = 90;
    float sunMiddleHalf = 7;
    float moonHalf = 7;
    float starHalf = 0.8;//0.3;
    meteorHalf = 10.0;
    
    int objectCount = NUM_OBJECT_ORDERS;
	lightsMesh.vertexCount = 4 * objectCount;
    
    [lightsMesh CreateVertexIndexArrays];
    
    //initial sun position, in start position of coordinate system
	sun.position = GLKVector3Make(0,0,0);
	sun.visible = true;
    //moon
    moon.position = GLKVector3Make(0,0,0);
	moon.visible = true;
    //star collction
    starCount = 2;
    starCollection = malloc(starCount * sizeof(SModelRepresentation));
    for (int i = 0; i <  starCount; i++)
    {
        starCollection[i].visible = true;
        starCollection[i].position = GLKVector3Make(0,0,0);
        starCollection[i].time = 0; //used to determine when time to change position
    }
    //meteor #v1.1
    meteor.position = GLKVector3Make(0,0,0);
    meteor.visible = NO;
    meteor.type = MT_LEFT; //type of meteor currently showing
    meteor.timeInMove = 0;
    
	int n = 0;
    //NOTE: order should match enumObjectOrder
    //sun consists of 2 circles
    //sun
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x - sunHalf, sun.position.y + sunHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x - sunHalf, sun.position.y - sunHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x + sunHalf, sun.position.y + sunHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x + sunHalf, sun.position.y - sunHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
    n++;
    //sun middle circle
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x - sunMiddleHalf, sun.position.y + sunMiddleHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x - sunMiddleHalf, sun.position.y - sunMiddleHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x + sunMiddleHalf, sun.position.y + sunMiddleHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(sun.position.x + sunMiddleHalf, sun.position.y - sunMiddleHalf, sun.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
    n++;
    
    //moon
    lightsMesh.verticesT[n].vertex = GLKVector3Make(moon.position.x - moonHalf, moon.position.y + moonHalf, moon.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(moon.position.x - moonHalf, moon.position.y - moonHalf, moon.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(moon.position.x + moonHalf, moon.position.y + moonHalf, moon.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(moon.position.x + moonHalf, moon.position.y - moonHalf, moon.position.z);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
    n++;
    
    //star
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-starHalf,starHalf, 0);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-starHalf,-starHalf, 0);
	lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make( starHalf,starHalf, 0);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
	n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(starHalf,-starHalf, 0);
	lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
    n++;
    
    //meteor left #v1.1
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-meteorHalf,meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-meteorHalf,-meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make( meteorHalf,meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(meteorHalf,-meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
    n++;
    
    //meteor right
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-meteorHalf,meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 0.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(-meteorHalf,-meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(1.0, 1.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(meteorHalf,meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 0.0);
    n++;
    lightsMesh.verticesT[n].vertex = GLKVector3Make(meteorHalf,-meteorHalf, 0);
    lightsMesh.verticesT[n].tex = GLKVector2Make(0.0, 1.0);
    
    
    //sun color palettes
    /*
    sunMiddayColor = GLKVector4Make(255/255.,255/255.,240/255.,255);
    sunEveningColor = GLKVector4Make(255/255.,250/255.,130/255.,255);
    //sunEveningColor = GLKVector4Make(255/255.,220/255.,110/255.,255);
    sunMorningColor =  GLKVector4Make(255/255.,245/255.,173/255.,255);
    */
    sunColoring.midday = GLKVector4Make(255/255.,255/255.,240/255.,255);
    sunColoring.evening = GLKVector4Make(255/255.,250/255.,130/255.,255);
    sunColoring.morning = GLKVector4Make(255/255.,245/255.,173/255.,255);
}

- (void) UpdateSun: (float) curTime
{
    //Update sun position/color
    //day starts at 00:00 midnight, which is directly north, 0 angle is east, so we need to shift to north
    float angleShift = -90;
    //since maximal day time is 1440, and maximum rotation angle is 360 , 4 = 1440 / 360
    float theta = curTime / 4 + angleShift; //horizontal rotation angle
    
    //x - east/west, z - north/south
    float rads = radius / 2; //max x and z values on both sides
    float thetaRad = GLKMathDegreesToRadians(theta);
    float sinValue = sinf(thetaRad); //used twise, so we optimize
    sun.position.x = radius * cosf(thetaRad);
    sun.position.z = rads * sinValue;
    sun.position.y = radius * sinValue;
    //update sun color depending on daytime
	[CommonHelpers InterpolateDaytimeColor: &sun.color : sunColoring.midday : sunColoring.evening : sunColoring.midday : sunColoring.morning : curTime];
    self.effectSun.constantColor = sun.color;
    
    //change visibility
    float visibilityBoundry = -75;//-85;
    if(sun.visible && sun.position.y < visibilityBoundry)
    {
        sun.visible = false;
    }else 
    if(!sun.visible && sun.position.y > visibilityBoundry)
    {
        sun.visible = true;
    }
}

- (void) UpdateMoon: (float) curTime
{
    //Update moon position/color
    //day starts at 00:00 midnight, which is directly north, 0 angle is east, so we need to shift to south
    float angleShift = 90;
    //since maximal day time is 1440, and maximum rotation angle is 360 , 4 = 1440 / 360
    float theta = curTime / 4 + angleShift; //horizontal rotation angle
    //x - east/west, z - north/south
    float rads = radius / 2; //max x and z values on both sides
    float sinkFactor = 30; //axis of rotation is lowered byt his amount, so moon rises later than sun sets,  etc
    float thetaRad = GLKMathDegreesToRadians(theta);
    float sinValue = sinf(thetaRad); //used twise, so we optimize
    moon.position.x = radius * cosf(thetaRad);
    moon.position.z = rads * sinValue;
    moon.position.y = radius * sinValue - sinkFactor;
    
    //change visibility
    float visibilityBoundry = -12;
    if(moon.visible && moon.position.y < visibilityBoundry)
    {
        moon.visible = false;
    }else 
    if(!moon.visible && moon.position.y > visibilityBoundry)
    {
        moon.visible = true;
    }
}

//stars rapidly change positions making effect if shining stars
- (void) UpdateStars: (float) dt
{
    for (int i = 0; i <  starCount; i++)
    {
        starCollection[i].visible = moon.visible; //visible only with moon
        
        if(starCollection[i].visible)
        {
            starCollection[i].time += dt;
            
            float shineTime = 0.2 /*0.3*/ + i * 0.01; //#v1.1 //how long stays in one place (make little uneven for so they dont shine at once)
            
            //time to change position
            if(starCollection[i].time > shineTime)
            {
                //randomize postion across plane
                float boundVal = 40; //bound of random plane
                float x = [CommonHelpers RandomInRange: -boundVal : boundVal];
                float y = [CommonHelpers RandomInRange: -boundVal : boundVal];
                
                starCollection[i].position = GLKVector3Make(x, radius / 3, y);
                starCollection[i].time = 0;
            }
        }
    }
}

//meteor update at night //#v1.1
- (void) UpdateMeteor: (float) curTime : (float) dt
{
    //fall speed
    float relSpeed = -70.0; //-75.0; //-35.0;
    GLKVector2 fallVel = GLKVector2Make(relSpeed, relSpeed);
    
    //time when meteor can appear
    float startTime = 21 * 60;
    float endTime = 3 * 60;
    
    //timing of flight. determines when next flight is going to happen
    meteor.timeInMove += dt; //time betwen last move ended
    meteor.moveTime = 7.0; //time in between flight
    
    //set star position
    if(!meteor.visible && (curTime > startTime || curTime < endTime) && meteor.timeInMove > meteor.moveTime) //fly only at night
    {
        meteor.visible = YES;
        //random on skudome border
        SCircle startCircle;
        startCircle.center = GLKVector3Make(0, 0, 0);
        startCircle.radius = radius;
        //initial position
        meteor.position = [CommonHelpers RandomOnCircleLine: startCircle];
        meteor.position.y = radius;
        
        //determine side movementvector
        meteor.movementVector = GLKVector3Normalize(meteor.position);
       // NSLog(@"%f %f %f", meteor.movementVector.x, meteor.movementVector.y, meteor.movementVector.z);
        
        //determine direction of movement
        float direction;
        switch (meteor.type)
        {
            case MT_LEFT:
                direction = -M_PI_2;
                break;
            case MT_RIGHT:
                direction = M_PI_2;
                break;
            default:
                direction = -M_PI_2;
                break;
        }
        
        [CommonHelpers RotateY:  &meteor.movementVector : direction]; // turn sideways
        //meteor.movementVector.y = 1.0;
        meteor.movementVector = GLKVector3MultiplyScalar(meteor.movementVector, fallVel.x);
    }
    
    //move across
    if(meteor.visible)
    {
        meteor.position = GLKVector3Add(meteor.position, GLKVector3MultiplyScalar(meteor.movementVector, dt));
        
        //if over horizont, stop
        if(meteor.position.y < -meteorHalf)
        {
            meteor.visible = NO;
            meteor.type = [CommonHelpers RandomInRangeInt: 0 : 1]; //choose left or right float
            meteor.timeInMove = 0;
            //NSLog(@"---   %d", meteor.type);
        }
    }
}

//Clean-up
- (void) ResourceCleanUp
{
    [skyMesh ResourceCleanUp];
    [lightsMesh ResourceCleanUp];
    
    self.effectSkyDome = nil;
    self.effectSun     = nil;
    self.effectMiddSun = nil;
    self.effectMoon    = nil;
    self.effectStar    = nil;
    self.effectMeteor  = nil;
    
    free(starCollection);
}

#pragma mark -  Additional

//get vector going from character in direction of sky light object sun or moon
- (GLKVector3) GetCharacterLightVector: (Character*) character
{
    //translate light together with character position
    GLKVector3 translatedPosition = GLKVector3Add(sun.position, character.camera.position);
    //GLKVector3 translatedPosition = sun.position;
    return [CommonHelpers GetVectorFrom2Points: character.camera.position : translatedPosition : NO];
}

//modifie given coloring (primaraly darken) depending weather character looks at light object
- (void) ModifyColoringByViewVector: (GLKVector4*) coloring : (Character*) character
{
    GLKVector4 returnColoring;
    float darkenKoef;
    
    //angle between view and light vector from 0 to PI (0 looking striaght at light,  PI - looking away)
    float lightAngle = [CommonHelpers AngleBetweenVectors180: [self GetCharacterLightVector: character] : character.camera.viewVector];
    
    //factors that determine brightness of object
    //factor depending on viewing angle toward lights object from 0.0 (viewind at light) to 1.0 (view away from light)
    float angleFactor = lightAngle / M_PI;
    
    darkenKoef = 0.4 - angleFactor;
    
    
    //darken color
    returnColoring.r = coloring->r - darkenKoef;
    returnColoring.g = coloring->g - darkenKoef;
    returnColoring.b = coloring->b - darkenKoef;
    
    //fit in bounds, bounds should not go under black and not above given color
    if(returnColoring.r > coloring->r)
    {
        returnColoring.r = coloring->r;
    }
    if(returnColoring.r < 0.0)
    {
        returnColoring.r = 0.0;
    }
    if(returnColoring.g > coloring->g)
    {
        returnColoring.g = coloring->g;
    }
    if(returnColoring.g < 0.0)
    {
        returnColoring.g = 0.0;
    }
    if(returnColoring.b > coloring->b)
    {
        returnColoring.b = coloring->b;
    }
    if(returnColoring.b < 0.0)
    {
        returnColoring.b = 0.0;
    }
    
    *coloring = returnColoring;
}

@end
