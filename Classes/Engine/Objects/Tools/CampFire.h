//
//  CampFire.h
//  Island survival
//
//  Created by Ivars Rusbergs on 5/15/13.
//
// Camp fire with all attributes
// only one at a time possible

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleSound.h"
#import "CommonHelpers.h"
#import "ModelLoader.h"
#import "Terrain.h"
#import "Character.h"
#import "Interface.h"
#import "Particles.h"

@interface CampFire : NSObject
{
    SModelRepresentation campfire;
    
    SModelRepresentation *storedItems; //store cooked items that are not picked up after making new fire
    int storedCount;
    
    //models
    ModelLoader *kindlingModel;
    ModelLoader *spindleModel;
    ModelLoader *cookingStandModel;
    ModelLoader *fishPrepModel;
    ModelLoader *ratPrepModel;
 
    //texture
    GLuint *texIDKindling;
    GLuint *texIDSpindle;
    GLuint *texIDCookingstand;
    GLuint *texIDFish;
    GLuint *texIDRat;
    GLuint texBurnedWood;
    
    //effect
    GLKBaseEffect *effect;
    
    //partcles
    //ParticleEffect *firePrt;
   // ParticleEffect *smokePrt;
    //ParticleEffect *cookSmokePrt; //smoke comes form cooked item //#v1.1.
    
    //global index array flags
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndexKindling; //start of global index array for this object
    int firstIndexSpindle;
    int firstIndexCookingstand;
    int firstIndexFish;
    int firstIndexRat;
    
    //states
    enumCampfireStates state; //fire state
    
    //campfire parameters
    SSpindle spindle; //spindle variable
    SLimitedFloat burnTime; //to control how long fire can burn
    SCookingItem cookingItem; //item that is currently cooked
    
    //character burns
    SBasicAnimation burnsInterval; //varable to regulate character burning when stepping in fire
}

//@property (strong, nonatomic) ParticleEffect *firePrt;
//@property (strong, nonatomic) ParticleEffect *smokePrt;
//@property (strong, nonatomic) ParticleEffect *cookSmokePrt;
@property (nonatomic,readonly) SModelRepresentation campfire;
@property (readonly, nonatomic) SModelRepresentation *storedItems;
@property (strong, nonatomic) ModelLoader *kindlingModel;
@property (strong, nonatomic) ModelLoader *spindleModel;
@property (strong, nonatomic) ModelLoader *cookingStandModel;
@property (strong, nonatomic) ModelLoader *fishPrepModel;
@property (strong, nonatomic) ModelLoader *ratPrepModel;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (readonly, nonatomic) int vertexCount;
@property (readonly, nonatomic) int indexCount;
@property (readonly, nonatomic) int storedCount;
@property (nonatomic,readonly) SSpindle spindle;
@property (nonatomic,readonly) enumCampfireStates state;
@property (readonly, nonatomic) SCookingItem cookingItem;

- (void) ResetData;
- (void) InitGeometry;
- (void) FillGlobalMesh: (GeometryShape*) mesh: (int*) vCnt: (int*) iCnt;
- (void) SetupRendering;
- (void) Update: (float)dt : (float) curTime : (GLKMatrix4*) modelviewMat : (GLKVector4) daytimeColor : (Character*) character : (Interface*) intr : (Particles*) particles;
- (void) Render;
- (void) RenderKindling;
- (void) RenderSpindle;
- (void) RenderCookingStand: (GLKMatrix4*) displMat;
- (void) RenderFish: (int) cState: (GLKMatrix4*) displMat;
- (void) RenderRat: (int) cState: (GLKMatrix4*) displMat;

- (void) ResourceCleanUp;

- (void) NullCampfireParameters;

- (void) StartDrilling: (CGPoint) prevPos;
- (void) UpdateSpindle: (float) curTime : (float) dt : (GLKMatrix4*) modelviewMat : (Character*) character : (Interface*) intr : (Particles*) particles;
- (void) DrillSpindle: (float) X: (float) dt: (Interface*) intr;

- (void) StartFire: (Character*) character:(Interface*) intr : (Particles*) particles;
- (void) UpdateFire:(float) curTime: (float) dt: (GLKMatrix4*) modelviewMat: (Character*) character:(Interface*) intr : (Particles*) particles;

- (void) CleanStoredItems;
- (void) AddItemToStore: (int) item: (int) stateOfItem :(GLKVector3) position: (float) orientation;
- (void) DeleteItemFromStore: (int) slotNumber;
- (int)  DetermineItem: (int) item: (int) stateOfItem;

- (void) InitCloseUpAction:(Character*) character;
- (void) LeaveFirePlace: (Character*) character: (Interface*) intr;

- (BOOL) CookingItemAllowed: (GLKVector3) spacePoint3D: (enumInventoryItems) item;
- (BOOL) WoodItemAllowed: (GLKVector3) spacePoint3D: (enumInventoryItems) item;

- (void) AddWood;
- (void) StartCooking: (enumInventoryItems) item;
- (void) HaltCooking;
- (void) UpdateCooking: (float) dt : (Particles*) particles;

- (int)  PickObject: (GLKVector3) charPos:(GLKVector3) pickedPos: (Inventory*) inv : (Particles*) particles;
- (void) PlaceObject: (GLKVector3) placePos: (Terrain*) terr: (Character*) character: (Interaction*)intct: (Interface*) intr : (Particles*) particles;
- (BOOL) IsPlaceAllowed: (GLKVector3) placePos: (Terrain*) terr: (Interaction*) intct;

- (BOOL) TouchBegin:(UITouch*) touch: (CGPoint) tpos: (Interface*) intr;
- (void) TouchMove:(UITouch*) touch: (CGPoint) tpos: (Character*) character: (Interface*) intr: (float) dt;
- (BOOL) TouchEnd:(UITouch*) touch: (CGPoint) tpos:(Character*) character:  (Interface*) intr: (GLKVector3) spacePoint;


@end
