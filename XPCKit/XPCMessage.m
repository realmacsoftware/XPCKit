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

@implementation XPCMessage

@synthesize lowLevelMessage=_lowLevelMessage;

#pragma mark - Lifecycle

+ (id)message
{
    return [[[XPCMessage alloc] init] autorelease];
}


+ (id)messageWithMessage:(XPCMessage *)inLowLevelMessage
{
    return [[[XPCMessage alloc] initWithMessage:inLowLevelMessage] autorelease];
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


//+ (id)messageWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION
//{
//    id eachObject;
//    va_list argumentList;
//    if (firstObject) // The first argument isn't part of the varargs list, so we'll handle it separately.
//    {
//        
//        [self addObject: firstObject];
//        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
//        while (eachObject = va_arg(argumentList, id)) // As many times as we can get an argument of type "id"
//            [self addObject: eachObject]; // that isn't nil, add it to self's contents.
//        va_end(argumentList);
//    }
//}


// First designated initializer

- (id)initWithMessage:(xpc_object_t)inLowLevelMessage
{
    if ((self = [super init]))
    {
        if (!inLowLevelMessage) {
            _lowLevelMessage = xpc_dictionary_create(NULL, NULL, 0);
        } else {
            _lowLevelMessage = xpc_retain(inLowLevelMessage);
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
            _lowLevelMessage = xpc_dictionary_create_reply(inOriginalMessage.lowLevelMessage);
        } else {
            _lowLevelMessage = xpc_dictionary_create(NULL, NULL, 0);
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
            [NSException raise:NSInvalidArgumentException format:@"Object and key arrays have different sizes"];
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


- (id)init
{
    return [self initWithMessage:nil];
}


- (void)dealloc
{
    if (_lowLevelMessage) {
        xpc_release(_lowLevelMessage);
    }
    [super dealloc];
}


#pragma mark - Accessing/Adding Values


- (id)objectForKey:(NSString *)inKey
{
    const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
    xpc_object_t value = xpc_dictionary_get_value(_lowLevelMessage, lowLevelKey);
    
    if (value) {
        return [NSObject objectWithXPCObject:value];
    } else {
        return nil;
    }
}


- (void)setObject:(id)inObject forKey:(NSString *)inKey
{
    const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
    
    // TODO: Maybe we should instead implement newXPCObject on NSObject which will archive
    // the object into xpc_data_t (but that required conformance to NSCoding)
    if ([inObject respondsToSelector:@selector(newXPCObject)])
    {
        xpc_object_t value = [inObject newXPCObject];
        xpc_dictionary_set_value([self lowLevelMessage], lowLevelKey, value);
        xpc_release(value);
    } else {
        // TODO: Deal with model objects that are not directly supported through xpc_object_t
        // (archive them into xpc_data_t)
    }
}

@end
