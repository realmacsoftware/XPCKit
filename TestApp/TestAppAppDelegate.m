//
//  TestAppAppDelegate.m
//  TestApp
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

#import "TestAppAppDelegate.h"
#import <xpc/xpc.h>
#import <dispatch/dispatch.h>

@implementation TestAppAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    mathConnection = [[XPCConnection alloc] initWithServiceName:@"com.mustacheware.TestService"];
//    mathConnection.eventHandler = ^(NSDictionary *message, XPCConnection *inConnection){
//		NSNumber *result = [message objectForKey:@"result"];
//		NSData *data = [message objectForKey:@"data"];
//		NSFileHandle *fileHandle = [message objectForKey:@"fileHandle"];
//		NSDate *date = [message objectForKey:@"date"];
//		if(result){
//			NSLog(@"We got a calculation result! %@", result);
//		}else if(data || fileHandle){
//			NSData *newData = [fileHandle readDataToEndOfFile];
//			NSLog(@"We got a file handle! Read %lu bytes - %@", newData.length, fileHandle);
//		}else if(date){
//			NSLog(@"It is now %@", date);
//		}
//    };
	
	readConnection = [[XPCConnection alloc] initWithServiceName:@"com.mustacheware.TestService"];
    readConnection.eventHandler = ^(XPCMessage *message, XPCConnection *inConnection){
		NSData *data = [message objectForKey:@"data"];
		NSFileHandle *fileHandle = [message objectForKey:@"fileHandle"];
		if(data || fileHandle){
			NSData *newData = [fileHandle readDataToEndOfFile];
			if(newData){
				NSLog(@"We got maybe mapped data! %lu bytes - Equal? %@", data.length, ([newData isEqualToData:data] ? @"YES" : @"NO"));
			}
				NSLog(@"We got a file handle! Read %lu bytes - %@", newData.length, fileHandle);
		}
    };
	
	// Let XPC service multiply some numbers
    
	XPCMessage *multiplyData = 
	[XPCMessage messageWithObjects:[NSArray arrayWithObjects:
                                     @"multiply", [NSArray arrayWithObjects:
                                                   [NSNumber numberWithInt:7],
                                                   [NSNumber numberWithInt:6],
                                                   [NSNumber numberWithDouble: 1.67], 
                                                   nil], nil]
                           forKeys:[NSArray arrayWithObjects:@"operation", @"values", nil]];
	
    [mathConnection sendMessage:multiplyData withReply:^(XPCMessage *message) {
		NSNumber *result = [message objectForKey:@"result"];
        if (result) {
            NSLog(@"I asked for multiplying and got back the following result: %@", result);
        }
    }];
    
	// Let XPC service ...
    
	XPCMessage *readData = 
	[XPCMessage messageWithObjects:[NSArray arrayWithObjects:@"read", @"/Users/syco/Library/Safari/Bookmarks.plist", nil]
                           forKeys:[NSArray arrayWithObjects:@"operation", @"path", nil]];
    
	NSData *loadedData = [[NSFileManager defaultManager] contentsAtPath:[readData objectForKey:@"path"]];
	NSFileHandle *loadedHandle = [NSFileHandle  fileHandleForReadingAtPath:[readData objectForKey:@"path"]];
	NSLog(@"Sandbox is %@ at path %@, got %lu bytes and a file handle %@",((loadedData.length == 0 && loadedHandle == nil) ? @"working" : @"NOT working"), [readData objectForKey:@"path"], loadedData.length, loadedHandle);
    
	[readConnection sendMessage:readData];
	
//	[mathConnection sendMessage:[XPCMessage messageWithObject:@"whatTimeIsIt" forKey:@"operation"]];
}

@end
