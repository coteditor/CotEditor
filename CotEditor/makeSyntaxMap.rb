=begin
 ==============================================================================
 makeSyntaxMap.rb
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-11-03 by 1024jp
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
        'filenames' => get_strings(style, 'filenames')
    }
}

File.write('SyntaxMap.json', JSON.pretty_generate(map))
