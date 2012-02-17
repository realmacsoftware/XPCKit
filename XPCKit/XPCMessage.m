//
//  XPCMessage.m
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

#import "XPCMessage+XPCKitInternal.h"
#import "XPCExtensions.h"

@interface XPCMessage()

- (id)_initWithFirstObject:(id)firstObject arguments:(va_list)argumentList;

@end


@implementation XPCMessage

@synthesize XPCDictionary=_XPCDictionary;

- (void) setXPCDictionary:(xpc_object_t)inXPCDictionary
{
    if (xpc_get_type(inXPCDictionary) != XPC_TYPE_DICTIONARY)
    {
        [NSException raise:NSInvalidArgumentException format:@"Argument must be of type XPC_TYPE_DICTIONARY"];
    }
    _XPCDictionary = inXPCDictionary;
}

#pragma mark - Lifecycle

+ (id)message
{
    return [[[XPCMessage alloc] init] autorelease];
}


+ (id)messageWithXPCDictionary:(xpc_object_t)inXPCDictionary
{
    return [[[XPCMessage alloc] initWithXPCDictionary:inXPCDictionary] autorelease];
}


// Returns an empty (reply)message based on a message supposedly coming from the wire.
// If that incoming message was sent through -sentMessage:withReply: the returned message
// will be setup for being sent to the incoming message's reply handler.
// Otherwise, this method will simply return an empty message (that will be routed
// to a generic event handler).
// Initialize a message that is supposed to be the reply to inOriginalMessage.
// See xpc_dictionary_create_reply() for details.

+ (id)messageReplyForMessage:(XPCMessage *)inOriginalMessage
{
    return [[[XPCMessage alloc] initReplyForMessage:inOriginalMessage] autorelease];
}


+ (id)messageWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys
{
    return [[[XPCMessage alloc] initWithObjects:inObjects forKeys:inKeys] autorelease];
}


+ (id)messageWithObject:(id)inObject forKey:(NSString *)inKey
{
    return [[[XPCMessage alloc] initWithObject:inObject forKey:inKey] autorelease];
}


+ (id)messageWithObjectsAndKeys:(id)firstObject, ...
{
    XPCMessage *this = [XPCMessage alloc];
    va_list argumentList;
    
    va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
    this = [this _initWithFirstObject:firstObject arguments:argumentList];
    va_end(argumentList);
    
    return [this autorelease];
}


// First designated initializer

- (id)initWithXPCDictionary:(xpc_object_t)inXPCDictionary
{
    if ((self = [super init]))
    {
        if (!inXPCDictionary) {
            [self setXPCDictionary:xpc_dictionary_create(NULL, NULL, 0)];
        } else {
            [self setXPCDictionary:xpc_retain(inXPCDictionary)];
        }
    }
    return self;
}

- (id)_initReplyForMessage:(XPCMessage *)inOriginalMessage
{
    if ((self = [super init]))
    {
        if ([inOriginalMessage needsDirectReply])
        {
            [self setXPCDictionary:xpc_dictionary_create_reply(inOriginalMessage.XPCDictionary)];
        } else {
            [self setXPCDictionary:xpc_dictionary_create(NULL, NULL, 0)];
        }
    }
    return self;
}


// Second designated initializer:
//
// Returns an empty (reply)message based on a message supposedly coming from the wire.
// If that incoming message was sent through -sentMessage:withReply: the returned message
// will be setup for being sent to the incoming message's reply handler.
// Otherwise, this method will simply return an empty message (that will be routed
// to a generic event handler).
// Initialize a message that is supposed to be the reply to inOriginalMessage.
// See xpc_dictionary_create_reply() for details.

- (id)initReplyForMessage:(XPCMessage *)inOriginalMessage
{
        if (inOriginalMessage)
        {
            return [self _initReplyForMessage:inOriginalMessage];
        } else {
            return [self init];
        }
}


- (id)initWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys
{
    if ((self = [self init]))
    {
        id object = nil;
        NSString *key = nil;
        
        if ([inObjects count] != [inKeys count]) {
            [NSException raise:NSInvalidArgumentException format:@"Objects and keys don't match in numbers"];
        }
        for (NSUInteger i = 0; i < [inObjects count]; i++)
        {
            object = [inObjects objectAtIndex:i];
            
            // TODO: Ensure that we indeed got NSString kind of objects here
            key = (NSString *)[inKeys objectAtIndex:i];
            
            [self setObject:object forKey:key];
        }
    }
    return self;
}


- (id)initWithObject:(id)inObject forKey:(NSString *)inKey
{
    return [self initWithObjects:[NSArray arrayWithObject:inObject] forKeys:[NSArray arrayWithObject:inKey]];
}


- (id)_initWithFirstObject:(id)firstObject arguments:(va_list)argumentList
{
    if (firstObject) // The first argument isn't part of the varargs list, so we'll handle it separately.
    {
        id eachObject;
        NSMutableArray *objects = [NSMutableArray array];
        NSMutableArray *keys = [NSMutableArray array];
        
        [objects addObject: firstObject];
        NSMutableArray *objectsOrKeys = keys;
        while ((eachObject = va_arg(argumentList, id)))  // As many times as we can get an argument of type "id"
        {
            [objectsOrKeys addObject: eachObject];
            objectsOrKeys = objectsOrKeys == objects ? keys : objects;
        }
        return [self initWithObjects:objects forKeys:keys];
    }
    return [self init];
}


- (id)initWithObjectsAndKeys:(id)firstObject, ...
{
    va_list argumentList;
    
    va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
    self = [self _initWithFirstObject:firstObject arguments:argumentList];
    va_end(argumentList);
    
    return self;
}


- (id)init
{
    return [self initWithXPCDictionary:NULL];
}


- (void)dealloc
{
    if (_XPCDictionary) {
        xpc_release(_XPCDictionary);
    }
    [super dealloc];
}


#pragma mark - Accessing/Adding Values


- (id)objectForKey:(NSString *)inKey
{
    const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
    xpc_object_t value = xpc_dictionary_get_value(_XPCDictionary, lowLevelKey);
    
    if (value) {
        return [NSObject objectWithXPCObject:value];
    } else {
        return nil;
    }
}


- (void)setObject:(id)inObject forKey:(NSString *)inKey
{
    xpc_object_t value = [inObject newXPCObject];
    
    if (value) 
    {
        const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
        
        xpc_dictionary_set_value(_XPCDictionary, lowLevelKey, value);
        xpc_release(value);
    } else {
        // There is no way to convert inObject into an xpc_object_t object
        
        [NSException raise:NSInvalidArgumentException format:@"Object %@ is not convertible into xpc_object_t type. If you make it conform to NSCoding it will be. For further insight have a look at -newXPCObject.", inObject];
    }
}


#pragma mark - Miscellaneous

-(NSString *) description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"\n{\n"];
    
    xpc_dictionary_apply(_XPCDictionary, ^bool(const char *inKey, xpc_object_t inValue){
        NSString *key = [NSString stringWithCString:inKey encoding:NSUTF8StringEncoding];
        id value = [NSObject objectWithXPCObject:inValue];
        if(key && value)
        {
            [description appendFormat:@"    %@: %@\n", key, value];
        }
        return true;
    });
    [description appendFormat:@"}\n"];
    return description;
}

@end
