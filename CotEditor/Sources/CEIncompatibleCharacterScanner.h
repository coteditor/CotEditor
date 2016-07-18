/*
 
 CEIncompatibleCharacterScanner.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

@import AppKit;


@protocol CEIncompatibleCharacterScannerDelegate;


@class Document;
@class CEIncompatibleCharacter;


@interface CEIncompatibleCharacterScanner : NSObject

@property (nonatomic, nullable, weak) id<CEIncompatibleCharacterScannerDelegate> delegate;

@property (readonly, nonatomic, nullable, weak) Document *document;
@property (readonly, nonatomic, nonnull) NSArray<CEIncompatibleCharacter *> *incompatibleCharacers;  // line endings applied


// initializer
- (nonnull instancetype)initWithDocument:(nonnull Document *)document;

// public methods
- (void)invalidate;
- (void)scan;

@end




@protocol CEIncompatibleCharacterScannerDelegate <NSObject>

@required
- (BOOL)documentNeedsUpdateIncompatibleCharacter:(nonnull __kindof NSDocument *)document;

@optional
- (void)document:(nonnull __kindof NSDocument *)document didUpdateIncompatibleCharacters:(nonnull NSArray<CEIncompatibleCharacter *> *)incompatibleCharacers;

@end
