//
//  AppController.h
//  FinCom
//
//  Created by Nick Combs on 10/10/11.
//  Copyright 2011 PuffyCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Category : NSObject <NSCoding> {
	NSString *category;
}

-(id)initWithName:(NSString *)name;

@property (readwrite, strong) NSString * category;

@end