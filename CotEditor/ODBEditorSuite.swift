//
//  ODB Editor Suite constants
//
//
//  Copyright ©2000 Bare Bones Software, Inc.
//  Copyright ©2016 1024jp. (converted to Swift)
//

//  For full information and documentation, see
//  <http://www.barebones.com/developer/>

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
