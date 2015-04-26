//
//  GraphView.m
//  Bar Graph
//
//  Created by Nick Combs on 9/19/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "GraphView.h"
#import "MyDocument.h"

#define START_POINT_X_AXIS -60
#define START_POINT_Y_AXIS  40
#define PERC_HEIGHT         50
#define NAME_TABLE_HEIGHT   38
#define NUM_TO_DISPLAY      8
#define TOP_POINT          (self.bounds.size.height - 65.0)

NSString * const GVPopUpContent = @"GraphViewPopUpContentKey";

@implementation GraphView

-(id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		start = 0;
		end = NUM_TO_DISPLAY;
		
		accountNames = [[NSMutableArray alloc] init];
		pointsArray = [[NSMutableArray alloc] init];
		accountBals = [[NSMutableArray alloc] init];
		
		[self setViewColor:[NSColor clearColor]];
		savingsAmount = checkingAmount = 0;
		prevXOrig = START_POINT_X_AXIS;
		
		[self prepareAttributes];
		
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(handlePopUpContent:)
				   name:GVPopUpContent
				 object:nil];
    }
    return self;
}

-(void)dealloc
{
	[nc removeObserver:self name:GVPopUpContent object:nil];
	
	pointsArray = nil;
	
	accountNames = nil;
	
	accountBals = nil;
	
	attributes = nil;
	
}

-(void)handlePopUpContent:(NSNotification *)note
{
	//MyDocument sends content and requests that it receives the user's selection
	NSArray *temp = [[note userInfo] objectForKey:@"selContent"];
	[categoryContent removeAllItems];
	[categoryContent addItemsWithTitles:temp];
}

-(IBAction)popUpSelected:(id)sender
{
	//Send the user's selection back to MyDocument
	NSString *selString = [categoryContent titleOfSelectedItem];
	NSDictionary *d = [NSDictionary dictionaryWithObject:selString forKey:@"selString"];
	[nc postNotificationName:PopUpCallBack object:self userInfo:d];
}

-(void)prepareAttributes
{
	attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Apple Casual" size:13] forKey:NSFontAttributeName];
}

#pragma mark Drawing

-(void)drawRect:(NSRect)dirtyRect {
	[viewColor set];
	[NSBezierPath fillRect:[self bounds]];

	path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 1, self.bounds.size.width, NAME_TABLE_HEIGHT)];
	[[NSColor blackColor] set];
	[path setLineWidth:2.0];
	[path stroke];
	
	int x;
	CGFloat y;
	NSString *percString, *tempString;
	
	for (x = start; x < end && x < [pointsArray count]; x++) {
		
		//Establish the size of the bar
		y = ([[pointsArray objectAtIndex:x] floatValue] * zoom);
		
		//Create the string that will display the percentage above the bar
		percString = [NSString stringWithFormat:@"%.2f%%", [[pointsArray objectAtIndex:x] floatValue]]; 
		
		//Create a bar
		path = [NSBezierPath bezierPathWithRect:[self makeBar:y]];
		[[NSColor blackColor] set];
		[path setLineWidth:4.5];
		[path stroke];
		
		//Draw the string that will display the percentage above the bar
		[self drawString:percString AtDistanceFromOrigin:(prevXOrig + (path.bounds.size.width / 5))
				  andBar:(path.bounds.size.height + PERC_HEIGHT)];
		
		//Draw the string that will display the account name
		tempString = [self separateAndFormatString:[accountNames objectAtIndex:x]];
		[self drawString:tempString 
	AtDistanceFromOrigin:(prevXOrig + 10) andBar:1];
		
		//Set color of bars and fill the path
		float barValue = [[accountBals objectAtIndex:x] floatValue];
		
		//Default Bar Color
		barColor = [NSColor greenColor];
		
		//Make red if debt is higher than current savings + checking
		barColor = (barValue > (savingsAmount + checkingAmount)) ? [NSColor redColor] : barColor;
		
		//Make orange if person will need to dip into savings to afford
		barColor = (barValue > checkingAmount && barValue < (savingsAmount + checkingAmount)) ? [NSColor orangeColor] : barColor;
		
		//Set bar color
		[barColor set];
		
		//Fill the bar with the color
		[path fill];
	}
	//Reset prevXOrig for the next set of bars that will be displayed
	prevXOrig = START_POINT_X_AXIS;
}

-(void)drawString:(NSString *)string AtDistanceFromOrigin:(CGFloat)distO andBar:(CGFloat)distB
{
	NSPoint strPoint;
	strPoint.x = distO;
	strPoint.y = distB;
	[string drawAtPoint:strPoint withAttributes:attributes];
}

-(NSString *)separateAndFormatString:(NSString *)string
{
	NSArray *stringArray = [[NSArray alloc] init];
	stringArray = [string componentsSeparatedByString:@" "];
	if ([stringArray count] > 2)
		return [NSString stringWithFormat:@"%@\n %@...", [stringArray objectAtIndex:0], [stringArray objectAtIndex:1]];
	else if ([stringArray count] == 2)
		return [NSString stringWithFormat:@"%@\n %@", [stringArray objectAtIndex:0], [stringArray objectAtIndex:1]];
	else
		return [stringArray objectAtIndex:0];
}

-(NSRect)makeBar:(CGFloat)height
{
	prevXOrig += 70;
	height = (height > TOP_POINT) ? TOP_POINT : height;
	return NSMakeRect(prevXOrig, START_POINT_Y_AXIS, 60, height);
}

-(void)createGraphWithAccountValues:(NSMutableArray *)accounts AndNames:(NSMutableArray *)names
{
	if ([accounts count] < 9) {
		[prev setEnabled:NO];
		[next setEnabled:NO];
	} else {
		[prev setEnabled:YES];
		[next setEnabled:YES];
	}
	
	/* Find our total accounts value */
	int x;
	for (x = 0; x < [accounts count]; x++)
		maxAccount += [[accounts objectAtIndex:x] floatValue];
	
	float a, prevZoom;
	NSNumber *perc;
	/* Get the percentage of each account */
	for (x = 0, prevZoom = 0; x < [accounts count]; x++) {
		if (maxAccount > 0.00)
			perc = [NSNumber numberWithFloat:(([[accounts objectAtIndex:x] floatValue] / maxAccount) * 100)];
		else
			perc = [NSNumber numberWithFloat:0.00];
		[pointsArray addObject:perc];
		[accountNames addObject:[names objectAtIndex:x]];
		[accountBals addObject:[accounts objectAtIndex:x]];
		
		//Decide how much to magnify the view of the bars
		a = [perc floatValue];
		zoom = (a >= 90.0 && a > prevZoom) ? 1.5 :
		(a >= 60.0 && a > prevZoom) ? 2.0 :
		(a >= 50.0 && a > prevZoom) ? 3.0 :
		(a >= 25.0 && a > prevZoom) ? 4.0 :
		(a >= 0 && a > prevZoom) ? 5.0 : zoom;
		prevZoom = a;
	}
	[self setNeedsDisplay:YES];
}

-(void)clearFrame
{
	//Reset the start point of the X axis for a new graph and reset variables
	maxAccount = start = 0;
	end = 8;
	[pointsArray removeAllObjects];
	[accountBals removeAllObjects];
	[accountNames removeAllObjects];
}

-(IBAction)viewNext:(id)sender
{	
	int count = [pointsArray count];
	start = (count > end) ? end : start;
	end += (count > (end + NUM_TO_DISPLAY)) ? NUM_TO_DISPLAY : (count - end);
	end = (end < start) ? (start + NUM_TO_DISPLAY) : end;
	
	[self setNeedsDisplay:YES];
}

-(IBAction)viewPrev:(id)sender
{	
	end = (start > 0) ? start : NUM_TO_DISPLAY;
	start = (0 <= (end - NUM_TO_DISPLAY)) ? (end - NUM_TO_DISPLAY) : 0;
	start = (start < 0) ? 0 : start;
	
	[self setNeedsDisplay:YES];
}

-(void)setViewColor:(NSColor *)color
{
	viewColor = color;
}

@synthesize savingsAmount, checkingAmount;

@end