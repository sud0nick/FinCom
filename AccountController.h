//
//  AccountController.h
//  FinCom
//
//  Created by Nicholas Combs on 4/9/12.
//  Copyright (c) 2012 PuffyCode. All rights reserved.
//

#import "Accounts.h"

@class Accounts;
@interface AccountController : NSArrayController {
    IBOutlet NSPopover *__weak popOver;
    IBOutlet NSViewController *addAccountVC;
    IBOutlet NSTextField *name, *balance;
    IBOutlet NSPopUpButton *category;
    IBOutlet NSDatePicker *dueDate;
}

-(IBAction)addAccount:(id)sender;

@property (weak) IBOutlet NSPopover *popOver;

@end