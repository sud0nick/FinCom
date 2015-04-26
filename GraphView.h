//
//  GraphView.h
//  Bar Graph
//
//  Created by Nick Combs on 9/19/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const GVPopUpContent;

@interface GraphView : NSView {
	NSBezierPath *path;
	NSMutableArray *pointsArray, *accountNames, *accountBals;
	CGFloat prevXOrig, maxAccount, zoom, savingsAmount, checkingAmount;
	NSColor *barColor, *viewColor;
	NSMutableDictionary *attributes;
	NSNotificationCenter *nc;
	
	IBOutlet NSPopUpButton *categoryContent;
	IBOutlet NSButton *prev, *next;
	
	int start, end;
}

/* Available user methods */
-(void)createGraphWithAccountValues:(NSMutableArray *)accounts AndNames:(NSMutableArray *)names;
-(void)clearFrame;
-(void)setViewColor:(NSColor *)color;

/* Methods hidden from users */
-(IBAction)popUpSelected:(id)sender;
-(void)prepareAttributes;
-(NSString *)separateAndFormatString:(NSString *)string;
-(void)drawString:(NSString *)string AtDistanceFromOrigin:(CGFloat)distO andBar:(CGFloat)distB;
-(NSRect)makeBar:(CGFloat)height;
-(IBAction)viewNext:(id)sender;
-(IBAction)viewPrev:(id)sender;

@property CGFloat savingsAmount, checkingAmount;

@end