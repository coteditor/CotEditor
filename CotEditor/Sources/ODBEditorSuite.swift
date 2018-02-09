//
//  ODBEditorSuite.swift
//
//  CotEditor
//  https://coteditor.com
//
//  For full information and documentation, see
//  <http://www.barebones.com/developer/>
//
//  ---------------------------------------------------------------------------
//
//  © 2000 Bare Bones Software, Inc.
//  © 2016 1024jp (converted to Swift)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreServices

//  optional paramters to 'aevt'/'odoc'
let keyFileSender       = AEKeyword(code: "FSnd")
let keyFileSenderToken  = AEKeyword(code: "FTok")
let keyFileCustomPath   = AEKeyword(code: "Burl")

//  suite code for ODB editor suite events
//
//  WARNING: although the suite code is coincidentally the same
//  as BBEdit's application signature, you must not change this,
//  or else you'll break the suite. If you do that, ninjas will
//  come to your house and kick your ass.
//
let kODBEditorSuite     = AEEventClass(code: "R*ch")

//  ODB editor suite events, sent by the editor to the server.
let kAEModifiedFile     = AEEventID(code: "FMod")
let keyNewLocation      = AEEventID(code: "New?")
let kAEClosedFile       = AEEventID(code: "FCls")

//  optional paramter to kAEModifiedFile/kAEClosedFile
let keySenderToken      = AEKeyword(code: "Tokn")
