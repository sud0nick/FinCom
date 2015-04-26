//
//  HistoryView.m
//  FinCom
//
//  Created by Nick Combs on 10/8/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "HistoryView.h"

#define TYPE_DIST        10.0
#define CHANGE_DIST     181.0
#define TIME_DIST       350.0
#define PREV_DIST_START 427.0
#define CENTER_W    (self.bounds.size.width / 2)
#define CENTER_H    (self.bounds.size.height / 2)

@implementation HistoryView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        logStrings = [[NSMutableArray alloc] init];
		changeStrings = [[NSMutableArray alloc] init];
		[self prepareAttributes];
    }
    return self;
}

-(void)dealloc
{
    [self clearLog];
	logStrings = nil;
	changeStrings = nil;
	attributes = nil;
}

-(void)prepareAttributes
{
	attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Apple Casual" size:12.5] forKey:NSFontAttributeName];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
	[[NSColor clearColor] set];
	[NSBezierPath fillRect:bounds];
	
	[self createTable];
	
	NSArray *titles = [NSArray arrayWithObjects:@"Change Type", @"Change Made", @"Change Time", nil];
	[self drawString:[titles objectAtIndex:0] AtDistanceFromOrigin:TYPE_DIST AndLastString:(bounds.size.height - 19)];
	[self drawString:[titles objectAtIndex:1] AtDistanceFromOrigin:CHANGE_DIST AndLastString:(bounds.size.height - 19)];
	[self drawString:[titles objectAtIndex:2] AtDistanceFromOrigin:TIME_DIST AndLastString:(bounds.size.height - 19)];
	
	CGFloat prevDist = PREV_DIST_START;
	
	for (x = 0; x < [logStrings count]; x++) {
		[self drawString:[logStrings objectAtIndex:x] AtDistanceFromOrigin:TYPE_DIST AndLastString:(prevDist - 20)];
		prevDist -= 20;
	}

	for (x = 0, prevDist = PREV_DIST_START; x < [changeStrings count]; x++) {
		[self drawString:[changeStrings objectAtIndex:x]
	AtDistanceFromOrigin:TIME_DIST
		   AndLastString:(prevDist - 20)];
		prevDist -= 20;
	}
}

-(void)createTable
{
	NSRect bounds = [self bounds];
	[[NSColor blackColor] set];
	
	path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, (bounds.size.height - 20), (CENTER_W * 2), 20)];
	[path stroke];
	
	path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, (CHANGE_DIST - 7), ((CENTER_H * 2) - 20))];
	[path stroke];
	
	path = [NSBezierPath bezierPathWithRect:NSMakeRect((CHANGE_DIST - 5), 0, (CHANGE_DIST - 10), ((CENTER_H * 2) - 20))];
	[path stroke];
	
	path = [NSBezierPath bezierPathWithRect:NSMakeRect((TIME_DIST - 5), 0, (CENTER_W - 76), ((CENTER_H * 2) - 20))];
	[path stroke];
}

-(void)drawString:(NSString *)string AtDistanceFromOrigin:(CGFloat)distO AndLastString:(CGFloat)distL
{
	NSPoint strPoint;
	strPoint.x = distO;
	strPoint.y = distL;
	[string drawAtPoint:strPoint withAttributes:attributes];
}

-(void)setLogDetails:(NSMutableArray *)details
{	
	for (x = 0; x < [details count]; x++) {
		[logStrings addObject:[[details objectAtIndex:x] objectForKey:@"hist"]];
		[changeStrings addObject:[[details objectAtIndex:x] objectForKey:@"change"]];
	}
}

-(void)clearLog
{
	[logStrings removeAllObjects];
	[changeStrings removeAllObjects];
	[self setNeedsDisplay:YES];
}

@end