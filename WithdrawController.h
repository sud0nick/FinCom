/*
 *  WithdrawController.h
 *  FinCom
 *
 *  Created by Nick Combs on 10/29/11.
 *  Copyright 2011 PuffyCode. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
@class Withdrawals;

@interface WithdrawController : NSArrayController {
    IBOutlet NSPopover *__weak popOver;
    IBOutlet NSViewController *withdrawVC;
	IBOutlet NSPopUpButton *selectFrom, *selectTo, *selectedType;
	IBOutlet NSTextField *enteredAmount, *labelTo;
	IBOutlet NSDatePicker *dPicker;
	IBOutlet NSButton *checkBox;
}

-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;
-(IBAction)newWithdraw:(id)sender;
-(IBAction)cancelNewWithdraw:(id)sender;
-(IBAction)selectType:(id)sender;
-(void)toAccountHidden:(BOOL)yn;
-(void)refreshView;

@property (weak) IBOutlet NSPopover *popOver;

@end