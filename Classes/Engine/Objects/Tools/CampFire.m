//
//  CampFire.m
//  Island survival
//
//  Created by Ivars Rusbergs on 5/15/13.
//
// STATUS: - OK


#import "CampFire.h"

@implementation CampFire
@synthesize campfire, kindlingModel,spindleModel,cookingStandModel,vertexCount,indexCount,storedItems,storedCount,
            effect, spindle, state, cookingItem, fishPrepModel, ratPrepModel;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self InitGeometry];
    }
    return self;
}


- (void) ResetData
{
    //nill particled
    //[firePrt End];
    //[smokePrt End];
    //[cookSmokePrt End];
    
    //null states
    state = FS_NONE;
    //null data
    [self NullCampfireParameters];
    [self CleanStoredItems];
    
    burnsInterval.timeInAction = 0.0;
}


- (void) InitGeometry
{
    //stored items are used to store cooked food after new fireplace has been set
    storedCount = FISH_COUNT + RAT_COUNT;
    storedItems = malloc(storedCount * sizeof(SModelRepresentation));
    
    //models
    float kindlingScale = 0.3;
    float spindleScale = 0.2;
    float cookingStandScale = 0.5; //0.7
    float fishScale = 0.6;  //NOTE scale is smaller than in fish module
    float ratScale = 0.2;
    
    //load models
    kindlingModel = [[ModelLoader alloc] initWithFileScale: @"kindling.obj" : kindlingScale];
    spindleModel = [[ModelLoader alloc] initWithFileScale: @"spindle.obj" : spindleScale];
    cookingStandModel = [[ModelLoader alloc] initWithFileScale: @"cooking_stand.obj" : cookingStandScale];
    
    fishPrepModel = [[ModelLoader alloc] initWithFileScale: @"fish_prep.obj" : fishScale];
    ratPrepModel = [[ModelLoader alloc] initWithFileScale: @"rat_prep.obj" : ratScale];
    
    vertexCount = kindlingModel.mesh.vertexCount + spindleModel.mesh.vertexCount + cookingStandModel.mesh.vertexCount +
                  fishPrepModel.mesh.vertexCount + ratPrepModel.mesh.vertexCount;
    indexCount = kindlingModel.mesh.indexCount + spindleModel.mesh.indexCount + cookingStandModel.mesh.indexCount +
                 fishPrepModel.mesh.indexCount + ratPrepModel.mesh.indexCount;

    //bounds
    //[kindlingModel  AssignBounds: &campfire : 0];
    
    //texture array
    texIDKindling = malloc(kindlingModel.materialCount * sizeof(GLuint));
    texIDSpindle = malloc(spindleModel.materialCount * sizeof(GLuint));
    texIDCookingstand = malloc(cookingStandModel.materialCount * sizeof(GLuint));
  
    texIDFish = malloc(fishPrepModel.materialCount * 2 * sizeof(GLuint)); //* 2 because there are raw and cooked texture
    texIDRat = malloc(ratPrepModel.materialCount * 2 * sizeof(GLuint));
    
    //particles
    //firePrt = [[ParticleEffect alloc] initWithType: PT_FIRE];
    //smokePrt = [[ParticleEffect alloc] initWithType: PT_SMOKE_DRILL];
    //cookSmokePrt = [[ParticleEffect alloc] initWithType: PT_SMOKE_COOKING]; //#v1.1.
    
    //parameters
    burnTime.max = 40; //maximal fire burning time in seconds
    cookingItem.time.max = 10; //how long object wil cook in seconds
    
    spindle.smokeTemperature = 0.1; //relative temperature from 0.0 to 1.0 when starts smoking
    spindle.fireTemperature = 1.0;
    
    // intervale before character burns while standin on fire
    burnsInterval.actionTime = 1.0;
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh : (int*) vCnt : (int*) iCnt
{
    //load model into external geometry mesh
    
    //---------- fill kindling
    int firstVertex = *vCnt;
    firstIndexKindling = *iCnt;
    for (int n = 0; n < kindlingModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = kindlingModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  kindlingModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < kindlingModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  kindlingModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
    
    //--------- fill spindle
    firstVertex = *vCnt;
    firstIndexSpindle = *iCnt;
    for (int n = 0; n < spindleModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = spindleModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  spindleModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < spindleModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  spindleModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
    
    //--------- fill cooking stand
    firstVertex = *vCnt;
    firstIndexCookingstand = *iCnt;
    for (int n = 0; n < cookingStandModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = cookingStandModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  cookingStandModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < cookingStandModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  cookingStandModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
    
    //--------- fill prepared fish
    firstVertex = *vCnt;
    firstIndexFish = *iCnt;
    for (int n = 0; n < fishPrepModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = fishPrepModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  fishPrepModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < fishPrepModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  fishPrepModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
    
    //--------- fill prepared rat
    firstVertex = *vCnt;
    firstIndexRat = *iCnt;
    for (int n = 0; n < ratPrepModel.mesh.vertexCount; n++)
    {
        //vertices
        mesh.verticesT[*vCnt].vertex = ratPrepModel.mesh.verticesT[n].vertex;
        mesh.verticesT[*vCnt].tex =  ratPrepModel.mesh.verticesT[n].tex;
        *vCnt = *vCnt + 1;
    }
    
    for (int n = 0; n < ratPrepModel.mesh.indexCount; n++)
    {
        //indices
        mesh.indices[*iCnt] =  ratPrepModel.mesh.indices[n] + firstVertex;
        *iCnt = *iCnt + 1;
    }
}


- (void) SetupRendering
{
    //init shaders
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.transform.projectionMatrix = [[SingleGraph sharedSingleGraph] projMatrix];
    
    //textures
    //load  textures
    //kindling
    for (int i = 0; i < kindlingModel.materialCount; i++)
    {
        texIDKindling[i] = [[SingleGraph sharedSingleGraph] AddTexture: [kindlingModel.materials objectAtIndex:i]: YES]; //bark - 64x64, tinder - 64x64
    }
    
    //spindle
    for (int i = 0; i < spindleModel.materialCount; i++)
    {
        texIDSpindle[i] = [[SingleGraph sharedSingleGraph] AddTexture: [spindleModel.materials objectAtIndex:i]: YES]; //bark - 64x64
    }
    
    //cooking stand
    for (int i = 0; i < cookingStandModel.materialCount; i++)
    {
        texIDCookingstand[i] = [[SingleGraph sharedSingleGraph] AddTexture: [cookingStandModel.materials objectAtIndex:i]: YES]; //bark - 64x64
    }
    
    //burned wood textue
    texBurnedWood = [[SingleGraph sharedSingleGraph] AddTexture: @"burned_wood.png" :YES];  //16x16
    
    //NOTE: raw and cooked texture are names are composed <original_texture>_raw.png (or _cooked)
    //fish prepared
    int IDcounter = 0;
    for (int i = 0; i < fishPrepModel.materialCount; i++)
    {
        NSArray *stringChunks = [[fishPrepModel.materials objectAtIndex:i] componentsSeparatedByString:@"."];
        //raw
        NSString *rawTexture = [NSString stringWithFormat:@"%@_raw.%@", [stringChunks objectAtIndex:0], [stringChunks objectAtIndex:1]];
        texIDFish[IDcounter++] = [[SingleGraph sharedSingleGraph] AddTexture: rawTexture: YES]; //64x64
        //cooked
        NSString *cookedTexture = [NSString stringWithFormat:@"%@_cooked.%@", [stringChunks objectAtIndex:0], [stringChunks objectAtIndex:1]];
        texIDFish[IDcounter++] = [[SingleGraph sharedSingleGraph] AddTexture: cookedTexture: YES]; //64x64
    }
    
    //rat prepared
    IDcounter = 0;
    for (int i = 0; i < ratPrepModel.materialCount; i++)
    {
        NSArray *stringChunks = [[ratPrepModel.materials objectAtIndex:i] componentsSeparatedByString:@"."];
        //raw
        NSString *rawTexture = [NSString stringWithFormat:@"%@_raw.%@", [stringChunks objectAtIndex:0], [stringChunks objectAtIndex:1]];
        texIDRat[IDcounter++] = [[SingleGraph sharedSingleGraph] AddTexture: rawTexture: YES]; //64x64
        //cooked
        NSString *cookedTexture = [NSString stringWithFormat:@"%@_cooked.%@", [stringChunks objectAtIndex:0], [stringChunks objectAtIndex:1]];
        texIDRat[IDcounter++] = [[SingleGraph sharedSingleGraph] AddTexture: cookedTexture: YES]; //64x64
    }
    
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.useConstantColor = GL_TRUE;
    //use bright light while fire is burning, but daytime color otherwise
    //self.effect.constantColor = daytimeColorGlobal = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    //particle set up
    //[firePrt SetupRendering: @"particle_fire.png"];
    //[smokePrt SetupRendering: @"particle_fire.png"];
    //[cookSmokePrt SetupRendering: @"particle_fire.png"];
}


- (void) Update: (float) dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Interface*) intr : (Particles*) particles
{
    //update fireplace
    if(state != FS_NONE)
    {
        [self UpdateSpindle: curTime : dt : modelviewMat : character : intr : particles];
        
        [self UpdateFire: curTime : dt : modelviewMat : character : intr : particles];
        
        [self UpdateCooking: dt : particles];
        
        campfire.displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, campfire.position);
        campfire.displaceMat = GLKMatrix4RotateY(campfire.displaceMat, campfire.orientation.y);

        //[character.camera UpdateCloseupAction : dt];
    }else
    {
        [particles.drillSmokePrt End]; //this removes drill smoke when we move while drilling
    }
    
    //update stored cooked items
    for (int i = 0; i <  storedCount; i++)
    {
        if(storedItems[i].type != kItemEmpty)
        {
            storedItems[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, storedItems[i].position);
            storedItems[i].displaceMat = GLKMatrix4RotateY(storedItems[i].displaceMat, storedItems[i].orientation.y);
        }
    }
    
    //check character burning when steppng in campfire
    if(state == FS_FIRE && [CommonHelpers PointInCircle: campfire.position : kindlingModel.bsRadius : character.camera.position])
    {
        if(fequal(burnsInterval.timeInAction, 0.0)) //interval between stings
        {
            float healtDecrement = 0.3;
            [character DecreaseHealth: healtDecrement : intr : JT_FIRE_BURN];
        }
        
        //wait seconds before making next sting
        burnsInterval.timeInAction += dt;
        if(burnsInterval.timeInAction > burnsInterval.actionTime)
        {
            burnsInterval.timeInAction = 0.0;
        }
    }else
    {
        burnsInterval.timeInAction = 0.0; //nill sting time when character moves out of bee swarm, but not out of attack range
    }
    
    
    //daytimeColorGlobal = daytimeColor; //store here because we will have to later in render function
    effect.constantColor = daytimeColor;
}

- (void) Render
{
    //stored after cooking / cleaned item list draw
    for (int i = 0; i <  storedCount; i++)
    {
        if(storedItems[i].type != kItemEmpty)
        {
            
            [[SingleGraph sharedSingleGraph] SetCullFace: YES];
            [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
            [[SingleGraph sharedSingleGraph] SetBlend: NO];
            
            [self RenderCookingStand: &storedItems[i].displaceMat];
            
            //fish
            if(storedItems[i].type == ITEM_FISH_CLEANED)
            {
                [[SingleGraph sharedSingleGraph] SetCullFace: NO];
                [self RenderFish: storedItems[i].state : &storedItems[i].displaceMat];
            }
            
            //rat
            if(storedItems[i].type == ITEM_RAT_CLEANED)
            {
                [self RenderRat: storedItems[i].state : &storedItems[i].displaceMat];
            }
        }
    }
    
    //render fireplace
    if(state != FS_NONE)
    {
        [[SingleGraph sharedSingleGraph] SetCullFace: YES];
        [[SingleGraph sharedSingleGraph] SetDepthTest: YES];
        [[SingleGraph sharedSingleGraph] SetDepthMask: YES];
        [[SingleGraph sharedSingleGraph] SetBlend: NO];
        
        //if fire is burning make objects bright
        if(state == FS_FIRE)
        {
            effect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        }
        
        //kindling
        [self RenderKindling];
        
        //spindle
        if(state == FS_DRILL)
        {
            [self RenderSpindle];
        }
        
        //cooking stand
        if(cookingItem.objectID != kItemEmpty)
        {
            [self RenderCookingStand: &campfire.displaceMat];
        }
        
        //fish
        if(cookingItem.objectID == ITEM_FISH_CLEANED)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace: NO];
            [self RenderFish:cookingItem.state: &campfire.displaceMat];
        }
        
        //rat
        if(cookingItem.objectID == ITEM_RAT_CLEANED)
        {
            [self RenderRat: cookingItem.state : &campfire.displaceMat];
        }
        
        //particles
        //render parameters are reset inside, be carfeull if not rendered last
        //NOTE: VBO altered
        //[firePrt Render];
        //[smokePrt Render];
    }
    
    //cooking smoke
    //[cookSmokePrt Render];
}

- (void) RenderKindling
{
    for (int i = 0; i < kindlingModel.materialCount; i++) //render by material
    {
        if(state == FS_DRY) //simulate burned wood when fire dies out
        {
            effect.texture2d0.name = texBurnedWood;
        }else
        {
            effect.texture2d0.name = texIDKindling[i];
        }
        
        effect.transform.modelviewMatrix = campfire.displaceMat;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, kindlingModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexKindling + kindlingModel.patches[i].startIndex)  * sizeof(GLushort)));
    }
}

- (void) RenderSpindle
{
    for (int i = 0; i < spindleModel.materialCount; i++) //render by material
    {
        effect.texture2d0.name = texIDSpindle[i];
        effect.transform.modelviewMatrix = GLKMatrix4Multiply(campfire.displaceMat, spindle.rotMat);;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, spindleModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexSpindle + spindleModel.patches[i].startIndex)  * sizeof(GLushort)));
    }
}

- (void) RenderCookingStand:(GLKMatrix4*) displMat
{
    for (int i = 0; i < cookingStandModel.materialCount; i++) //render by material
    {
        effect.texture2d0.name = texIDCookingstand[i];
        self.effect.transform.modelviewMatrix = *displMat;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, cookingStandModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexCookingstand + cookingStandModel.patches[i].startIndex)  * sizeof(GLushort)));
    }
}

- (void) RenderFish: (int) cState: (GLKMatrix4*) displMat
{
    for (int i = 0; i < fishPrepModel.materialCount; i++) //render by material
    {
        if(cState == CI_COOKING) //still cooking
        {
            effect.texture2d0.name = texIDFish[i * 2]; //even
        }else
        if(cState == CI_DONE) //cooked
        {
            effect.texture2d0.name = texIDFish[(i * 2) + 1]; //odd
        }
        
        effect.transform.modelviewMatrix = GLKMatrix4Translate(*displMat, 0, cookingStandModel.AABBmax.y, 0);
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, fishPrepModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexFish + fishPrepModel.patches[i].startIndex)  * sizeof(GLushort))); 
    }
}

- (void) RenderRat: (int) cState : (GLKMatrix4*) displMat
{
    for (int i = 0; i < ratPrepModel.materialCount; i++) //render by material
    {
        if(cState == CI_COOKING) //still cooking
        {
            effect.texture2d0.name = texIDRat[i * 2]; //even
        }else
        if(cState == CI_DONE) //cooked
        {
            effect.texture2d0.name = texIDRat[(i * 2) + 1]; //odd
        }
        
        effect.transform.modelviewMatrix = GLKMatrix4Translate(*displMat, 0, cookingStandModel.AABBmax.y,0);
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, ratPrepModel.patches[i].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET((firstIndexRat + ratPrepModel.patches[i].startIndex)  * sizeof(GLushort)));
    }
}


//-
- (void) ResourceCleanUp
{
    [kindlingModel ResourceCleanUp];
    [spindleModel ResourceCleanUp];
    [cookingStandModel ResourceCleanUp];
    [fishPrepModel ResourceCleanUp];
    [ratPrepModel ResourceCleanUp];
    
    self.effect = nil;
    
    free(texIDKindling);
    free(texIDSpindle);
    free(texIDCookingstand);
    free(texIDFish);
    free(texIDRat);
    
    free(storedItems);
    
    //[firePrt ResourceCleanUp];
    //[smokePrt ResourceCleanUp];
    //[cookSmokePrt ResourceCleanUp];
}


#pragma mark - Helper functions

//null cooking and spindle parameters
- (void) NullCampfireParameters
{
    burnTime.current = 0;
    spindle.temperature = 0;
    spindle.isDrilled = NO;
    spindle.direction = spindle.prevDirection = 0;
    spindle.rotation = 0;
    spindle.rotMat = GLKMatrix4MakeRotation(0, 0, 1, 0);
    
    cookingItem.state = CI_EMPTY;
    cookingItem.objectID = kItemEmpty;
    cookingItem.time.current = 0;
}

#pragma mark - Drilling functions

- (void) StartDrilling: (CGPoint) prevPos
{
    if(state == FS_DRILL)
    {
        spindle.prevTouch.x = [CommonHelpers ConvertToRelative: prevPos.x];
    }
}

- (void) UpdateSpindle:(float) curTime: (float) dt: (GLKMatrix4*) modelviewMat: (Character*) character:(Interface*) intr : (Particles*) particles
{
    if(state == FS_DRILL)
    {
        //cool down spindle temperature
        float coolingFactor = 0.4;
        spindle.temperature -= coolingFactor * dt;
        if(spindle.temperature < 0)
        {
            spindle.temperature = 0;
        }
        
        //start smoking if spindle is running hot
        if(spindle.temperature > spindle.smokeTemperature && spindle.temperature < spindle.fireTemperature)
        {
            float additHeight = 0.05; //slightly raise smoke particles
            float smokeKoef = 1.3;
            GLKVector3 smokePosition = campfire.position;
            smokePosition.y += additHeight;
            
            [particles.drillSmokePrt AssigneMaxParticleSpeed:(spindle.temperature - spindle.smokeTemperature) * smokeKoef];//smoke intensity
            [particles.drillSmokePrt Start: smokePosition];
        }else
        if(spindle.temperature <= 0.0)
        {
            [particles.drillSmokePrt End];
        }else
        //start fire
        if(spindle.temperature >= spindle.fireTemperature)
        {
            spindle.isDrilled = NO;
            [particles.drillSmokePrt End];
            
            [self StartFire: character : intr : particles];
        }
        
        //[particles.smokePrt Update: dt : curTime : modelviewMat];
    }
}


//process of drilling spindle and increasing temperature
//used when drill board stroke swiped
- (void) DrillSpindle: (float) X: (float) dt: (Interface*) intr
{
    if(state == FS_DRILL)
    {
        float heatCoef; //drill heat up coef
        if([[SingleDirector sharedSingleDirector] difficulty] == GD_HARD)
        {
            //it is easier to drill on iphone because screen is smaller
            if(isIpad)
            {
                heatCoef = 3.0;
            }else
            {
                heatCoef = 2.0;
            }
        }else
        {
            if(isIpad)
            {
                heatCoef = 5.0;
            }else
            {
                heatCoef = 3.0;
            }
        }
        
        X = [CommonHelpers ConvertToRelative: X];
        
        float swipeRel = X - spindle.prevTouch.x; //length of swipe in relative space
        
        //increase temperature when drilling
        //swipe factor is how long tsroke was compared to board size
        Button *drillBoardIcon = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
        float swipeFactor = fabs(swipeRel) / drillBoardIcon.rect.relative.size.width;
        
        spindle.temperature += swipeFactor * heatCoef * dt;
        
        //for rotation visualisation
        float rotKoef = 700; //how fast spindle rotates
        spindle.rotation -= swipeRel * rotKoef * dt;
        //NSLog(@"%f", spindle.rotation);
        spindle.rotMat = GLKMatrix4MakeRotation(spindle.rotation, 0, 1, 0);
        
        //for sound we need to determine when direction of stroke changes
        spindle.prevDirection = spindle.direction;
        spindle.direction = swipeRel;

        //NSLog(@"rel - %f", swipeRel);
        
        //true previous position
        spindle.prevTouch.x = X;
    }
}

#pragma mark - Fire functions

//start burning
- (void) StartFire: (Character*) character : (Interface*) intr  : (Particles*) particles
{
    state = FS_FIRE;
    
    float additHeight = 0.06; //slightly raise fire particles
    GLKVector3 firePosition = campfire.position;
    firePosition.y += additHeight;
    
    [particles.firePrt Start: firePosition];
    burnTime.current = 0;
    
    [self LeaveFirePlace: character : intr];
}


- (void) UpdateFire: (float) curTime : (float) dt : (GLKMatrix4*) modelviewMat : (Character*) character : (Interface*) intr : (Particles*) particles
{
    if(state == FS_FIRE)
    {
        //intenisty of fire
        float fireIntensity = particles.firePrt.attributes.prtclSpeedInitial * (1.0 - (burnTime.current / burnTime.max));
        [particles.firePrt AssigneMaxParticleSpeed: fireIntensity];
        
        //[firePrt Update: dt : curTime : modelviewMat];
        
        burnTime.current += dt;
        
        //end check
        if(burnTime.current > burnTime.max)
        {
            state = FS_DRY; //fire died out
            [particles.firePrt End];
        }
    }
}

#pragma mark - Cooking actions

//cooking item place allowed
- (BOOL) CookingItemAllowed: (GLKVector3) spacePoint3D: (enumInventoryItems) item
{
    //NOTE: koef must match also in interactions module
    float placeRadius = kindlingModel.bsRadius * 3.0; //size of area where wood and food can be placed
    return state == FS_FIRE && cookingItem.objectID == kItemEmpty &&
    //dropped on fire place
    [CommonHelpers PointInSphere: campfire.position : placeRadius : spacePoint3D];
}

- (BOOL) WoodItemAllowed: (GLKVector3) spacePoint3D : (enumInventoryItems) item
{
    //NOTE: koef must match also in interactions module
    float placeRadius = kindlingModel.bsRadius * 3.0; //size of area where wood and food can be placed
    return item == ITEM_WOOD && state == FS_FIRE && [CommonHelpers PointInSphere:campfire.position :placeRadius :spacePoint3D];
}

//start cooking - draw cooking stand cookable object
- (void) StartCooking: (enumInventoryItems) item
{ 
    cookingItem.state = CI_COOKING;
    cookingItem.objectID = item;
    cookingItem.time.current = 0;
}

//halt cooking (NOT end cooking)
- (void) HaltCooking
{
    cookingItem.state = CI_EMPTY;
    cookingItem.objectID = kItemEmpty;
    cookingItem.time.current = 0;
}

//update item cooking
- (void) UpdateCooking: (float) dt : (Particles*) particles
{
    if(cookingItem.state == CI_COOKING && state == FS_FIRE)
    {
        cookingItem.time.current += dt;
        
        //item is cooked
        if(cookingItem.time.current >= cookingItem.time.max)
        {
            cookingItem.state = CI_DONE;
            
            //start cooking smoking after is cooked #v1.1.
            GLKVector3 smokePosition = campfire.position;
            float aboveCookingStand = 0.3;
            smokePosition.y += cookingStandModel.AABBmax.y + aboveCookingStand;
            [particles.cookSmokePrt Start: smokePosition];
        }
    }
}


//add wood to campfire
- (void) AddWood
{
    burnTime.current = 0;
}


#pragma mark - Cooked item storage

//only stored when new fireplace is made and old food is not taken off

//clear all stored items
- (void) CleanStoredItems
{
    for (int i = 0; i < storedCount; i++)
    {
        storedItems[i].type = kItemEmpty;
    }
}

//add item to store
//stateOfItem - weather item was cooked before fire died out
- (void) AddItemToStore: (int) item: (int) stateOfItem :(GLKVector3) position: (float) orientation
{
    //find free slot
    int freeSlot = -1;
    for (int i = 0; i < storedCount; i++)
    {
        if(storedItems[i].type == kItemEmpty)
        {
            freeSlot = i;
            break;
        }
    }
    
    if(freeSlot >= 0) //if free slot is found
    {
        storedItems[freeSlot].type = item; // [self DetermineItem:item :stateOfItem];
        storedItems[freeSlot].state = stateOfItem;
        storedItems[freeSlot].position = position;
        storedItems[freeSlot].orientation.y = orientation;
    }else
    {
         //when no new places are allowed, process here
    }
}

//remove item form store
- (void) DeleteItemFromStore: (int) slotNumber
{
    if(slotNumber < storedCount)
    {
        storedItems[slotNumber].type = kItemEmpty;
    }
}

//given coocable item and cooking state, determine item that is corrently on fire
//stateOfItem - item cooking state
- (int) DetermineItem: (int) item: (int) stateOfItem
{
    int itemFinal = kItemEmpty;
    switch (item)
    {
        case ITEM_FISH_CLEANED:
            if(stateOfItem == CI_COOKING)
            {
                itemFinal = ITEM_FISH_CLEANED;
            }else
            if(stateOfItem == CI_DONE)
            {
                itemFinal = ITEM_FISH_COOKED;
            }
            break;
        case ITEM_RAT_CLEANED:
            if(stateOfItem == CI_COOKING)
            {
                itemFinal = ITEM_RAT_CLEANED;
            }else
            if(stateOfItem == CI_DONE)
            {
                itemFinal = ITEM_RAT_COOKED;
            }
            break;
        default:
            break;
    }

    return itemFinal;
}

#pragma mark - CloseUp actions

//set up and init closeup action on fire
- (void) InitCloseUpAction:(Character*) character
{
    float distanceFromObject = 1.0;
    float timeOfCloseup = 0.7;
    [character.camera StartCloseupAction: campfire.position: distanceFromObject: timeOfCloseup];
}


//leave closed fire state
//used in with caharcter joystick touch
- (void) LeaveFirePlace: (Character*) character: (Interface*) intr
{
    if(character.state == CS_FIRE_DRILL) //leave during drilling
    {
        spindle.isDrilled = NO;
        //if returned when drilling, put back kindling
        if(state == FS_DRILL)
        {
            state = FS_NONE;
            [character.inventory AddItemInstance: ITEM_KINDLING];
        }
    
        //return back used kindling and set previous state
        //put view vector at fire just drilled
        [character.camera RestoreVectorsWithViewAt:campfire.position]; 

        [character SetPreviousState: intr];
    }
}

#pragma mark - Picking functions

//check if object is picked, and add to inve ntory
//return 0 - has not picked, 1 - picked, 2 - invenotry was full, not able to pick
- (int) PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv : (Particles*) particles
{
    int returnVal = 0;
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;

    //pick from fireplace
    if(cookingItem.objectID > kItemEmpty)
    {
        GLKVector3 pickCenter = campfire.position;
        pickCenter.y += cookingStandModel.AABBmax.y / 2.0;
        resultBool = [CommonHelpers IntersectLineSphere: pickCenter : cookingStandModel.bsRadius :
                                                charPos : pickedPos : pickDistance];
        if(resultBool)
        {
            returnVal = 2;
        
            int itemPicked = [self DetermineItem:cookingItem.objectID :cookingItem.state];
            if(itemPicked != kItemEmpty)
            {
                //add item
                if([inv AddItemInstance: itemPicked]) //succesfully added
                {
                    [self HaltCooking];
                    
                    [particles.cookSmokePrt End]; //in case there was cooked item, stop smoking when picked up
                    returnVal = 1;
                }
            }
            
        }
    }
    
    //check for picking other stored items
    if(!returnVal)
    {
        for (int i = 0; i <  storedCount; i++)
        {
            if(storedItems[i].type != kItemEmpty)
            {
                GLKVector3 pickCenter = storedItems[i].position;
                pickCenter.y += cookingStandModel.AABBmax.y / 2.0;
                
                resultBool = [CommonHelpers IntersectLineSphere: pickCenter : cookingStandModel.bsRadius :
                                                        charPos : pickedPos : pickDistance];
                if(resultBool)
                {
                    returnVal = 2;
                    
                    int itemPicked = [self DetermineItem: storedItems[i].type : storedItems[i].state];
                    
                    if(itemPicked != kItemEmpty)
                    {
                        //add item
                        if([inv AddItemInstance: itemPicked]) //succesfully added
                        {
                            [self DeleteItemFromStore:i];
                            returnVal = 1;
                        }
                    }
                    
                    break;
                }
            }
        }
    }
    
    
    return returnVal;
}

//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct: (Interface*) intr : (Particles*) particles
{
    if(character.state == CS_BASIC && [self IsPlaceAllowed: placePos: terr: intct])
    {
        //if item is on fire (cooked or not) store it
        //if there is dry fireplace at the moment
        if(state == FS_DRY && cookingItem.objectID != kItemEmpty)
        {
            [self AddItemToStore: cookingItem.objectID : cookingItem.state : campfire.position : campfire.orientation.y];
        }
        
        campfire.position = placePos;
        //orientation maches user
        GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
        campfire.orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect] + M_PI_2; //turn 90 more because cooking things will look perpendicular to view vector
        
        //enter drilling mode
        [self NullCampfireParameters];
        state = FS_DRILL;
        
        //particles
        [particles.firePrt End];
        [particles.drillSmokePrt End];
        [particles.cookSmokePrt End];
        
        //start action to move camera to object
        [self InitCloseUpAction:character];
        
        //interface related
        [character setState: CS_FIRE_DRILL]; //eneter fire starting mode (more related to interface)
        [intr SetFireDrillInterface];
        
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: ITEM_KINDLING: character.inventory.grabbedItem.previousSlot];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos : (Terrain*) terr : (Interaction*) intct
{
    if(state != FS_NONE && state != FS_DRY)
    {
        return NO;
    }
    
    //if(![CommonHelpers PointInCircle: terr.oceanLineCircle.center: terr.oceanLineCircle.radius: placePos])
    //if(![CommonHelpers PointInCircle: terr.inlandCircle.center : terr.inlandCircle.radius : placePos])
    if(![terr IsInland: placePos])
    {
        return NO;
    }
    
    if(![intct FreeToDrop:placePos])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - Touch functions


- (BOOL) TouchBegin:(UITouch*) touch: (CGPoint) tpos: (Interface*) intr
{
    BOOL retVal = NO;
    
    //start drilling
    if([intr IsDrillBoardTouched: tpos])
    {
        Button *drillBoardIcon = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
        [drillBoardIcon PressBegin: touch];
        [self StartDrilling:tpos];
        retVal = YES;
    }
    
    return retVal;
}

- (void) TouchMove:(UITouch*) touch : (CGPoint) tpos : (Character*) character : (Interface*) intr : (float) dt
{
    //drilling
    if(character.state == CS_FIRE_DRILL && [intr IsDrillBoardPressed: touch])
    {
        //rotate spindle
        spindle.isDrilled = YES;
        [self DrillSpindle: tpos.x : dt : intr];
        
        //drill stick
        Button *drillStick = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILL_STICK_ICON];
        Button *drillBoardIcon = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
        //reposition movemet of drill stick
        float stickMoveDelta = [CommonHelpers ConvertToRelative: tpos.x] - [drillBoardIcon  CenterPointRelative].x ;
        //calculate stick and board boundries
        float stickX = drillStick.rect.relative.origin.x + stickMoveDelta;
        float lowBoundX = drillBoardIcon.rect.relative.origin.x;
        float highBoundX = drillBoardIcon.rect.relative.origin.x + drillBoardIcon.rect.relative.size.width - drillStick.rect.relative.size.width;
        //boundry check and repositioning
        if(stickX >= lowBoundX && stickX <= highBoundX)
        {
            drillStick.rePosition = GLKVector2Make(stickMoveDelta, 0);
        }else
        {
            if(stickX < lowBoundX)
            {
                drillStick.rePosition = GLKVector2Make(lowBoundX - drillStick.rect.relative.origin.x, 0);
            }else
            if(stickX > highBoundX)
            {
                drillStick.rePosition = GLKVector2Make(highBoundX - drillStick.rect.relative.origin.x, 0);
            }
        }
        drillStick.modelviewMat = GLKMatrix4MakeTranslation(drillStick.rePosition.x, 0, 0);
    }
}

- (BOOL) TouchEnd: (UITouch*) touch : (CGPoint) tpos : (Character*) character :  (Interface*) intr : (GLKVector3) spacePoint
{
    BOOL retVal = NO;
    
    if([intr IsDrillBoardPressed: touch])
    {
        Button *drillBoardIcon = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
        Button *drillStick = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILL_STICK_ICON];
        [drillBoardIcon PressEnd];
        
        [drillStick SetMatrixToIdentity];
        
        spindle.isDrilled = NO;
        
        retVal = YES;
    }
    
    return retVal;
}



@end
