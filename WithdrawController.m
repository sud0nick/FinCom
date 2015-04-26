//
//  WithdrawController.m
//  FinCom
//
//  Created by Nick Combs on 10/29/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "WithdrawController.h"
#import "Withdrawals.h"

@implementation WithdrawController

-(void)awakeFromNib
{
	[self refreshView];
}

-(id)newObject
{	
	Withdrawals *w = [[Withdrawals alloc] init];
    [w setFromAccount:[selectFrom titleOfSelectedItem]];
	
	if ([[selectedType titleOfSelectedItem] isEqualToString:@"Transfer"])
		[w setToAccount:[selectTo titleOfSelectedItem]];
	else
		[w setToAccount:@"N/A"];
	
	[w setType:[selectedType titleOfSelectedItem]];
	[w setAmount:[enteredAmount floatValue]];
	[w setDate:[dPicker dateValue]];
	
	if ([checkBox state] == NSOnState)
		[w setRecurString:@"Yes"];
	else
		[w setRecurString:@"No"];
	
    [[self popOver] close];
	[self refreshView];
	
	return w;
}

-(IBAction)newWithdraw:(id)sender
{
    NSInteger tag = [sender tag];
    
    if (tag == 0) {
        [self displayPopOver:[self popOver]
          withViewController:withdrawVC
                      ofView:sender
                      onEdge:NSMaxXEdge];
    } else if (tag == 1) {
        //Cancel
        [self refreshView];
        [[self popOver] close];
    }
}

-(IBAction)cancelNewWithdraw:(id)sender
{
    [self refreshView];
    [[self popOver] close];
}

-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge
{
    [pO setContentViewController:vc];
    [pO setContentSize:vc.view.bounds.size];
    [pO showRelativeToRect:[sender bounds] ofView:sender preferredEdge:edge];
}

-(IBAction)selectType:(id)sender
{
	if ([[sender titleOfSelectedItem] isEqualToString:@"Transfer"])
		[self toAccountHidden:NO];
	else
		[self toAccountHidden:YES];
}

-(void)refreshView
{
	if (![[selectedType titleOfSelectedItem] isEqualToString:@"Transfer"]) {
		[labelTo setHidden:YES];
		[selectTo setHidden:YES];
	}
	[enteredAmount setStringValue:@""];
	[selectFrom becomeFirstResponder];
	[checkBox setState:NSOffState];
	[dPicker setDateValue:[NSDate dateWithTimeIntervalSinceNow:86400]];
}

-(void)toAccountHidden:(BOOL)yn
{
	if (yn == YES) {
		[labelTo setHidden:YES];
		[selectTo setHidden:YES];
	} else if (yn == NO) {
		[labelTo setHidden:NO];
		[selectTo setHidden:NO];
	}
	return;
}

@synthesize popOver;

@end