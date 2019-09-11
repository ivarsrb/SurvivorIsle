//
//  Environment.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: OK

#import "Environment.h"

@implementation Environment
@synthesize time,raining,wind,dayLength,windAngle, dayNumber;

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        
    }
    return self;
}

//data that changes with setting new game
- (void) ResetData
{
    [self NillData];
    
    time = startTime = 60 * 12; //start time
    dayNumber = 1;
    raining = NO;
    //randoize wind direction
    windAngle = GLKMathDegreesToRadians(arc4random_uniform(360));
    wind = GLKVector3Make(0, 0, 10);//wind speed m/s (related movement is relative to this value)
    //NSLog(@"wind angle: %f",windAngle);
    [CommonHelpers RotateY: &wind : windAngle]; //rotate wind in random direction
    //NSLog(@"wind vector: %f %f",wind.x, wind.z);
    
    dayLength = 5; //minutes per day
    //dayLength = 1;
}

//data that should be nilled every time game is entered from menu screen (no mater new or continued)
- (void) NillData
{
    /*
    //difficulty related
    //easy
    if([[SingleDirector sharedSingleDirector] difficulty] == GD_EASY)
    {
        dayLength = 5; //minutes per day
    }
    //hard
    else
    {
        dayLength = 5;//minutes per day
    }
    */
}


- (void) Update: (float) dt
{
    //update time
    //1440 - minutes in daynight
	//dt / 60 - delta  represendet in minutes
	time = time + (1440 / dayLength) * (dt / 60);
	if(time > 1440) //daynight has passed
	{
		time = 0;
        dayNumber++;
	}
}   

@end
