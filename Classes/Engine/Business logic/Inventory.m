//
//  Inventory.m
//  Island survival
//
//  Created by Ivars Rusbergs on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// STATUS: - 

#import "Inventory.h"
#import "SingleSound.h"
#import "Character.h"

@implementation Inventory
@synthesize items, itemCombiner, itemCombinerCount, itemSlots, slotCount, grabbedItem, lastAddedSlotId;

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        //constant data
        //all available items dictionary
        items = malloc(NUM_INV_ITEMS * sizeof(SInventoryItem));
        //item slots
        slotCount = 6; 
        itemSlots = malloc(slotCount * sizeof(int));
        lastAddedSlotId = -1; //stores number of slot, that has just been upddated, starting fropm 0. -1 if nothing has ben updated or after animation is ended
        
        //item combiner
        itemCombinerCount = 16;
        itemCombiner = malloc(itemCombinerCount * sizeof(SItemCombiner));
        
        [self InitInventoryData];
    }
    return self;
}

//data that chages from game to game
- (void) ResetData
{
    //null grabbd item
    [self ClearGrabbedItem];
    grabbedTouch = nil;
    [self InitItemSlots];
}


- (void) ResourceCleanUp
{
    free(items);
    free(itemSlots);
    free(itemCombiner);
    grabbedTouch = nil;
}

#pragma mark -  Inventory management

//add to first empty slot
//return true if item was added, false if no free slots were available and item was not add
- (BOOL) AddItemInstance: (enumInventoryItems) type
{
    BOOL retVal = NO;

    for (int i = 0; i < slotCount; i++)
    {
        //first empty slot
        if(itemSlots[i] == kItemEmpty)
        {
            itemSlots[i] = type;
            lastAddedSlotId = i; //stores final added slot index
            retVal = YES;
            break;
        }
    }
    
    return retVal;
}

//remove item from given slot
- (void) RemoveItemInstance: (int) slotNUmber
{
    itemSlots[slotNUmber] = kItemEmpty;
}

//place item instance in given slot (and remove ir from previous slot)
//from slotNumber to newSlotNUmber
//return if sucesfully places
- (BOOL) PlaceItemInstance: (int) slotNumber: (int) newSlotNUmber
{
    BOOL retVal = NO;
    if(itemSlots[newSlotNUmber] == kItemEmpty)
    {
        itemSlots[newSlotNUmber] = itemSlots[slotNumber];
        [self RemoveItemInstance:slotNumber];
        retVal = YES;
    }
    return retVal;
}

//put given item in given slot
- (BOOL) PutItemInstance:  (enumInventoryItems) type: (int) slotNumber
{
    BOOL retVal = NO;
    if(slotNumber >= 0 && itemSlots[slotNumber] == kItemEmpty)
    {
        itemSlots[slotNumber] = type;
        retVal = YES;
    }
    return retVal;
}

//return number of first free slot in inventory
//-1 returns if inventory is full
- (int) GetFirstFreeSlot
{
    int n = -1; // probably held in hand when grabbed
    for (int i = 0; i < slotCount; i++) 
    {
        if(itemSlots[i] == kItemEmpty)
        {
            n = i;
            break;
        }
    }
    return n;
}


//wetaher all inventory slots are taken
- (BOOL) InventoryFull
{
    BOOL retVal = YES;
    for (int i = 0; i < slotCount; i++) 
    {
        if(itemSlots[i] == kItemEmpty)
        {
            retVal = NO;
            break;
        }
    }
    return retVal;
}


//combine item
//return weather combined sucefully
- (BOOL) CombineItemInstances: (SGrabbedItem*) dragItem: (int) placeSlotNumber : (Character*) character : (Interface*) intr
{
    BOOL retVal = NO;
    if(dragItem->type != kItemEmpty && itemSlots[placeSlotNumber] != kItemEmpty /*&& !items[itemSlots[placeSlotNumber]].permanent*/)
    {
        //for all combiners
        for (int i = 0; i < itemCombinerCount; i++) 
        {
            if((itemCombiner[i].item1 == dragItem->type && itemCombiner[i].item2 == itemSlots[placeSlotNumber])
               ||
               (itemCombiner[i].item1 == itemSlots[placeSlotNumber] && itemCombiner[i].item2 == dragItem->type))
            {
                //special case where item is dragged on permannet
                if(items[itemSlots[placeSlotNumber]].permanent && !items[dragItem->type].permanent)
                {
                    itemSlots[dragItem->previousSlot] = itemCombiner[i].result;
                    lastAddedSlotId = dragItem->previousSlot; //stores final combined slot index
                }else
                //special case where permannet is dragged on item 
                if(!items[itemSlots[placeSlotNumber]].permanent && items[dragItem->type].permanent)
                {
                    itemSlots[placeSlotNumber] = itemCombiner[i].result;
                    lastAddedSlotId = placeSlotNumber; //stores final combined slot index
                    if(dragItem->previousSlot >= 0) //when permanent item is picked from slot
                    {
                        itemSlots[dragItem->previousSlot] = dragItem->type;
                    }else //when permanent item is picked from hand
                    {
                        [character PickItemHand: intr : dragItem->type];
                    }
                }
                else //all other cases 
                {
                    itemSlots[placeSlotNumber] = itemCombiner[i].result;
                    lastAddedSlotId = placeSlotNumber; //stores final combined slot index
                }
                
                retVal = YES;
    
                break;
            }
        }
    }
    return retVal;
}

#pragma mark -  Init inventory

- (void) InitInventoryData
{
    [self InitItems];
    [self InitItemCombiners];
}

//initialize all available game inventory items
//ID = index
- (void) InitItems
{
    //knife
    items[ITEM_KNIFE].ID = ITEM_KNIFE;
    items[ITEM_KNIFE].droppable = true;
    items[ITEM_KNIFE].edible = false;
    items[ITEM_KNIFE].permanent = true;
    items[ITEM_KNIFE].cookable = false;
    items[ITEM_KNIFE].holdable = true;
    items[ITEM_KNIFE].onlyHold = false;
    //coconut
    items[ITEM_COCONUT].ID = ITEM_COCONUT;
    items[ITEM_COCONUT].droppable = true;
    items[ITEM_COCONUT].edible = false;
    items[ITEM_COCONUT].permanent = false;
    items[ITEM_COCONUT].cookable = false;
    items[ITEM_COCONUT].holdable = false;
    items[ITEM_COCONUT].onlyHold = false;
    //coconut half
    items[ITEM_COCONUT_HALF].ID = ITEM_COCONUT_HALF;
    items[ITEM_COCONUT_HALF].droppable = false;
    items[ITEM_COCONUT_HALF].edible = true;
    items[ITEM_COCONUT_HALF].permanent = false;
    items[ITEM_COCONUT_HALF].cookable = false;
    items[ITEM_COCONUT_HALF].reNutrition = 0.2;
    items[ITEM_COCONUT_HALF].reHydration = 1.0;
    items[ITEM_COCONUT_HALF].holdable = false;
    items[ITEM_COCONUT_HALF].onlyHold = false;
    //wood
    items[ITEM_WOOD].ID = ITEM_WOOD;
    items[ITEM_WOOD].droppable = true;
    items[ITEM_WOOD].edible = false;
    items[ITEM_WOOD].permanent = false;
    items[ITEM_WOOD].cookable = false;
    items[ITEM_WOOD].holdable = false;
    items[ITEM_WOOD].onlyHold = false;
    //stick
    items[ITEM_STICK].ID = ITEM_STICK;
    items[ITEM_STICK].droppable = true;
    items[ITEM_STICK].edible = false; 
    items[ITEM_STICK].permanent = false;
    items[ITEM_STICK].cookable = false;
    items[ITEM_STICK].holdable = false;
    items[ITEM_STICK].onlyHold = false;
    //spear
    items[ITEM_SPEAR].ID = ITEM_SPEAR;
    items[ITEM_SPEAR].droppable = true;
    items[ITEM_SPEAR].edible = false;
    items[ITEM_SPEAR].permanent = false;
    items[ITEM_SPEAR].cookable = false;
    items[ITEM_SPEAR].holdable = true;
    items[ITEM_SPEAR].onlyHold = false;
    //tinder
    items[ITEM_TINDER].ID = ITEM_TINDER;
    items[ITEM_TINDER].droppable = true;
    items[ITEM_TINDER].edible = false;
    items[ITEM_TINDER].permanent = false;
    items[ITEM_TINDER].cookable = false;
    items[ITEM_TINDER].holdable = false;
    items[ITEM_TINDER].onlyHold = false;
    //kindling
    items[ITEM_KINDLING].ID = ITEM_KINDLING;
    items[ITEM_KINDLING].droppable = true;
    items[ITEM_KINDLING].edible = false;
    items[ITEM_KINDLING].permanent = false;
    items[ITEM_KINDLING].cookable = false;
    items[ITEM_KINDLING].holdable = false;
    items[ITEM_KINDLING].onlyHold = false;
    //fish type 1 raw
    items[ITEM_FISH_RAW].ID = ITEM_FISH_RAW;
    items[ITEM_FISH_RAW].droppable = true;
    items[ITEM_FISH_RAW].edible = false;
    items[ITEM_FISH_RAW].permanent = false;
    items[ITEM_FISH_RAW].cookable = false;
    items[ITEM_FISH_RAW].holdable = false;
    items[ITEM_FISH_RAW].onlyHold = false;
    //fish type 2 raw
    items[ITEM_FISH_2_RAW].ID = ITEM_FISH_2_RAW;
    items[ITEM_FISH_2_RAW].droppable = true;
    items[ITEM_FISH_2_RAW].edible = false;
    items[ITEM_FISH_2_RAW].permanent = false;
    items[ITEM_FISH_2_RAW].cookable = false;
    items[ITEM_FISH_2_RAW].holdable = false;
    items[ITEM_FISH_2_RAW].onlyHold = false;
    //fish cleaned
    items[ITEM_FISH_CLEANED].ID = ITEM_FISH_CLEANED;
    items[ITEM_FISH_CLEANED].droppable = true;
    items[ITEM_FISH_CLEANED].edible = false;
    items[ITEM_FISH_CLEANED].permanent = false;
    items[ITEM_FISH_CLEANED].cookable = true;
    items[ITEM_FISH_CLEANED].holdable = false;
    items[ITEM_FISH_CLEANED].onlyHold = false;
    //fish cooked
    items[ITEM_FISH_COOKED].ID = ITEM_FISH_COOKED;
    items[ITEM_FISH_COOKED].droppable = false;
    items[ITEM_FISH_COOKED].edible = true;
    items[ITEM_FISH_COOKED].permanent = false;
    items[ITEM_FISH_COOKED].cookable = false;
    items[ITEM_FISH_COOKED].reNutrition = 1.0;
    items[ITEM_FISH_COOKED].reHydration = 0;
    items[ITEM_FISH_COOKED].holdable = false;
    items[ITEM_FISH_COOKED].onlyHold = false;
    //leaf
    items[ITEM_LEAF].ID = ITEM_LEAF;
    items[ITEM_LEAF].droppable = true;
    items[ITEM_LEAF].edible = false;
    items[ITEM_LEAF].permanent = false;
    items[ITEM_LEAF].cookable = false;
    items[ITEM_LEAF].holdable = false;
    items[ITEM_LEAF].onlyHold = false;
    //berries
    items[ITEM_BERRIES].ID = ITEM_BERRIES;
    items[ITEM_BERRIES].droppable = false;
    items[ITEM_BERRIES].edible = true;
    items[ITEM_BERRIES].permanent = false;
    items[ITEM_BERRIES].cookable = false;
    items[ITEM_BERRIES].reNutrition = 0.25;
    items[ITEM_BERRIES].reHydration = 0.20;
    items[ITEM_BERRIES].holdable = false;
    items[ITEM_BERRIES].onlyHold = false;
    //shell
    items[ITEM_SHELL].ID = ITEM_SHELL;
    items[ITEM_SHELL].droppable = true;
    items[ITEM_SHELL].edible = false;
    items[ITEM_SHELL].permanent = false;
    items[ITEM_SHELL].cookable = false;
    items[ITEM_SHELL].holdable = false;
    items[ITEM_SHELL].onlyHold = false;
    //rain catch
    items[ITEM_RAINCATCH].ID = ITEM_RAINCATCH;
    items[ITEM_RAINCATCH].droppable = true;
    items[ITEM_RAINCATCH].edible = false;
    items[ITEM_RAINCATCH].permanent = false;
    items[ITEM_RAINCATCH].cookable = false;
    items[ITEM_RAINCATCH].holdable = false;
    items[ITEM_RAINCATCH].onlyHold = false;
    //rain catch full
    items[ITEM_RAINCATCH_FULL].ID = ITEM_RAINCATCH_FULL;
    items[ITEM_RAINCATCH_FULL].droppable = false;
    items[ITEM_RAINCATCH_FULL].edible = true;
    items[ITEM_RAINCATCH_FULL].permanent = false;
    items[ITEM_RAINCATCH_FULL].cookable = false;
    items[ITEM_RAINCATCH_FULL].reNutrition = 0;
    items[ITEM_RAINCATCH_FULL].reHydration = 1.0; //fully recovers hydration
    items[ITEM_RAINCATCH_FULL].holdable = false;
    items[ITEM_RAINCATCH_FULL].onlyHold = false;
    //flat rock
    items[ITEM_ROCK_FLAT].ID = ITEM_ROCK_FLAT;
    items[ITEM_ROCK_FLAT].droppable = true;
    items[ITEM_ROCK_FLAT].edible = false; 
    items[ITEM_ROCK_FLAT].permanent = false;
    items[ITEM_ROCK_FLAT].cookable = false;
    items[ITEM_ROCK_FLAT].holdable = false;
    items[ITEM_ROCK_FLAT].onlyHold = false;
    //deadfall trap
    items[ITEM_DEADFALL_TRAP].ID = ITEM_DEADFALL_TRAP;
    items[ITEM_DEADFALL_TRAP].droppable = true;
    items[ITEM_DEADFALL_TRAP].edible = false; 
    items[ITEM_DEADFALL_TRAP].permanent = false;
    items[ITEM_DEADFALL_TRAP].cookable = false;
    items[ITEM_DEADFALL_TRAP].holdable = false;
    items[ITEM_DEADFALL_TRAP].onlyHold = false;
    //rat raw
    items[ITEM_RAT_RAW].ID = ITEM_RAT_RAW;
    items[ITEM_RAT_RAW].droppable = false;
    items[ITEM_RAT_RAW].edible = false; 
    items[ITEM_RAT_RAW].permanent = false;
    items[ITEM_RAT_RAW].cookable = false;
    items[ITEM_RAT_RAW].holdable = false;
    items[ITEM_RAT_RAW].onlyHold = false;
    //rat cleaned
    items[ITEM_RAT_CLEANED].ID = ITEM_RAT_CLEANED;
    items[ITEM_RAT_CLEANED].droppable = true;
    items[ITEM_RAT_CLEANED].edible = false;
    items[ITEM_RAT_CLEANED].permanent = false;
    items[ITEM_RAT_CLEANED].cookable = true;
    items[ITEM_RAT_CLEANED].holdable = false;
    items[ITEM_RAT_CLEANED].onlyHold = false;
    //rat cooked
    items[ITEM_RAT_COOKED].ID = ITEM_RAT_COOKED;
    items[ITEM_RAT_COOKED].droppable = false;
    items[ITEM_RAT_COOKED].edible = true; 
    items[ITEM_RAT_COOKED].permanent = false;
    items[ITEM_RAT_COOKED].cookable = false;
    items[ITEM_RAT_COOKED].reNutrition = 1.0;
    items[ITEM_RAT_COOKED].reHydration = 0;
    items[ITEM_RAT_COOKED].holdable = false;
    items[ITEM_RAT_COOKED].onlyHold = false;
    //sharp wood
    items[ITEM_SHARP_WOOD].ID = ITEM_SHARP_WOOD;
    items[ITEM_SHARP_WOOD].droppable = true;
    items[ITEM_SHARP_WOOD].edible = false; 
    items[ITEM_SHARP_WOOD].permanent = false;
    items[ITEM_SHARP_WOOD].cookable = false;
    items[ITEM_SHARP_WOOD].holdable = false;
    items[ITEM_SHARP_WOOD].onlyHold = false;
    //crab raw
    items[ITEM_CRAB_RAW].ID = ITEM_CRAB_RAW;
    items[ITEM_CRAB_RAW].droppable = false;
    items[ITEM_CRAB_RAW].edible = false; 
    items[ITEM_CRAB_RAW].permanent = false;
    items[ITEM_CRAB_RAW].cookable = false;
    items[ITEM_CRAB_RAW].holdable = false;
    items[ITEM_CRAB_RAW].onlyHold = false;
    //crab cooked
    items[ITEM_CRAB_COOKED].ID = ITEM_CRAB_COOKED; //prpared crab to eat raw
    items[ITEM_CRAB_COOKED].droppable = false;
    items[ITEM_CRAB_COOKED].edible = true; 
    items[ITEM_CRAB_COOKED].permanent = false;
    items[ITEM_CRAB_COOKED].cookable = false;
    items[ITEM_CRAB_COOKED].reNutrition = 1.0;
    items[ITEM_CRAB_COOKED].reHydration = 0;
    items[ITEM_CRAB_COOKED].holdable = false;
    items[ITEM_CRAB_COOKED].onlyHold = false;
    //rag
    items[ITEM_RAG].ID = ITEM_RAG;
    items[ITEM_RAG].droppable = true;
    items[ITEM_RAG].edible = false; 
    items[ITEM_RAG].permanent = false;
    items[ITEM_RAG].cookable = false;
    items[ITEM_RAG].holdable = false;
    items[ITEM_RAG].onlyHold = false;
    //sail
    items[ITEM_SAIL].ID = ITEM_SAIL;
    items[ITEM_SAIL].droppable = false;
    items[ITEM_SAIL].edible = false; 
    items[ITEM_SAIL].permanent = false;
    items[ITEM_SAIL].cookable = false;
    items[ITEM_SAIL].holdable = false;
    items[ITEM_SAIL].onlyHold = false;
    //log raft (only holdable)
    items[ITEM_RAFT_LOG].ID = ITEM_RAFT_LOG;
    items[ITEM_RAFT_LOG].droppable = true;
    items[ITEM_RAFT_LOG].edible = false; 
    items[ITEM_RAFT_LOG].permanent = false;
    items[ITEM_RAFT_LOG].cookable = false;
    items[ITEM_RAFT_LOG].holdable = true;
    items[ITEM_RAFT_LOG].onlyHold = true; //only place in hand, no inventoy
    //stone
    items[ITEM_STONE].ID = ITEM_STONE;
    items[ITEM_STONE].droppable = true;
    items[ITEM_STONE].edible = false;
    items[ITEM_STONE].permanent = false;
    items[ITEM_STONE].cookable = false;
    items[ITEM_STONE].holdable = true;
    items[ITEM_STONE].onlyHold = false;
    //smallpalm leaf
    items[ITEM_SMALLPALM_LEAF].ID = ITEM_SMALLPALM_LEAF;
    items[ITEM_SMALLPALM_LEAF].droppable = true;
    items[ITEM_SMALLPALM_LEAF].edible = false;
    items[ITEM_SMALLPALM_LEAF].permanent = false;
    items[ITEM_SMALLPALM_LEAF].cookable = false;
    items[ITEM_SMALLPALM_LEAF].holdable = true;
    items[ITEM_SMALLPALM_LEAF].onlyHold = false;
    //honey comb
    items[ITEM_HONEYCOMB].ID = ITEM_HONEYCOMB;
    items[ITEM_HONEYCOMB].droppable = false;
    items[ITEM_HONEYCOMB].edible = true;
    items[ITEM_HONEYCOMB].cookable = false;
    items[ITEM_HONEYCOMB].reNutrition = 1.0;
    items[ITEM_HONEYCOMB].reHydration = 0;
    items[ITEM_HONEYCOMB].permanent = false;
    items[ITEM_HONEYCOMB].cookable = false;
    items[ITEM_HONEYCOMB].holdable = false;
    items[ITEM_HONEYCOMB].onlyHold = false;
    //sea urchin
    items[ITEM_SEA_URCHIN].ID = ITEM_SEA_URCHIN;
    items[ITEM_SEA_URCHIN].droppable = true;
    items[ITEM_SEA_URCHIN].edible = false;
    items[ITEM_SEA_URCHIN].permanent = false;
    items[ITEM_SEA_URCHIN].cookable = false;
    items[ITEM_SEA_URCHIN].holdable = false;
    items[ITEM_SEA_URCHIN].onlyHold = false;
    //sea urchin cut and made edible
    items[ITEM_SEA_URCHIN_FOOD].ID = ITEM_SEA_URCHIN_FOOD;
    items[ITEM_SEA_URCHIN_FOOD].droppable = false;
    items[ITEM_SEA_URCHIN_FOOD].edible = true;
    items[ITEM_SEA_URCHIN_FOOD].permanent = false;
    items[ITEM_SEA_URCHIN_FOOD].cookable = false;
    items[ITEM_SEA_URCHIN_FOOD].reNutrition = 0.5;
    items[ITEM_SEA_URCHIN_FOOD].reHydration = 0.0;
    items[ITEM_SEA_URCHIN_FOOD].holdable = false;
    items[ITEM_SEA_URCHIN_FOOD].onlyHold = false;
    //egg
    items[ITEM_EGG].ID = ITEM_EGG;
    items[ITEM_EGG].droppable = false;
    items[ITEM_EGG].edible = false;
    items[ITEM_EGG].permanent = false;
    items[ITEM_EGG].cookable = false;
    items[ITEM_EGG].holdable = false;
    items[ITEM_EGG].onlyHold = false;
    //opened egg
    items[ITEM_EGG_OPENED].ID = ITEM_EGG_OPENED;
    items[ITEM_EGG_OPENED].droppable = false;
    items[ITEM_EGG_OPENED].edible = true;
    items[ITEM_EGG_OPENED].permanent = false;
    items[ITEM_EGG_OPENED].cookable = false;
    items[ITEM_EGG_OPENED].reNutrition = 0.5;
    items[ITEM_EGG_OPENED].reHydration = 0.0;
    items[ITEM_EGG_OPENED].holdable = false;
    items[ITEM_EGG_OPENED].onlyHold = false;
}

//initialize standard inventory
- (void) InitItemSlots
{
    for (int i = 0; i < slotCount; i++) 
    {
        itemSlots[i] = kItemEmpty;
    }
    
    //already in inventory item
    [self AddItemInstance: ITEM_KNIFE];
    //[self AddItemInstance: ITEM_HONEYCOMB];
   // [self AddItemInstance: ITEM_BERRIES];
   // [self AddItemInstance: ITEM_SMALLPALM_LEAF];
   // [self AddItemInstance: ITEM_KINDLING];
    //[self AddItemInstance: ITEM_SPEAR];
    //[self AddItemInstance: ITEM_RAFT_LOG];
    //[self AddItemInstance: ITEM_KINDLING];
    //[self AddItemInstance: ITEM_RAT_CLEANED];
    //[self AddItemInstance: ITEM_WOOD];
    
}

//initialize item combiner relations
- (void) InitItemCombiners
{
    //order is not important
    int n = 0;
    itemCombiner[n].item1 = ITEM_STICK;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_SPEAR;
    
    n++;
    itemCombiner[n].item1 = ITEM_WOOD;
    itemCombiner[n].item2 = ITEM_TINDER;
    itemCombiner[n].result = ITEM_KINDLING;
    
    n++;
    itemCombiner[n].item1 = ITEM_SHARP_WOOD;
    itemCombiner[n].item2 = ITEM_TINDER;
    itemCombiner[n].result = ITEM_KINDLING;
    
    n++;
    itemCombiner[n].item1 = ITEM_COCONUT;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_COCONUT_HALF;
    
    n++;
    itemCombiner[n].item1 = ITEM_SHELL;
    itemCombiner[n].item2 = ITEM_LEAF;
    itemCombiner[n].result = ITEM_RAINCATCH;
    
    n++;
    itemCombiner[n].item1 = ITEM_SHARP_WOOD;
    itemCombiner[n].item2 = ITEM_ROCK_FLAT;
    itemCombiner[n].result = ITEM_DEADFALL_TRAP;
    
    n++;
    itemCombiner[n].item1 = ITEM_WOOD;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_SHARP_WOOD;
    
    n++;
    itemCombiner[n].item1 = ITEM_STICK;
    itemCombiner[n].item2 = ITEM_RAG;
    itemCombiner[n].result = ITEM_SAIL;
     
    n++;
    itemCombiner[n].item1 = ITEM_SPEAR;
    itemCombiner[n].item2 = ITEM_RAG;
    itemCombiner[n].result = ITEM_SAIL;
    
    n++;
    itemCombiner[n].item1 = ITEM_FISH_RAW;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_FISH_CLEANED;
    
    n++;
    itemCombiner[n].item1 = ITEM_FISH_2_RAW;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_FISH_CLEANED;
    
    n++;
    itemCombiner[n].item1 = ITEM_RAT_RAW;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_RAT_CLEANED;
    
    n++;
    itemCombiner[n].item1 = ITEM_CRAB_RAW;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_CRAB_COOKED;
    
    n++;
    itemCombiner[n].item1 = ITEM_WOOD;
    itemCombiner[n].item2 = ITEM_ROCK_FLAT;
    itemCombiner[n].result = ITEM_DEADFALL_TRAP;
    
    n++;
    itemCombiner[n].item1 = ITEM_SEA_URCHIN;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_SEA_URCHIN_FOOD;
    
    n++;
    itemCombiner[n].item1 = ITEM_EGG;
    itemCombiner[n].item2 = ITEM_KNIFE;
    itemCombiner[n].result = ITEM_EGG_OPENED;
}

//nill grabbed item
- (void) ClearGrabbedItem
{
    grabbedItem.type = kItemEmpty;
}
//set grabb item and touch
//tpos - touch position, holderOrigin - origin of place where iutem lays
- (void) InitGrabbItem: (enumInventoryItems) type : (int) prevSlotNumber : (CGPoint) tpos : (CGPoint) holderOrigin : (UITouch*) touch
{
    //grab item
    grabbedItem.type = type;
    grabbedItem.previousSlot = prevSlotNumber;
    grabbedItem.grabDistance = CGSizeMake(fabs(tpos.x - holderOrigin.x),
                                          fabs(tpos.y - holderOrigin.y));
    grabbedItem.position = CGPointMake(tpos.x - grabbedItem.grabDistance.width, 
                                       tpos.y - grabbedItem.grabDistance.height);
    grabbedTouch = touch;
}

- (void) AssignGrabbedItem:(int)gItem
{
    grabbedItem.type = gItem;
}

#pragma mark -  Touch related functions

- (BOOL) TouchBegin:(UITouch*) touch: (CGPoint) tpos: (Interface*) intr
{
    BOOL retVal = NO;

    //inventory board touched
    if([intr IsInventoryBoardTouched:tpos])
    {
        for (int i = 0; i < slotCount; i++) 
        {
            //NSLog(@"touch %@", grabbedTouch);
            
            //if any of items is touched
            if(itemSlots[i] != kItemEmpty && grabbedTouch == nil && grabbedItem.type == kItemEmpty && CGRectContainsPoint(intr.slotCoordinates[i].points, tpos))
            {
                //grab item
                [self InitGrabbItem: itemSlots[i]: i: tpos: intr.slotCoordinates[i].points.origin: touch];
                
                //remove grabbed item from slot
                [self RemoveItemInstance:i];
                
                break;
            }
        }
        retVal = YES;
    }
    
    return retVal;
}

- (void) TouchMove:(UITouch*) touch: (CGPoint) tpos: (Interface*) intr: (float) dt
{
    //changed dragged item coordinates
    if(grabbedTouch != nil && [touch isEqual:grabbedTouch] && grabbedItem.type != kItemEmpty)
    {
        grabbedItem.position = CGPointMake(tpos.x - grabbedItem.grabDistance.width, 
                                           tpos.y - grabbedItem.grabDistance.height);
    }
}

- (BOOL) TouchEnd: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character
{
    BOOL retVal = NO;
    
    //if item is grabbed
    if(grabbedTouch != nil && [touch isEqual:grabbedTouch] && grabbedItem.type != kItemEmpty)
    {
        if(!items[grabbedItem.type].onlyHold) //do not place in inventory items that can be only holdable
        {
            //when releasing item, check if it was not released over empty slot, if yes - place it therte
            for (int i = 0; i < slotCount; i++) 
            {
                //check against middle of grabbed icon
                CGPoint iconMiddleCoords = CGPointMake(grabbedItem.position.x + intr.slotCoordinates[0].points.size.width/2 ,
                                                       grabbedItem.position.y + intr.slotCoordinates[0].points.size.width/2);
                //if released over some item slot
                if(CGRectContainsPoint(intr.slotCoordinates[i].points, iconMiddleCoords)) //was tpos
                {
                    //place in free slot
                    if(itemSlots[i] == kItemEmpty)
                    {
                        [self PutItemInstance: grabbedItem.type : i];
                        [self ClearGrabbedItem];
                        [[SingleSound sharedSingleSound]  PlaySound: SOUND_INV_CLICK];
                    }else
                    //place slot is not empty, so check if we could combine them
                    if([self CombineItemInstances: &grabbedItem : i : character : intr])
                    {
                        [self ClearGrabbedItem];
                        [[SingleSound sharedSingleSound]  PlaySound: SOUND_INV_CLICK2];
                    }
                    
                    break;
                }
            }
        }
        
        //!!! CONTINUED in Character ToucheEnd brackets (FinalizeItemGrab is there)
        
        retVal = YES;
    }
    
    return retVal;
}

//last step of item grab, used in Character ToucheEnd
//silent - YES, no drop sound will be played
- (void) FinalizeItemGrab: (BOOL) silent
{
    //put back item, if was not placed anywhere
    if(grabbedItem.type != kItemEmpty)
    {
        [self PutItemInstance: grabbedItem.type : grabbedItem.previousSlot];
        [self ClearGrabbedItem];
        if(!silent)
        {
            [[SingleSound sharedSingleSound]  PlaySound: SOUND_DROP_FAIL];
        }
    }
    grabbedTouch = nil;
}

@end
