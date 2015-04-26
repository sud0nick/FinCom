//
//  LRHoverButton.h
//  Local Rhythm
//
//  Created by Nick on 12/18/12.
//  Copyright (c) 2012 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LRHoverButton : NSButton {
    IBOutlet NSViewController *controller;
    IBOutlet NSTextField *sharedLabel, *description;
    NSRect baseRect;
}

-(void)resetPosition;
-(void)createTrackingArea;
-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge;

@property (weak) IBOutlet NSPopover * popOver;

@end