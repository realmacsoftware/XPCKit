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
#import "SBUtilities.h"
#import "Multiplier.h"

@implementation TestAppAppDelegate

@synthesize window;

// Returns an arbitrary file URL where we have access to that file.
// This may serve as a container URL a document scoped bookmark is relative to.
// (We use our own preferences plist here)

- (NSURL *)URLForArbitraryAccessibleFile
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%@.plist", bundleId];
    
    // Make sure user defaults file exists
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"Straw Man"];
    [userDefaults synchronize];
        
    return [NSURL fileURLWithPath:path];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    mathConnection = [[XPCConnection alloc] initWithServiceName:@"com.mustacheware.TestService"];
    mathConnection.eventHandler =
    ^(XPCMessage *message, XPCConnection *inConnection)
    {
		NSNumber *result = [message objectForKey:@"result"];
		NSData *data = [message objectForKey:@"data"];
		NSFileHandle *fileHandle = [message objectForKey:@"fileHandle"];
		NSDate *date = [message objectForKey:@"date"];
		if(result){
			NSLog(@"We got a calculation result! %@", result);
		}else if(data || fileHandle){
			NSData *newData = [fileHandle readDataToEndOfFile];
			NSLog(@"We got a file handle! Read %lu bytes - %@", newData.length, fileHandle);
		}else if(date){
			NSLog(@"It is now %@", date);
		}
    };
	
	readConnection = [[XPCConnection alloc] initWithServiceName:@"com.mustacheware.TestService"];
    readConnection.eventHandler =
    ^(XPCMessage *message, XPCConnection *inConnection)
    {
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
    
    XPCConnection *crashConnection = [[XPCConnection alloc] initWithServiceName:@"com.mustacheware.TestService"];
	
	// Let XPC service multiply some numbers
    
	XPCMessage *message = 
	[XPCMessage messageWithObjectsAndKeys:@"multiply", @"operation",
     [NSArray arrayWithObjects:[NSNumber numberWithInt:7], [NSNumber numberWithInt:6], [NSNumber numberWithDouble: 1.67], nil], @"values", nil];
	
    [mathConnection sendMessage:message withReply:^(XPCMessage *message) {
		NSNumber *result = [message objectForKey:@"result"];
        if (result) {
            NSLog(@"I asked for multiplying and got back the following result: %@", result);
        }
    }];
    
    // Multiply some (other) numbers using a more generalized message sending mechanism that is designed to also work in
    // a non-XPC service environment (like OS X  10.6)
    
    NSArray * values = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:14],
                        [NSNumber numberWithInt:7],
                        [NSNumber numberWithDouble: 1.67], nil];
    
    Multiplier *multiplier = [[Multiplier alloc] initWithValues:values];
    
//    XPCMsgDispatchAsyncWithObject(nil, @selector(multiply), multiplier, nil,      // With nil connection it will use GCD
    XPCPerformSelectorAsync(mathConnection, @selector(multiply), multiplier, nil,
                                  ^(id product, NSError *error) {
                                      if (error) {
                                          NSLog(@"Oops! we got an error: %@", [error localizedDescription]);
                                      } else {
                                          NSLog(@"I asked for multiplying some numbers and got back: %@", product);
                                      }
                                  });

    
    // Read test file from XPC service (file will be chosen by XPC service)
    
	message = [XPCMessage messageWithObjectsAndKeys:@"read", @"operation", nil];
        
	[readConnection sendMessage:message];
	
    
    // Resolve document scoped bookmark for test file from XPC service (file will be chosen by XPC service)

    // Need a straw man URL to serve as a "relative URL" for our document scoped bookmark
    NSURL *bookmarkContainerURL = [self URLForArbitraryAccessibleFile];
    
    message = [XPCMessage messageWithObjectsAndKeys:
               @"getDocumentBookmark", @"operation",
               bookmarkContainerURL,   @"bookmarkContainerURL", nil];
    
    [readConnection sendMessage:message withReply:
     ^(XPCMessage *inMessage)
    {
        // Resolve bookmark and log file content
        
		id result = [inMessage objectForKey:@"result"];
        if (result && [result isKindOfClass:[NSData class]])
        {
            NSError *error = nil;
            BOOL isStale = NO;
            NSURL *URL = [NSURL URLByResolvingBookmarkData:result
                                                   options:NSURLBookmarkResolutionWithSecurityScope
                                             relativeToURL:bookmarkContainerURL
                                       bookmarkDataIsStale:&isStale
                                                     error:&error];
            
            [URL startAccessingSecurityScopedResource];
            
            NSString *fileContent = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
            NSLog(@"Read from URL based on document-scoped bookmark: %@", fileContent);
            
            [URL stopAccessingSecurityScopedResource];
            
        }
    }];
    
    // Crash the XPC service to test error handler provided

    message = [XPCMessage messageWithObjectsAndKeys:@"crashYou", @"operation", nil];
    
    [crashConnection sendMessage:message withReply:^(XPCMessage *inMessage) {
        // Empty reply handler since we are crashing the XPC service to test error handling
    } errorHandler:^(NSError *inError) {
        NSLog(@"XPC service successfully crashed with description: %@", [inError localizedDescription]);
    }];

    
	[mathConnection sendMessage:[XPCMessage messageWithObject:@"whatTimeIsIt" forKey:@"operation"]];
    
}

@end
