//
//  NSObject+XPCParse.m
//  XPCKit
//
//  Created by Steve Streza on 7/25/11. Copyright 2011 XPCKit.
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

#import "NSObject+XPCParse.h"
#import <xpc/xpc.h>
#import "XPCExtensions.h"

@implementation NSObject (XPCParse)

+(id)objectWithXPCObject:(xpc_object_t)xpcObject{
    id object = nil;
    xpc_type_t type = xpc_get_type(xpcObject);
    if(type == XPC_TYPE_DICTIONARY){
        object = [NSDictionary dictionaryWithContentsOfXPCObject:xpcObject];
	}else if(type == XPC_TYPE_ARRAY){
		object = [NSArray arrayWithContentsOfXPCObject:xpcObject];
	}else if(type == XPC_TYPE_DATE){
		object = [NSDate dateWithXPCObject:xpcObject];
    }else if(type == XPC_TYPE_DATA || type == XPC_TYPE_SHMEM)
    {
        // Try to return an object that was archived as NSData. Return NSData if that fails.
        object = [NSData objectWithXPCObject:xpcObject];
        if (!object) {
            object = [NSData dataWithXPCObject:xpcObject];
        }
    }else if(type == XPC_TYPE_STRING){
        object = [NSString stringWithXPCObject:xpcObject];
    }else if(type == XPC_TYPE_UUID){
		object = [XPCUUID uuidWithXPCObject:xpcObject];
	}else if(type == XPC_TYPE_FD){
		object = [NSFileHandle fileHandleWithXPCObject:xpcObject];
    }else if(type == XPC_TYPE_BOOL || type == XPC_TYPE_UINT64 || type == XPC_TYPE_INT64 || type == XPC_TYPE_DOUBLE){
        object = [NSNumber numberWithXPCObject:xpcObject];
	}
    return object;
}


// Returns NULL if self does not conform to NSCoding protocol

-(xpc_object_t)newXPCObject
{
    if ([self conformsToProtocol:@protocol(NSCoding)])
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
        return xpc_data_create([data bytes], [data length]);
    } else {
        // There is no way to convert self into an xpc_object_t object
        
        [NSException raise:@"XPCNotNSCodingConformantException" format:@"Object %@ is not convertible into xpc_object_t type because it is not NSCoding conformant", self];
    }
    return NULL;
}
@end
