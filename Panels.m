//
//  Panels.m
//  FinCom
//
//  Created by Nick Combs on 9/18/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "Panels.h"
#import "AboutPanel.h"

@implementation Panels

-(IBAction)showAboutPanel:(id)sender
{
	if (!aboutPanel)
		aboutPanel = [[AboutPanel alloc] init];
	[aboutPanel showWindow:self];
}

@end