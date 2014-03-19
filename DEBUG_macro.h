/*
=================================================
DEBUG macro
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.06.27
 
 -fno-objc-arc
 
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

/*
Targets > CotEditor 選択後 GetInfo、Configuration==Development、Collection==GNU C/C++Compiler 4.0で、
下から2番目 Processor Macros に "DEBUGGING" を入力。
通常の NSLog() のかわりに DEBUG_LOG() を使用する。
*/


#ifdef DEBUGGING
#define DEBUG_LOG NSLog
#else
#define DEBUG_LOG(...)
#endif
