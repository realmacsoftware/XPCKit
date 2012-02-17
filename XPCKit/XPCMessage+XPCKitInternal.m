//
//  XPCMessage+XPCKitInternal.m
//  XPCKit
//
//  Created by Jörg Jacobsen on 15/2/12. Copyright 2012 XPCKit.
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

#define XPC_DIRECT_REPLY_KEY @"__directReply"

@implementation XPCMessage (XPCKitInternal)

- (xpc_object_t) XPCDictionary
{
    return _XPCDictionary;
}


- (BOOL) needsDirectReply
{
    NSNumber *directReply = nil;
    return (directReply = [self objectForKey:XPC_DIRECT_REPLY_KEY]) && [directReply boolValue];
}


- (void) setNeedsDirectReply:(BOOL)inDirectReply
{
    [self setObject:[NSNumber numberWithBool:inDirectReply] forKey:XPC_DIRECT_REPLY_KEY];
}

@end
