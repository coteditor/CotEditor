#!/usr/bin/env ruby

app = "./CotEditor.app"

unless Dir.exist?(app) then
	puts "Dir not found : #{app}"
	exit
end

unless system "spctl -a -v #{app}" then
	puts "Code sign error : #{app}"
	exit
end

version = `/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" #{app}/Contents/Info.plist`.chomp
puts "Version #{version}"

dmg = "./CotEditor_#{version}.dmg"

if File.exist?(dmg) then
	puts "Already exist : #{dmg}"
	exit
end

# Create work directory
dmgwork = "./CotEditor_#{version}"
require 'fileutils'
FileUtils.rm_rf(dmgwork)
FileUtils.mkdir(dmgwork)
FileUtils.mv(app, dmgwork)

# Copy additional files
files = "./files"
if Dir.exist?(files) then
	FileUtils.cp_r("#{files}/.", dmgwork)
end

# Create dmg
system "hdiutil create -format UDBZ -srcfolder #{dmgwork} #{dmg}"
FileUtils.rm_rf(dmgwork)

puts "Created dmg for #{version}."
