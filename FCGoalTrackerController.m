//
//  FCGoalTrackerController.m
//  FinCom
//
//  Created by Nick on 1/23/13.
//
//

#import "FCGoalTrackerController.h"

NSString * const FC_UpdateCheckingNotification = @"FC_UpdateCheckingNotification";
NSString * const FC_UpdateSavingsNotification  = @"FC_UpdateSavingsNotification";
NSString * const FC_SendUpdateNotification     = @"FC_SendUpdateNotification";

@interface FCGoalTrackerController() {
    NSMutableArray *summaryComponents;
    NSNotificationCenter *nc;
}

-(BOOL)fieldsAreValid;
-(void)refreshView;
-(void)displayView:(NSView *)view;
-(NSString *)currentSelectedAccount;
-(void)timeChanged;
-(void)modifySummaryAtIndex:(NSInteger)index WithString:(NSString *)string;

@end

@implementation FCGoalTrackerController

-(void)awakeFromNib
{
    summaryComponents = [[NSMutableArray alloc] init];
    nc = [NSNotificationCenter defaultCenter];
    
    //Begin listening for account updates from any account
    [nc addObserver:self
           selector:@selector(handleCallBack:)
               name:AccountUpdateNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleCallBack:)
               name:FC_UpdateCheckingNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleCallBack:)
               name:FC_UpdateSavingsNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(reapAccount:)
               name:(NSString *)GT_ReadyToDie
             object:nil];
    
    //Enumerate over goal objects and check for missed deadlines
    NSEnumerator *enumerator = [[self arrangedObjects] objectEnumerator];
    NSMutableArray *toBeRemoved = [[NSMutableArray alloc] initWithCapacity:[[self arrangedObjects] count]];
    id obj;
    while (obj = [enumerator nextObject]) {
        if ([obj progress] < 100 && [obj passedDeadline]) {
            if (![obj deadlineAlerted]) {
                NSInteger res = NSRunAlertPanel(@"Deadline Missed",
                                                @"You have missed the deadline for your %@ account goal.",
                                                @"Ignore",
                                                @"Delete Goal",
                                                nil, [obj goalAccount]);
                if (res == NSAlertAlternateReturn) {
                    [toBeRemoved addObject:obj];
                } else {
                    [obj setDeadlineAlerted:YES];
                }
            }
        }
    }
    
    //Set today as the minimum date for the date picker
    [deadlinePicker setMinDate:[NSDate date]];
    
    //Remove the objects
    [self removeObjects:toBeRemoved];
    
    [self refreshView];
}

-(void)handleCallBack:(NSNotification *)note
{
    NSString *accountName = [NSString string];
    double currentVal = 0.00;
    if ([[note name] isEqualToString:AccountUpdateNotification]) {
        accountName = [[note object] accountName];
        currentVal = [[note object] accountBalance];
    } else if ([[note name] isEqualToString:FC_UpdateCheckingNotification]) {
        accountName = @"Checking";
        currentVal = [[[note userInfo] objectForKey:FC_UpdateCheckingNotification] doubleValue];
    } else if ([[note name] isEqualToString:FC_UpdateSavingsNotification]) {
        accountName = @"Savings";
        currentVal = [[[note userInfo] objectForKey:FC_UpdateSavingsNotification] doubleValue];
    }
    //Enumerate our goal objects to find the one that needs to be updated
    NSEnumerator *enumerator = [[self arrangedObjects] objectEnumerator];
    id obj;
    while (obj = [enumerator nextObject]) {
        if ([[obj goalAccount] isEqualToString:accountName]) {
            [obj setCurrentValue:currentVal];
            [obj calculateProgress];
        }
    }
}

-(void)reapAccount:(NSNotification *)note
{
    [self removeObject:[note object]];
}

-(id)newObject
{
    if (![self fieldsAreValid]) {
        NSRunAlertPanel(@"Missing Information",
                        @"You must fill out all information before setting a goal.",
                        @"OK",
                        nil,
                        nil);
        return nil;
    }
    
    FCGoalTracker *newGoal = [[FCGoalTracker alloc] init];
    
    [newGoal setTitle:[titleField stringValue]];
    [newGoal setSummary:[summary stringValue]];
    [newGoal setGoalAccount:[self currentSelectedAccount]];
    [newGoal setGoalLogic:[[logic selectedCell] title]];
    [newGoal setGoalValue:[goalAmount doubleValue]];
    [newGoal setDeleteWhenComplete:[deleteCheckBox state]];
    
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:flags fromDate:[deadlinePicker dateValue]];
    [newGoal setDeadline:[calendar dateFromComponents:components]];
    
    if ([[newGoal goalAccount] isEqualToString:@"Checking"]) {
        [newGoal setCurrentValue:[document checking]];
        [newGoal setInitialValue:[document checking]];
    } else if ([[newGoal goalAccount] isEqualToString:@"Savings"]) {
        [newGoal setCurrentValue:[document savings]];
        [newGoal setInitialValue:[document savings]];
    } else {
        //Enumerate through the current account objects to get the current balance
        NSEnumerator *enumerator = [[accountController arrangedObjects] objectEnumerator];
        id obj;
        while (obj = [enumerator nextObject]) {
            if ([[obj accountName] isEqualToString:[self currentSelectedAccount]]) {
                [newGoal setCurrentValue:[obj accountBalance]];
                [newGoal setInitialValue:[obj accountBalance]];
            }
        }
    }
    
    
    //I am setting user alerted here to YES so the progress
    //can initially be checked without alerting the user to
    //whether or not the goal has been met.  If it has we will
    //not add it to the array.
    //[newGoal setUserAlerted:YES];
    
    //Calculate the current progress
    [newGoal calculateProgress];
    
    //Check if the goal has already been met
    if ([newGoal progress] >= 100) {
        NSRunAlertPanel(@"Goal Error",
                        @"Goals must be made so that they do not begin at 100%% progress.  That's cheating.",
                        @"OK",
                        nil,
                        nil);
        return nil;
    }
    
    //Reset user alerted to NO
    //[newGoal setUserAlerted:NO];
    
    [NSApp endSheet:[container window]];
    [[container window] orderOut:self];
    
    [self refreshView];
    
    return newGoal;
}

-(void)refreshView
{
    //Reset accounts popupmenu, titleField, and goalAmount.
    [accounts setEnabled:NO];
    [titleField setStringValue:@""];
    [goalAmount setStringValue:@""];
    
    //Refresh the array
    NSArray *temp = [NSArray arrayWithObjects:@"Your goal will be reached when your ",
                     @"",
                     @" account contains a value ",
                     @"",   //Chosen logic
                     @"",   //Goal amount
                     @"",   //Before or After
                     @"",   //Date
                     nil];
    [summaryComponents removeAllObjects];
    [summaryComponents addObjectsFromArray:temp];
    
    //Reset the summary string, date picker, and slide0
    [summary setStringValue:@"This will update as you complete the process below."];
    [deadlinePicker setDateValue:[NSDate date]];
    [deleteCheckBox setState:NSOffState];
    [self displayView:slide0];
}

#pragma mark - Buttons

-(IBAction)addGoal:(id)sender
{
    NSInteger tag = [sender tag];
    if (tag == OPEN) {
        [NSApp beginSheet:[container window]
           modalForWindow:[addGoalButton window]
            modalDelegate:self
           didEndSelector:nil
              contextInfo:NULL];
    } else if (tag == CANCEL) {
        [NSApp endSheet:[container window]];
        [[container window] orderOut:sender];
        [self refreshView];
    }
}

-(IBAction)nextSlide:(id)sender
{
    if ([sender tag] == BEGIN) {
        [self displayView:slide1];
        [self accountSelectionChanged:accountPicker];
    } else if ([sender tag] == FIRST_SLIDE) {
        [self displayView:slide2];
        [self logicChanged:logic];
    } else if ([sender tag] == SECOND_SLIDE) {
        [self displayView:slide3];
        [self timeChanged];
        [self dateChanged:deadlinePicker];
    } else if ([sender tag] == THIRD_SLIDE) {
        [self displayView:slide4];
    }
}

-(IBAction)prevSlide:(id)sender
{
    if ([sender tag] == SECOND_SLIDE) {
        [self displayView:slide1];
    } else if ([sender tag] == THIRD_SLIDE) {
        [self displayView:slide2];
    } else if ([sender tag] == FOURTH_SLIDE) {
        [self displayView:slide3];
    }
}

-(IBAction)accountSelectionChanged:(id)sender
{
    NSString *selectedItem = [[accountPicker selectedCell] title];
    if ([selectedItem isEqualToString:@"Other"]) {
        [accounts setEnabled:YES];
    } else {
        [accounts setEnabled:NO];
    }
    [self modifySummaryAtIndex:ACCOUNT WithString:[self currentSelectedAccount]];
}

-(IBAction)logicChanged:(id)sender
{
    //Add a space after the selected item
    NSString *selectedItem = [[[sender selectedCell] title] stringByAppendingString:@" "];
    [self modifySummaryAtIndex:LOGIC WithString:[selectedItem lowercaseString]];
}

-(IBAction)amountChanged:(id)sender
{
    [self modifySummaryAtIndex:AMOUNT WithString:[[sender stringValue] stringByAppendingString:@" "]];
}

-(void)timeChanged
{
    [self modifySummaryAtIndex:TIME WithString:@"on or before "];
}

-(IBAction)dateChanged:(id)sender
{
    [self modifySummaryAtIndex:DATE WithString:[[[sender dateValue] descriptionWithCalendarFormat:@"%m/%d/%y"
                                                                                        timeZone:nil
                                                                                          locale:nil] stringByAppendingString:@"."]];
}

#pragma mark - Helpers

-(BOOL)fieldsAreValid
{
    if ([[titleField stringValue] isEqualToString:@""]) {
        return NO;
    }
    if ([[goalAmount stringValue] isEqualToString:@""]) {
        return NO;
    }
    return YES;
}

-(void)modifySummaryAtIndex:(NSInteger)index WithString:(NSString *)string
{
    [summaryComponents replaceObjectAtIndex:index withObject:string];
    [summary setStringValue:[summaryComponents componentsJoinedByString:@""]];
}

-(NSString *)currentSelectedAccount
{
    if ([[[accountPicker selectedCell] title] isEqualToString:@"Other"]) {
        return [accounts titleOfSelectedItem];
    } else {
        return [[accountPicker selectedCell] title];
    }
}

#pragma mark - Display Methods

-(void)displayView:(NSView *)view
{
    //Hide view
    [view setAlphaValue:0.0];
    
    //Place the new view in the container
    [container setContentView:view];
    
    //Fade view in
    [[view animator] setAlphaValue:1.0];
}

@end