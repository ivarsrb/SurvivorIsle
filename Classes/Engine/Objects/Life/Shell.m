//
//  Shell.m
//  Island survival
//
//  Created by Ivars Rusbergs on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK

#import "Shell.h"

@implementation Shell

@synthesize model, effect, collection, vertexCount, indexCount, firstIndex, count;


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
- (void) ResetData:(Terrain*) terr
{
    for (int i = 0; i < count; i++) 
    {
        SCircle beachCircle = terr.oceanLineCircle;
        beachCircle.radius += 8; //put shell in water
        collection[i].position = [CommonHelpers RandomOnCircleLine:beachCircle];
        collection[i].position.y = [terr GetHeightByPoint:&collection[i].position];
        collection[i].orientation.y = [CommonHelpers RandomInRange: 0 : PI_BY_2 : 10];
        collection[i].visible = true;
        collection[i].boundToGround = 0; //axtra space to ground
        [model  AssignBounds: &collection[i] : 0.0];
        
        [ObjectHelpers NillDropping: &collection[i]]; //#v1.1.
    }
}


- (void) InitGeometry
{
    count = 1;
    collection = malloc(count * sizeof(SModelRepresentation));
    
    float scale = 0.33;
    model = [[ModelLoader alloc] initWithFileScale: @"shell.obj": scale];
    
    vertexCount = model.mesh.vertexCount;
    indexCount = model.mesh.indexCount;
    
    //NSLog(@"%d %d",vertexCount, indexCount);//40 213 //58 336
}

//vCnt,iCnt - global vertex/index counter in global mesh, update it while loading into mesh
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt
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

    //load model textures
    GLuint texID = [[SingleGraph sharedSingleGraph] AddTexture:[model.materials objectAtIndex:0] : YES]; //64x64

    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = texID; 
    self.effect.useConstantColor = GL_TRUE;
}

- (void) Update:(float)dt: (float)curTime: (GLKMatrix4*) modelviewMat: (GLKVector4) daytimeColor : (Interaction*) inter
{
    self.effect.constantColor = daytimeColor;
    
    for (int i = 0; i < count; i++) 
    {
        [ObjectHelpers UpdateDropping: &collection[i] : dt : inter : -1 : -1]; //#v1.1.
        
        if(collection[i].visible)
        {
            collection[i].displaceMat = GLKMatrix4TranslateWithVector3(*modelviewMat, collection[i].position);
            collection[i].displaceMat = GLKMatrix4RotateY(collection[i].displaceMat, collection[i].orientation.y);
        }
    }
}

- (void) Render
{
    //vertex buffer object is determined by global mesh in upper level class
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            [[SingleGraph sharedSingleGraph] SetCullFace:NO];
            [[SingleGraph sharedSingleGraph] SetDepthTest:YES];
            [[SingleGraph sharedSingleGraph] SetDepthMask:YES];
            [[SingleGraph sharedSingleGraph] SetBlend:NO];
            
            self.effect.transform.modelviewMatrix = collection[i].displaceMat;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, model.patches[0].indexCount, GL_UNSIGNED_SHORT, BUFFER_OFFSET(firstIndex * sizeof(GLushort)));
        }
    }    
}

- (void) ResourceCleanUp
{
    self.effect = nil;
    [model ResourceCleanUp];
    free(collection);
}


#pragma mark - Bounds

//calculate square AABB by maximum and minimum for picking
- (void) MakeSquareAABB: (GLKVector3*) AABBmin : (GLKVector3*) AABBmax
{
    *AABBmin = model.AABBmin, *AABBmax = model.AABBmax;
    float reducer = 0.68; //make AABB percent smaller
    //find miniums and maximums to make square
    AABBmin->x = fmin(AABBmin->x, AABBmin->z) * reducer;
    AABBmin->z = AABBmin->x;
    AABBmax->x = fmax(AABBmax->x, AABBmax->z) * reducer;
    AABBmax->z = AABBmax->x;
}

#pragma mark - Picking / Dropping function

//check if object is picked, and add to inventory
- (int) PickObject: (GLKVector3) charPos : (GLKVector3) pickedPos : (Inventory*) inv
{
    float pickDistance = PICK_DISTANCE; //maximal distance of picking object
    bool resultBool;
    int returnVal = 0;
    
    for (int i = 0; i < count; i++) 
    {
        if(collection[i].visible)
        {
            //resultBool = [CommonHelpers IntersectLineSphere: collection[i].position : collection[i].bsRadius : charPos : pickedPos : pickDistance];
            //resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : collection[i].AABBmin : collection[i].AABBmax : pickDistance];
            GLKVector3 AABBmin, AABBmax;
            [self MakeSquareAABB: &AABBmin : &AABBmax];
            //add position
            AABBmin = GLKVector3Add(collection[i].position, AABBmin);
            AABBmax = GLKVector3Add(collection[i].position, AABBmax);
            resultBool = [CommonHelpers IntersectLineAABB: charPos : pickedPos : AABBmin : AABBmax : pickDistance];

            if(resultBool)
            {
                returnVal = 2;
                if([inv AddItemInstance: ITEM_SHELL]) //succesfully added
                {
                    returnVal = 1;
                    collection[i].visible = false;
                }
                break;
            }
        }
    }
    
    return returnVal;
}


//place object at given coordinates
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct
{
    float aboveGround = 0.04; //space above ground so ground doest show through bottom
    placePos.y += aboveGround;
    
    if([self IsPlaceAllowed: placePos: terr: intct])
    {
        for (int i = 0; i < count; i++)
        {
            //find some already picked item, assign coords and make visible
            if(!collection[i].visible)
            {
                collection[i].position = placePos;
                //collection[i].position.y += aboveGround;
                collection[i].visible = true;
                
                [ObjectHelpers StartDropping: &collection[i]]; //#v1.1.
                
                 //orientation maches user
                GLKVector3 pVect = GLKVector3Normalize(GLKVector3Subtract(character.camera.position, placePos));
                collection[i].orientation.y = [CommonHelpers AngleBetweenVectorAndZ:pVect] + M_PI;
                
                [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP];
                break;
            }
        }
    }else
    {
        [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        //put back item to inventory if it may not be put in 3d space
        [character.inventory PutItemInstance: ITEM_SHELL: character.inventory.grabbedItem.previousSlot];
    }
}

//weather object is allwed to be placed in given position
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct
{
    if(![intct FreeToDrop:placePos])
    {
        return NO;
    }
    
    return YES;
}



@end
