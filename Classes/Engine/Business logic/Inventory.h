//
//  Inventory.h
//  Island survival
//
//  Created by Ivars Rusbergs on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Inventory storage and management of character

#import <Foundation/Foundation.h>
#import "MacrosAndStructures.h"
#import "Interface.h"


@class Character;

@interface Inventory : NSObject
{
    //item dictionarry
    SInventoryItem *items; //unique item dictionary
    int slotCount; //number of slots in inventory
    int *itemSlots; //inventory slots, value is item id, -1 is empty, needed for ordering
    int lastAddedSlotId; //index of slot that was added the latest item
    
    //combiner
    SItemCombiner  *itemCombiner;
    int itemCombinerCount;
    
    //item grabbed
    SGrabbedItem grabbedItem;
    UITouch *grabbedTouch;
}
@property (nonatomic, readonly) SInventoryItem *items;
@property (nonatomic, readonly) int *itemSlots;
@property (nonatomic, readonly) int slotCount;
@property (nonatomic) int lastAddedSlotId;
@property (nonatomic, readonly) SItemCombiner *itemCombiner;
@property (nonatomic, readonly) int itemCombinerCount;
@property (nonatomic, readonly) SGrabbedItem grabbedItem;

- (void) ResetData;

- (BOOL) AddItemInstance: (enumInventoryItems) type;
- (void) RemoveItemInstance: (int) slotNUmber;
- (BOOL) PlaceItemInstance: (int) slotNumber : (int) newSlotNUmber;
- (BOOL) PutItemInstance:  (enumInventoryItems) type : (int) slotNumber;
- (BOOL) CombineItemInstances: (SGrabbedItem*) dragItem : (int) placeSlotNumber : (Character*) character : (Interface*) intr;
- (int)  GetFirstFreeSlot;
- (BOOL) InventoryFull;

- (void) InitInventoryData;
- (void) InitItemCombiners;
- (void) InitItems;
- (void) InitItemSlots;

- (void) ClearGrabbedItem;
- (void) InitGrabbItem: (enumInventoryItems) type : (int) prevSlotNumber : (CGPoint) tpos : (CGPoint) holderOrigin : (UITouch*) touch;
- (void) AssignGrabbedItem: (int) gItem;

- (BOOL) TouchBegin: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr;
- (void) TouchMove: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (float) dt;
- (BOOL) TouchEnd: (UITouch*) touch : (CGPoint) tpos : (Interface*) intr : (Character*) character;
- (void) FinalizeItemGrab: (BOOL) silent;

- (void) ResourceCleanUp;
@end
