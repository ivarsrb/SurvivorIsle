//
//  MacrosAndStructures.h
//  Island survival
//
//  Created by Ivars Rusbergs on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK 
//
// All common data structures and macros



#ifndef Island_survival_MacrosAndStructures_h
#define Island_survival_MacrosAndStructures_h

#import "InterfaceEnums.h"
#import <GLKit/GLKit.h>

//Macros

//maximum frames per second
//#define PREFERRED_FPS 30

#define DEBUG_ON 1 //#TODO put 0 when released

#define isIpad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//singleton macro
#ifndef SINGLETON_GCD
#define SINGLETON_GCD(classname)                        \
                                                        \
+ (classname *)shared##classname {                      \
                                                        \
static dispatch_once_t pred=0;                          \
__strong static classname * shared##classname = nil;    \
dispatch_once( &pred, ^{                                \
shared##classname = [[self alloc] init]; });            \
return shared##classname;                               \
}                                                           
#endif

//----------------------------------------
//math
//safe float comparison
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)

#define PI_BY_2 6.28318530718

#define G_VAL 9.8

//----------------------------------------

//heightmap size in vertices and scale (1 means one section)
#define HF_SIZE 64
#define HF_SCALE 1.1

//----------------------------------------
//item dropping distance from z-near plane
//#define DROP_DISTANCE 2.5
#define DROP_DISTANCE 2.8
#define PICK_DISTANCE 4.5

//----------------------------------------
//character nutrition and hudration, injury limit when it approeached dangerous levels (starts blnking)
#define ENERGY_SAFE_LIMIT 0.1
#define INJURY_SAFE_LIMIT 0.2
//----------------------------------------
//count of some in game object, put here counts that are likely to be reused somewhere
#define FISH_COUNT 8
#define CRAB_COUNT 1
#define RAT_COUNT 2
#define PRTCL_BEE_COUNT 25 //used in different places

//----------------------------------------
//radius of shipwreck circle from center of island
#define SHIP_DIST (127 * HF_SCALE)


//----------------------------------------
//interface
//default z value of interface elements
#define interZval -0.1

//----------------------------------------
//current device type
enum _enumDeviceTypes
{
    DEVICE_UNKNOWN,
    DEVICE_IPHONE_CLASSIC, //iPhone 3GS, iPod 3gen
    DEVICE_IPHONE_RETINA,  //iPhone 4, 4S, iPod 4gen
    DEVICE_IPHONE_5,       //iPhone 5/5C, 5S, iPod 5gen
    DEVICE_IPHONE_6,       //iphone 6
    DEVICE_IPHONE_6_PLUS,  //iPHone 6 plus (use ipad textures, but some (inventory board, menu) special for long screen)
    DEVICE_IPAD_CLASSIC,   //iPad 1,2, mini
    DEVICE_IPAD_RETINA     //iPad 3,4, Air 1/2, mini 2
};
typedef enum _enumDeviceTypes enumDeviceTypes;

//----------------------------------------
//game difficulty
enum _enumGameDifficulty
{
    GD_EASY,
    GD_HARD
};
typedef enum _enumGameDifficulty enumGameDifficulty;

//----------------------------------------
//game states/scenes
enum _enumGameScenes
{
    SC_STARTUP,
    SC_MAIN_MENU,
    SC_MAIN_MENU_PAUSE,
    SC_PLAY,
    
    NUM_SCENES
};
typedef enum _enumGameScenes enumGameScenes;
//----------------------------------------
//character states
enum _enumCharacterStates
{
    CS_BASIC, //basic state in which char has upright / normal movement
    CS_SHELTER_RESTING, //resting in shelter
    CS_FIRE_DRILL, //character is drilling fire
    CS_RAFT, //character is floating on raft, pre-game winning state
    CS_DEAD, //character cann not move, all action are blocked, items dissapera from hand, allother states are alive
    NUM_CHAR_STATES
};

typedef enum _enumCharacterStates enumCharacterStates;
//----------------------------------------
//interface types (in game interfaces)
enum _enumInterfaceTypes
{
    IT_NONE, //non-set interface
    IT_BASIC, //basic in-game interface
    IT_SPEAR, //fish spearing
    IT_STONE, //stone throwing
    IT_KNIFE, //knife interface
    IT_LEAF,  //leaf blowing interface
    IT_RAFT,  //floating on raft
    IT_FIRE_DRILL,  //starting fire
    IT_RESTING,  //reting
    IT_DEATH,
    NUM_INT_TYPES
};
typedef enum _enumInterfaceTypes enumInterfaceTypes;

//----------------------------------------
//types of injuries character may suffer
enum _enumInjuryTypea
{
    JT_NONE, //no injury
    JT_BEE_STING, //sting from bees
    JT_FIRE_BURN, //burning from fireplace
    JT_URCHIN_STING, //stung by stepping on sea urchin
    NUM_INJ_TYPES
};
typedef enum _enumInjuryTypea enumInjuryTypea;


//----------------------------------------
//color structure
struct _SColor {
    GLubyte r;
    GLubyte g;
    GLubyte b;
    GLubyte a;

};
typedef struct _SColor SColor;
static inline SColor SColorMake(GLubyte r, GLubyte g, GLubyte b, GLubyte a)
{
    SColor temp;
    temp.r = r;temp.g = g;temp.b = b;temp.a = a;
    return temp;
}

//data types
struct _SVertexColor
{
    GLKVector3 vertex;
    SColor color;
};
typedef struct _SVertexColor SVertexColor;

struct _SVertexTex
{
    GLKVector3 vertex;
    GLKVector2 tex;
};
typedef struct _SVertexTex SVertexTex;

struct _SVertexColorTex
{
    GLKVector3 vertex;
    SColor color;
    GLKVector2 tex;
};
typedef struct _SVertexColorTex SVertexColorTex;

struct _SVertexColorTex2
{
    GLKVector3 vertex;
    SColor color;
    GLKVector2 tex;
    GLKVector2 tex2;
};
typedef struct _SVertexColorTex2 SVertexColorTex2;

//----------------------------------------
//structure to hold parameters for index/vertex arrays
struct _SIndVertAttribs
{
    //static
    int vertexCount; //how many vertixes are stored from this class into global array
    int indexCount;
    int firstIndex; //start of global index array for this object
    int firstVertex;
    
    //dynamic
    int vertexDynamicCount; //how many vertixes are stored from this class into global array
    int indexDynamicCount;
    int firstDynamicIndex; //start of global index array for this object
    int firstDynamicVertex;
};
typedef struct _SIndVertAttribs SIndVertAttribs;


//----------------------------------------
// Geometry shape configuration enumerations
//to configure mesh to vertex structure
enum enumVertexStruct
{
    VERTEX_COLOR_STR,
    VERTEX_TEX_STR,
	VERTEX_COLOR_TEX_STR,
    VERTEX_COLOR_TEX_2_STR,
    VERTEX_COLOR_SEPARATE_STR //vertex and color are stored in 2 separate buffers
};

//to configure mesh to vertex/index or just vertex structure
enum enumGeomDataSets
{
    VERTEX_SET,
	VERTEX_INDEX_SET
};

//to configure mesh to dynamic or static draw
enum enumDrawType
{
    STATIC_DRAW,
	DYNAMIC_DRAW,
    COLOR_DYNAMIC_DRAW //only color is dynaimx, other (if used) are static (used only for separate buffers)
};

//----------------------------------------
//shader constants
// Uniform index.
enum enumUniforms
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    //textures
	SAMPLER0_UF,
	SAMPLER1_UF,
    
    //common color (to simulate day night change)
    COMMON_COLOR,
    
    NUM_UNIFORMS
};

// Attribute index.
//order is important fro GLKIT shaders to work!!
enum enumAttributes
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIB_COLOR,
    ATTRIB_TEX0,
    ATTRIB_TEX1,
    NUM_ATTRIBUTES
};

//----------------------------------------
//helper to store current and limit value
struct _SLimitedFloat
{
    float current; //current value
    float max; //maximal value
};
typedef struct _SLimitedFloat SLimitedFloat;
//----------------------------------------
//helper to store current and limit value
struct _SLimitedInt
{
    int current; //current value
    int max; //maximal value
};
typedef struct _SLimitedInt SLimitedInt;


//----------------------------------------
//daytime coloring structure
struct _SDaytimeColors
{
    GLKVector4 dayTime; //color at current moment
    GLKVector4 midday;
    GLKVector4 evening;
    GLKVector4 night;
    GLKVector4 morning;
};
typedef struct _SDaytimeColors SDaytimeColors;

//----------------------------------------
//basic animation data structure
struct _SBasicAnimation
{
    bool enabled; //animation is enabled
    float actionTime; //how long animation will last in seconds
    float timeInAction; //how long action has lasted till current
};
typedef struct _SBasicAnimation SBasicAnimation;

//----------------------------------------
//uset to animate onjects like legs, wings etc
struct _SSceletalAnimation
{
    BOOL started; //current object animation is started
    
    GLKVector3 position; //rotate about this position
    GLKVector3 angle; //rotation angle about X,Y,Z axis (current)
    GLKVector3 velocity; //rotation speed in each direction
    
    GLKVector3 limitUpper; //angle rotation upper limit
    GLKVector3 limitLower; //angle rotation lower limit
    
   // float startTime; //object animation start time from start of animation 
    float etalonShift; //angle shift from sceletal etalon (all sceletal parts are moved according to etalon)
    
    GLKMatrix4 rotMat; //rotations
};
typedef struct _SSceletalAnimation SSceletalAnimation;

//----------------------------------------
//uset to animate onjects like branches leaves
struct _SBranchAnimation
{
    GLKVector3 position; //rotate about this position
    GLKVector3 angle; //initial rotation angle about X,Y,Z axis (current)
    GLKVector3 offsetAngle; //rotation offset (current swinging angle)
};

typedef struct _SBranchAnimation SBranchAnimation;

//----------------------------------------
//used to manipulate tunring of model into direction of movement, so turn appear smother
struct _SSmoothTurnAngle
{
    float previous; //turn angle in previous movement
    float destination; //angle we are trying to tun tu
    float current; //curent model turning angle
};
typedef struct _SSmoothTurnAngle SSmoothTurnAngle;


//----------------------------------------
//Model loading

//model patch type
enum _enumModelPatchTypes
{
    GROUP_BY_MATERIAL, /*indices in patch are sorted by unique textures(materials), so patch count matches
                         count of unique textuire names*/
    GROUP_BY_OBJECT    /*indices in patch are sorted by object. Patch count matches number of objects in model */
};
typedef enum _enumModelPatchTypes enumModelPatchTypes;

#define kGroupIndexVertex 0 //means that first number in faces group is indice
#define kGroupIndexTexture 1 //texture
#define kMaxMaterials 4 //maximal number of textures to a single model
//structure for drawable patch (usually sorted by material)_
struct _SModelPatch 
{
    int startIndex;
    int indexCount;
};
typedef struct _SModelPatch SModelPatch;


//----------------------------------------
//used to describe physical motion and interaction #v.1.1.
struct _SPhysicsDescription
{
    
    float velocity; // resultant velocity, single number representing length of movement vector
    GLKVector3 projectVel; //vector of movement velocity per component (origin vector)
    BOOL inMotion; //flag that helps to tell weather object is in physics motion or still
};

typedef struct _SPhysicsDescription SPhysicsDescription;


//----------------------------------------
//model representation (storage) structures

struct _SModelRepresentation
{
    GLKVector3 position;
    float scale; //original modeel dsize is multiplied by this
    GLKVector3 orientation; //radians of rotation from roiginal orientation
    bool visible; //visibility flag
    GLKMatrix4 displaceMat; //modelview matrix for placing/animating movable objects
    bool enabled; //enabled (used for different puropses)
    bool marked; //some extra boolean flag for different puropses
    GLKVector4 color; //color of model (used in constant color)
    int type; //some type of object if needed
    int num; //some number for whatever use
    int state; //state - use at will
    float size; //freely interpretable size parameter
    float speed; //interpet as eny speed needed for object
    //colision detection
    float bsRadius; //bounding sphere radius, used for colision detection
    float crRadius; //bounding circle radius for 2d
    GLKVector3 AABBmin; //minimums vertice for axis-aligned bounding box
    GLKVector3 AABBmax; //maximum vertice
    GLKVector3 endPoint1; //extremne points for model, used in long, thin objects to panipulate collis. detection and positioning
    GLKVector3 endPoint2;
    float boundToGround; //extra space from orgin of model to ground
    //physics
    SPhysicsDescription physics; //for motion/collision physics
    
    //loaction detection
    //CGRect locationRct; //2D place that current object occupies on land, used for placed objects not to overlap and to get dimension
    bool located; //if current object is being currently located, must be set to false, used when intially setting it
    //waiting parmeters
    float time; //vaiable that could be used for any type of time management
    //--dynamic movement
    bool moving; //weather object is currently moving normaly
    bool runaway; //moving in runnaway mode (usually from character)
    bool bouncedInObstacle; //character has hit obstacle
    GLKVector3 movementVector; //movement direction and speed (only from dynamic objects)
    //GLKVector3 movementAng;  //to store movement angles //TODO if needed put this in physics not here
    float movementAngle; //current movement angle
    float moveTime; //how long current direction will be moved
    float timeInMove; //current time in current direction
    GLKVector3 moveStartPoint; //if movement is made from one point to another with lerp than use these two parameters
    GLKVector3 moveEndPoint;
    //sceletal animation parts
    SSceletalAnimation legEtalon; //all other legs ar moved according to this
    int legCount; //how many legs model has
    SSceletalAnimation legs[8]; //no more tha 8 legs
    SBasicAnimation legAnimation; //structure for leg animation management
    SSceletalAnimation taleAnimation; //animation for tale
    //smooth turning (manipulates orientation angle so turning looks smoother)
    SSmoothTurnAngle smoothTurnAngle;
    //add more if needed (i.e. wings etc)
};
typedef struct _SModelRepresentation SModelRepresentation;
//the default initial object position, before it is assigned real position
//#define DEFAULT_OBJ_POS GLKVector3Make(-1.0,1.0,-1.0)


//----------------------------------------
//inventory item
struct _SInventoryItem
{
    int ID; //what type of item
    //parameters
    bool permanent; //weather item does not dissapear when combined with others
    bool droppable; //weather item can be applied (dropped) to 3d world
    bool cookable; //weather can cook item on fire
    bool edible; //weather char can eat or drink this item
    bool holdable; //weather item can be placed in hand
    bool onlyHold; //item can be picked up only in hand, but not placed in ionventory
    //edibility
    float reNutrition; //in case item is edible, determine how much nutrition level will it restore  
    float reHydration; //restore hydration level
};
typedef struct _SInventoryItem SInventoryItem;

//grabbed item structure
struct _SGrabbedItem
{
    int type;
    int previousSlot; //from which slot current item is grabbed
    CGPoint position; //current position of grabbed item
    CGSize grabDistance; //distance delta from grab point to top left corcer of item icon
};
typedef struct _SGrabbedItem SGrabbedItem;

//cooridnates of object both in relative and screen point space
struct _SScreenCoordinates
{
    CGRect relative; //relative
    CGRect points; //in screen rect (IN POINTS!)
};
typedef struct _SScreenCoordinates SScreenCoordinates;

//item combination lookup table structure
struct _SItemCombiner
{
    enumInventoryItems item1; 
    enumInventoryItems item2;
    enumInventoryItems result;
};
typedef struct _SItemCombiner SItemCombiner;

//----------------------------------------
//particle engine types
enum _enumParticleTypes
{
    PT_FIRE,
    PT_SMOKE,
    PT_SPLASH_OCEAN,
    PT_SPLASH_GROUND,
    PT_DUST_GROUND,
    PT_EXPLOSION,
    PT_SINGLE_GLOW,
    PT_INSECT_SWARM
};
typedef enum _enumParticleTypes enumParticleTypes;

//----------------------------------------
//particle structure for particle effect
struct _SParticles
{
    bool active; //if  particle is ready to draw
    bool alive; //if particle life has ended, used in types like splashes, tahtare self-ending
    GLKVector3 position; //position of particle
    GLKVector4 color; //color of particle
    GLKVector3 velocity; //movement speed in each direction
    SLimitedFloat lifetime; //particle lifetime
    GLKMatrix4 displaceMat; //modelview matrix for placing/animating movable objects
};
typedef struct _SParticles SParticles;

//----------------------------------------
//particle effect structure to discribe particle effect behaviour
struct _SParticleEffect
{
    enumParticleTypes type;
    int maxCount; //this is maximal count of particles in effect (at any given momnet adjusted by 'currentCount')
    int currentCount; //adjustable number of particles currently in effect,  always currentCount <= maxCount
    //attributes
    GLKVector3 initialPos; //effect inital location
    GLKVector3 direction; //particle direction movement, interpreted at need, default (0,0,0), set with start function
    float triggerRadius; //radius of particle mesh start area (ie. horizontal size of fireplace)
    CGSize prtSize; //particle size
    float prtclSpeedMax;//how long at max particle will move
    float prtclSpeedInitial; //store initial value of prtclSpeedMax
    float prtclLifeMax; //how long at max particle will live
    GLKVector4 color; //initial color of particle
};
typedef struct _SParticleEffect SParticleEffect;

//----------------------------------------
//campire structs
//states of camp fire
enum _enumCampfireStates
{
    FS_NONE, //no fire is set
    FS_DRILL,//state in which fire ir drilled
    FS_FIRE, //fire started 
    FS_DRY  //kindling without fire in ground
};
typedef enum _enumCampfireStates enumCampfireStates;

//----------------------------------------
//states of cooked item
enum _enumCookingItemStates
{
    CI_EMPTY,  //nothing is beaing cooked
    CI_COOKING,//item is cooking at the moment
    CI_DONE    //item is cooked and reaty to be eaten
};
typedef enum _enumCookingItemStates enumCookingItemStates;

//----------------------------------------
//structure about item that is being cooked
struct _SCookingItem
{
    enumCookingItemStates state; //state of cooking item
    int objectID; //object that is being currently cooked
    SLimitedFloat time; //time object is cooking
};
typedef struct _SCookingItem SCookingItem;

//----------------------------------------
//drill spindle structure
struct _SSpindle
{
    BOOL isDrilled; //weather currently spindle is being drilled
    float direction; // spindle direction , determined by sign (negative, positive)
    float prevDirection; //direction in previous stroke, to be able to compare
    CGPoint prevTouch; //location of previous touch on drill board (in relative)
    
    float temperature; //current spindle temperature
    float rotation; //current spindle rotation radians
    GLKMatrix4 rotMat; //rotation matrix
    
    //constants
    float smokeTemperature; //relative temperature from 0.0 to 1.0 when starts smoking
    float fireTemperature; //relative temperature when fire starts
};
typedef struct _SSpindle SSpindle;

//----------------------------------------
//stucture for rendering dynamic object patch
struct _SObjectPatch 
{
    int startIndex;
    int indexCount;
    GLKVector3 position; //current position of patch
    GLKVector3 velocity; //speed of patch movement
    GLKMatrix4 translationMat; //matrix for patch location
};
typedef struct _SObjectPatch SObjectPatch;

//----------------------------------------
//cloud types
enum _enumCloudTypes
{
    CT_BASIC,  //basic white cloud
    CT_STORM   //storm cloud
};
typedef enum _enumCloudTypes enumCloudTypes;

//----------------------------------------
//palm tree types
enum _enumPalmTypes
{
    TT_STRAIGHT,
    TT_BENDED
};
typedef enum _enumPalmTypes enumPalmTypes;

//----------------------------------------
//texture atlass coordinates
struct _STextureAtlas
{
    //bounds
    GLKVector2 lowerBound;
    GLKVector2 upperBound;
    
    //actual texture coordinates for quad
    GLKVector2 tex0;
    GLKVector2 tex1;
    GLKVector2 tex2;
    GLKVector2 tex3;
};
typedef struct _STextureAtlas STextureAtlas;

//-----------------------------------------
//data structures
struct _SCircle
{
    //bounds
    GLKVector3 center;
    float radius;
};
typedef struct _SCircle SCircle;

//-----------------------------------------
//BUTTON STRUCTURES
enum _enumButtonType
{
    BT_AREA, //area on screen without any textures
    BT_ICON, //texture on screen, could be touchable or not
    BT_BUTTON, //button that turn to selected image when pressed, and jumps to non-selected when released
    BT_BUTTON_CUSTOM, //differs from button in that does not change image/selection anything automatically when clicked
    BT_BUTTON_AUTO  //button that turns to slected image when pressed  and automatically turns back to basic image, TouchEnd isn't used
};
typedef enum _enumButtonType enumButtonType;

//movement types
enum _enumButtonMoveAction
{
    BS_TOP_DOWN_TO_VISIBLE, //from top to down, from hide to visible
    BS_LEFT_RIGHT_TO_VISIBLE, //from left to right, from hide to visible
    BS_LEFT_RIGHT_TO_HIDE, //from left to right, from visible to hide
    BS_RIGHT_LEFT_TO_VISIBLE, //from right to left
    BS_RIGHT_LEFT_TO_HIDE, //from right to left
};
typedef enum _enumButtonMoveAction enumButtonMoveAction;

//butons movement properties
struct _SButtonMovement
{
    enumButtonMoveAction type;
    bool started; //movement moded is started
    float actionTime; //movement timing
    float timeInAction;
    GLKMatrix4 translation; //used as modelview matrix
    GLKVector2 initPos; //initial pos of translation matrix
    GLKVector2 destPos; //destination position of matrix (this if offset from identity, so usually one of them will be at (0,0))
};
typedef struct _SButtonMovement SButtonMovement;


//flicker
enum _enumButtonFlickerType
{
    BF_SINGLE_BLINK,
    BF_DOUBLE_BLINK,
    BF_CONTINUOUS_BLINK
};
typedef enum _enumButtonFlickerType enumButtonFlickerType;

//butons flickering properties
struct _SButtonFlicker
{
    enumButtonFlickerType type;
    bool started; //flickering moded is started
    bool direction; //sets visibility action. if is set true, means that flicker starts with making button visible, and hides after flicker
    int flickerCount; //hoe many flicker have passed since start, used for multiple flicker types
    float actionTime; //flicker timing
    float timeInAction;
};
typedef struct _SButtonFlicker SButtonFlicker;

//scaling
struct _SButtonScaling
{
    bool started; //scaling moded is started
    float actionTime; //scaling timing
    float timeInAction;
    GLKMatrix4 scalingMat; //used as modelview matrix to scale
    float maxScale;//maximum scale of scaling
};
typedef struct _SButtonScaling SButtonScaling;


//-----------------------------------------
//Raft states
enum _enumRaftStates
{
    RS_NONE, //not started building
    RS_PUT_LOG, //started building, adding logs
    RS_PUT_SAIL, //base is set, sail can be added
    RS_DONE, //raft is built
};
typedef enum _enumRaftStates enumRaftStates;

//-----------------------------------------
//fish types
enum _enumFishTypes
{
    FT_1,
    FT_2,
    NUM_FISH_TYPES
};
typedef enum _enumFishTypes enumFishTypes;

//-----------------------------------------
//interactive wildlife types
enum _enumWildlifeTypes
{
    WT_CRAB,
    WT_RAT,
    NUM_WILDLIFE_TYPES
};
typedef enum _enumWildlifeTypes enumWildlifeTypes;

//-----------------------------------------
//dolphin move types
enum _enumDolphinMoveTypes
{
    DM_NONE,
    DM_FIN_SLIDE,
    DM_JUMP,
    NUM_DOLPHIN_MOVE_TYPES
};
typedef enum _enumDolphinMoveTypes enumDolphinMoveTypes;


//----------------------------------------
//meteor movement ype
enum _enumMeteorType
{
    MT_LEFT,
    MT_RIGHT
};
typedef enum _enumMeteorType enumMeteorType;


#endif
