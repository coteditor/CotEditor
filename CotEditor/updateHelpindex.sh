#!/bin/sh

#  updateHelpindex.sh
#  
#  CotEditor
#  https://coteditor.com
#  
#  Created by 1024jp on 2016-06-08.
#  
#  ------------------------------------------------------------------------------
#  
#  © 2016 1024jp
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#  https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

cd CotEditor.help/Contents/Resources/

for dir in *.lproj/; do
    lang=`basename $dir .lproj`
    [ $lang == 'ja' ] && min_length=1 || min_length=3
    
    echo "📦 Indexing ${dir}..."
    hiutil -av --create $dir --file ${dir}/CotEditor.helpindex -m $min_length -e "xpgs/.*" --stopwords $lang 2>&1 | \
    awk "{ if (/error:/) {err = 1}; print} END {exit err}"
    if [ $? -gt 0 ]; then
        exit 1
    else
        echo "    ✅ ok."
    fi
done
