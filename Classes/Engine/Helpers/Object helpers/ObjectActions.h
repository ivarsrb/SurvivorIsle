//
//  ObjectActions.h
//  Island survival
//
//  Created by Ivars Rusbergs on 4/30/13.
//
// Module helps to reuse actions for live objects - movement, animations

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleSound.h"
#import "SingleDirector.h"
#import "CommonHelpers.h"
#import "Terrain.h"
#import "Character.h"
#import "CommonHelpers.h"


@interface ObjectActions : NSObject
{
    enumWildlifeTypes type; //some functionallity is waried depending on type object is used with
    
    //movement parameters
    float normalSpeed; //speed of normal object movement
    float runawaySpeed;  //fast runaway movement
    int moveMaxTimeNormal; //maximum length for normal move (seconds)
    int moveMaxTimeRunaway; //maximum length for fast move (seconds)
    float minObjCharDistance; //minimal distance to object after witch object start running away (0 means dont check)
    float minObjTrapDistance; //minimal distance from obj to trap, when objcet sees trap and moves to it
}
@property (nonatomic) enumWildlifeTypes type;
@property (nonatomic) float normalSpeed;
@property (nonatomic) float runawaySpeed;
@property (nonatomic) int moveMaxTimeNormal;
@property (nonatomic) int moveMaxTimeRunaway;
@property (nonatomic) float minObjCharDistance;
@property (nonatomic) float minObjTrapDistance;

- (void) ResourceCleanUp;

- (void) UpdateMovement: (SModelRepresentation*) obj: (float) dt: (Terrain*) terr:
                         (Character*) character:(BOOL) trapNoticed: (GLKVector3) trapPoint;
- (void) CollisionProcession: (SModelRepresentation*) obj: (float) dt: (BOOL) obstacleHit;
- (void) ObjectCatchProcession: (SModelRepresentation*) obj: (BOOL) objectInTrap;

- (void) StartMovement:(SModelRepresentation*) obj: (GLKVector3) startPosition;
- (void) StopMovement: (SModelRepresentation*) obj;

- (void) SetMove:(SModelRepresentation *)obj :(float)speed :(int)upperTime;
- (void) SetMoveRandom: (SModelRepresentation*) obj: (float) speed : (int) upperTime;
- (void) SetMoveDirection: (SModelRepresentation*) obj: (float) speed: (int) upperTime: (GLKVector3) direction;
- (void) SetMoveDirectionRandom: (SModelRepresentation*) obj: (float) speed: (int) upperTime: (GLKVector3) direction;
- (void) SetMoveToPoint: (SModelRepresentation*) obj: (GLKVector3) destPoint;

- (void) HaltToRunaway: (SModelRepresentation*) obj;
- (void) HaltToBounce: (SModelRepresentation*) obj: (float) dt;
- (void) ObjectCatch: (SModelRepresentation*) obj;
- (void) StartRunaway: (SModelRepresentation*) obj : (GLKVector3) threatPosition;
@end
