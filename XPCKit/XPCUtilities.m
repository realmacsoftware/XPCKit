//
//  XPCUtilities.m
//  XPCKit
//
//  Created by Jörg Jacobsen on 3/7/12. Copyright 2012 XPCKit.
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

#import "XPCUtilities.h"

#pragma mark - Message Dispatching

// Dispatch a message with optional argument object to a target object asynchronously.
// When XPConnection is not nil the message will be transfered to XPC service for execution
//     (i.e. target and object must conform to NSCoding when connection is not nil).
// When XPCConnection is nil (e.g. running on Snow Leopard) message will be dispatched asynchronously via GCD.

void XPCMsgDispatchAsyncWithObject(XPCConnection *inConnection,
                                   SEL inSelector, id inTarget, id inObject,
                                   XPCReturnValueHandler inReturnHandler)
{
    // Copy completion handler onto the heap to make it stick around until we need it...
    
    XPCReturnValueHandler returnHandler = [inReturnHandler copy];
    
    // If we are running sandboxed on Lion (or newer), then send a request to perform selector on target to our XPC
    // service and hand the results to the supplied completion block...
    
    if (inConnection)
    {
        [inConnection sendSelector:inSelector
                        withTarget:inTarget
                            object:inObject
                returnValueHandler:inReturnHandler];
    }
    
    // If we are not sandboxed (e.g. running on Snow Leopard) we'll just do the work directly (but asynchronously)
    // via GCD queues. Once again the result is handed over to the completion block...
    // Note that we never call the error handler here since we can't have connection-level errors
    
    else
    {
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        dispatch_retain(currentQueue);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^()
                       {
                           NSError* error = nil;
                           id result = [inTarget performSelector:inSelector withObject:inObject withObject:(id)&error];
                           
                           dispatch_async(currentQueue,^()
                                          {
                                              inReturnHandler(result, error);
                                              [returnHandler release];
                                              dispatch_release(currentQueue);
                                          });
                       });
    }
}



