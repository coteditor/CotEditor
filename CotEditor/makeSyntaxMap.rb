=begin
 
 makeSyntaxMap.rb
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-11-03.
 
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
=end

require 'find'
require 'yaml'
require 'json'


def get_strings(style, key)
    strings = []
    
    if style[key] then
        for dict in style[key] do
            strings << dict['keyString']
        end
    end
    
    return strings
end


#pragma mark - main

map = {}

Find.find('Syntaxes') {|f|
    next unless (File.extname(f) == '.yaml')  # skip if not YAML
    
    style = YAML.load_file(f)
    name = File.basename(f, '.yaml')
    
    map[name] = {
        'extensions' => get_strings(style, 'extensions'),
        'filenames' => get_strings(style, 'filenames'),
        'interpreters' => get_strings(style, 'interpreters'),
    }
}

File.write('SyntaxMap.json', JSON.pretty_generate(map))
