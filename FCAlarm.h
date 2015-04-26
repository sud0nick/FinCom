//
//  FCAlarm.h
//  FinCom
//
//  Created by Nick on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "Accounts.h"

extern NSString * const FC_CreateCalendarKey;
extern NSString * const FC_CreateReminderKey;

#define OPEN    0
#define CLOSE   1
#define CONFIRM 2
#define S_SLIDE0 0
#define S_SLIDE1 1
#define S_SLIDE2 2

@interface FCAlarm : NSObject {
}

-(void)displayAlertsForAccount:(Accounts *)account;

@property (readonly) BOOL anyCalendarsExist;
@property (readwrite) NSMutableArray * eventAlarms, *reminderAlarms;

@end