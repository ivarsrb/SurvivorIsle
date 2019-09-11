//
//  InterfaceEnums.h
//  The Survivor
//
//  Created by Ivars Rusbergs on 9/25/13.
//  Copyright (c) 2013 Ivars Rusbergs. All rights reserved.
//
// STATUS: OK 

#ifndef The_Survivor_InterfaceEnums_h
#define The_Survivor_InterfaceEnums_h


//----------------------------------------
//types of menu interface objects
//NOTE: for performance group transaperent and opaque objects
//NOTE: must in same order as added to the array later in file
enum _enumMenuObjects
{
    MO_MENU_BACKGROUND,
    MO_PLAY_BUTTON,
    MO_CONTINUE_BUTTON,
    MO_INFO_BUTTON,
    MO_SOUND_BUTTON,
    MO_DIFFICULTY_PANEL, 
    MO_DIFFICULTY_SWITCH_1,
    MO_DIFFICULTY_SWITCH_2,
    MO_HELP_GENERAL_PANEL,
    MO_BACK_BUTTON,
    NUM_MENU_OBJ
};
typedef enum _enumMenuObjects enumMenuObjects;


//----------------------------------------
//types of in-game interface objects
//NOTE: for performance group transaperent and opaque objects
//NOTE: must in same order as added to the array later in file
enum _enumInterfaceObjects
{
    INT_VIEW_SPACE,
    INT_INVENTORY_BOARD,
    INT_MOV_JOYSTICK,
    INT_JOYSTICK_STICK,
    INT_PAUSE_BUTT,
    INT_NUTRITION_IND,
    INT_HYDRATION_IND,
    INT_INJURY_IND,
    INT_NUTRITION_SPLASH_ICON,
    INT_HYDRATION_SPLASH_ICON,
    INT_INJURY_SPLASH_ICON,
    INT_DAY_ICON,
    INT_INVNTORY_FULL,
    INT_HAND_FULL,
    INT_ITEM_HIGHLIGHT,
    INT_ACTION_BUTT,
    INT_CROSSHAIR,
    INT_RAFT_BEGIN_BUTT,
    INT_RAFT_FLOAT_BUTT,
    INT_WIN_ICON,
    INT_START_ICON,
    INT_LOOSE_ICON,
    INT_DRILLBOARD_ICON,
    INT_DRILL_STICK_ICON,
    INT_ITEM_DISALLOWED,
    INT_ITEM_ON_FIRE,
    INT_ITEM_ON_RAFT,
    INT_ITEM_PLACEMARK,
    INT_SHELTER_BEGIN_BUTT,
    INT_ITEM_ON_SHELTER,
    NUM_INT_OBJ
};
typedef enum _enumInterfaceObjects enumInterfaceObjects;

//----------------------------------------
//types of items in inventory
enum _enumInventoryItems
{
    ITEM_KNIFE,
    ITEM_COCONUT,
    ITEM_COCONUT_HALF,
    ITEM_WOOD,
    ITEM_STICK,
    ITEM_SPEAR,
    ITEM_TINDER,
    ITEM_KINDLING,
    ITEM_FISH_RAW,
    ITEM_FISH_2_RAW,
    ITEM_FISH_CLEANED,
    ITEM_FISH_COOKED,
    ITEM_LEAF,
    ITEM_BERRIES,
    ITEM_SHELL,
    ITEM_RAINCATCH,
    ITEM_RAINCATCH_FULL,
    ITEM_ROCK_FLAT,
    ITEM_DEADFALL_TRAP,
    ITEM_RAT_RAW,
    ITEM_RAT_CLEANED,
    ITEM_RAT_COOKED,
    ITEM_SHARP_WOOD,
    ITEM_CRAB_RAW,
    ITEM_CRAB_COOKED,
    ITEM_RAFT_LOG,
    ITEM_RAG,
    ITEM_SAIL,
    ITEM_STONE,
    ITEM_SMALLPALM_LEAF,
    ITEM_HONEYCOMB,
    ITEM_SEA_URCHIN,
    ITEM_SEA_URCHIN_FOOD,
    ITEM_EGG,
    ITEM_EGG_OPENED,
    
    NUM_INV_ITEMS
};
typedef enum _enumInventoryItems enumInventoryItems;
#define kItemEmpty -1 //empty place in inventory


#endif
