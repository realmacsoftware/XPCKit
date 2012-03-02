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
#import "SBUtilities.h"

void ensureTestFile(void);

static NSString *testFilePath;
static const NSString *testFileContent = @"\nHere's to the crazy sandbox creators\nThe misfits, the rebels";


// Create a file to test with that is out of the app's sandbox

void ensureTestFile()
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    if (![fm fileExistsAtPath:testFilePath]) {
        if (![fm createFileAtPath:testFilePath contents:[testFileContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil])
        {
            [NSException raise:@"Could not create file" format:@"path %@", testFilePath];
        }
    }
    [fm release];
    
}


int main(int argc, const char *argv[])
{
    testFilePath = [SBHomeDirectory() stringByAppendingString:@"/XPCKit - you may delete this test file.txt"];
    
	[XPCService runServiceWithConnectionHandler:^(XPCConnection *connection){
		[connection sendLog:@"TestService received a connection"];
		[connection setEventHandler:^(XPCMessage *message, XPCConnection *connection){
			[connection sendLog:[NSString stringWithFormat:@"TestService received a message! %@", message]];
            
            XPCMessage *reply = [XPCMessage messageReplyForMessage:message];
            
            NSString *operation = [message objectForKey:@"operation"];
            
            if([operation isEqual:@"multiply"])
            {
                NSArray *values = [message objectForKey:@"values"];
                
                // calculate the product
                double product = 1.0;
                for(NSUInteger index=0; index < values.count; index++){
                    product = product * [(NSNumber *)[values objectAtIndex:index] doubleValue];
                }
                [reply setObject:[NSNumber numberWithDouble:product] forKey:@"result"];
            }
            
            
            if([operation isEqual:@"read"])
            {
                ensureTestFile();
                
                NSString *path = testFilePath;
                NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
                
//                [connection sendLog:[NSString stringWithFormat:@"data %i bytes handle %@",data.length, fileHandle]];

                [reply setObject:data forKey:@"data"];
                [reply setObject:fileHandle forKey:@"fileHandle"];
            }
            
            
            if([operation isEqual:@"whatTimeIsIt"])
            {
               [reply setObject:[NSDate date] forKey:@"date"];
            }
            
            
            if([operation isEqual:@"getDocumentBookmark"])
            {
                ensureTestFile();
                
                NSURL *documentContainerURL = [message objectForKey:@"bookmarkContainerURL"];
                NSError *error = nil;
                
                NSURL *bookmarkURL = [[NSURL fileURLWithPath:testFilePath] fileReferenceURL];
                NSData *documentBookmark =
                [bookmarkURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                      includingResourceValuesForKeys:nil
                                       relativeToURL:documentContainerURL error:&error];

                [reply setObject:documentBookmark forKey:@"result"];
            }
            
            
            if([operation isEqual:@"crashYou"])
            {
                // Give other operations a chance to complete
                sleep(2);
                
                // Crash me
                NSArray *dummyArray = [NSArray array];
                [dummyArray objectAtIndex:10];
            }
            
            
            // Treat more operations here...
            
            
            [connection sendMessage:reply];
                
		}];
//        xpc_connection_resume(xpc_retain(connection.connection));
	}];
	
	
	
	return 0;
}
