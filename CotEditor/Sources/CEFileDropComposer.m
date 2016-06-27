/*
 
 CEFileDropComposer.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-09.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CEFileDropComposer.h"

#import "CEDefaults.h"
#import "Constants.h"

#import "NSURL+CEAdditions.h"


@implementation CEFileDropComposer

#pragma mark Public Methods

// ------------------------------------------------------

+ (nullable NSString *)dropTextForFileURL:(nonnull NSURL *)droppedFileURL documentURL:(nullable NSURL *)documentURL
// ------------------------------------------------------
{
    NSString *pathExtension = [droppedFileURL pathExtension];
    NSString *dropText = [self templateForExtension:pathExtension];
    
    if (!dropText) { return nil; }
    
    // replace template
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenAbsolutePath
                                                   withString:[droppedFileURL path]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenRelativePath
                                                   withString:[droppedFileURL pathRelativeToURL:documentURL] ?: [droppedFileURL path]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenFilename
                                                   withString:[droppedFileURL lastPathComponent]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenFilenameNosuffix
                                                   withString:[[droppedFileURL lastPathComponent] stringByDeletingPathExtension]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenFileextension
                                                   withString:pathExtension];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenFileextensionLower
                                                   withString:[pathExtension lowercaseString]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenFileextensionUpper
                                                   withString:[pathExtension uppercaseString]];
    dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenDirectory
                                                   withString:[[droppedFileURL URLByDeletingLastPathComponent] lastPathComponent]];
    
    // get image dimension if needed
    //   -> Use NSImageRep because NSImage's `size` returns an DPI applied size.
    __block NSImageRep *imageRep;
    [[[NSFileCoordinator alloc] init] coordinateReadingItemAtURL:droppedFileURL
                                                         options:NSFileCoordinatorReadingWithoutChanges | NSFileCoordinatorReadingResolvesSymbolicLink
                                                           error:nil
                                                      byAccessor:^(NSURL * _Nonnull newURL)
     {
         imageRep = [NSImageRep imageRepWithContentsOfURL:droppedFileURL];
     }];
    if (imageRep) {
        dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenImageWidth
                                                       withString:[NSString stringWithFormat:@"%zd", [imageRep pixelsWide]]];
        dropText = [dropText stringByReplacingOccurrencesOfString:CEFileDropTokenImageHeight
                                                       withString:[NSString stringWithFormat:@"%zd", [imageRep pixelsHigh]]];
    }
    
    return dropText;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// find matched template for path extension
+ (nullable NSString *)templateForExtension:(nullable NSString *)fileExtension
// ------------------------------------------------------
{
    NSArray<NSDictionary<NSString *, NSString *> *> *settings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultFileDropArrayKey];
    
    for (NSDictionary<NSString *, NSString *> *definition in settings) {
        NSArray<NSString *> *extensions = [definition[CEFileDropExtensionsKey] componentsSeparatedByString:@", "];
        
        if ([extensions containsObject:[fileExtension lowercaseString]] ||
            [extensions containsObject:[fileExtension uppercaseString]])
        {
            return definition[CEFileDropFormatStringKey];
        }
    }
    
    return nil;
}

@end
