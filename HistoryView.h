//
//  HistoryView.h
//  FinCom
//
//  Created by Nick Combs on 10/8/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HistoryView : NSView {
	NSBezierPath *path;
	NSMutableArray *logStrings, *changeStrings;
	NSMutableDictionary *attributes;
	
	int x;
}

-(void)clearLog;
-(void)createTable;
-(void)prepareAttributes;
-(void)setLogDetails:(NSMutableArray *)details;
-(void)drawString:(NSString *)string AtDistanceFromOrigin:(CGFloat)distO AndLastString:(CGFloat)distL;

@end