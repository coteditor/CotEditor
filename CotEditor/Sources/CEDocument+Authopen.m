/*
 ==============================================================================
 CEDocument+Authopen
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-06-29 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEDocument+Authopen.h"


@implementation CEDocument (Authopen)

// ------------------------------------------------------
/// Try reading data at the URL using authopen (Sandobox incompatible)
- (nullable NSData *)forceReadDataFromURL:(nonnull NSURL *)url
// ------------------------------------------------------
{
    __block BOOL success = NO;
    __block NSData *data = nil;
    
    // read data using `authopen` command
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingResolvesSymbolicLink
                                      error:nil byAccessor:^(NSURL *newURL)
     {
         NSString *path = @([[newURL path] UTF8String]);
         NSTask *task = [[NSTask alloc] init];
         
         [task setLaunchPath:@"/usr/libexec/authopen"];
         [task setArguments:@[path]];
         [task setStandardOutput:[NSPipe pipe]];
         
         [task launch];
         data = [NSData dataWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile]];
         [task waitUntilExit];
         
         int status = [task terminationStatus];
         success = (status == 0);
     }];
    
    return success ? data : nil;
}


// ------------------------------------------------------
/// Try writing data to the URL using authopen (Sandobox incompatible)
- (BOOL)forceWriteToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
// ------------------------------------------------------
{
    __block BOOL success = NO;
    NSData *data = [self dataOfType:typeName error:nil];
    
    if (!data) { return NO; }
    
    // save data using `authopen` command
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [coordinator coordinateWritingItemAtURL:url options:0
                                      error:nil
                                 byAccessor:^(NSURL *newURL)
     {
         NSString *path = @([[newURL path] UTF8String]);
         NSTask *task = [[NSTask alloc] init];
         
         [task setLaunchPath:@"/usr/libexec/authopen"];
         [task setArguments:@[@"-c", @"-w", path]];
         [task setStandardInput:[NSPipe pipe]];
         
         [task launch];
         [[[task standardInput] fileHandleForWriting] writeData:data];
         [[[task standardInput] fileHandleForWriting] closeFile];
         
         // [caution] Do not use `[task waitUntilExit]` here,
         //           since it passes through the run-loop and other file access can interrupt.
         while ([task isRunning]) {
             usleep(200);
         }
         
         
         int status = [task terminationStatus];
         success = (status == 0);
     }];
    
    return success;
}

@end
