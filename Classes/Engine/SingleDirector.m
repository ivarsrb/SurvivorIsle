//
//  SingleDirector.m
//  Island survival
//
//  Created by Ivars Rusbergs on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// STATUS: - OK
//
//-----------------------------
// Version 1.1 Changes
// Content:
// - Meteor
// - Dolphin jump splash
// - Lightning ambient illumination
// - Cooking smoke added
// - Items visually fall when dropped out of inventory
// - Cocos no longer fall on timing, but on stones hitting it (except first one)
// - holdable object are picked up automatically in hand
// Technical:
// - new particle types added
// - daytime color structure added
// - added ObjectHelper class
// - no longer separated strike, throw, ... buttons, instead one - action button
// - in PlayScene objects dropping position is calculated with new function
// - interface types introduced
// Bugfix:
// - stuck camera when setting fire low
// - when placing spear on unallowed ground, spearing interface dissapears upon item dropping back in hand
//-----------------------------
// App supported iOS (v 1.0)
// min iOS 5.1.1
// max iOS 7.0+
//-----------------------------
// App target devices and specs
//
// iPhone 3GS  - 480×320, 600mhz, PowerVR SGX535 150mhz, 256 MB RAM, max iOS 6.1.3
// iPhone 4    - 960×640, 800mhz Apple A4, PowerVR SGX535 200mhz, 512 MB RAM, max iOS 7.0
// iPhone 4S   - 960×640, 800mhz A5 2-core, PowerVR SGX543MP2, 512 MB RAM, max iOS 7.0
// iPhone 5/5C - 1136x640, 1,3 Ghz A6 2-core, PowerVR SGX543MP3, 1 GB RAM, max iOS 7.0
// iPhone 5S   - 1136x640, 1,7 Ghz A7 2-core, ?, ?, max iOS 7.0
// iPhone 6    - 1334x750
// iPhone 6plus- 2208x1242

//
// iPod 3gen   - 480×320, 600mhz, PowerVR SGX535, 256 MB RAM, max iOS 5.1.1
// iPod 4gen   - 960×640, 800mhz Apple A4, PowerVR SGX535, 256 MB RAM, max iOS 6.1.3
// iPod 5gen   - 1136x640, 1GHz(or 800mhz) A5 2-core, PowerVR SGX543MP2, 512 MB RAM, max iOS 7.0
//
// iPad        - 1024×768, 1Ghz A4, PowerVR SGX535, 256 MB RAM, max iOS 5.1.1
// iPad 2      - 1024×768, 1Ghz A5 2-core, PowerVR SGX543MP2, 512 MB RAM, max iOS 7.0
// iPad 3gen   - 2048x1536, 1Ghz A5 2-core, PowerVR SGX543MP4, 1 GB RAM,  max iOS 7.0
// iPad 4gen   - 2048x1536, 1.4Ghz A6 2-core, PowerVR SGX554MP4, 1 GB RAM,  max iOS 7.0
// iPad mini   - 1024×768, A5 2-core, PowerVR SGX543MP2, 512 MB RAM, max iOS 7.0
// iPad Air    - 2048x1536,         , PowerVR G6430, 1GB RAM, max iOS 7.0
// iPad Mini 2 - 2048x1536,
// ipad Air  2 - 2048×1536,
//-----------------------------
/*
USEFULL:
iPhone 6 Plus   736x414 points  2208x1242 pixels    3x scale    1920x1080 physical pixels   401 physical ppi    5.5"
iPhone 6        667x375 points  1334x750 pixels     2x scale    1334x750 physical pixels    326 physical ppi    4.7"
iPhone 5        568x320 points  1136x640 pixels     2x scale    1136x640 physical pixels    326 physical ppi    4.0"
iPhone 4        480x320 points  960x640 pixels      2x scale    960x640 physical pixels     326 physical ppi    3.5"
iPhone 3GS      480x320 points  480x320 pixels      1x scale    480x320 physical pixels     163 physical ppi    3.5"
*/
//Screen ratious - 1.333 (iPad), 1.5 (iPhone original), 1.775 (iPhone long) , 1.778 (iPhone 6), 1.777 (iPhone 6plus)
//
// Launch image namings
//
// Default.png (iPhone) (480x320)
// Default@2x.png (iPhone Retina 3.5 inch) (960x640)
// Default-568h@2x.png (iPhone Retina 4 inch) (1136x640)
// Default-667h@3x.png (iPHone 6) (1334x750)
// Default-736h@3x.png (iPHone 6 plus) (2208x1242)
// ?Default-Portrait.png (iPad in portrait orientation)
// ?Default-Portrait@2x.png (iPad Retina in portrait orientation)
// Default-Landscape.png (iPad in landscape orientation) (1024×768)
// Default-Landscape@2x.png (iPad Retina in landscape orientation) 2048×1536


#import "SingleDirector.h"

@implementation SingleDirector

@synthesize gameScene ,difficulty, initialized, deviceType, interfaceType;

SINGLETON_GCD(SingleDirector);

- (id) init 
{
    if ((self = [super init])) 
    {
        gameScene = SC_STARTUP;
        
        //Difficulty difference description
        //
        // * Day length - On EASY day is longer than on HARD
        // * Fire drill speed - On EASY it is easier/faster to start fire than on HARD
        // * Distance from traps (rat,crab) - On EASY live animals notice trap bait at larger distance than HARD
        // * Fish - On HARD fish swims away from character if he runs near it. On EASY fish don't notice character
        // * Inventory board - On EASY combinable item is highlighted whn other is picked, on HARD nothing is highlighted
        
        difficulty = GD_EASY; //easy is default
        initialized = NO; //flag used to check if game scenes has been initialized (just in case method is called twice)
        deviceType = DEVICE_UNKNOWN;
        interfaceType = IT_NONE; //#v.1.1. NON needs to be set because basic interface needs to be set in reset function not enywhere on startup
    }
    
    return self;
}

//get current device type
- (void) GetCurrentDevice:(CGSize) scrSize
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        deviceType = DEVICE_IPHONE_6; //if everything fails use iphone 6 (goes for future devices)
       // NSLog(@"iphone 6");
        
      //  NSLog(@"scrSize.width %f", scrSize.width);
        // if needed iphone  6 = 667.0
        if(fequal(scrSize.width, 568.0))
        {
            deviceType = DEVICE_IPHONE_5;
        //    NSLog(@"iphone 5");
        }else
        if(fequal(scrSize.width, 736.0))
        {
            deviceType = DEVICE_IPHONE_6_PLUS;
           // NSLog(@"iphone 6 pls");
        }else
        if(fequal(screenScale, 2.0) && fequal(scrSize.width, 480.0))
        {
            deviceType = DEVICE_IPHONE_RETINA;
          //  NSLog(@"iPhone retina");
        }else
        if(fequal(screenScale, 1.0))
        {
            deviceType = DEVICE_IPHONE_CLASSIC;
         //   NSLog(@"iPhone classic");
        }
    }
    else
    {
        deviceType = DEVICE_IPAD_RETINA; //if everything fails use ipad retina set  #DECIDE
       // NSLog(@"ipad retina");
        //iPad
        if(fequal(screenScale, 2.0))
        {
            deviceType = DEVICE_IPAD_RETINA;
        //    NSLog(@"ipad retina");
        }else
        if(fequal(screenScale, 1.0))
        {
            deviceType = DEVICE_IPAD_CLASSIC;
        //    NSLog(@"ipad classic");
        }
    }
}


@end
