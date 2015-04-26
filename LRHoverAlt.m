//
//  LRHoverAlt.m
//  Local Rhythm
//
//  Created by Nick on 1/6/13.
//  Copyright (c) 2013 PuffyCode. All rights reserved.
//

#import "LRHoverAlt.h"

@interface LRHoverAlt() {
}

@end

@implementation LRHoverAlt

-(void)awakeFromNib
{
    baseRect = [self frame];
    [self createTrackingArea];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    //Display the info popover
    [self displayPopOver:[self popOver]
      withViewController:controller
                  ofView:self
                  onEdge:NSMinYEdge];
    
    NSRect newRect = baseRect;
    newRect.origin.y += 5;
    [[self animator] setFrame:newRect];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [[self popOver] close];
    [[self animator] setFrame:baseRect];
}

@end