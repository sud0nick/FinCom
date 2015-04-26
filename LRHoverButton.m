//
//  LRHoverButton.m
//  Local Rhythm
//
//  Created by Nick on 12/18/12.
//  Copyright (c) 2012 PuffyCode. All rights reserved.
//

#import "LRHoverButton.h"

@implementation LRHoverButton

-(void)awakeFromNib
{
    baseRect = [self frame];
    [self createTrackingArea];
}

-(void)resetPosition
{
    [self mouseExited:nil];
}

-(void)createTrackingArea
{
    NSTrackingAreaOptions focusTrackingAreaOptions = NSTrackingActiveInActiveApp;
    focusTrackingAreaOptions |= NSTrackingMouseEnteredAndExited;
    focusTrackingAreaOptions |= NSTrackingInVisibleRect;
    
    NSTrackingArea *focusTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                                     options:focusTrackingAreaOptions owner:self userInfo:nil];
    [self addTrackingArea:focusTrackingArea];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [self displayPopOver:[self popOver]
      withViewController:controller
                  ofView:self
                  onEdge:NSMinYEdge];
    
    //Set our description in the shared space
    [[sharedLabel animator] setHidden:YES];
    [sharedLabel setStringValue:description.stringValue];
    [[sharedLabel animator] setHidden:NO];
    
    NSRect newRect = baseRect;
    newRect.origin.y += 20;
    [[self animator] setFrame:newRect];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [sharedLabel setStringValue:@""];
    [[self popOver] close];
    [[self animator] setFrame:baseRect];
}

-(void)displayPopOver:(NSPopover *)pO
   withViewController:(NSViewController *)vc
               ofView:(id)sender
               onEdge:(NSRectEdge)edge
{
    [pO setContentViewController:vc];
    [pO showRelativeToRect:[sender bounds] ofView:sender preferredEdge:edge];
}

@synthesize popOver;

@end