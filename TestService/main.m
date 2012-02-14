//
//  main.c
//  TestService
//
//  Created by Steve Streza on 7/24/11. Copyright 2011 XPCKit.
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
#import "XPCKit.h"

int main(int argc, const char *argv[])
{
	[XPCService runServiceWithConnectionHandler:^(XPCConnection *connection){
		[connection _sendLog:@"TestService received a connection"];
		[connection setEventHandler:^(XPCMessage *message, XPCConnection *connection){
			[connection _sendLog:[NSString stringWithFormat:@"TestService received a message! %@", message]];
            
            // Treat direct-reply message differently
            
            NSNumber *directReply = [message objectForKey:XPC_DIRECT_REPLY_KEY];
            
            // Respond to a specific reply handler or generic event handler
            
            XPCMessage *reply = nil;
            if (directReply && [directReply boolValue])
            {
                reply = [XPCMessage messageReplyForMessage:message];
            } else {
                reply = [XPCMessage message];
            }
                
            if([[message objectForKey:@"operation"] isEqual:@"multiply"])
            {
                NSArray *values = [message objectForKey:@"values"];
                
                // calculate the product
                double product = 1.0;
                for(NSUInteger index=0; index < values.count; index++){
                    product = product * [(NSNumber *)[values objectAtIndex:index] doubleValue];
                }
                [reply setObject:[NSNumber numberWithDouble:product] forKey:@"result"];
            }
            
            
            if([[message objectForKey:@"operation"] isEqual:@"read"])
            {
                NSString *path = [message objectForKey:@"path"];
                NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
                
//                [connection _sendLog:[NSString stringWithFormat:@"data %i bytes handle %@",data.length, fileHandle]];
                

                [reply setObject:data forKey:@"data"];
                [reply setObject:fileHandle forKey:@"fileHandle"];
            }
            
            
            if([[message objectForKey:@"operation"] isEqual:@"whatTimeIsIt"])
            {
                [reply setObject:[NSDate date] forKey:@"date"];
            }
            
            
            // Treat more operations here...
            
            
            [connection sendMessage:reply];
                
		}];
//        xpc_connection_resume(xpc_retain(connection.connection));
	}];
	
	
	
	return 0;
}
