//
//  SingleSound.h
//  Island survival
//
//  Created by Ivars Rusbergs on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Sound engine

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>
#import <GLKit/GLKit.h>
#import "Terrain.h"
#import "Character.h"
#import "Environment.h"
#import "Clouds.h"
#import "HandSpear.h"
#import "Interface.h"

@class CampFire;
@class Beehive;
//#import <AVFoundation/AVFoundation.h>

//sound types
//LIMIT 32 sounds
enum _enumSounds
{
    SOUND_CLICK,
    SOUND_OCEAN,
    SOUND_FOOTSTEPS,
    SOUND_WET_FOOTSTEPS,
    SOUND_WET_FOOTSTEPS_SLOW,
    SOUND_RAIN,
    SOUND_THUNDER,
    SOUND_WIND,
    SOUND_SPEAR,
    SOUND_BIRD,
    SOUND_PICK,
    SOUND_PICK_FAIL,
    SOUND_DROP,
    SOUND_DROP_FAIL,
    SOUND_DRILL,
    SOUND_FIRE,
    SOUND_INV_CLICK,
    SOUND_INV_CLICK2,
    SOUND_EATING,
    SOUND_RAT_SQUEAK,
    SOUND_SCREAM,
    SOUND_CONTRUCTION,
    SOUND_SPLASH,
    SOUND_HEARTBEAT,
    SOUND_THROW,
    SOUND_HIT_SOFT,
    SOUND_HIT_WATER,
    SOUND_HIT_WOOD,
    SOUND_BEES,
    SOUND_PAIN,
    SOUND_BLOW,
    NUM_SOUNDS
};
typedef enum _enumSounds enumSounds;


//Sound source structure
struct _SSource
{
    //NSUInteger sourceID; //id of source
    //NSUInteger bufferID; //id of tied buffer
    //--
    ALuint sourceID; //id of source
    ALuint bufferID; //id of tied buffer
    
    char *soundFile; //sound file name
    bool relative; // if false, sound is played 3d
    float referenceDistance; //the distance under which the volume for the source would normally drop by half (before being influenced by rolloff factor or AL_MAX_DISTANCE)
   // float maxDistance; //used with the Inverse Clamped Distance Model to set the distance where there will no longer be any attenuation of the source
    GLKVector3 position;
    SBasicAnimation trigger; //used for random sounds, or are time interval dependent
};
typedef struct _SSource SSource;

//------------

@interface SingleSound : NSObject
{
    ALCcontext* mContext;
    ALCdevice* mDevice;
    
    SSource *sourceList;
    
    GLKVector3 listenerPos;
    
    BOOL muted; //if mute, all sounds are not played
}

@property ( nonatomic) BOOL muted;

+ (SingleSound *) sharedSingleSound;
- (void) InitValues;
- (void) InitOpenAL;
- (void) CleanUpOpenAL;
- (void) SetBuffersSources;
- (UInt32) AudioFileSize:(AudioFileID)fileDescriptor;
- (AudioFileID) OpenAudioFile:(NSString*)filePath;
- (void) PlaySound:(int) soundKey;
- (void) PlaySound:(int) soundKey : (BOOL) looped;
- (void) StopSound:(int) soundKey;
- (void) StopAllSounds;
- (void) StopAllSoundsButOne: (int) soundKey;
- (BOOL) IsPlaying : (int) soundKey;
- (void) SetListenerPos:(GLKVector3) pos;
- (void) SetUpListener;
- (void) SetUpSource:(SSource*) s;
- (void) SetSourcePosition: (int) soundKey : (GLKVector3) pos;
- (void) PlayAbsoluteSound: (int) soundKey : (GLKVector3) sourcePos : (BOOL) looped;
- (void) InitSources;
- (void) UpdateOceanSound:(Terrain*) terr;
- (void) UpdateFootstepSound:(Character*) character :(Terrain*) terr;
- (void) UpdateRainSound: (Environment*) env;
- (void) UpdateThunderSound: (Clouds*) clouds;
- (void) UpdateWindSound:(float) dt;
- (void) UpdateBirdSound:(float) dt : (Environment*) env;
- (void) UpdateSpearSound:(HandSpear*) spear;
- (void) UpdateFireSound:(CampFire*) fire : (Interface*) intr;
- (void) UpdateHeartbeatSound:  (Character*) character;
- (void) UpdateBeeSound: (Beehive*) beehive;
@end

