//
//  XPCConnection.m
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

#import "XPCConnection.h"
#import "XPCMessage+XPCKitInternal.h"
#import <xpc/xpc.h>
#import "NSObject+XPCParse.h"
#import "NSDictionary+XPCParse.h"

#define XPCLogMessages 1
#define XPCSendLogMessages 1

@implementation XPCConnection

@synthesize eventHandler=_eventHandler, dispatchQueue=_dispatchQueue, connection=_connection;

- (id)initWithServiceName:(NSString *)serviceName{
	xpc_connection_t connection = xpc_connection_create([serviceName cStringUsingEncoding:NSUTF8StringEncoding], NULL);
	self = [self initWithConnection:connection];
	xpc_release(connection);
	return self;
}

-(id)initWithConnection:(xpc_connection_t)connection{
	if(!connection){
		[self release];
		return nil;
	}
	
	if(self = [super init]){
		_connection = xpc_retain(connection);
		[self receiveConnection:_connection];

		dispatch_queue_t queue = dispatch_queue_create(xpc_connection_get_name(_connection), 0);
		self.dispatchQueue = queue;
		dispatch_release(queue);
		
		[self resume];
	}
	return self;
}

-(void)dealloc{
	if(_connection){
		xpc_connection_cancel(_connection);
		xpc_release(_connection);
		_connection = NULL;
	}
	
	[super dealloc];
}

-(void)setDispatchQueue:(dispatch_queue_t)dispatchQueue{
	if(dispatchQueue){
		dispatch_retain(dispatchQueue);
	}
	
	if(_dispatchQueue){
		dispatch_release(_dispatchQueue);
	}
	_dispatchQueue = dispatchQueue;
	
	xpc_connection_set_target_queue(self.connection, self.dispatchQueue);
}

-(void)receiveConnection:(xpc_connection_t)connection
{
    __block XPCConnection *this = self;
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        XPCMessage *message = nil;
        
        if (object == XPC_ERROR_CONNECTION_INTERRUPTED ||
            object == XPC_ERROR_CONNECTION_INVALID ||
            object == XPC_ERROR_KEY_DESCRIPTION ||
            object == XPC_ERROR_TERMINATION_IMMINENT)
        {
            xpc_object_t errorDict = xpc_dictionary_create(NULL, NULL, 0);
            xpc_dictionary_set_value(errorDict, "__XPCError", object);
            message = [XPCMessage messageWithXPCDictionary:errorDict];
        }else{
            message = [XPCMessage messageWithXPCDictionary:object];
		}	
#if XPCSendLogMessages
        if([message objectForKey:@"XPCDebugLog"]){
            NSLog(@"LOG: %@", [message objectForKey:@"XPCDebugLog"]);
            return;
        }
#endif
        
        if(this.eventHandler){
            this.eventHandler(message, this);
        }
    });
}


-(void)sendMessage:(XPCMessage *)inMessage
{
#if XPCLogMessages
    NSLog(@"Sending message %@", inMessage);
#endif
    
	dispatch_async(self.dispatchQueue, ^{
        xpc_connection_send_message(_connection, inMessage.XPCDictionary);
	});
}


-(void)sendMessage:(XPCMessage *)inMessage withReply:(XPCReplyHandler)replyHandler
{
    [self sendMessage:inMessage withReply:replyHandler errorHandler:nil];
}


-(void)sendMessage:(XPCMessage *)inMessage withReply:(XPCReplyHandler)replyHandler errorHandler:(XPCErrorHandler)errorHandler
{
    // Need to tell message that we want a direct reply
    [inMessage setNeedsDirectReply:YES];
    
#if XPCLogMessages
    NSLog(@"Sending message %@", inMessage);
#endif
    
	dispatch_async(self.dispatchQueue, ^{
        xpc_connection_send_message_with_reply(_connection, inMessage.XPCDictionary, self.dispatchQueue, ^(xpc_object_t event) {
            
            xpc_type_t type = xpc_get_type(event);

            if (type == XPC_TYPE_ERROR)
            {
                if (errorHandler) {
                    errorHandler([XPCMessage errorForXPCObject:event]);
                } else {
                    if (event == XPC_ERROR_CONNECTION_INVALID) {
                        // The process on the other end of the connection has either
                        // crashed or cancelled the connection. After receiving this error,
                        // the connection is in an invalid state, and you do not need to
                        // call xpc_connection_cancel(). Just tear down any associated state
                        // here.
                        NSLog(@"Connection is invalid");
                    } else if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                        // Handle per-connection termination cleanup.
                        NSLog(@"Connection was interrupted");
                    }
                }
            } else {
                assert(type == XPC_TYPE_DICTIONARY);
                XPCMessage *replyMessage = [XPCMessage messageWithXPCDictionary:event];
                replyHandler(replyMessage);
            }
        });
	});
}


-(void)sendSelector:(SEL)inSelector withTarget:(id)inTarget object:(id)inObject returnValueHandler:(XPCReturnValueHandler)inReturnHandler
{
    // Copy return value handler onto the heap to make it stick around until we need it...
    
    XPCReturnValueHandler returnHandler = [inReturnHandler copy];
    
    XPCMessage* message = [XPCMessage messageWithSelector:inSelector target:inTarget object:inObject];
    
    [self sendMessage:message withReply:^(XPCMessage* inReply)
     {
         NSError *error = nil;
         id returnValue = [inReply invocationReturnValue:&error];
         returnHandler(returnValue, error);             // Handle method-level errors here
         [returnHandler release];
     }
                 errorHandler:^(NSError* inError)       // Handle connection-level errors here
     {
         returnHandler(nil, inError);
         [returnHandler release];
     }];
}


-(NSString *)connectionName{
	__block char* name = NULL; 
	dispatch_sync(self.dispatchQueue, ^{
		name = (char*)xpc_connection_get_name(_connection);
	});
	if(!name) return nil;
	return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
}

-(NSNumber *)connectionEUID{
	__block uid_t uid = 0;
	dispatch_sync(self.dispatchQueue, ^{
		uid = xpc_connection_get_euid(_connection);
	});
	return [NSNumber numberWithUnsignedInt:uid];
}

-(NSNumber *)connectionEGID{
	__block gid_t egid = 0;
	dispatch_sync(self.dispatchQueue, ^{
		egid = xpc_connection_get_egid(_connection);
	});
	return [NSNumber numberWithUnsignedInt:egid];
}

-(NSNumber *)connectionProcessID{
	__block pid_t pid = 0;
	dispatch_sync(self.dispatchQueue, ^{
		pid = xpc_connection_get_pid(_connection);
	});
	return [NSNumber numberWithUnsignedInt:pid];
}

-(NSNumber *)connectionAuditSessionID{
	
	__block au_asid_t auasid = 0;
	dispatch_sync(self.dispatchQueue, ^{
		auasid = xpc_connection_get_asid(_connection);
	});
	return [NSNumber numberWithUnsignedInt:auasid];
}

-(void)suspend{
	dispatch_async(self.dispatchQueue, ^{
		xpc_connection_suspend(_connection);
	});
}

-(void)resume{
	dispatch_async(self.dispatchQueue, ^{
		xpc_connection_resume(_connection);
	});
}

-(void)sendLog:(NSString *)string{
#if XPCSendLogMessages
	[self sendMessage:[XPCMessage messageWithObject:string forKey:@"XPCDebugLog"]];
#endif
}

@end
