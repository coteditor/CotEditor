//
//  ODB Editor Suite constants
//
//
//  Copyright ©2000 Bare Bones Software, Inc.
//  Copyright ©2016 1024jp.
//

//  For full information and documentation, see
//  <http://www.barebones.com/developer/>

@import CoreServices;

//  optional paramters to 'aevt'/'odoc'
static const AEKeyword keyFileSender      = 'FSnd';
static const AEKeyword keyFileSenderToken = 'FTok';
static const AEKeyword keyFileCustomPath  = 'Burl';

//  suite code for ODB editor suite events
//
//  WARNING: although the suite code is coincidentally the same
//  as BBEdit's application signature, you must not change this,
//  or else you'll break the suite. If you do that, ninjas will
//  come to your house and kick your ass.
//
static const AEEventClass kODBEditorSuite = 'R*ch';

//  ODB editor suite events, sent by the editor to the server.
static const AEEventID kAEModifiedFile    = 'FMod';
static const AEEventID keyNewLocation     = 'New?';
static const AEEventID kAEClosedFile      = 'FCls';

//  optional paramter to kAEModifiedFile/kAEClosedFile
static const AEKeyword keySenderToken     = 'Tokn';
