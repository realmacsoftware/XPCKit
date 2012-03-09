//
//  Multiplier.m
//  XPCKit
//
//  Created by Jörg Jacobsen on 07.03.12.
//  Copyright (c) 2012 Mustacheware. All rights reserved.
//

#import "Multiplier.h"

@implementation Multiplier

#pragma mark - Lifecycle

- (id)initWithValues:(NSArray *)inValues
{
    self = [super init];
    
    if (self) {
        _values = inValues;
        [_values retain];
    }
    return self;
}


- (void)dealloc
{
    [_values release];
    
    [super dealloc];
}


#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder*)inCoder
{
	if (self = [super init])
	{
		_values = [inCoder decodeObjectForKey:@"values"];
        [_values retain];
	}
	
	return self;
}


- (void) encodeWithCoder:(NSCoder*)inCoder
{
	[inCoder encodeObject:_values forKey:@"values"];
}


#pragma mark - Do thy work

- (NSNumber *) multiply:(NSError **)outError
{
    double result = 1.0;
    for (NSNumber *value in _values)
    {
        if (![value isKindOfClass:[NSNumber class]])
        {
            NSInteger errorCode = 0;
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            NSString *localizedDescription = [NSString stringWithFormat:@"Cannot multiply with object of type %@", [value className]];
            [userInfo setValue:localizedDescription forKey:NSLocalizedDescriptionKey];

            *outError = [NSError errorWithDomain:@"TestAppErrorDomain" code:errorCode userInfo:userInfo];
        }
        result = result * [value doubleValue];
    }
    return [NSNumber numberWithDouble:result];
}


@end
