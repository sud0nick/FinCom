//
//  MyDocument.h
//  FinCom
//
//  Created by Nick Combs on 9/16/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccountController.h"
#import "FCAlarm.h"
@class Accounts;
@class GraphView;
@class HistoryView;

extern NSString * const HistoryNotification;
extern NSString * const HistoryCallBack;
extern NSString * const PopUpCallBack;
extern NSString * const DateAlertCB;

@interface MyDocument : NSDocument <NSTableViewDelegate>
{
    Accounts *currentAccount;
    NSString *currency, *currencyLabel;
    NSInteger selectedCurrencyRow;
	NSMutableArray *accountsArray, *categories, *withdrawArray, *goalArray;
	NSNotificationCenter *nc;
    NSView *currentView;
    NSArray *tempEvents, *tempReminders;
    
	//Outlets
    IBOutlet AccountController *myController;
    IBOutlet GraphView *graph;
	IBOutlet HistoryView *hv;
    IBOutlet FCAlarm *alarm;
    IBOutlet NSMatrix *currencySelection;
	IBOutlet NSWindow *barGraphSheet, *detailWindow, *settingsWindow, *newCategoryWindow;
    IBOutlet NSViewController *chksavVC, *editAccountVC;
	IBOutlet NSTableView *acctTable;
	IBOutlet NSPopUpButton *to, *history, *editCategory;
	IBOutlet NSArrayController *catController;
	IBOutlet NSTextField *subField, *transferAmount, *newChecking, *newSavings;
    IBOutlet NSTextField *editName, *editBalance;
    IBOutlet NSDatePicker *editDueDate;
	IBOutlet NSButton *transferCheck, *subCheck;
    IBOutlet NSView *mainView, *accountView, *goalView, *alarmView, *accountDetailView;
    IBOutlet NSBox *viewContainer;
	
	//Primitive Types
	double checking, savings;
}

//Getter Methods
-(double)checking;
-(double)savings;

//Setter Methods
-(void)setAccounts:(NSMutableArray *)newArray;
-(void)setCategories:(NSMutableArray *)newArray;
-(void)setWithdrawArray:(NSMutableArray *)newArray;
-(void)setGoalArray:(NSMutableArray *)newArray;
-(void)setChecking:(double)value;
-(void)setSavings:(double)value;

//Undo Methods
-(void)addToChecking:(double)value;
-(void)subFromChecking:(double)value;
-(void)unSetChecking:(double)value;
-(void)unSetSavings:(double)value;
-(void)startObservingAccount:(Accounts *)a;
-(void)stopObservingAccount:(Accounts *)a;
-(void)removeObjectFromAccountsArrayAtIndex:(int)index;
-(void)insertObject:(Accounts *)a inAccountsArrayAtIndex:(int)index;

//Helper Methods
-(BOOL)alertedPayments;
-(void)displayView:(NSView *)view;
-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;
-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
       relativeToRect:(NSRect)rect
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;
-(void)runAlertSheetWithTitle:(NSString *)title andMessage:(NSString *)message;

//Buttons
-(IBAction)displayMainView:(id)sender;
-(IBAction)displayAlarmView:(id)sender;
-(IBAction)closeSelectedWindow:(id)sender;
-(IBAction)editCheckSav:(id)sender;
-(IBAction)openCalc:(id)sender;
-(IBAction)selectHistory:(id)sender;
-(IBAction)displayHistory:(id)sender;
-(IBAction)transferBalance:(id)sender;
-(IBAction)currencySetter:(id)sender;
-(IBAction)newCategoryOnFly:(id)sender;
-(IBAction)changeAccountProperty:(id)sender;
-(IBAction)displayGraph:(id)sender;
-(IBAction)displayPreferences:(id)sender;
-(IBAction)displayAccounts:(id)sender;
-(IBAction)displayGoalView:(id)sender;
-(IBAction)makePayment:(id)sender;

@property (assign) IBOutlet NSPopover *popOver;
@property (readwrite, assign) NSInteger selectedCurrencyRow;

@end