(*
 ==============================================================================
 RemoteEditorController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-11-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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
 *)


 script RemoteEditorController
     property parent : class "NSObject"
     property editor : application "CotEditor"
     property newDocument : missing value
     
     
     on createNewDocument:contents_
         tell my editor
             using terms from application "CotEditor"
                 make new document
                 set my newDocument to front document
                 
                 tell newDocument
                     set contents to contents_ as text
                     set range of selection to {0, 0}
                 end tell
             end using terms from
         end tell
     end createNewDocument:
     
     
     on jumpToLine:lineNum column:columnNum
         tell my editor
             using terms from application "CotEditor"
                 if front document is missing value then return
                 
                 tell front document
                     -- cast arguments
                     set lineNum to lineNum as integer
                     set columnNum to columnNum as integer
                     
                     -- count location of line
                     set loc to 0
                     set theLines to paragraphs 1 thru (lineNum - 1) of contents
                     repeat with theLine in theLines
                         set loc to loc + (count of theLine)
                     end repeat
                     set loc to loc + columnNum
                     
                     -- jump to location
                     set range of selection to {loc, 0}
                     scroll to caret
                 end tell
             end using terms from
         end tell
     end jumpToLine:column:
 end script
