//
//  AboutPanel.m
//  FinCom
//
//  Created by Nick Combs on 9/18/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "AboutPanel.h"


@implementation AboutPanel

-(id)init
{
	BOOL successful = [NSBundle loadNibNamed:@"AboutPanel" owner:self];
	if (!successful)
		return nil;
	return self;
}

-(IBAction)closePanel:(id)sender
{
	[self close];
}

@end