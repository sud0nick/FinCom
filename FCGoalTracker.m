//
//  FCGoalTracker.m
//  FinCom
//
//  Created by Nick on 1/23/13.
//
//

#import "FCGoalTracker.h"

NSString const * GT_TitleKey         = @"GoalTrackerTitleKey";
NSString const * GT_SummaryKey       = @"GoalTrackerSummaryKey";
NSString const * GT_ProgressKey      = @"GoalTrackerProgressKey";
NSString const * GT_GoalAccountKey   = @"GoalTrackerGoalAccountKey";
NSString const * GT_DeadlineKey      = @"GoalTrackerDeadlineKey";
NSString const * GT_GoalValueKey     = @"GoalTrackerGoalValueKey";
NSString const * GT_CurrentValueKey  = @"GoalTrackerCurrentValueKey";
NSString const * GT_GoalLogicKey     = @"GoalTrackerLogicKey";
NSString const * GT_InitialValueKey  = @"GoalTrackerInitialValueKey";
NSString const * GT_DeleteKey        = @"GoalTrackerDeleteWhenCompleteKey";
NSString const * GT_DeadlineAlertKey = @"GoalTrackerDealineAlertKey";

//NSString const * GT_UserAlertedKey   = @"GoalTrackerUserAlertedKey";

//External key to get self deleted
NSString const * GT_ReadyToDie = @"GoalTrackerGoalCompleteAndReadyToDie";

@interface FCGoalTracker() {
    NSString *title, *summary, *goalAccount, *goalLogic, *progLabel;
    NSDate *deadline;
    double progress, goalValue, currentValue, initialValue;
    BOOL deleteWhenComplete, deadlineAlerted;
}

@end

@implementation FCGoalTracker

-(id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    [self setTitle:@"New Goal"];
    [self setSummary:@"No summary"];
    [self setGoalAccount:@""];
    [self setGoalLogic:@""];
    [self setInitialValue:0.0];
    [self setCurrentValue:0.0];
    [self setGoalValue:0.0];
    [self setProgress:0.0];
    [self setDeadline:[NSDate date]];
    //userAlerted = NO;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:title forKey:(NSString *)GT_TitleKey];
    [aCoder encodeObject:summary forKey:(NSString *)GT_SummaryKey];
    [aCoder encodeObject:goalAccount forKey:(NSString *)GT_GoalAccountKey];
    [aCoder encodeObject:goalLogic forKey:(NSString *)GT_GoalLogicKey];
    [aCoder encodeObject:deadline forKey:(NSString *)GT_DeadlineKey];
    [aCoder encodeDouble:goalValue forKey:(NSString *)GT_GoalValueKey];
    [aCoder encodeDouble:progress forKey:(NSString *)GT_ProgressKey];
    [aCoder encodeDouble:currentValue forKey:(NSString *)GT_CurrentValueKey];
    [aCoder encodeDouble:initialValue forKey:(NSString *)GT_InitialValueKey];
    [aCoder encodeBool:deleteWhenComplete forKey:(NSString *)GT_DeleteKey];
    [aCoder encodeBool:deadlineAlerted forKey:(NSString *)GT_DeadlineAlertKey];
    //[aCoder encodeBool:userAlerted forKey:(NSString *)GT_UserAlertedKey];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super init])) {
        return nil;
    }
    
    title               = [aDecoder decodeObjectForKey:(NSString *)GT_TitleKey];
    summary             = [aDecoder decodeObjectForKey:(NSString *)GT_SummaryKey];
    goalAccount         = [aDecoder decodeObjectForKey:(NSString *)GT_GoalAccountKey];
    goalLogic           = [aDecoder decodeObjectForKey:(NSString *)GT_GoalLogicKey];
    deadline            = [aDecoder decodeObjectForKey:(NSString *)GT_DeadlineKey];
    goalValue           = [aDecoder decodeDoubleForKey:(NSString *)GT_GoalValueKey];
    progress            = [aDecoder decodeDoubleForKey:(NSString *)GT_ProgressKey];
    currentValue        = [aDecoder decodeDoubleForKey:(NSString *)GT_CurrentValueKey];
    initialValue        = [aDecoder decodeDoubleForKey:(NSString *)GT_InitialValueKey];
    deleteWhenComplete  = [aDecoder decodeBoolForKey:(NSString *)GT_DeleteKey];
    deadlineAlerted     = [aDecoder decodeBoolForKey:(NSString *)GT_DeadlineAlertKey];
    //userAlerted         = [aDecoder decodeBoolForKey:(NSString *)GT_UserAlertedKey];
    
    //Don't know why I have to call this myself...I shouldn't.
    //But if I don't it doesn't happen...
    [self awakeFromNib];
    
    return self;
}

-(void)awakeFromNib
{
    [self calculateProgress];
}

-(BOOL)passedDeadline
{
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:flags fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:components];
    
    if ([today isEqualToDate:deadline]) {
        return NO;
    } else if ([today isEqualTo:[deadline laterDate:today]]) {
        return YES;
    }
    return NO;
}

-(void)calculateProgress
{
    //Both Less Than and Less Than or Equal To
    if ([[self goalLogic] rangeOfString:@"Less Than"].length > 0) {
        if (currentValue <= goalValue) {
            [self setProgress:100.0];
        } else if (currentValue >= goalValue) {
            [self setProgress:0.00];
        } else {
            if ([[self goalLogic] rangeOfString:@"Equal To"].length > 0) {
                [self setProgress:((initialValue - currentValue) / (initialValue - goalValue)) * 100];
            } else {
                [self setProgress:((initialValue - currentValue) / (initialValue - (goalValue - 1))) * 100];
            }
        }
    } else if ([[self goalLogic] rangeOfString:@"Greater Than"].length > 0) {
        if ([[self goalLogic] rangeOfString:@"Equal To"].length > 0) {
            [self setProgress:(currentValue / goalValue) * 100];
        } else {
            [self setProgress:(currentValue / (goalValue + 1)) * 100];
        }
    } else {
        [self setProgress:(currentValue / goalValue) * 100];
    }
    //Check if goal has been met
    if (progress >= 100) {
        /*
        if (!userAlerted) {
            userAlerted = YES;
            NSRunAlertPanel(@"Congratulations",
                            @"You have reached the goal you set for your %@ account!",
                            @"YAY!",
                            nil,
                            nil, [self goalAccount]);
        }
         */
        [self setProgress:100];
        //Commit suicide
        if (deleteWhenComplete) {
            [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)GT_ReadyToDie object:self];
        }
    }
    //Set the label so the user sees the percentage value
    [self setValue:[NSString stringWithFormat:@"%.2f%%", progress] forKey:@"progLabel"];
}

@synthesize title, summary, goalAccount, goalLogic;
@synthesize deadline;
@synthesize progress, goalValue, currentValue, initialValue;
@synthesize deleteWhenComplete, deadlineAlerted;

@end