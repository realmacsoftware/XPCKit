//
//  XPCMessage.h
//  XPCKit
//
//  Created by Jörg Jacobsen on 14/2/12. Copyright 2012 XPCKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

@interface XPCMessage : NSObject
{    
    xpc_object_t _XPCDictionary;
}

+ (id)message;
+ (id)messageWithXPCDictionary:(xpc_object_t)inXPCDictionary;
+ (id)messageReplyForMessage:(XPCMessage *)inOriginalMessage;
+ (id)messageWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys;
+ (id)messageWithObject:(id)inObject forKey:(NSString *)inKey;
+ (id)messageWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (id)initWithXPCDictionary:(xpc_object_t)inXPCDictionary;
- (id)initReplyForMessage:(XPCMessage *)inOriginalMessage;
- (id)initWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys;
- (id)initWithObject:(id)inObject forKey:(NSString *)inKey;
- (id)initWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;

- (id)objectForKey:(NSString *)inKey;

// Convenience accessors
- (NSArray *) arrayForKey:(NSString *)inKey;
- (NSDictionary *) dictionaryForKey:(NSString *)inKey;
- (NSString *) stringForKey:(NSString *)inKey;
- (NSURL *) URLForKey:(NSString *)inKey;
- (NSData *) dataForKey:(NSString *)inKey;
- (BOOL) boolForKey:(NSString *)inKey;
- (float) floatForKey:(NSString *)inKey;
- (NSInteger) integerForKey:(NSString *)inKey;
- (double) doubleForKey:(NSString *)inKey;

- (void)setObject:(id)inObject forKey:(NSString *)inKey;

// Convenience mutators
- (void) setBool:(BOOL)inValue forKey:(NSString *)inKey;
- (void) setDouble:(double)inValue forKey:(NSString *)inKey;
- (void) setFloat:(float)inValue forKey:(NSString *)inKey;
- (void) setInteger:(NSInteger)inValue forKey:(NSString *)inKey;

@end
