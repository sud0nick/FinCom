//
//  Withdrawals.h
//  FinCom
//
//  Created by Nick Combs on 10/29/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Withdrawals : NSObject <NSCoding> {
	NSString *fromAccount, *toAccount, *type, *recurString;
	float amount;
	NSDate *withdrawDate;
	BOOL shouldDelete;
}

-(void)setDate:(NSDate *)newDate;

@property (readwrite, copy) NSString *fromAccount, *toAccount, *type, *recurString;
@property (readwrite, copy) NSDate *withdrawDate;
@property float amount;
@property BOOL shouldDelete;

@end