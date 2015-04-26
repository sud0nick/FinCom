//
//  AccountController.m
//  FinCom
//
//  Created by Nicholas Combs on 4/9/12.
//  Copyright (c) 2012 PuffyCode. All rights reserved.
//

#import "AccountController.h"

#define OPEN   0
#define CANCEL 1

@interface AccountController()
-(void)refreshView;
-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;
@end

@implementation AccountController

-(void)awakeFromNib
{
    [self refreshView];
}

-(id)newObject
{
    Accounts *newAccount = [[Accounts alloc] init];
    if ([[name stringValue] isEqualToString:@""]) {
        [newAccount setAccountName:@"New Account"];
    } else {
        [newAccount setAccountName:[name stringValue]];
    }
    [newAccount setAccountBalance:[balance doubleValue]];
    [newAccount setCategory:[category titleOfSelectedItem]];
    
    NSDate *cur = [NSDate date];
    NSComparisonResult res =  [cur compare:[dueDate dateValue]];
    if (res == NSOrderedDescending) {
        [newAccount setDueDate:[NSDate dateWithTimeIntervalSinceNow:86400]];
        NSRunAlertPanel(@"Due Date Changed",
                        @"The date entered was not a future date.  It has been set to tomorrow's date.",
                        @"OK",
                        nil,
                        nil);
    } else
        [newAccount setDueDate:[dueDate dateValue]];
    [[self popOver] close];
    [self refreshView];
    return newAccount;
}

-(void)refreshView
{
    [name setStringValue:@""];
    [balance setStringValue:@""];
    [dueDate setDateValue:[NSDate dateWithTimeIntervalSinceNow:86400]];
}

-(IBAction)addAccount:(id)sender
{
    NSInteger tag = [sender tag];
    if (tag == OPEN) {
        [self displayPopOver:[self popOver]
          withViewController:addAccountVC
                      ofView:sender
                      onEdge:NSMinYEdge];
    } else if (tag == CANCEL) {
        [[self popOver] close];
        [self refreshView];
    }
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

@synthesize popOver;

@end