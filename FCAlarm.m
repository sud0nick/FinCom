//
//  FCAlarm.m
//  FinCom
//
//  Created by Nick on 1/26/13.
//
//

#import "FCAlarm.h"
#import "AccountController.h"
#import <EventKit/EventKit.h>

//Archive Keys
NSString * const FC_EventStoreKey    = @"FC_EventDictionaryStoreKey";
NSString * const FC_ReminderStoreKey = @"FC_ReminderDictionaryStoreKey";
NSString * const FC_CalendarIDKey    = @"FC_CalendarIDKey";
NSString * const FC_ReminderIDKey    = @"FC_ReminderIDKey";

//Alarm dictionary keys
NSString * const FC_AlarmEventKey   = @"FC_AlarmEventKey";
NSString * const FC_AlarmAccountKey = @"FC_AlarmAccountKey";
NSString * const FC_AlarmTitleKey   = @"FC_AlarmTitleKey";
NSString * const FC_AlarmTypeKey    = @"FC_AlarmTypeKey";
NSString * const FC_AlarmIconKey    = @"FC_AlarmIconKey";

//External notification
NSString * const FC_CreateCalendarKey = @"CreateAlertCalendarKey";
NSString * const FC_CreateReminderKey = @"CreateAlertReminderKey";

@interface FCAlarm() {
    EKEventStore *eventStore, *reminderStore;
    EKCalendar *eventCalendar, *reminderCalendar;
    NSNotificationCenter *nc;
    NSMutableArray *eventAlarms, *reminderAlarms;
    BOOL calendarChecked, remindersChecked, anyCalendarsExist, emailChecked, instructionsOpen, emailOpen, allAccountsChecked;
    NSImage *calendarIcon, *calendarCheckedIcon, *remindersIcon, *remindersCheckedIcon;
    NSImage *emailIcon, *emailCheckedIcon;
    NSString *emailAddress;
    
    IBOutlet AccountController *accountController;
    IBOutlet NSViewController *emailController, *instructionController;
    IBOutlet NSBox *container;
    IBOutlet NSView *single_slide0, *single_slide1, *single_slide2, *disableAlarmView;
    IBOutlet NSButton *newAlarmButton, *calendarButton, *remindersButton, *recurCheckBox, *emailButton, *allAccountsButton;
    IBOutlet NSWindow *singleAlarmView;
    IBOutlet NSTextField *daysPrior, *emailField;
    IBOutlet NSPopUpButton *accountSelect;
    IBOutlet NSTableView *alertTable;
}

//Void methods
-(void)displayView:(NSView *)view;
-(void)refreshView;
-(void)createCalendar;
-(void)createReminders;
-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;
-(void)newCalendarEventForAccount:(Accounts *)account;
-(void)newRemindersEventForAccount:(Accounts *)account;
-(void)deleteAllAlarms;
-(void)deleteAlarmWithInfo:(NSDictionary *)alarmInfo;

//Buttons
-(IBAction)newSingleAlarm:(id)sender;
-(IBAction)calendarClicked:(id)sender;
-(IBAction)remindersClicked:(id)sender;
-(IBAction)addAlarm:(id)sender;
-(IBAction)selectEmailAlert:(id)sender;
-(IBAction)singleNextSlide:(id)sender;
-(IBAction)singlePrevSlide:(id)sender;
-(IBAction)emailSubmitted:(id)sender;
-(IBAction)openInstructions:(id)sender;
-(IBAction)mailPreferences:(id)sender;
-(IBAction)disableAlarms:(id)sender;
-(IBAction)allAccountsClicked:(id)sender;
-(IBAction)deleteAccountAlarm:(id)sender;

@property (assign) IBOutlet NSPopover * popover;
@property (readwrite) NSArray *accountAlerts;

@end

@implementation FCAlarm

-(id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    //Access event and reminder stores
    eventStore = [[EKEventStore alloc] initWithAccessToEntityTypes:EKEntityMaskEvent];
    reminderStore = [[EKEventStore alloc] initWithAccessToEntityTypes:EKEntityMaskReminder];
    
    //Initiate all other variables
    eventAlarms = [[NSMutableArray alloc] init];
    reminderAlarms = [[NSMutableArray alloc] init];
    accountAlerts = [[NSArray alloc] init];
    calendarIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"calendar" ofType:@"png"]];
    calendarCheckedIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"calendar_checked" ofType:@"png"]];
    remindersIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"reminders" ofType:@"png"]];
    remindersCheckedIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"reminders_checked" ofType:@"png"]];
    emailIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"email" ofType:@"png"]];
    emailCheckedIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"email_checked" ofType:@"png"]];
    
    nc = [NSNotificationCenter defaultCenter];
    anyCalendarsExist = calendarChecked = remindersChecked = emailChecked = instructionsOpen = emailOpen = allAccountsChecked = NO;
    emailAddress = nil;
    
    return self;
}

-(void)awakeFromNib
{
    //Observer our notification so we know when the main window is being displayed by MyDocument
    [nc addObserver:self
           selector:@selector(createNewCalendar:)
               name:FC_CreateCalendarKey
             object:nil];
    [nc addObserver:self
           selector:@selector(createNewCalendar:)
               name:FC_CreateReminderKey
             object:nil];
    
    [emailButton setEnabled:NO];
    
    //Retrieve events and reminders; compare them to eventAlarms array
    //If any are missing alert the user and give them the option of readding or deleting them
    NSString *calID = [[NSUserDefaults standardUserDefaults] objectForKey:FC_CalendarIDKey];
    NSString *remID = [[NSUserDefaults standardUserDefaults] objectForKey:FC_ReminderIDKey];
    if (calID) {
        eventCalendar = [eventStore calendarWithIdentifier:calID];
        if (!eventCalendar) {
            //Recreate the calendar
            [self createCalendar];
        } else {
            anyCalendarsExist = YES;
        }
    }
    if (remID) {
        reminderCalendar = [reminderStore calendarWithIdentifier:remID];
        if (!reminderCalendar) {
            //Recereate the reminders calendar
            [self createReminders];
        } else {
            anyCalendarsExist = YES;
        }
    }
}

#pragma mark - Alarm Methods

-(IBAction)addAlarm:(id)sender
{
    //Check if all parameters are complete
    if (((!calendarChecked) && (!remindersChecked)) || [[daysPrior stringValue] isEqualToString:@""]) {
        NSRunAlertPanel(@"Form Incomplete",
                        @"All parts of the form are required, except the Email option, to create an alert.",
                        @"OK",
                        nil,
                        nil);
        return;
    }
    
    Accounts *singleAccount = [[accountController arrangedObjects] objectAtIndex:[accountSelect indexOfSelectedItem]];;
    __block NSInteger failed = 0;
    __block NSMutableArray *failedAccounts = [[NSMutableArray alloc] init];
    
    if (calendarChecked) {
        if (!allAccountsChecked) {
            [self newCalendarEventForAccount:singleAccount];
        } else {
            for (Accounts *account in [accountController arrangedObjects]) {
                [self newCalendarEventForAccount:account];
            }
            //Verify that all the events were created
            for (NSDictionary *d in [self eventAlarms]) {
                if (![eventStore eventWithIdentifier:[d objectForKey:FC_AlarmEventKey]]) {
                    failed++;
                    [failedAccounts addObject:[[d objectForKey:FC_AlarmAccountKey] accountName]];
                }
            }
        }
    } else {
        if (!allAccountsChecked) {
            [self newRemindersEventForAccount:singleAccount];
        } else {
            for (Accounts *account in [accountController arrangedObjects]) {
                [self newRemindersEventForAccount:account];
            }
            //Verify that all the events were created
            NSPredicate *predicate = [reminderStore predicateForRemindersInCalendars:[NSArray arrayWithObject:reminderCalendar]];
            [reminderStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *fetchedReminders) {
                for (EKReminder *reminder in fetchedReminders) {
                    if (![reminderAlarms containsObject:[reminder calendarItemIdentifier]]) {
                        failed++;
                        [failedAccounts addObject:@"Unknown"];
                    }
                }
            }];
        }
    }
    if (allAccountsChecked) {
        if (failed > 0) {
            NSRunAlertPanel(@"Failed To Complete",
                            @"%lu alerts could not be created for the following accounts:\n\n%@",
                            @"OK",
                            nil,
                            nil, failed,[failedAccounts componentsJoinedByString:@"\n"]);
        } else {
            NSRunAlertPanel(@"Success!",
                            @"All alerts were created successfully!",
                            @"OK",
                            nil,
                            nil);
        }
    }
    //End the sheet
    [NSApp endSheet:singleAlarmView];
    [singleAlarmView orderOut:sender];
    [self refreshView];
}

-(void)newCalendarEventForAccount:(Accounts *)account
{
    //Create a new event
    EKEvent *newEvent = [EKEvent eventWithEventStore:eventStore];
    [newEvent setCalendar:eventCalendar];
    
    //Set the event components
    NSString *title = [NSString stringWithFormat:@"%@ Payment Due", [account accountName]];
    [newEvent setTitle:title];
    [newEvent setNotes:[NSString stringWithFormat:@"A payment is due on %@",
                        [[account dueDate] descriptionWithCalendarFormat:@"%B %d, %Y" timeZone:nil locale:nil]]];
    [newEvent setStartDate:[account dueDate]];
    [newEvent setEndDate:[account dueDate]];
    [newEvent setAllDay:NO];
    
    //Check if the user wants to make the alert recurring
    if ([recurCheckBox state] == NSOnState) {
        EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly
                                                                              interval:1
                                                                                   end:nil];
        [newEvent addRecurrenceRule:rule];
    }
    
    //Create a new EKAlarm object for the event
    EKAlarm *ekalarm = [EKAlarm alarmWithRelativeOffset:60 * 60 * 24 * ([daysPrior integerValue] * -1)];
    if (emailChecked) {
        [ekalarm setEmailAddress:emailAddress];
    }
    
    //Add the alarm to the EKEvent object
    [newEvent addAlarm:ekalarm];
    
    //Place the EKEvent object and Accounts object in a dictionary in our array
    NSDictionary *alarm = [NSDictionary dictionaryWithObjectsAndKeys:
                           [newEvent eventIdentifier], FC_AlarmEventKey,
                           account, FC_AlarmAccountKey,
                           title, FC_AlarmTitleKey,
                           @"EKEvent", FC_AlarmTypeKey,
                           calendarIcon, FC_AlarmIconKey, nil];
    [eventAlarms addObject:alarm];
    
    //Place the event in the Calendar or Reminders
    NSError *error;
    [eventStore saveEvent:newEvent
                     span:EKSpanFutureEvents
                   commit:YES
                    error:&error];
    if (error) {
        [NSApp presentError:error];
    } else if (!allAccountsChecked) {
        NSRunAlertPanel(@"Success!",
                        @"Your alert has successfully been created.",
                        @"OK",
                        nil,
                        nil);
    }
}

-(void)newRemindersEventForAccount:(Accounts *)account
{
    //Create a new event
    EKReminder *reminder = [EKReminder reminderWithEventStore:reminderStore];
    [reminder setCalendar:reminderCalendar];
    
    //Create an alert date equivalent to dueDate - daysPrior
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day   = [[[account dueDate] descriptionWithCalendarFormat:@"%d" timeZone:nil locale:nil] integerValue];
    components.month = [[[account dueDate] descriptionWithCalendarFormat:@"%m" timeZone:nil locale:nil] integerValue];
    components.year  = [[[account dueDate] descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil] integerValue];
    
    NSString *title = [NSString stringWithFormat:@"%@ Payment Due", [account accountName]];
    [reminder setTitle:title];
    [reminder setNotes:[NSString stringWithFormat:@"A payment is due on %@",
                        [[account dueDate] descriptionWithCalendarFormat:@"%B %d, %Y" timeZone:nil locale:nil]]];
    [reminder setStartDateComponents:components];
    [reminder setDueDateComponents:components];
    
    //Check if the user wants to make the alert recurring
    if ([recurCheckBox state] == NSOnState) {
        EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly
                                                                              interval:1
                                                                                   end:nil];
        [reminder addRecurrenceRule:rule];
    }
    
    //Create a new EKAlarm object for the event
    EKAlarm *ekalarm = [EKAlarm alarmWithRelativeOffset:60 * 60 * 24 * ([daysPrior integerValue] * -1)];
    if (emailChecked) {
        [ekalarm setEmailAddress:emailAddress];
    }
    
    //Add the alarm to the Reminder object
    [reminder addAlarm:ekalarm];
    
    //Place the EKEvent object and Accounts object in a dictionary in our array
    NSDictionary *alarm = [NSDictionary dictionaryWithObjectsAndKeys:
                           [reminder calendarItemIdentifier], FC_AlarmEventKey,
                           account, FC_AlarmAccountKey,
                           title, FC_AlarmTitleKey,
                           @"EKReminder", FC_AlarmTypeKey,
                           remindersIcon, FC_AlarmIconKey, nil];
    [reminderAlarms addObject:alarm];
    
    //Place the event in the Calendar or Reminders
    NSError *error;
    [reminderStore saveReminder:reminder
                         commit:YES
                          error:&error];
    
    //Check for errors
    if (error) {
        [NSApp presentError:error];
    } else if (!allAccountsChecked) {
        NSRunAlertPanel(@"Success!",
                        @"Your alert has successfully been created.",
                        @"OK",
                        nil,
                        nil);
    }
}

-(void)deleteAlarmWithInfo:(NSDictionary *)alarmInfo
{
    __block Accounts *account = [alarmInfo objectForKey:FC_AlarmAccountKey];
    __block NSPredicate *predicate;
    NSString *type = [alarmInfo objectForKey:FC_AlarmTypeKey];
    if ([type isEqualToString:@"EKEvent"]) {
        NSDate *past = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 365 * (-3)];
        NSDate *future = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 32];
        NSPredicate *eventPredicate = [eventStore predicateForEventsWithStartDate:past
                                                                          endDate:future
                                                                        calendars:[NSArray arrayWithObject:eventCalendar]];
        NSArray *fetchedEvents = [eventStore eventsMatchingPredicate:eventPredicate];
        for (EKEvent *event in fetchedEvents) {
            if ([[event eventIdentifier] isEqualToString:[alarmInfo objectForKey:FC_AlarmEventKey]]) {
                [eventStore removeEvent:event
                                   span:EKSpanFutureEvents
                                 commit:YES
                                  error:nil];
                
                //Delete the item from the array
                [eventAlarms removeObject:alarmInfo];
                
                //Update the alert table view
                [self displayAlertsForAccount:account];
            }
        }
    } else if ([type isEqualToString:@"EKReminder"]) {
        predicate = [reminderStore predicateForRemindersInCalendars:[NSArray arrayWithObject:reminderCalendar]];
        [reminderStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *fetchedReminders) {
            for (EKReminder *reminder in fetchedReminders) {
                if ([[reminder calendarItemIdentifier] isEqualToString:[alarmInfo objectForKey:FC_AlarmEventKey]]) {
                    [reminderStore removeReminder:reminder
                                           commit:YES
                                            error:nil];
                    
                    //Delete the item from the array
                    [reminderAlarms removeObject:alarmInfo];
                    
                    //Update the alert table view
                    [self displayAlertsForAccount:account];
                }
            }
        }];
    }
}

-(void)deleteAllAlarms
{
    __block NSError *error;
    NSDate *past = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 365 * (-2)];
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 365];
    NSPredicate *eventPredicate = [eventStore predicateForEventsWithStartDate:past
                                                                      endDate:future
                                                                    calendars:[NSArray arrayWithObject:eventCalendar]];
    NSArray *fetchedEvents = [eventStore eventsMatchingPredicate:eventPredicate];
    for (EKEvent *event in fetchedEvents) {
        for (NSDictionary *d in [self eventAlarms]) {
            if ([[event eventIdentifier] isEqualToString:[d objectForKey:FC_AlarmEventKey]]) {
                [eventStore removeEvent:event
                                   span:EKSpanFutureEvents
                                 commit:YES
                                  error:&error];
            }
        }
    }
    NSPredicate *predicate = [reminderStore predicateForRemindersInCalendars:[NSArray arrayWithObject:reminderCalendar]];
    [reminderStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *fetchedReminders) {
        for (EKReminder *reminder in fetchedReminders) {
            for (NSDictionary *d in reminderAlarms) {
                if ([[reminder calendarItemIdentifier] isEqualToString:[d objectForKey:FC_AlarmEventKey]]) {
                    [reminderStore removeReminder:reminder
                                           commit:YES
                                            error:&error];
                }
            }
        }
    }];
    if (error) {
        [NSApp presentError:error];
    } else {
        NSRunAlertPanel(@"Success!",
                        @"All alarms have been successfully removed!",
                        @"OK",
                        nil,
                        nil);
    }
    [eventAlarms removeAllObjects];
    [reminderAlarms removeAllObjects];
}

#pragma mark - Callback

-(void)createNewCalendar:(NSNotification *)note
{
    if ([[note name] isEqualToString:FC_CreateCalendarKey]) {
        [self createCalendar];
    } else if ([[note  name] isEqualToString:FC_CreateReminderKey]) {
        [self createReminders];
    }
}

-(void)createCalendar
{
    //Get the calendar's source
    NSError *error;
    EKSource *localSource;
    for (EKSource *source in eventStore.sources) {
        if (source.sourceType == EKSourceTypeLocal) {
            localSource = source;
            break;
        }
    }
    if (!localSource) {
        NSRunAlertPanel(@"Operation Failed",
                        @"Could not create new calendar, please try again later.\n"
                        @"If the issue persists contact admin@puffycode.com and inform us.",
                        @"OK",
                        nil,
                        nil);
        return;
    }
    
    //Create the new calendar and reminder
    EKCalendar *newCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent
                                                     eventStore:eventStore];
    //New calendar properties
    NSString *calendarID = [newCalendar calendarIdentifier];
    [newCalendar setTitle:@"FinCom Alerts"];
    [newCalendar setSource:localSource];
    
    //Save the new calendar
    [eventStore saveCalendar:newCalendar
                      commit:YES
                       error:&error];
    if (error) {
        [NSApp presentError:error];
    } else {
        //Save the identifier in the users defaults database
        [[NSUserDefaults standardUserDefaults] setObject:calendarID forKey:FC_CalendarIDKey];
        
        //Set the current alertCalendar
        eventCalendar = newCalendar;
        
        //Set anyCalendarsExist to YES
        anyCalendarsExist = YES;
    }
}

-(void)createReminders
{
    //Get the calendar's source
    NSError *error;
    EKSource *localSource;
    for (EKSource *source in reminderStore.sources) {
        if (source.sourceType == EKSourceTypeLocal) {
            localSource = source;
            break;
        }
    }
    if (!localSource) {
        NSRunAlertPanel(@"Operation Failed",
                        @"Could not create new calendar, please try again later.\n"
                        @"If the issue persists contact admin@puffycode.com and inform us.",
                        @"OK",
                        nil,
                        nil);
        return;
    }
    
    EKCalendar *newReminder = [EKCalendar calendarForEntityType:EKEntityTypeReminder
                                                     eventStore:reminderStore];
    
    //New Reminder properties
    NSString *reminderID = [newReminder calendarIdentifier];
    [newReminder setTitle:@"FinCom Alerts"];
    [newReminder setSource:localSource];
    
    //Save the new reminder
    [reminderStore saveCalendar:newReminder
                         commit:YES
                          error:&error];
    if (error) {
        [NSApp presentError:error];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:reminderID forKey:FC_ReminderIDKey];
        
        //Set the current alertReminder
        reminderCalendar = newReminder;
        
        //Set anyCalendarsExist to YES
        anyCalendarsExist = YES;
    }
}

#pragma mark - Buttons

-(IBAction)newSingleAlarm:(id)sender
{
    if ([sender tag] == OPEN) {
        [NSApp beginSheet:singleAlarmView
           modalForWindow:[newAlarmButton window]
            modalDelegate:self
           didEndSelector:nil
              contextInfo:NULL];
        [self displayView:single_slide0];
    } else if ([sender tag] == CLOSE) {
        [NSApp endSheet:singleAlarmView];
        [singleAlarmView orderOut:sender];
        [self displayView:nil];
        [self refreshView];
    }
}

-(IBAction)disableAlarms:(id)sender
{
    if ([[self eventAlarms] count] < 1 && [[self reminderAlarms] count] < 1) {
        NSRunAlertPanel(@"No Alerts Found",
                        @"There are no alerts to disable.  Therefore, my job is finished.",
                        @"OK",
                        nil,
                        nil);
        return;
    }
    
    if ([sender tag] == OPEN) {
        [NSApp beginSheet:singleAlarmView
           modalForWindow:[newAlarmButton window]
            modalDelegate:self
           didEndSelector:nil
              contextInfo:NULL];
        [self displayView:disableAlarmView];
    } else if ([sender tag] == CLOSE) {
        [NSApp endSheet:singleAlarmView];
        [singleAlarmView orderOut:sender];
        [self displayView:nil];
    } else if ([sender tag] == CONFIRM) {
        [self deleteAllAlarms];
        [NSApp endSheet:singleAlarmView];
        [singleAlarmView orderOut:sender];
        [self displayView:nil];
    }
}

-(IBAction)singleNextSlide:(id)sender
{
    if ([sender tag] == S_SLIDE0) {
        if ([[accountController arrangedObjects] count] < 1) {
            NSRunAlertPanel(@"No Accounts Found",
                            @"There are no accounts to set alerts for.  Come back when you have created some.",
                            @"OK",
                            nil,
                            nil);
            return;
        }
        [self displayView:single_slide1];
    } else if ([sender tag] == S_SLIDE1) {
        [self displayView:single_slide2];
    }
}

-(IBAction)singlePrevSlide:(id)sender
{
    if ([sender tag] == S_SLIDE2) {
        [self displayView:single_slide1];
    }
}

-(IBAction)calendarClicked:(id)sender
{
    if (calendarChecked) {
        return;
    }
    [sender setImage:calendarCheckedIcon];
    [remindersButton setImage:remindersIcon];
    [emailButton setEnabled:YES];
    
    calendarChecked = YES;
    remindersChecked = NO;
}

-(IBAction)remindersClicked:(id)sender
{
    if (remindersChecked) {
        return;
    }
    [sender setImage:remindersCheckedIcon];
    [calendarButton setImage:calendarIcon];
    [emailButton setEnabled:NO];
    
    remindersChecked = YES;
    calendarChecked = NO;
}

-(IBAction)openInstructions:(id)sender
{
    if (!emailOpen) {
        if (instructionsOpen) {
            [[self popover] close];
            instructionsOpen = NO;
        } else {
            [self displayPopOver:[self popover]
              withViewController:instructionController
                          ofView:sender
                          onEdge:NSMinYEdge];
            instructionsOpen = YES;
        }
    }
}

-(IBAction)mailPreferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/InternetAccounts.prefPane"];
}

-(IBAction)allAccountsClicked:(id)sender
{
    if ([sender state] == NSOnState) {
        allAccountsChecked = YES;
        [accountSelect setEnabled:NO];
    } else {
        allAccountsChecked = NO;
        [accountSelect setEnabled:YES];
    }
}

#pragma mark - Account Alert Methods

-(void)displayAlertsForAccount:(Accounts *)account
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@", FC_AlarmAccountKey, account];
    [self setAccountAlerts:[[eventAlarms arrayByAddingObjectsFromArray:reminderAlarms] filteredArrayUsingPredicate:searchPredicate]];
}

-(IBAction)deleteAccountAlarm:(id)sender
{
    if ([alertTable selectedRow] < 0) {
        return;
    }
    NSDictionary *selectedAlert = [accountAlerts objectAtIndex:[alertTable selectedRow]];
    [self deleteAlarmWithInfo:selectedAlert];
}

#pragma mark - Email Methods

-(IBAction)selectEmailAlert:(id)sender
{
    if (!instructionsOpen) {
        //Check if the popover is already open
        if ([[self popover] isShown]) {
            [[self popover] close];
            emailOpen = NO;
        }
        
        if (emailChecked) {
            emailChecked = NO;
            [emailButton setImage:emailIcon];
        } else {
            emailChecked = YES;
            [self displayPopOver:[self popover]
              withViewController:emailController
                          ofView:sender
                          onEdge:NSMinYEdge];
            [emailButton setImage:emailCheckedIcon];
            emailOpen = YES;
        }
    }
}

-(IBAction)emailSubmitted:(id)sender
{
    if ([[emailField stringValue] isEqualToString:@""]) {
        NSRunAlertPanel(@"Missing Email Address",
                        @"You must enter a valid email address to continue.",
                        @"OK",
                        nil,
                        nil);
        return;
    }
    emailAddress = [emailField stringValue];
    [[self popover] close];
    emailOpen = NO;
}

#pragma mark - Display Methods

-(void)displayView:(NSView *)view
{
    //Check if the view is already set
    if ([container contentView] == view) {
        return;
    }
    
    //Hide view
    [view setAlphaValue:0.0];
    
    //Place the new view in the container
    [container setContentView:view];
    
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

-(void)refreshView
{
    [calendarButton setImage:calendarIcon];
    [remindersButton setImage:remindersIcon];
    [emailButton setImage:emailIcon];
    [allAccountsButton setState:NSOffState];
    calendarChecked = NO;
    remindersChecked = NO;
    [daysPrior setStringValue:@""];
    [recurCheckBox setState:NSOffState];
    [emailField setStringValue:@""];
    [emailButton setEnabled:NO];
    [self displayView:nil];
}

#pragma mark - Synthesizers

@synthesize eventAlarms, reminderAlarms;
@synthesize anyCalendarsExist;
@synthesize popover;
@synthesize accountAlerts;

@end