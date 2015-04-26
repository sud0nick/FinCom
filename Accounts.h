//
//  Accounts.h
//  FinCom
//
//  Created by Nick Combs on 8/21/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const AccountUpdateNotification;
extern NSString * const HistoryContent;

@interface Accounts : NSObject <NSCoding> {
	NSString *accountName, *category;
	NSDate *dueDate;
	double accountBalance;
	NSMutableArray *history;
	NSNotificationCenter *nc;
}

-(void)becomeObserver;

@property (readwrite, copy) NSString *category, *accountName;
@property (readwrite, copy) NSDate *dueDate;
@property double accountBalance;

@end