//
//  SingleSound.m
//  Island survival
//
//  Created by Ivars Rusbergs on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Implies that each source has one buffers and each buffer has one source
// If one sound must played simultainiously from 2 different sources, must rewrite code
//
// STATUS: - 

#import "SingleSound.h"
#import "CampFire.h"
#import "Beehive.h"

@implementation SingleSound
@synthesize muted;

SINGLETON_GCD(SingleSound);

- (id) init 
{
    if ((self = [super init])) 
    {
        sourceList = malloc(NUM_SOUNDS * sizeof(SSource));
        
        [self InitSources];
        [self InitValues];
        
        muted = NO;
    }
    return self;
}

// start up openAL
-(void) InitOpenAL
{
	// Initialization 
	mDevice = alcOpenDevice(NULL); // select the "preferred device"  
	 
    if(mDevice) 
    { 
        // use the device to make a context
		mContext = alcCreateContext(mDevice, NULL); 
		// set my context to the currently active one
		alcMakeContextCurrent(mContext);  //#NOTE: potentiol problem line! (why?) (ios simulator crash maybe)
        
        //sound distance model
        alDistanceModel(AL_INVERSE_DISTANCE);
        
        [self SetUpListener];
        [self SetBuffersSources];
    } 
}

- (void) CleanUpOpenAL
{
    //delete sources and buffers
    for (int i = 0; i < NUM_SOUNDS; i++) 
    {
        //NSUInteger sourceID = sourceList[i].sourceID;
        //NSUInteger bufferID = sourceList[i].bufferID;
        ALuint sourceID = /*(int)*/ sourceList[i].sourceID;
        ALuint bufferID = /*(int)*/ sourceList[i].bufferID;
        alDeleteSources(1, &sourceID);
        alDeleteBuffers(1, &bufferID);
    }
	
	// destroy the context
	alcDestroyContext(mContext);
	// close the device
	alcCloseDevice(mDevice);
    
    free(sourceList);
}


#pragma mark - Sound management

// grab the sound ID from the library
// and start the source playing
- (void) PlaySound: (int) soundKey : (BOOL) looped
{ 
	if(!muted)
    {
        //NSUInteger sourceID = sourceList[soundKey].sourceID;
        ALuint sourceID = sourceList[soundKey].sourceID;
        
        //parameters
        if (looped) {
            alSourcei(sourceID, AL_LOOPING, AL_TRUE);
        }else {
            alSourcei(sourceID, AL_LOOPING, AL_FALSE);
        }
        
        //play
        alSourcePlay(sourceID);
    }
} 

- (void) PlaySound: (int) soundKey
{
    [self PlaySound :soundKey :NO];
}

//stop sound
- (void) StopSound: (int) soundKey
{ 
	ALuint sourceID =  sourceList[soundKey].sourceID;
	alSourceStop(sourceID);	
}

//stop all sounds
- (void) StopAllSounds
{
    for (int i = 0; i < NUM_SOUNDS; i++)
    {
        alSourceStop(sourceList[i].sourceID);
    }
}

//stop all sounds but given one, used when all sounds stop on click, click would also stop in the middle and will not sound good
- (void) StopAllSoundsButOne: (int) soundKey
{
    for (int i = 0; i < NUM_SOUNDS; i++)
    {
        if(soundKey != i)
        {
            alSourceStop(sourceList[i].sourceID);
        }
    }
}



//weather source sound is playing
//OPTI: make my own boolean walue to check if sound is playing
- (BOOL) IsPlaying : (int) soundKey
{
    ALint sourceState;
	ALuint sourceID = sourceList[soundKey].sourceID;
    alGetSourcei(sourceID, AL_SOURCE_STATE, &sourceState);
    return sourceState == AL_PLAYING;
}


#pragma mark - Buffer, source, listener

- (void) SetBuffersSources
{
    //for all sound files
    for (int i = 0; i < NUM_SOUNDS; i++) 
    {
        //OPEN FILE
        // get the full path of the file
        NSString* fileName;
        fileName = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:sourceList[i].soundFile] ofType:@"caf"];
        // first, open the file
        AudioFileID fileID = [self OpenAudioFile:fileName];
        // find out how big the actual audio data is
        UInt32 fileSize = [self AudioFileSize:fileID];
        
        //READ FILE
        // this is where the audio data will live for the moment
        unsigned char *outData = malloc(fileSize);
        // this where we actually get the bytes from the file and put them 
        // into the data buffer
        OSStatus result = noErr;
        result = AudioFileReadBytes(fileID, false, 0, &fileSize, outData);
        AudioFileClose(fileID); //close the file
        if (result != 0)
        {
           // NSLog(@"Cannot load sound effect: %@",fileName);
        }
        //BUFFER
        ALuint bufferID;
        alGenBuffers(1, &bufferID);
        alBufferData(bufferID,AL_FORMAT_MONO16,outData,fileSize,44100); 
        sourceList[i].bufferID = bufferID;
        
        //SOURCE
        ALuint sourceID;
        alGenSources(1, &sourceID); 
        sourceList[i].sourceID = sourceID;
        [self SetUpSource:&sourceList[i]];

        // clean up the buffer
        if (outData)
        {
            free(outData);
            outData = NULL;
        }
    }
}


//set up listener parameters
- (void) SetUpListener
{
    ALfloat listenerOri[]={0.0,0.0,1.0, 0.0,1.0,0.0};
    ALfloat listenerVel[]={0.0,0.0,0.0};
    listenerPos = GLKVector3Make(0.0, 0.0, 0.0);
    
    alListenerfv(AL_ORIENTATION,listenerOri);
    alListenerfv(AL_VELOCITY,listenerVel);
    alListenerfv(AL_POSITION,listenerPos.v);
}

//set listener position in space
- (void) SetListenerPos:(GLKVector3) pos
{
   // ALfloat listenerPos[]={pos.x,pos.y,pos.z};
    listenerPos = pos;
    alListenerfv(AL_POSITION,listenerPos.v);
}

//set up source
- (void) SetUpSource:(SSource*) s
{
    // attach the buffer to the source
    alSourcei(s->sourceID, AL_BUFFER, s->bufferID);
    
    //properties
    alSourcef(s->sourceID, AL_PITCH, 1.0f);
    alSourcef(s->sourceID, AL_GAIN, 1.0f);
    s->position = GLKVector3Make(0.0, 0.0, 0.0);
    alSourcefv(s->sourceID, AL_POSITION, s->position.v);
    ALfloat srcDir[]={0.0,0.0,0.0};
    alSourcefv(s->sourceID, AL_DIRECTION, srcDir);
    ALfloat srcVel[]={0.0,0.0,0.0};
    alSourcefv(s->sourceID, AL_VELOCITY, srcVel);
    
    if(s->relative)
    {
        //2d sound (disable attuneation)
        alSourcei(s->sourceID, AL_SOURCE_RELATIVE, AL_TRUE);
        alSourcef(s->sourceID, AL_ROLLOFF_FACTOR, 0.0);
    }else 
    {
        //3d attunated sound
        alSourcei(s->sourceID, AL_SOURCE_RELATIVE, AL_FALSE);
        alSourcef(s->sourceID, AL_ROLLOFF_FACTOR, 1.0);
        alSourcef(s->sourceID, AL_REFERENCE_DISTANCE, s->referenceDistance);
        alSourcei(s->sourceID, AL_MAX_DISTANCE, FLT_MAX);
    }
}

//set parameters when positioning source
- (void) SetSourcePosition: (int) soundKey: (GLKVector3) pos
{
	ALuint sourceID = sourceList[soundKey].sourceID;
    sourceList[soundKey].position = pos;
    alSourcefv(sourceID, AL_POSITION, sourceList[soundKey].position.v);
}

//play asbolute sound from source to listener
- (void) PlayAbsoluteSound: (int) soundKey : (GLKVector3) sourcePos : (BOOL) looped
{
    //move source along z-axis closer to listener,or further to listener depending on distance from source
    
    //determine distance between listener and object
    float distance;
    distance = GLKVector3Distance(sourcePos, listenerPos);
    
    sourceList[soundKey].position.x = listenerPos.x;//keep identical on x-axis
    sourceList[soundKey].position.y = listenerPos.y;
    sourceList[soundKey].position.z = listenerPos.z - distance; //source close/further to listener
    [self SetSourcePosition: soundKey : sourceList[soundKey].position];
    
    //turn on sound
    if(![self IsPlaying: soundKey])
    {
        [self PlaySound: soundKey : looped];
    }
}


#pragma mark - Helper unctions

// open the audio file
// returns a big audio ID struct
- (AudioFileID) OpenAudioFile:(NSString*)filePath
{
	AudioFileID outAFID;
	// use the NSURl instead of a cfurlref cuz it is easier
	NSURL *afUrl = [NSURL fileURLWithPath:filePath];
	
	// do some platform specific stuff.. 
    // #DECIDE maybe __bridge_retained
	OSStatus result = AudioFileOpenURL((__bridge CFURLRef)afUrl, kAudioFileReadPermission, 0, &outAFID);
    if (result != 0)
    {
      //  NSLog(@"Cannot open sound file: %@",filePath);
    }
        
    
    
	return outAFID;
}

// find the audio portion of the file
// return the size in bytes
- (UInt32) AudioFileSize:(AudioFileID)fileDescriptor
{
	UInt64 outDataSize = 0;
	UInt32 thePropSize = sizeof(UInt64);
	OSStatus result = AudioFileGetProperty(fileDescriptor, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize);
	if(result != 0)
    {
     //   NSLog(@"Cannot find sound file size");
    }
	return (UInt32)outDataSize;
}

#pragma mark - Specifix game object functions

//process ocean sound depneding on position of listener
- (void) UpdateOceanSound: (Terrain*) terr
{
    //move source along z-axis closer to listener,or further to listener depending on distance from island center
    
    //determine distance between listener and center of island
    float distance, sourceOffset; 
    distance = GLKVector3Distance(terr.islandCircle.center, GLKVector3Make(listenerPos.x, 0, listenerPos.z));
    
    //if we are at sea,make loudest
    if(distance > terr.islandCircle.radius)
    {
        distance = terr.islandCircle.radius;
    }
    sourceOffset = terr.islandCircle.radius - distance; 
    
    sourceList[SOUND_OCEAN].position.x = listenerPos.x;//keep identical on x-axis
    sourceList[SOUND_OCEAN].position.y = 0;
    sourceList[SOUND_OCEAN].position.z = listenerPos.z - sourceOffset; //source close/further to listener
    [self SetSourcePosition: SOUND_OCEAN : sourceList[SOUND_OCEAN].position];
    
    //turn on sound
    if(![self IsPlaying: SOUND_OCEAN])
    {
        [self PlaySound: SOUND_OCEAN : YES];
    }
}

//footsteps in ground and water
- (void) UpdateFootstepSound:  (Character*) character : (Terrain*) terr
{
    float distance;
    distance = GLKVector3Distance(terr.islandCircle.center, GLKVector3Make(character.camera.position.x, 0, character.camera.position.z));
    
    if(distance < terr.oceanLineCircle.radius) //dry footsteps
    {
        //stop wet footsteps, if played before
        if([self IsPlaying: SOUND_WET_FOOTSTEPS])
        {
            [self StopSound: SOUND_WET_FOOTSTEPS];
        }
        if([self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW])
        {
            [self StopSound: SOUND_WET_FOOTSTEPS_SLOW];
        }
        
        if([character IsMoving] && ![self IsPlaying: SOUND_FOOTSTEPS])
        {
            [self PlaySound: SOUND_FOOTSTEPS : NO];
        }
        /*
        //play
        if([character IsMoving] && ![self IsPlaying: SOUND_FOOTSTEPS])
        {
            [self PlaySound: SOUND_FOOTSTEPS : YES];
        }else 
        if(![character IsMoving] && [self IsPlaying: SOUND_FOOTSTEPS])
        {
            [self StopSound: SOUND_FOOTSTEPS];
        }
        */
        
    }else  //wet footsteps
    {
        //stop dry footsteps, if played before
        if([self IsPlaying: SOUND_FOOTSTEPS])
        {
            [self StopSound: SOUND_FOOTSTEPS];
        }
        
        if([character IsMoving])
        {
            if([character IsRunning]) //fast footsteps
            {
                if(![self IsPlaying: SOUND_WET_FOOTSTEPS] && ![self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW])
                {
                    [self PlaySound: SOUND_WET_FOOTSTEPS : NO];
                }
            }
            else  //slow footsteps
            {
                if(![self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW] && ![self IsPlaying: SOUND_WET_FOOTSTEPS])
                {
                    [self PlaySound: SOUND_WET_FOOTSTEPS_SLOW : NO];
                }
            }
        }
        
        /*
        //play
        if([character IsMoving])
        {
            if([character IsRunning]) //fast footsteps
            {
                if([self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW])
                {
                    [self StopSound: SOUND_WET_FOOTSTEPS_SLOW];
                }
                //play fast footsteps wet
                if(![self IsPlaying: SOUND_WET_FOOTSTEPS])
                {
                    [self PlaySound: SOUND_WET_FOOTSTEPS : YES];
                }
            }
            else //slow footsteps
            {
                if([self IsPlaying: SOUND_WET_FOOTSTEPS])
                {
                    [self StopSound: SOUND_WET_FOOTSTEPS];
                }
                //play slow footsteps wet
                if(![self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW])
                {
                    [self PlaySound: SOUND_WET_FOOTSTEPS_SLOW : YES];
                }
            }
        }else //stop when chaacter stopp
        {
            if([self IsPlaying: SOUND_WET_FOOTSTEPS])
            {
                [self StopSound: SOUND_WET_FOOTSTEPS];
            }
            if([self IsPlaying: SOUND_WET_FOOTSTEPS_SLOW])
            {
                [self StopSound: SOUND_WET_FOOTSTEPS_SLOW];
            }
        }
        */
        
    }
}

//rain sound
- (void) UpdateRainSound: (Environment*) env
{
    if(env.raining && ![self IsPlaying: SOUND_RAIN])
    {
        [self PlaySound: SOUND_RAIN : YES];
    }else 
    if(!env.raining && [self IsPlaying: SOUND_RAIN])
    {
        [self StopSound: SOUND_RAIN];
    }
    
   // if(![self IsPlaying: SOUND_RAIN])
   //    [self PlaySound: SOUND_RAIN : YES];
}

//thunder sounds
- (void) UpdateThunderSound: (Clouds*) clouds
{
    float distance = 0;

    //start thunder sound
    if(clouds.lightningStrike.enabled && ![self IsPlaying:SOUND_THUNDER])
    {
        //find current lightning producing clouds coordinates
        for (int i = 0; i < clouds.count; i++)
        {
            //check only storm clouds, and the cloud that we need to atach lightning
            if(i == clouds.lightning.type && clouds.collection[i].type == CT_STORM)            
            {
                //distance from center to lightning [producing cloud
                distance = GLKVector3Distance(GLKVector3Make(clouds.collection[i].position.x, 0, clouds.collection[i].position.z), GLKVector3Make(0, 0, 0));
                break;
            }
        }
        
        //don't sound when far away
        if(distance < clouds.radius / 2.3)
        {
            sourceList[SOUND_THUNDER].position.x = listenerPos.x;//keep identical on x-axis
            sourceList[SOUND_THUNDER].position.y = 0;
            sourceList[SOUND_THUNDER].position.z = listenerPos.z - distance; //source close/further to listener
            [self SetSourcePosition:SOUND_THUNDER :sourceList[SOUND_THUNDER].position];
            
            //play
            [self PlaySound:SOUND_THUNDER];
        }
    }
}

//wind sound, played randomly after some timeperiod
- (void) UpdateWindSound:(float) dt
{
    sourceList[SOUND_WIND].trigger.timeInAction += dt;
    
    if(sourceList[SOUND_WIND].trigger.actionTime <= sourceList[SOUND_WIND].trigger.timeInAction)
    {
        //set new time to play
        sourceList[SOUND_WIND].trigger.actionTime = [CommonHelpers RandomInRange:20 :50];
        sourceList[SOUND_WIND].trigger.timeInAction = 0;
        //play
        [self PlaySound:SOUND_WIND];
    }
}

//bird sound, played randomly after some timeperiod
- (void) UpdateBirdSound: (float) dt : (Environment*) env
{
    //dont play sound during night
    float bedTime = 19 * 60;
    float wakeupTime = 5 * 60;
    
    //calculate only during day
    if(env.time < bedTime && env.time > wakeupTime)
    {
        sourceList[SOUND_BIRD].trigger.timeInAction += dt;
    }
    
    if(sourceList[SOUND_BIRD].trigger.actionTime <= sourceList[SOUND_BIRD].trigger.timeInAction)
    {
        //set new time to play
        sourceList[SOUND_BIRD].trigger.actionTime = [CommonHelpers RandomInRange:20 :60];
        sourceList[SOUND_BIRD].trigger.timeInAction = 0;
        //play
        [self PlaySound:SOUND_BIRD];
    }
}


//spear sounds
- (void) UpdateSpearSound: (HandSpear*) spear
{
    if(spear.strikeDown && ![self IsPlaying: SOUND_SPEAR])
    {
        [self PlaySound: SOUND_SPEAR]; //#TODO put sound in spear module
    }
}


//camp fire sound
- (void) UpdateFireSound:(CampFire*) fire: (Interface*) intr
{
    //drill sound
    if(fire.spindle.isDrilled)
    {
        Button *drillBoardIcon = [intr.overlays.interfaceObjs objectAtIndex: INT_DRILLBOARD_ICON];
        
        //we are only intersted in signs
        /*
        if(![self IsPlaying: SOUND_DRILL] &&  //sound is not playing already
            (fire.spindle.direction * fire.spindle.prevDirection) < 0 //stroke direction changed
            && fabs(fire.spindle.direction) > (drillBoardIcon.rect.relative.size.width / 100.0) ) //dont make sound when stroke was very small
        {
            [self PlaySound: SOUND_DRILL];
        }
        */
        if(![self IsPlaying: SOUND_DRILL] &&
           fabs(fire.spindle.direction) > drillBoardIcon.rect.relative.size.width / 25.0)
           //direction = length of swipe in relative space
        {
            [self PlaySound: SOUND_DRILL];
        }
    }
    
    //fire burning sound
    if(fire.state == FS_FIRE)
    {
        float sourceOffset;
        sourceOffset = GLKVector3Distance(fire.campfire.position, GLKVector3Make(listenerPos.x, 0, listenerPos.z));

        //move source along z-axis closer to listener,or further to listener depending on distance from island center
        sourceList[SOUND_FIRE].position.x = listenerPos.x;//keep identical on x-axis
        sourceList[SOUND_FIRE].position.y = 0;
        sourceList[SOUND_FIRE].position.z = listenerPos.z - sourceOffset; //source close/further to listener
        [self SetSourcePosition: SOUND_FIRE : sourceList[SOUND_FIRE].position];
        
        //turn on sound
        if(![self IsPlaying: SOUND_FIRE])
        {
            [self PlaySound: SOUND_FIRE : YES];
        }        
    }else 
    {
        //stop when fire has died out
        if([self IsPlaying: SOUND_FIRE])
        {
            [self StopSound: SOUND_FIRE];
        }
    }
}

//play heartbeat when life indikators are running low when blinking
- (void) UpdateHeartbeatSound:  (Character*) character
{
    if(character.nutrition > 0.0 && character.hydration > 0.0 && character.health > 0.0)
    {
        //start sounding when life indicators go under safe limit
        if((character.nutrition < ENERGY_SAFE_LIMIT || character.hydration < ENERGY_SAFE_LIMIT || character.health < INJURY_SAFE_LIMIT) && character.state != CS_RAFT)
        {
            if(![self IsPlaying: SOUND_HEARTBEAT])
            {
                [self PlaySound: SOUND_HEARTBEAT : YES];
            }
        }else
        {
            [self StopSound: SOUND_HEARTBEAT];
        }
    }else
    {
        [self StopSound: SOUND_HEARTBEAT]; //also stopped in raft float
    }
}


//bee hive sound
- (void) UpdateBeeSound: (Beehive*) beehive
{    
    //fire burning sound
    if(!beehive.hive.marked)
    {
        float sourceOffset;
        sourceOffset = GLKVector3Distance(beehive.beeswarm.position, GLKVector3Make(listenerPos.x, 0, listenerPos.z));
        
        //move source along z-axis closer to listener,or further to listener depending on distance from island center
        sourceList[SOUND_BEES].position.x = listenerPos.x;//keep identical on x-axis
        sourceList[SOUND_BEES].position.y = 0;
        sourceList[SOUND_BEES].position.z = listenerPos.z - sourceOffset; //source close/further to listener
        [self SetSourcePosition: SOUND_BEES : sourceList[SOUND_BEES].position];
        
        //turn on sound
        if(![self IsPlaying: SOUND_BEES])
        {
            [self PlaySound: SOUND_BEES : YES];
        }
    }else
    {
        //stop when fire has died out
        if([self IsPlaying: SOUND_BEES])
        {
            [self StopSound: SOUND_BEES];
        }
    }
}

#pragma mark - Sound source initialization

//set initial values
- (void) InitValues
{
    sourceList[SOUND_WIND].trigger.actionTime = [CommonHelpers RandomInRange: 20 : 60]; //time to next sound play
    sourceList[SOUND_WIND].trigger.timeInAction = 0; //how many have past since last play
    
    sourceList[SOUND_BIRD].trigger.actionTime = [CommonHelpers RandomInRange: 20 : 60]; //time to next sound play
    sourceList[SOUND_BIRD].trigger.timeInAction = 0; //how many have past since last play
}

//init sound and source values
///usr/bin/afconvert -f caff -d LEI16@44100 -c 1 click.mp3 click.caf
/*
Ideas : add wood squeek when sailing raft;
        sneezing from soundjay at random times; cloth sound effect for raft sails (ie. http://www.soundjay.com/cloth-sounds-1.html

 
LICENSES:
 http://www.soundjay.com
 
 Sound Effects
 You are allowed to use the sounds free of charge and royalty free in your projects (such as films, videos, 
 games, presentations, animations, stage plays, radio plays, audio books, apps) be it for commercial or 
 non-commercial purposes.
 If you use the sound effects, please consider giving us a credit but it's not required.
 //----------------------------------------------
 http://www.freesfx.co.uk
 
 You can use our sound effects and music in any commercial, non-commercial project including those 
 that will be broadcast, including:
 
 > Films, television programmes and radio programmes.
 
 > YouTube videos. Because we don't own the copyright for all of the content on our site - be aware that the owners of the copyright may reserve the right to monetize their music on Youtube. You can still use it, but they may place ads on your video.
 
 > Websites, blogs and podcasts.
 
 > Games and apps (including iPhone, Android apps etc).
 
 > Exhibitions, conferences, museums etc.
 
 > In your school or college project.
 
 You MUST credit freesfx.co.uk if you use our sound effects or music in your project. 
 How you do this is up to you but please make sure that you include our website URL in your credit as follows:
 
 http://www.freesfx.co.uk
 
 If your project doesn't have a website or blog associated with it the credit back can be printed on 
 any artwork for your project, added to the final credits for a film, added to your YouTube video description
 etc. If none of the above apply to you - you can always Tweet about us and let everyone know that you used 
 our sounds.
 //----------------------------------------------
 youtube channel Jojikiba
 
 The sound effects (and sound bites and music bites) are royalty free and you can use them in your projects. 
 Please don't ask for permission. If someone is mentioned in the video's info box, you will need to credit 
 them when using the sound. The animations are copyright © Jojikiba
*/

- (void) InitSources
{
    //---------------------------------------------------------------------------------------------------
    //MENU BUTTONS
    /*
      http://www.soundjay.com/button-sounds-5.html
      Button Sound 50\
      STATUS: OK
    */
    sourceList[SOUND_CLICK].soundFile = "click";
    sourceList[SOUND_CLICK].relative = YES; //2d sound (no attenuation)
   
    //---------------------------------------------------------------------------------------------------
    //OCEAN
    /*
      http://www.soundjay.com/nature-sounds-3.html
      
     //-------
      old
      Ocean Waves 1
     //-------
     
     Ocean wave 1
     -2 Db gain
     
     STATUS: OK
    */
    sourceList[SOUND_OCEAN].soundFile = "ocean";
    sourceList[SOUND_OCEAN].relative = NO; //3d sound (with attenuation)
    sourceList[SOUND_OCEAN].referenceDistance = 4.0;
    
    //---------------------------------------------------------------------------------------------------
    //FOOTSTEPS LAND
    /*
      http://www.freesfx.co.uk/sfx/footsteps?p=2
      Footsteps Gravel 01
      Part cut out with 1 step
      mewest version in audiacity project footsteps_1
      STATUS: OK
    */
    sourceList[SOUND_FOOTSTEPS].soundFile = "footsteps"; 
    sourceList[SOUND_FOOTSTEPS].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //WET FOOTSTEPS
    /*
     http://www.freesfx.co.uk/sfx/footsteps?p=3  
     Footsteps In Water 1
     Cut aout part of 1 step
     silence ends and middle between steps
     make faster than original
     gain higher
     STATUS: OK
    */
    sourceList[SOUND_WET_FOOTSTEPS].soundFile = "wet_footsteps";
    sourceList[SOUND_WET_FOOTSTEPS].relative = YES;

    //---------------------------------------------------------------------------------------------------
    //WET FOOTSTEPS SLOW
    /*
     Take wet_footsteps  and add extra silence 
     But speed same as original (in 'Footsteps In Water 1' not in wet_footsteps)
     gain higher
     STATUS: OK
     */
    sourceList[SOUND_WET_FOOTSTEPS_SLOW].soundFile = "wet_footsteps_slow";
    sourceList[SOUND_WET_FOOTSTEPS_SLOW].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //RAIN
    /*
      http://www.soundjay.com/rain-sound-effect.html
      Rain Sound Effect 03
      Cut out first 15 seconds, trimmed ends to make loop
      STATUS: OK
    */
    sourceList[SOUND_RAIN].soundFile = "rain";
    sourceList[SOUND_RAIN].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //THUNDER
    /*
     http://www.freesfx.co.uk/sfx/thunder
     Earthquake, thunder, or Rumble
     Cut out part
     Begginning and end faded in
     Bass boost 12
     Make louder
     STATUS: OK
    */
    sourceList[SOUND_THUNDER].soundFile = "thunder";
    sourceList[SOUND_THUNDER].relative = NO;
    sourceList[SOUND_THUNDER].referenceDistance = 15.0;//5.0;
    
    //---------------------------------------------------------------------------------------------------
    //WIND
    /*
     http://www.youtube.com/watch?v=5n4sy1cSle8
     Channel: Jojikiba
     Cut out part
     Beginning and end faded in
     STATUS: OK
    */
    sourceList[SOUND_WIND].soundFile = "wind";
    sourceList[SOUND_WIND].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //SPEAR
    /*
      http://www.freesfx.co.uk/sfx/swoosh
      Badminton Racket Fast Movement Swoosh 005
      STATUS: OK
    */
    sourceList[SOUND_SPEAR].soundFile = "spear";
    sourceList[SOUND_SPEAR].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //SEAGULL
    /*
     http://www.youtube.com/watch?v=xolWjKkf244
     Channel: Jojikiba
     cut silent ends off
     STATUS: OK
    */
    sourceList[SOUND_BIRD].soundFile = "seagull";
    sourceList[SOUND_BIRD].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //PICK ITEM
    /*
      http://www.soundjay.com/button-sounds-5.html
      Button Sound 46
      Lower gain
      STATUS: OK
    */
    sourceList[SOUND_PICK].soundFile = "pick";
    sourceList[SOUND_PICK].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //INVENTORY FULL
    /*
      http://www.freesfx.co.uk/sfx/button?p=5
      Big Plasic Button/Switch Press
      STATUS: OK
    */
    sourceList[SOUND_PICK_FAIL].soundFile = "pick_fail";
    sourceList[SOUND_PICK_FAIL].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //DROP ITEM
    /*
      http://www.freesfx.co.uk/sfx/throw
      Cushion Throw Down On Sofa
      STATUS: OK
    */
    sourceList[SOUND_DROP].soundFile = "drop";
    sourceList[SOUND_DROP].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //DROP FAIL
    /*
      http://www.soundjay.com/button-sounds-2.html
      Button Sound 15
      STATUS: OK
    */
    sourceList[SOUND_DROP_FAIL].soundFile = "drop_fail";
    sourceList[SOUND_DROP_FAIL].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //DRILLING
    /*
      http://www.freesfx.co.uk/sfx/Sanding
      Sanding Wood By Hand
     
     Small part is cut out from original file
     Silent ends are trimmed off
     Lower gain
     STATUS: OK
    */
    sourceList[SOUND_DRILL].soundFile = "drill";
    sourceList[SOUND_DRILL].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //FIRE
    /*
      http://www.soundjay.com/nature-sounds.html
      Campfire
     
      cut out part
      sound gain increased
      STATUS: OK
    */
    sourceList[SOUND_FIRE].soundFile = "fire";
    sourceList[SOUND_FIRE].relative = NO; //3d sound
    sourceList[SOUND_FIRE].referenceDistance = 1.0;
    
    //---------------------------------------------------------------------------------------------------
    //PLACE ITEM
    /*
     http://www.freesfx.co.uk/sfx/button?p=4
     Multimedia Button Click 015
     STATUS: OK
    */
    sourceList[SOUND_INV_CLICK].soundFile = "inv_click";
    sourceList[SOUND_INV_CLICK].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //COMBINE ITEMS
    /*
     http://www.soundjay.com/button-sounds-2.html
     Button Sound 20
     STATUS: OK
    */
    sourceList[SOUND_INV_CLICK2].soundFile = "inv_click2";
    sourceList[SOUND_INV_CLICK2].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //SWALLOW
    /*
     http://www.freesfx.co.uk/sfx/swallows
     STATUS: OK
    */
    sourceList[SOUND_EATING].soundFile = "eating";
    sourceList[SOUND_EATING].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //RAT SQUEAK
    /*
     http://www.soundjay.com/toy-sounds-1.html
     Squeeze Toy Sound Effect 3
     Cut of end
     Shanged pitch from D to B
     faded out
     gain lowered
     STATUS: OK
    */
    sourceList[SOUND_RAT_SQUEAK].soundFile = "rat_squeak";
    sourceList[SOUND_RAT_SQUEAK].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //DEATH
    /*
     http://www.freesfx.co.uk/soundeffects/choking/
     STATUS: OK
    */
    sourceList[SOUND_SCREAM].soundFile = "scream";
    sourceList[SOUND_SCREAM].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //RAFT CONSTRUCTION
    /*
      http://www.freesfx.co.uk/sfx/hammering
      Hammer hitting nail into wood
      STATUS: OK
    */
    sourceList[SOUND_CONTRUCTION].soundFile = "construction"; 
    sourceList[SOUND_CONTRUCTION].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //STRIKE WATER SPLASH
    /*
      http://www.freesfx.co.uk/sfx/splash?p=3
      Water Movement Fast 002
      added silence in front
      STATUS: OK
    */
    sourceList[SOUND_SPLASH].soundFile = "splash";
    sourceList[SOUND_SPLASH].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //HEARTBEAT
    /*
      http://www.soundjay.com/heartbeat-sound-effect.html
      Heartbeat Sound Effect 02
      Cut out part
      STATUS: OK
    */
    sourceList[SOUND_HEARTBEAT].soundFile = "heartbeat";
    sourceList[SOUND_HEARTBEAT].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //THROW
    /*
     http://www.freesfx.co.uk/soundeffects/impacts-crashes/?p=10   
     punch 26
     Trim ends
     STATUS: OK
    */
    sourceList[SOUND_THROW].soundFile = "throw";
    sourceList[SOUND_THROW].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //HIT SOFT
    /*
     http://www.freesfx.co.uk/soundeffects/impacts-crashes/?p=9
     punch14
     Trim ends
     STATUS: OK
     */
    sourceList[SOUND_HIT_SOFT].soundFile = "hit_soft";
    sourceList[SOUND_HIT_SOFT].relative = NO;
    sourceList[SOUND_HIT_SOFT].referenceDistance = 2.0;
    
    //---------------------------------------------------------------------------------------------------
    //HIT WATER
    /*
     http://www.freesfx.co.uk/sfx/water?p=18
     Plastic Drinks Bottle (With Water Inside) Movement 001
     Trim ends
     STATUS: OK
     */
    sourceList[SOUND_HIT_WATER].soundFile = "hit_water";
    sourceList[SOUND_HIT_WATER].relative = NO;
    sourceList[SOUND_HIT_WATER].referenceDistance = 2.0;
    
    //---------------------------------------------------------------------------------------------------
    //HIT WOOD
    /*
    http://www.freesfx.co.uk/soundeffects/impacts-crashes/?p=2
    Wood Stick Hit Log Hard
    Trim ends
    STATUS: OK
    */
    sourceList[SOUND_HIT_WOOD].soundFile = "hit_wood";
    sourceList[SOUND_HIT_WOOD].relative = NO;
    sourceList[SOUND_HIT_WOOD].referenceDistance = 2.0;
    
    //---------------------------------------------------------------------------------------------------
    //BEES
    /*
    http://www.freesfx.co.uk/sfx/bee
    Bee Hive
    Cut out part
    Boost volume
    STATUS: OK
    */
    sourceList[SOUND_BEES].soundFile = "bee_hive";
    sourceList[SOUND_BEES].relative = NO; //3d sound
    sourceList[SOUND_BEES].referenceDistance = 0.4;
    //---------------------------------------------------------------------------------------------------
    //PAIN
    /*
    http://www.freesfx.co.uk/sfx/scream?p=2
    Horror, Arm Or Leg Break Male Scream 002
    Trim ends
    STATUS: OK
    */
    sourceList[SOUND_PAIN].soundFile = "pain";
    sourceList[SOUND_PAIN].relative = YES;
    
    //---------------------------------------------------------------------------------------------------
    //HANDLEAF WIND BLOWING
    /*
    http://www.freesfx.co.uk/sfx/wind?p=4
    Ghost Town Wind
    Cut out parts
    Fade in and fade out
    Volume minimized
    STATUS: OK
    */
    sourceList[SOUND_BLOW].soundFile = "blow";
    sourceList[SOUND_BLOW].relative = YES;
}


@end
