//
//  Withdrawals.m
//  FinCom
//
//  Created by Nick Combs on 10/29/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "Withdrawals.h"

NSString * const FromAccountNameKey = @"WI_FR_Acc_Name";
NSString * const ToAccountNameKey = @"WI_TO_Acc_Name";
NSString * const RecurStringKey = @"WI_RecurString_Key";
NSString * const TypeKey = @"WI_Type_Key";
NSString * const DateKey = @"WI_Date_Key";
NSString * const AmountKey = @"WI_Amount_Key";

@implementation Withdrawals

-(id)init
{
	if (!(self = [super init])) return nil;
	fromAccount = [NSString string];
	toAccount = [NSString string];
	recurString = [NSString string];
	type = [NSString string];
	withdrawDate = [NSDate date];
	[self setShouldDelete:NO];
	amount = 0.00;
	return self;
}

-(id)initWithCoder:(NSCoder *)coder
{
	if (!(self = [super init])) return nil;
	fromAccount = [coder decodeObjectForKey:FromAccountNameKey];
	toAccount = [coder decodeObjectForKey:ToAccountNameKey];
	recurString = [coder decodeObjectForKey:RecurStringKey];
	type = [coder decodeObjectForKey:TypeKey];
	withdrawDate = [coder decodeObjectForKey:DateKey];
	amount = [coder decodeFloatForKey:AmountKey];
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:fromAccount forKey:FromAccountNameKey];
	[coder encodeObject:toAccount forKey:ToAccountNameKey];
	[coder encodeObject:recurString forKey:RecurStringKey];
	[coder encodeObject:type forKey:TypeKey];
	[coder encodeObject:withdrawDate forKey:DateKey];
	[coder encodeFloat:amount forKey:AmountKey];
}

-(void)setDate:(NSDate *)newDate
{
	if (newDate == withdrawDate)
		return;
	withdrawDate = newDate;
}


@synthesize fromAccount, toAccount, type, recurString;
@synthesize withdrawDate;
@synthesize amount;
@synthesize shouldDelete;

@end