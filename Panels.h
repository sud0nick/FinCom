//
//  Panels.h
//  FinCom
//
//  Created by Nick Combs on 9/18/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AboutPanel;

@interface Panels : NSObject {
	AboutPanel *aboutPanel;
}

-(IBAction)showAboutPanel:(id)sender;

@end