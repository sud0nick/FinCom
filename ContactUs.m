//
//  ContactUs.m
//  FinCom
//
//  Created by Nicholas Combs on 4/4/12.
//  Copyright (c) 2012 PuffyCode. All rights reserved.
//

#import "ContactUs.h"

@implementation ContactUs

-(IBAction)emailUs:(id)sender
{
    NSURL *contact = [NSURL URLWithString:@"http://www.puffycode.com/contact.php"];
    [[NSWorkspace sharedWorkspace] openURL:contact];
}

-(IBAction)installFont:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/AppleCasual.dfont",
                                             [[NSBundle mainBundle] resourcePath]]];
}

@end