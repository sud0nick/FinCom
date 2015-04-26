//
//  Accounts.m
//  FinCom
//
//  Created by Nick Combs on 8/21/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

/*
 *** NOTE ***
 The Accounts class holds the account name and balance for each account.  The accountsArray in MyDocument
 holds an instance of this class for each new account created.
*/

#import "MyDocument.h"
#import "Accounts.h"
#import "HistoryView.h"

NSString * const NamePath = @"accountName";
NSString * const BalancePath = @"accountBalance";
NSString * const HistoryPath = @"history";
NSString * const HistoryContent = @"historyLogContent";
NSString * const CategoryPath = @"category";
NSString * const DueDatePath = @"dueDate";

NSString * const AccountUpdateNotification = @"FC_AccountUpdateNotification";

@implementation Accounts

-(id)init
{
	if (!(self = [super init])) return nil;
	accountName = @"New Account";
	category = @"None";
	accountBalance = 0.00;
	dueDate = [[NSDate date] dateWithCalendarFormat:@"%m/%d/%y" timeZone:nil];
	history = [[NSMutableArray alloc] init];
	
	[self becomeObserver];
	
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:accountName forKey:NamePath];
	[coder encodeObject:category forKey:CategoryPath];
	[coder encodeDouble:accountBalance forKey:BalancePath];
	[coder encodeObject:history forKey:HistoryPath];
	[coder encodeObject:dueDate forKey:DueDatePath];
}

-(id)initWithCoder:(NSCoder *)coder
{
	if (!(self = [super init])) return nil;
	accountName = [coder decodeObjectForKey:NamePath];
	category = [coder decodeObjectForKey:CategoryPath];
	dueDate = [coder decodeObjectForKey:DueDatePath];
	history = [coder decodeObjectForKey:HistoryPath];
	accountBalance = [coder decodeDoubleForKey:BalancePath];
	
	[self becomeObserver];
	
	return self;
}

-(void)becomeObserver
{
	[self addObserver:self
		   forKeyPath:NamePath
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:NULL];
	
	[self addObserver:self
		   forKeyPath:BalancePath
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:NULL];
	
	[self addObserver:self
		   forKeyPath:CategoryPath
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:NULL];
	
	[self addObserver:self
		   forKeyPath:DueDatePath
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:NULL];
	
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(handleNote:)
			   name:HistoryNotification
			 object:nil];
}

-(void)dealloc
{
	[nc removeObserver:self name:HistoryNotification object:nil];
	[self removeObserver:self forKeyPath:NamePath];
	[self removeObserver:self forKeyPath:BalancePath];
	[self removeObserver:self forKeyPath:CategoryPath];
	[self removeObserver:self forKeyPath:DueDatePath];
	history = nil;
}

-(void)handleNote:(NSNotification *)note
{
    if ([[note name] isEqualToString:HistoryNotification]) {
        NSString *msgName = [[note userInfo] objectForKey:@"name"];
        if ([msgName isEqualToString:accountName]) {
            NSDictionary *d = [NSDictionary dictionaryWithObject:history forKey:HistoryContent];
            [nc postNotificationName:HistoryCallBack object:self userInfo:d];
        }
    }
	return;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{	
	//Get the old value of the changed key
	id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    id oldVal = [change objectForKey:NSKeyValueChangeOldKey];
	NSString *changeString, *histString;
	
	if (newVal == [NSNull null])
		return;
	
#pragma mark Observe Due Date
	//Compare new dueDate to current date to make sure the new date has not already passed.
	if ([keyPath isEqualToString:DueDatePath]) {
        if ([newVal isEqualTo:[[NSDate date] earlierDate:newVal]]) {
            [nc postNotificationName:DateAlertCB object:self];
			dueDate = [change objectForKey:NSKeyValueChangeOldKey];
			return;
        }
	}
	
	//Allow only 20 logs in history
	if ([history count] > 20)
		[history removeObjectAtIndex:0];
	
#pragma mark Observe NamePath
	if ([keyPath isEqualToString:NamePath]) {
        if ([newVal isEqualToString:oldVal]) return;
		//If the string is too long
		if ([newVal length] > 25)
			newVal = [NSString stringWithFormat:@"%@...", [newVal substringToIndex:20]];
		
		//If there are more than two words in the string only include the first two
		NSArray *tempArray = [newVal componentsSeparatedByString:@" "];
		if ([tempArray count] > 2)
			newVal = [NSString stringWithFormat:@"%@ %@...", [tempArray objectAtIndex:0], [tempArray objectAtIndex:1]];
		
		histString = [NSString stringWithFormat:@"New Account Name\t\t\t %@", newVal];
		
#pragma mark Observe BalancePath
	} else if ([keyPath isEqualToString:BalancePath]) {
        if ([newVal floatValue] == [oldVal floatValue]) return;
		histString = [NSString stringWithFormat:@"New Balance\t\t\t\t %.2f", [newVal floatValue]];
        
        //Post an update for FCGoalTrackerController
        [nc postNotificationName:AccountUpdateNotification object:self];
	
#pragma mark Observe CategoryPath
	} else if ([keyPath isEqualToString:CategoryPath]) {
        if ([newVal isEqualToString:oldVal]) return;
		histString = [NSString stringWithFormat:@"New Category\t\t\t\t %@", newVal];
	} else
		//Something went wrong...bail
		return;
	
	changeString = [[NSDate date] descriptionWithCalendarFormat:@"%H:%M:%S on %b %d, %Y" timeZone:nil locale:nil];
	
	NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:histString, @"hist", changeString, @"change", nil];
	[history addObject:d];
}

@synthesize category, accountName;
@synthesize dueDate;
@synthesize accountBalance;

@end