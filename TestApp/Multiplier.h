//
//  Multiplier.h
//  XPCKit
//
//  Created by Jörg Jacobsen on 07.03.12.
//  Copyright (c) 2012 Mustacheware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Multiplier : NSObject <NSCoding>
{
    NSArray *_values;
}

- (id)initWithValues:(NSArray *)inValues;
- (NSNumber *) multiply;
@end
