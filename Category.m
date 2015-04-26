//
//  AppController.m
//  FinCom
//
//  Created by Nick Combs on 10/10/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import "Category.h"


@implementation Category

-(id)init
{
	if (!(self = [super init])) return nil;
	category = @"New Category";
	return self;
}

-(id)initWithName:(NSString *)name
{
    if (!(self = [super init])) return nil;
    if ([name isEqualToString:@""]) return nil;
    category = name;
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if (!(self = [super init])) return nil;
	category = [aDecoder decodeObjectForKey:@"category"];
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:category forKey:@"category"];
}


@synthesize category;

@end