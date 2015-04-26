//
//  FCGoalTracker.h
//  FinCom
//
//  Created by Nick on 1/23/13.
//
//

#import <Foundation/Foundation.h>

extern NSString const * GT_ReadyToDie;

@interface FCGoalTracker : NSObject <NSCoding> {
}

-(BOOL)passedDeadline;
-(void)calculateProgress;

@property (readwrite) NSString *title, *summary, *goalAccount, *goalLogic;
@property (readwrite) NSDate *deadline;
@property (readwrite) double progress, goalValue, currentValue, initialValue;
@property (readwrite) BOOL deleteWhenComplete, deadlineAlerted;

@end