//
//  FCGoalTrackerController.h
//  FinCom
//
//  Created by Nick on 1/23/13.
//
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"
#import "FCGoalTracker.h"
#import "Accounts.h"
#import "AccountController.h"

#define OPEN         0
#define CANCEL       1

#define BEGIN        0
#define FIRST_SLIDE  1
#define SECOND_SLIDE 2
#define THIRD_SLIDE  3
#define FOURTH_SLIDE 4

//Indexes for summaryComponents
#define ACCOUNT 1
#define LOGIC   3
#define AMOUNT  4
#define TIME    5
#define DATE    6

extern NSString * const FC_UpdateCheckingNotification;
extern NSString * const FC_UpdateSavingsNotification;
extern NSString * const FC_SendUpdateNotification;

@interface FCGoalTrackerController : NSArrayController {
    IBOutlet MyDocument *document;
    IBOutlet AccountController *accountController;
    IBOutlet NSTextField *titleField, *goalAmount, *summary;
    IBOutlet NSPopUpButton *accounts;
    IBOutlet NSBox *container;
    IBOutlet NSMatrix *logic, *accountPicker;
    IBOutlet NSDatePicker *deadlinePicker;
    IBOutlet NSView *slide0, *slide1, *slide2, *slide3, *slide4;
    IBOutlet NSButton *addGoalButton, *deleteCheckBox;
}

-(IBAction)addGoal:(id)sender;
-(IBAction)nextSlide:(id)sender;
-(IBAction)prevSlide:(id)sender;
-(IBAction)accountSelectionChanged:(id)sender;
-(IBAction)logicChanged:(id)sender;
-(IBAction)amountChanged:(id)sender;
-(IBAction)dateChanged:(id)sender;

@end