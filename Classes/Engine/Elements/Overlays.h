//
//  Overlays.h
//  Island survival
//
//  Created by Ivars Rusbergs on 9/6/13.
//
// In-game interface objects drawing attached to Interface module

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "MacrosAndStructures.h"
#import "SingleGraph.h"
#import "GeometryShape.h"
#import "Button.h"
#import "Environment.h"

@class Character;

@interface Overlays : NSObject
{
    //universal geometry
    GeometryShape *overlayMesh;
    
    //arrays of interface objects
    NSMutableArray *interfaceObjs;
    NSMutableArray *inventoryItems;
    NSMutableArray *dayNumbers;

    //parameters
    SScreenCoordinates itemSize;
    
    //animation effect
    SBasicAnimation *itemSlotAnimation;
}

@property (strong, nonatomic) GeometryShape *overlayMesh;
@property (strong, nonatomic, readonly) NSMutableArray *interfaceObjs;
@property (strong, nonatomic, readonly) NSMutableArray *inventoryItems;
@property (strong, nonatomic, readonly) NSMutableArray *dayNumbers;
@property (nonatomic, readonly) SScreenCoordinates itemSize;
@property (nonatomic, readonly) SBasicAnimation *itemSlotAnimation;

- (id) initWithParams: (Character*) chr;
- (void) ResetData: (Character*) chr;
- (void) NillData: (Character*) chr;
- (void) InitGeometry;
- (void) SetupRendering;
- (void) Update: (Character*) character: (float) dt;
- (void) Render: (Character*) character: (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates: (Environment*) env;
- (void) ResourceCleanUp;

- (void) InitInterfaceArray: (Character*) chr;
- (void) InitInventoryArray;
- (void) DrawInventory: (Character*) character: (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates;
- (void) DrawItemHighlighter: (Character*) character : (SScreenCoordinates *) slotCoordinates : (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates;
- (void) DrawPlaceMark: (Character*) character: (SScreenCoordinates) handCoordinates : (SScreenCoordinates) mouthCoordinates;
- (void) DrawDisallowedIcon: (Character*) character : (SScreenCoordinates *) slotCoordinates;
- (void) DrawPutOnFireIcon: (Character*) character;
- (void) DrawPutOnRaftIcon: (Character*) character;
- (void) DrawPutOnShelterIcon: (Character*) character;

- (void) InitDayNumbersArray;
- (void) DrawDayNumbers: (Environment*) env;

- (int) GetNumberOfTotalVertices;
- (void) HideAllOverlays;
- (void) SetInterfaceVisibility: (enumInterfaceObjects) objId : (BOOL) visible;
- (BOOL) IsVisible: (enumInterfaceObjects) objId;

- (void) NillInventoryAnimation: (Character*) character;
- (void) StartSlotAnimation: (int) slodId;
- (void) InitiateSlotAnimation: (Character*) character: (int) slodId;
- (void) EndSlotAnimation: (int) slodId;
- (void) UpdateSlotAnimation: (Character*) character: (float) dt;
- (float) CalculateSloAnimOffset: (int) slodId;
@end
