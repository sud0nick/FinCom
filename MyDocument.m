//
//  MyDocument.m
//  FinCom
//
//  Created by Nick Combs on 9/16/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "MyDocument.h"
#import "Accounts.h"
#import "GraphView.h"
#import "HistoryView.h"
#import "Withdrawals.h"
#import "Category.h"
#import "FCGoalTrackerController.h"

NSString * const FINNameKey = @"accountName"; 
NSString * const FINBalanceKey = @"accountBalance";
NSString * const HistoryNotification = @"histNote";
NSString * const HistoryCallBack = @"historyCallBack";
NSString * const PopUpCallBack = @"popUpCallBack";
NSString * const DateAlertCB = @"dateAlertCallBack";

NSString * const FC_PaymentAlertedKey = @"FC_PaymentAlertedKey";

#define ACCOUNT_BALS   [[myController arrangedObjects] valueForKey:FINBalanceKey]
#define ACCOUNT_NAMES  [[myController arrangedObjects] valueForKey:FINNameKey]

#define OPEN       0
#define NONE       0
#define GV_WINDOW  0
#define LEFT       1
#define GRAPH      1
#define DETAIL_WIN 1
#define RIGHT      2
#define HISTORY    2
#define SETTINGS   3

/* Define Currency Selections */
#define US_DOLLAR     0
#define BRITISH_POUND 1
#define EURO          2
#define JAPAN_YEN     3
#define CHINA_YAUN    4

@implementation MyDocument

-(id)init
{
	if (!(self = [super init])) return nil;
	accountsArray = [[NSMutableArray alloc] init];
    goalArray = [[NSMutableArray alloc] init];
	categories = [[NSMutableArray alloc] init];
	withdrawArray = [[NSMutableArray alloc] init];
    currency = [[NSString alloc] init];
    currencyLabel = [[NSString alloc] init];
	
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(handleCallBack:)
			   name:HistoryCallBack
			 object:nil];
	[nc addObserver:self
		   selector:@selector(handleCallBack:)
			   name:PopUpCallBack
			 object:nil];
	[nc addObserver:self
		   selector:@selector(handleCallBack:)
			   name:DateAlertCB
			 object:nil];
	
	return self;
}

-(void)awakeFromNib
{
    if (!goalArray) {
        goalArray = [[NSMutableArray alloc] init];
    }
    
    //Schedule auto saving
    [self scheduleAutosaving];
    [[NSDocumentController sharedDocumentController] setAutosavingDelay:5.0];
    
	NSDate *curDate = [NSDate date];
	NSUndoManager *undo = [self undoManager];
	NSComparisonResult res;
	NSMutableArray *removeArray = [[NSMutableArray alloc] init];
	
	//Withdrawals
	for (Withdrawals *w in withdrawArray) {
		res = [[curDate descriptionWithCalendarFormat:@"%m/%d/%y" timeZone:nil locale:nil]
			   compare:[[w withdrawDate] descriptionWithCalendarFormat:@"%m/%d/%y" timeZone:nil locale:nil]];
		
		//If the account has a payment to be made...
		if (res == NSOrderedSame || res == NSOrderedDescending) {
			float payment = [w amount];
			
			//Deduct the payment or make the transfer
			if ([[w type] isEqualToString:@"Payment"]) {
				//Payments
				[[undo prepareWithInvocationTarget:self] addToChecking:payment];
				[self willChangeValueForKey:@"checking"];
				checking -= payment;
				[self didChangeValueForKey:@"checking"];
				
				//Find the account and deduct the payment
				for (Accounts *a in accountsArray) {
					if ([[a accountName] isEqualToString:[w fromAccount]])
						[a setAccountBalance:([a accountBalance] - payment)];
				}
				[undo setActionName:@"Payments"];
			} else if ([[w type] isEqualToString:@"Transfer"]) {
				//Transfer
				for (Accounts *a in accountsArray) {
					if ([[a accountName] isEqualToString:[w fromAccount]])
						[a setAccountBalance:([a accountBalance] - payment)];
					else if ([[a accountName] isEqualToString:[w toAccount]])
						[a setAccountBalance:([a accountBalance] + payment)];
				}
				[undo setActionName:@"Transfer"];
			}
			
			//Check for recurrence of payments
			if ([[w recurString] isEqualToString:@"Yes"]) {
				//Add 1 month to the date
				NSCalendar *greg = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
				NSDateComponents *comp = [[NSDateComponents alloc] init];
				comp.month = 1;
				NSDate *nextMonth = [greg dateByAddingComponents:comp toDate:[w withdrawDate] options:0];
                
				[w setDate:nextMonth];
                
			} else if ([[w recurString] isEqualToString:@"No"]) {
				//Set to delete it from the array
				[removeArray addObject:w];
			}
		}
	}
	//Delete all withdrawals set to delete
	for (Withdrawals *w in removeArray)
		[withdrawArray removeObjectIdenticalTo:w];
	
	removeArray = nil;
	
	if (![self alertedPayments]) {
        //Check if any accounts are past due and display an alert
        NSMutableArray *pastDue = [[NSMutableArray alloc] init];
        
        for (Accounts *a in accountsArray) {
            if ([a accountBalance] > 0.00) {
                if ([[a dueDate] isEqualTo:[[NSDate date] earlierDate:[a dueDate]]])
                    [pastDue addObject:[a accountName]];
            } else {
                if ([[a dueDate] isEqualToDate:[[NSDate date] earlierDate:[a dueDate]]])
                    [a setDueDate:[NSDate dateWithTimeIntervalSinceNow:86400]];
            }
        }
        if ([pastDue count] > 0) {
            NSString *alertString = [pastDue componentsJoinedByString:@"\n"];
            NSAlert *alert = [NSAlert alertWithMessageText:@"Payments Past Due!"
                                             defaultButton:@"Go to Accounts"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"%@", alertString];
            [alert runModal];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FC_PaymentAlertedKey];
    }
    
    //Zero all negative accounts
    for (Accounts *a in accountsArray) {
        if ([a accountBalance] < 0)
            [a setAccountBalance:0];
    }
    
    //Set the currency value
    [self currencySetter:nil];
    
    //Set the double action for the table
    [acctTable setDoubleAction:@selector(doubleClicked:)];
    
    //Display the initial accountView
    [self displayView:accountView];
    
    //Set default categories if there are none
    NSMutableArray *defaultCatetgories = [NSMutableArray arrayWithObjects:[[Category alloc] initWithName:@"Credit Card"],
                                          [[Category alloc] initWithName:@"Insurance"],
                                          [[Category alloc] initWithName:@"Bills"],
                                          [[Category alloc] initWithName:@"Loan"],
                                          [[Category alloc] initWithName:@"Auto"], nil];
    if ([categories count] < 1) {
        [self setCategories:defaultCatetgories];
    }
}

-(void)dealloc
{
	[nc removeObserver:self name:HistoryCallBack object:nil];
	[nc removeObserver:self name:PopUpCallBack object:nil];
	[nc removeObserver:self name:DateAlertCB object:nil];
	[self setCategories:nil];
	[self setAccounts:nil];
	[self setWithdrawArray:nil];
    [self setGoalArray:nil];
    currency = nil;
    currencyLabel = nil;
}

-(void)setAccounts:(NSMutableArray *)newArray
{
	if (newArray == accountsArray)
		return;
	
	for (Accounts *a in accountsArray)
		[self stopObservingAccount:a];
	
	accountsArray = newArray;
	
	for (Accounts *a in accountsArray)
		[self startObservingAccount:a];
}

-(void)setCategories:(NSMutableArray *)newArray
{
	if (newArray == categories)
		return;
	categories = newArray;
}

-(void)setWithdrawArray:(NSMutableArray *)newArray
{
	if (newArray == withdrawArray)
		return;
	withdrawArray = newArray;
}

-(void)setGoalArray:(NSMutableArray *)newArray
{
    if (newArray == goalArray) {
        return;
    }
    goalArray = newArray;
}

-(double)checking
{
    return checking;
}

-(double)savings
{
    return savings;
}

#pragma mark - Callbacks

-(void)handleCallBack:(NSNotification *)note
{	
	if ([[note name] isEqualToString:DateAlertCB]) {
		return;
	} else if ([[note name] isEqualToString:HistoryCallBack]) {
		[hv clearLog];
		[hv setLogDetails:[[note userInfo] objectForKey:HistoryContent]];
		[hv setNeedsDisplay:YES];
	} else if ([[note name] isEqualToString:PopUpCallBack]) {
		
		//If the user selects the default value
		if ([[[note userInfo] objectForKey:@"selString"] isEqualToString:@"All"]) {
			[graph clearFrame];
			[graph createGraphWithAccountValues:ACCOUNT_BALS AndNames:ACCOUNT_NAMES];
			return;
		}
		//Else if the user selects a category
		int x;
		NSMutableArray *filteredNames = [NSMutableArray arrayWithCapacity:[accountsArray count]];
		NSMutableArray *filteredBalances = [NSMutableArray arrayWithCapacity:[accountsArray count]];
		for (x = 0; x < [accountsArray count]; x++) {
			if ([[[[myController arrangedObjects] objectAtIndex:x] valueForKey:@"category"]
				 isEqualToString:[[note userInfo] objectForKey:@"selString"]]) {
				[filteredNames addObject:[[[myController arrangedObjects] objectAtIndex:x] valueForKey:FINNameKey]];
				[filteredBalances addObject:[[[myController arrangedObjects] objectAtIndex:x] valueForKey:FINBalanceKey]];
			}
		}
		[graph clearFrame];
		[graph createGraphWithAccountValues:filteredBalances AndNames:filteredNames];
	}
    
    return;
}

#pragma mark - Undo Methods

-(void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)newValue
{
	[obj setValue:newValue forKeyPath:keyPath];
    [editBalance setStringValue:[NSString stringWithFormat:@"%.2f", [currentAccount accountBalance]]];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* Perform a logical equivalence check of "keyPath" and send an NSNotification to the "object"
	   that changed to invoke an undo operation MANUALLY (i.e. [array removeLastObject]) */
	
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	
	if (oldValue == [NSNull null])
		oldValue = nil;
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
    [undo setActionName:@"Edit"];
}

-(void)startObservingAccount:(Accounts *)a
{
	[a addObserver:self
		forKeyPath:@"accountName"
		   options:NSKeyValueObservingOptionOld
		   context:NULL];
	
	[a addObserver:self
		forKeyPath:@"accountBalance"
		   options:NSKeyValueObservingOptionOld
		   context:NULL];
	
	[a addObserver:self
		forKeyPath:@"category"
		   options:NSKeyValueObservingOptionOld
		   context:NULL];
	
	[a addObserver:self
		forKeyPath:@"dueDate"
		   options:NSKeyValueObservingOptionOld
		   context:NULL];
}

-(void)stopObservingAccount:(Accounts *)a
{
	[a removeObserver:self forKeyPath:@"accountName"];
	[a removeObserver:self forKeyPath:@"accountBalance"];
	[a removeObserver:self forKeyPath:@"category"];
	[a removeObserver:self forKeyPath:@"dueDate"];
}

-(void)insertObject:(Accounts *)a inAccountsArrayAtIndex:(int)index
{
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromAccountsArrayAtIndex:index];
	if (![undo isUndoing])
		[undo setActionName:@"Insert Account"];
	
	[self startObservingAccount:a];
	[accountsArray insertObject:a atIndex:index];
}

-(void)removeObjectFromAccountsArrayAtIndex:(int)index
{
	Accounts *a = [accountsArray objectAtIndex:index];
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:a inAccountsArrayAtIndex:index];
	if (![undo isUndoing])
		[undo setActionName:@"Delete Account"];
	
	[self stopObservingAccount:a];
	[accountsArray removeObjectAtIndex:index];
}

-(void)addToChecking:(double)value
{
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] subFromChecking:value];
	
	[self willChangeValueForKey:@"checking"];
	checking += value;
	[self didChangeValueForKey:@"checking"];
}

-(void)subFromChecking:(double)value
{
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] addToChecking:value];
	[self willChangeValueForKey:@"checking"];
	checking -= value;
	[self didChangeValueForKey:@"checking"];
}

-(void)setChecking:(double)value
{
	[self willChangeValueForKey:@"checking"];
	checking = value;
	[self didChangeValueForKey:@"checking"];
    
    NSNumber *check = [NSNumber numberWithDouble:checking];
    NSDictionary *d = [NSDictionary dictionaryWithObject:check forKey:FC_UpdateCheckingNotification];
    [nc postNotificationName:FC_UpdateCheckingNotification object:self userInfo:d];
	
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] unSetChecking:value];
}

-(void)setSavings:(double)value
{
	[self willChangeValueForKey:@"savings"];
	savings = value;
	[self didChangeValueForKey:@"savings"];
    
    NSNumber *save = [NSNumber numberWithDouble:savings];
    NSDictionary *d = [NSDictionary dictionaryWithObject:save forKey:FC_UpdateSavingsNotification];
    [nc postNotificationName:FC_UpdateSavingsNotification object:self userInfo:d];
	
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] unSetSavings:value];
}

-(void)unSetChecking:(double)value
{
	[self willChangeValueForKey:@"checking"];
	checking = value;
	[self didChangeValueForKey:@"checking"];
    
    NSNumber *check = [NSNumber numberWithDouble:checking];
    NSDictionary *d = [NSDictionary dictionaryWithObject:check forKey:FC_UpdateCheckingNotification];
    [nc postNotificationName:FC_UpdateCheckingNotification object:self userInfo:d];
	
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setChecking:value];
}

-(void)unSetSavings:(double)value
{
	[self willChangeValueForKey:@"savings"];
	savings = value;
	[self didChangeValueForKey:@"savings"];
    
    NSNumber *save = [NSNumber numberWithDouble:savings];
    NSDictionary *d = [NSDictionary dictionaryWithObject:save forKey:FC_UpdateSavingsNotification];
    [nc postNotificationName:FC_UpdateSavingsNotification object:self userInfo:d];
	
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setSavings:value];
}

#pragma mark - Edit Account Methods

-(void)doubleClicked:(NSTableView *)tv
{
    if ([tv selectedRow] > [accountsArray count]) {
        return;
    }
    
    //Set the current values of the account in the window
    currentAccount = [accountsArray objectAtIndex:[tv selectedRow]];
    [editName setStringValue:[currentAccount accountName]];
    [editBalance setStringValue:[NSString stringWithFormat:@"%.2f", [currentAccount accountBalance]]];
    [editDueDate setDateValue:[currentAccount dueDate]];
    [editCategory selectItemWithTitle:[currentAccount category]];
    
    //Set the alerts for the account
    [alarm displayAlertsForAccount:currentAccount];
    
    [self displayPopOver:[self popOver]
      withViewController:editAccountVC
          relativeToRect:[tv frameOfCellAtColumn:1 row:[tv selectedRow]]
                  ofView:tv
                  onEdge:NSMaxXEdge];
}

-(IBAction)changeAccountProperty:(id)sender
{
    [currentAccount setAccountName:[editName stringValue]];
    [currentAccount setAccountBalance:[editBalance doubleValue]];
    [currentAccount setDueDate:[editDueDate dateValue]];
    [currentAccount setCategory:[editCategory titleOfSelectedItem]];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([[self popOver] isShown])
        [self doubleClicked:acctTable];
}

-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
       relativeToRect:(NSRect)rect
               ofView:(id)sender
               onEdge:(NSRectEdge)edge
{
    [pO setContentViewController:vc];
    [pO setContentSize:vc.view.bounds.size];
    [pO showRelativeToRect:rect ofView:sender preferredEdge:edge];
}

#pragma mark - Menu Buttons

-(IBAction)displayMainView:(id)sender
{
    [self displayView:mainView];
}

-(IBAction)displayAccounts:(id)sender
{
    [self displayView:accountView];
}

-(IBAction)displayGoalView:(id)sender
{
    [self displayView:goalView];
}

-(IBAction)displayAlarmView:(id)sender
{
    if (![alarm anyCalendarsExist]) {
        NSInteger ret = NSRunAlertPanel(@"Alert Calendars Required",
                                        @"If you wish to use the alert feature you must have the appropriate alert calendars.\n\n"
                                        @"Would you like to create them now?\n"
                                        @"This will create \"FinCom Alerts\" in both Calendar and Reminders on your Mac.",
                                        @"Create Calendars",
                                        @"Cancel",
                                        nil);
        if (ret == NSAlertDefaultReturn) {
            [nc postNotificationName:FC_CreateCalendarKey object:self];
            [nc postNotificationName:FC_CreateReminderKey object:self];
        } else {
            return;
        }
    }
    [self displayView:alarmView];
}

#pragma mark - Buttons

-(IBAction)currencySetter:(id)sender
{
    NSString *change = [[currencySelection selectedCell] title];
    
    //Change the selected currency
    [self willChangeValueForKey:@"currency"];
    [self setValue:[change substringToIndex:1] forKey:@"currency"];
    [self didChangeValueForKey:@"currency"];
    
    //Change the labels
    [self willChangeValueForKey:@"currencyLabel"];
    [self setValue:change forKey:@"currencyLabel"];
    [self didChangeValueForKey:@"currencyLabel"];
    
    //Set our NSInteger to the selected row
    [self setSelectedCurrencyRow:[currencySelection selectedRow]];
}

-(IBAction)newCategoryOnFly:(id)sender
{
    [newCategoryWindow setIsVisible:YES];
}

-(IBAction)displayGraph:(id)sender
{
    NSMutableArray *titles;
    int x;
    
    [graph setSavingsAmount:savings];
    [graph setCheckingAmount:checking];
    [graph createGraphWithAccountValues:ACCOUNT_BALS AndNames:ACCOUNT_NAMES];
    
    titles = [NSMutableArray arrayWithObjects:@"All", nil];
    for (x = 0; x < [categories count]; x++)
        [titles addObject:[[[catController arrangedObjects] objectAtIndex:x] valueForKey:@"category"]];
    NSDictionary *d = [NSDictionary dictionaryWithObject:titles forKey:@"selContent"];
    [nc postNotificationName:GVPopUpContent object:self userInfo:d];
    
    [NSApp beginSheet:barGraphSheet
       modalForWindow:[viewContainer window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:NULL];
}

#pragma mark - History Methods

-(IBAction)displayHistory:(id)sender
{
    NSMutableArray *titles;
    int x;
    
    [NSApp beginSheet:detailWindow
       modalForWindow:[viewContainer window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:NULL];
    
    titles = [NSMutableArray arrayWithObjects:@"Select an Account", nil];
    for (x = 0; x < [accountsArray count]; x++)
        [titles addObject:[[[myController arrangedObjects] objectAtIndex:x] valueForKey:FINNameKey]];
    [history addItemsWithTitles:titles];
}

-(IBAction)selectHistory:(id)sender
{
	if ([[myController arrangedObjects] count] == 0) {
		return;
    }
	
	int tag = [sender tag];
	int index;
	
	index = (tag == 0) ? ([sender indexOfSelectedItem] - 1) : ([history indexOfSelectedItem] - 1);
	index = (tag == LEFT) ? (index - 1) : (tag == RIGHT) ? (index + 1) : index;
	
	if (index < 0) {
		[history selectItemAtIndex:0];
		[hv clearLog];
		[hv setNeedsDisplay:YES];
		return;
	}
	
	index = (index >= ([history numberOfItems] - 1)) ? (index - 1) : index;
	[history selectItemAtIndex:(index + 1)];
	
	NSString *acctName = [[[myController arrangedObjects] objectAtIndex:index] valueForKey:FINNameKey];
	NSDictionary *d = [NSDictionary dictionaryWithObject:acctName forKey:@"name"];
	[nc postNotificationName:HistoryNotification object:self userInfo:d];
}

#pragma mark - Sheet Methods

-(IBAction)displayPreferences:(id)sender
{
    [NSApp beginSheet:settingsWindow
       modalForWindow:[viewContainer window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:NULL];
}

-(IBAction)closeSelectedWindow:(id)sender
{
	int tag = [sender tag];
	switch (tag) {
		case GV_WINDOW:
			/* Clean up and close the Graph View */
			[NSApp endSheet:barGraphSheet];
			[barGraphSheet orderOut:sender];
			[graph clearFrame];
			
			break;
		case DETAIL_WIN:
			/* Clean up and close the History window */
			[NSApp endSheet:detailWindow];
			[detailWindow orderOut:sender];
			[hv clearLog];
			[hv setNeedsDisplay:YES];
			[history removeAllItems];
			
			break;
        case SETTINGS:
            [NSApp endSheet:settingsWindow];
            [settingsWindow orderOut:sender];
			break;
		default:
			break;
	}
}

#pragma mark - Pay & Transfer Methods

-(IBAction)transferBalance:(id)sender
{	
	if ([accountsArray count] < 2) {
		[self runAlertSheetWithTitle:@"Not Enough Accounts"
						  andMessage:@"There must be at least two accounts to transfer balances."];
		return;
	}
    if (([transferCheck state] == NSOffState) && ([[transferAmount stringValue] isEqualToString:@""])) {
        NSRunAlertPanel(@"Missing Amount",
                        @"You must enter a valid amount to transfer.",
                        @"OK",
                        nil, nil);
        return;
    }
    
    /* Method for transferring balances from one account to another. */
    Accounts *toAccount = [accountsArray objectAtIndex:[to indexOfSelectedItem]];
    
    //Check if the user tried transferring to the same account
    if (currentAccount == toAccount) {
        return;
    }
    
    NSNumber *newBal, *clearBal;
    //Create new balance and zero balance
    if ([transferCheck state] == NSOnState) {
        newBal = [NSNumber numberWithFloat:([currentAccount accountBalance] + [toAccount accountBalance])];
        clearBal = [NSNumber numberWithFloat:0.00];
    } else {
        newBal = [NSNumber numberWithFloat:([transferAmount floatValue] + [toAccount accountBalance])];
        clearBal = [NSNumber numberWithFloat:([currentAccount accountBalance] - [transferAmount floatValue])];
    }
    
    /* Change "from balance" to zero and "to balance" to newBal */
    [currentAccount setValue:clearBal forKey:FINBalanceKey];
    [toAccount setValue:newBal forKey:FINBalanceKey];
    [editBalance setStringValue:[NSString stringWithFormat:@"%.2f", [clearBal doubleValue]]];
    
    [transferAmount setStringValue:@""];
    [transferCheck setState:NSOffState];
}

-(IBAction)makePayment:(id)sender
{
    /* Subtract from checking and selected balance / close window */
    double subFrom;
    NSNumber *newBalance;
    
    if ([subCheck state] == NSOnState) {
        //Subtract whole balance
        subFrom = [currentAccount accountBalance];
        newBalance = [NSNumber numberWithFloat:0.00];
    } else {
        //Subtract some of the balance
        subFrom = [subField doubleValue];
        newBalance = [NSNumber numberWithFloat:([currentAccount accountBalance] - subFrom)];
    }
    
    if (subFrom > checking) {
        NSInteger res = NSRunAlertPanel(@"Not Enough Money!",
                                        @"There is not enough in your Checking account to make this payment.\n"
                                        @"Do you want to continue anyway?",
                                        @"Yes",
                                        @"Cancel",
                                        nil);
        if (res == NSAlertAlternateReturn) {
            return;
        }
    }
    
    [self subFromChecking:subFrom];
    [currentAccount setValue:newBalance forKey:FINBalanceKey];
    [editBalance setStringValue:[NSString stringWithFormat:@"%.2f", [currentAccount accountBalance]]];
    [subField setStringValue:@""];
    [subCheck setState:NSOffState];
}

-(IBAction)editCheckSav:(id)sender
{
	if ([sender tag] == 0) {
        [self displayPopOver:[self popOver]
          withViewController:chksavVC
                      ofView:sender
                      onEdge:NSMinYEdge];
        return;
    } else if ([sender tag] == 1) {
        /* Done editing checking and savings accounts / Close window */
        if (![[newChecking stringValue] isEqualToString:@""]) {
            double oldChecking = checking;
            NSUndoManager *undo = [self undoManager];
            [[undo prepareWithInvocationTarget:self] setChecking:oldChecking];
            [self setChecking:[newChecking doubleValue]];
        }
        if (![[newSavings stringValue] isEqualToString:@""]) {
            double oldSavings = savings;
            NSUndoManager *undo = [self undoManager];
            [[undo prepareWithInvocationTarget:self] setSavings:oldSavings];
            [self setSavings:[newSavings doubleValue]];
        }
        
        [newChecking setStringValue:@""];
        [newSavings setStringValue:@""];
        [newChecking becomeFirstResponder];
    }
    [[self popOver] close];
}

#pragma mark - Helpers

-(BOOL)alertedPayments
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:FC_PaymentAlertedKey];
}

-(IBAction)openCalc:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"Calculator.app"];
	return;
}

-(void)displayView:(NSView *)view
{
    //Close all popovers first
    if ([[self popOver] isShown]) {
        [[self popOver] close];
    }
    if ([[myController popOver] isShown]) {
        [[myController popOver] close];
    }
    
    //Hide view
    [view setAlphaValue:0.0];
    
    //Set the current view
    currentView = view;
    
    //Place the new view in the container
    [viewContainer setContentView:currentView];
    
    //Fade view in
    [[view animator] setAlphaValue:1.0];
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

-(void)runAlertSheetWithTitle:(NSString *)title andMessage:(NSString *)message
{
	NSAlert *alert = [NSAlert alertWithMessageText:title
									 defaultButton:@"OK"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:message, nil];
	
	[alert beginSheetModalForWindow:[acctTable window]
					  modalDelegate:self
					 didEndSelector:nil
						contextInfo:NULL];
}

#pragma mark - Document Methods

- (NSString *)windowNibName
{
    return @"MyDocument";
}

-(void)windowControllerWillLoadNib:(NSWindowController *)windowController
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"SetupComplete"]) {
        NSInteger res = NSRunAlertPanel(@"Font Installation Required",
                                        @"The Apple Casual font is required to use FinCom.  "
                                        @"Please take a moment to ensure it is installed before continuing.",
                                        @"Check",
                                        nil,
                                        nil);
        if (res == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/AppleCasual.dfont",
                                                     [[NSBundle mainBundle] resourcePath]]];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SetupComplete"];
    }
    
    //Set the database to NO for alerting payments
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FC_PaymentAlertedKey];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [alarm setEventAlarms:[NSMutableArray arrayWithArray:tempEvents]];
    [alarm setReminderAlarms:[NSMutableArray arrayWithArray:tempReminders]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	//Stop all editing
    [[acctTable window] endEditingFor:nil];
	
	//Turn checking and savings into NSNumber objects
	NSNumber *newCheck = [NSNumber numberWithFloat:checking];
	NSNumber *newSav = [NSNumber numberWithFloat:savings];
    NSNumber *currencyType = [NSNumber numberWithInt:[self selectedCurrencyRow]];
    	
	//Create a dictionary of all the data we want to save
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:accountsArray, @"accArray",
                       [alarm eventAlarms], @"events",
                       [alarm reminderAlarms], @"reminders",
					   categories, @"categories",
					   withdrawArray, @"withdrawArray",
                       goalArray, @"goalArray",
					   newCheck, @"checkKey",
					   newSav, @"savingsKey",
                       currencyType, @"currencyType",
					   nil];
	
	//Return our data packaged in an NSData object
	return [NSKeyedArchiver archivedDataWithRootObject:d];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	@try {
		id loadData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        tempEvents = [loadData objectForKey:@"events"];
        tempReminders = [loadData objectForKey:@"reminders"];
		[self setAccounts:[loadData objectForKey:@"accArray"]];
		[self setCategories:[loadData objectForKey:@"categories"]];
		[self setWithdrawArray:[loadData objectForKey:@"withdrawArray"]];
        [self setGoalArray:[loadData objectForKey:@"goalArray"]];
		[self setChecking:[[loadData objectForKey:@"checkKey"] floatValue]];
		[self setSavings:[[loadData objectForKey:@"savingsKey"] floatValue]];
        [self setSelectedCurrencyRow:[[loadData objectForKey:@"currencyType"] intValue]];
	}
	@catch (NSException *e) {
		if (outError) {
			NSDictionary *d = [NSDictionary dictionaryWithObject:@"The Data is Corrupt." forKey:NSLocalizedFailureReasonErrorKey];
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:d];
		}
		return NO;
	}
    return YES;
}

+(BOOL)autosavesInPlace
{
    return YES;
}

-(BOOL)hasUnautosavedChanges
{
    return YES;
}

@synthesize popOver;
@synthesize selectedCurrencyRow;

@end