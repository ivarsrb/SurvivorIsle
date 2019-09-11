//
//  ModelLoader.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "ModelLoader.h"

@implementation ModelLoader

@synthesize mesh,materialCount,patches, materials, bsRadius, AABBmin, AABBmax, crRadius, objectCount,matToTex, objects;

- (id) initWithFile:(NSString*) file
{
    return [self initWithFileScale:file: 1];
}

- (id) initWithFileScale:(NSString*) file: (float) scale
{
    return [self initWithFileScalePatchType:file:scale:GROUP_BY_MATERIAL];
}

- (id) initWithFileScalePatchType:(NSString*) file: (float) scale: (enumModelPatchTypes) ptype
{
    self = [super init];
    if (self != nil)
    {
        geomScaleFactor = scale;
        patchType = ptype;
        [self LoadModel:file];
    }
    return self;
}


- (void) LoadModel:(NSString*) file
{
    mesh = [[GeometryShape alloc] init];
    mesh.vertStructType = VERTEX_TEX_STR;
    
    GLKVector2 *uvarray;
    int uvayrrayCount;
    
    mesh.vertexCount = 0;
    mesh.indexCount = 0;
    uvayrrayCount = 0;
    materialCount = 0; //this holds number of textures needed for model, array holds texture file names
    bsRadius = 0; //3d
    crRadius = 0; //2d
    AABBmin = GLKVector3Make(0, 0, 0);
    AABBmax = GLKVector3Make(0, 0, 0);
    materials = [[NSMutableArray alloc] init]; //unique textures of model
    objectCount = 0; //when grouped by object, holds object count
    //when grouped by object
    if(patchType == GROUP_BY_OBJECT)
    {
        objects = [[NSMutableArray alloc] init];
        matToTex = [[NSMutableArray alloc] init];
    }
    
    //open obj file
    NSArray *fileParts = [file componentsSeparatedByString:@"."];
    NSString *path = [[NSBundle mainBundle] pathForResource:[fileParts objectAtIndex:0] ofType:[fileParts objectAtIndex:1]];
    NSString *objData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    // Iterate through file once to discover how many vertices, normals, and faces there are
    NSArray *lines = [objData componentsSeparatedByString:@"\n"];
    for (NSString * line in lines)
    {
        if ([line hasPrefix:@"v "])
        {
            mesh.vertexCount++;
        }
        else if ([line hasPrefix:@"f "])
        {
            mesh.indexCount += 3; //3 indices per face 
        }
        else if([line hasPrefix:@"vt "]) //fill vertex UV reference array
        {
            uvayrrayCount++;
        }
        else if([line hasPrefix:@"o "]) //fill objects
        {
            if(patchType == GROUP_BY_OBJECT)
            {
                NSString *lineTrunc = [line substringFromIndex:2];
                [objects addObject:lineTrunc];
                
                objectCount++;
            }
        }
        else if([line hasPrefix:@"usemtl _"]) //get unique material array
        {
            NSString *lineTrunc = [line substringFromIndex:8];//throw off "usemtl _" part
            
            if(patchType == GROUP_BY_OBJECT)
            {
                //add all materials if needed grouping by object
                //used to add texture ids in usage code
                [matToTex addObject:lineTrunc];
            }
            
            bool materialExists = false;

            //check if material is already in array
            for (NSString *mat in materials) 
            {  
                if([mat isEqualToString:lineTrunc])
                {
                    materialExists = true;
                    break;
                }
            }  
            
            //if is not, add to array
            if(!materialExists)
            {
                [materials addObject:lineTrunc]; 
                //printf("%s \n", materials[materialCount]);
                materialCount++;
            }
        }
    }
    
    //create arrays to store data
    [mesh CreateVertexIndexArrays];
    
    //patches are interpreted by patchType
    //BY_MATERIAL- patch count will match unique texture count
    //BY_OBJECT-   patch count will match object count 
    if(patchType == GROUP_BY_MATERIAL)
    {
        //NSLog(@"1 : %d", materialCount);
        patches = malloc(materialCount * sizeof(SModelPatch));
    }else
    if(patchType == GROUP_BY_OBJECT)
    {
        //NSLog(@"2 : %d", objectCount);
        patches = malloc(objectCount * sizeof(SModelPatch));
    }

    //NSLog(@"3 : %d", uvayrrayCount);
    uvarray = malloc(uvayrrayCount * sizeof(GLKVector2));
    
    

    //collect vertices
    int vCounter = 0;
    int uvCounter = 0;
    for (NSString * line in lines)
    {
        if([line hasPrefix:@"v "]) //vertices
        {
            NSString *lineTrunc = [line substringFromIndex:2]; //throw off "v " part
            NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; //divide by vertices
            
            mesh.verticesT[vCounter].vertex.x = [[lineVertices objectAtIndex:0] floatValue] * geomScaleFactor;
            mesh.verticesT[vCounter].vertex.y = [[lineVertices objectAtIndex:1] floatValue] * geomScaleFactor;
            mesh.verticesT[vCounter].vertex.z = [[lineVertices objectAtIndex:2] floatValue] * geomScaleFactor;
            //mesh.verticesT[vCounter].color = GLKVector4Make(1,1,1,1);
            //determine bounding sphere radius (works if origin is in 0,0,0)
            bsRadius = fmax(bsRadius, fabs(mesh.verticesT[vCounter].vertex.x));
            bsRadius = fmax(bsRadius, fabs(mesh.verticesT[vCounter].vertex.y));
            bsRadius = fmax(bsRadius, fabs(mesh.verticesT[vCounter].vertex.z));
            //2d circle
            crRadius = fmax(crRadius, fabs(mesh.verticesT[vCounter].vertex.x));
            crRadius = fmax(crRadius, fabs(mesh.verticesT[vCounter].vertex.z));
            //unrotated AABB, if rotation occurs, recalculate in code
            AABBmin.x = fmin(AABBmin.x, mesh.verticesT[vCounter].vertex.x);
            AABBmin.y = fmin(AABBmin.y, mesh.verticesT[vCounter].vertex.y);
            AABBmin.z = fmin(AABBmin.z, mesh.verticesT[vCounter].vertex.z);
            AABBmax.x = fmax(AABBmax.x, mesh.verticesT[vCounter].vertex.x);
            AABBmax.y = fmax(AABBmax.y, mesh.verticesT[vCounter].vertex.y);
            AABBmax.z = fmax(AABBmax.z, mesh.verticesT[vCounter].vertex.z);
            
            vCounter++;
        }
        if([line hasPrefix:@"vt "]) //st coordinates
        {
            NSString *lineTrunc = [line substringFromIndex:3]; //throw off "vt " part
            NSArray *lineUV = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            uvarray[uvCounter].s = [[lineUV objectAtIndex:0] floatValue]; 
            uvarray[uvCounter].t = [[lineUV objectAtIndex:1] floatValue];
            uvCounter++;
        }
    }
    
    
    //fill indexes, texture coordinates
    //NOTE : grouping is interpreted by patch type
    int iCounter = 0;
    bool faceAllowed;
    if(patchType == GROUP_BY_MATERIAL)
    {
        for(int mc = 0; mc < materialCount; mc++) //add data to array by materials
        {
            faceAllowed = false;
            patches[mc].startIndex = iCounter;
            
            for (NSString * line in lines)
            {
                if([line hasPrefix:@"usemtl _"]) //allow only to collect face data from current material
                {
                    NSString *lineTrunc = [line substringFromIndex:8];//throw off "usemtl _" part
                    if([[materials objectAtIndex:mc] isEqualToString:lineTrunc])
                    {
                        faceAllowed = true;               
                    }else
                    {
                        faceAllowed = false;  
                    }
                }
                
                if(faceAllowed && [line hasPrefix:@"f "]) //faces (indices)
                {   
                    NSString *lineTrunc = [line substringFromIndex:2];
                    NSArray *faceIndexGroups = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    
                    // From the WaveFront OBJ specification: (f a/b/c a1/b1/c1 a2/b2/c2)
                    // o The first reference number is the geometric vertex.
                    // o The second reference number is the texture vertex. It follows the first slash.
                    // o The third reference number is the vertex normal. It follows the second slash.
                    NSString *oneGroup;
                    NSArray *groupParts;
                    //all thee indices for a face
                    
                    for(int i = 0; i < 3; i++)
                    {
                        oneGroup = [faceIndexGroups objectAtIndex:i];
                        groupParts = [oneGroup componentsSeparatedByString:@"/"];
                        
                        //set idnices
                        mesh.indices[iCounter] = [[groupParts objectAtIndex:kGroupIndexVertex] intValue] - 1; // indices in file are 1-indexed, not 0 indexed
                        
                        //set UV coordinate to related vertice
                        if([groupParts count] > 1)
                        {
                            int tCrdIndex = [[groupParts objectAtIndex:kGroupIndexTexture] intValue] - 1;
                            mesh.verticesT[mesh.indices[iCounter]].tex.s = uvarray[tCrdIndex].s;
                            mesh.verticesT[mesh.indices[iCounter]].tex.t = uvarray[tCrdIndex].t;
                        }
                        iCounter++;
                    }
                }
            }
            patches[mc].indexCount = iCounter - patches[mc].startIndex;
        }
    }else
    if(patchType == GROUP_BY_OBJECT)
    {
        for(int oc = 0; oc < objectCount; oc++) //add data to array by materials
        {
            faceAllowed = false;
            patches[oc].startIndex = iCounter;
            
            for (NSString * line in lines)
            {
                //add to index object by object
                if([line hasPrefix:@"o "]) //object name
                {
                    NSString *objectName = [line substringFromIndex:2];
                    if([[objects objectAtIndex:oc] isEqualToString:objectName])
                    {
                        faceAllowed = true;
                    }else
                    {
                        faceAllowed = false;
                    }
                }
                
                if(faceAllowed && [line hasPrefix:@"f "]) //faces (indices)
                {
                    
                    NSString *lineTrunc = [line substringFromIndex:2];
                    NSArray *faceIndexGroups = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    
                    // From the WaveFront OBJ specification: (f a/b/c a1/b1/c1 a2/b2/c2)
                    // o The first reference number is the geometric vertex.
                    // o The second reference number is the texture vertex. It follows the first slash.
                    // o The third reference number is the vertex normal. It follows the second slash.
                    NSString *oneGroup;
                    NSArray *groupParts;
                    //all thee indices for a face
                    
                    for(int i = 0; i < 3; i++)
                    {
                        oneGroup = [faceIndexGroups objectAtIndex:i];
                        groupParts = [oneGroup componentsSeparatedByString:@"/"];
                        
                        //set idnices
                        mesh.indices[iCounter] = [[groupParts objectAtIndex:kGroupIndexVertex] intValue] - 1; // indices in file are 1-indexed, not 0 indexed
                        
                        //set UV coordinate to related vertice
                        if([groupParts count] > 1)
                        {
                            int tCrdIndex = [[groupParts objectAtIndex:kGroupIndexTexture] intValue] - 1;
                            mesh.verticesT[mesh.indices[iCounter]].tex.s = uvarray[tCrdIndex].s;
                            mesh.verticesT[mesh.indices[iCounter]].tex.t = uvarray[tCrdIndex].t;
                        }
                        iCounter++;
                    }
                }
            }

            patches[oc].indexCount = iCounter - patches[oc].startIndex;
        }
    }
    
    free(uvarray);
}


//can be used to assign bounds to modelrepresentation instance
//instance - model representation isntance
//AABBscale - possible o scale down AABB, if normal scale put 1.0, assign 0 if AABB is not needed
//(current position added to AABB)
- (void) AssignBounds: (SModelRepresentation*) instance : (float) AABBscale
{
    instance->bsRadius = bsRadius; //3d radious
    instance->crRadius = crRadius; //2d radious, x,z plane
    
    //axis aligned bounding box
    if(AABBscale > 0)
    {
        instance->AABBmin = GLKVector3MultiplyScalar(AABBmin, AABBscale);
        instance->AABBmin = GLKVector3Add(instance->position, instance->AABBmin);
        instance->AABBmax = GLKVector3MultiplyScalar(AABBmax, AABBscale);
        instance->AABBmax = GLKVector3Add(instance->position, instance->AABBmax);
    }
    
    //calculate location rect to its current position
    /*
    float halfsize = crRadius;
    instance->locationRct = CGRectMake(instance->position.x - halfsize,
                                       instance->position.z - halfsize,
                                       halfsize * 2,
                                       halfsize * 2);
    */
}


- (void) ResourceCleanUp
{
    //#OPTI - seriously think, what happens to mesh data, may be we dont need it after loading
    //        (in this case, it should be done in object file after loading in global mesh)
    //may be release those earlier after writing to buffers, more memory will be free
    [mesh ResourceCleanUp];
    free(patches);
}


@end

