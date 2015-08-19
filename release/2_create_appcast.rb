#!/usr/bin/env ruby

IS_SANDBOXED = true
APPCAST_PATH = "./appcast-beta.xml"

app = "./CotEditor.app"

unless Dir.exist?(app) then
	puts "Dir not found : #{app}"
	exit
end

version = `/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" #{app}/Contents/Info.plist`.chomp
puts "Version #{version}"

dmg = "./CotEditor_#{version}.dmg"

unless File.exist?(dmg) then
	puts "File not found : #{dmg}"
	exit
end


if File.exist?(APPCAST_PATH) then
	puts "Already exist : #{APPCAST_PATH}"
	exit
end

dsa_priv = "./sparkle/dsa_priv.pem"

unless File.exist?(dsa_priv) then
	puts "File not found : #{dsa_priv}"
	exit
end

# Sparkle signature
dsa = `openssl dgst -sha1 -binary < "#{dmg}" | openssl dgst -dss1 -sign "#{dsa_priv}" | openssl enc -base64`.chomp

# DMG file information
require 'time'
date = File.mtime(dmg).rfc822
length = File.size(dmg)


# craate last item code
if IS_SANDBOXED then
	latest_item = <<-APPCAST_ITEM
		<item>
			<title>CotEditor #{version}</title>
			<sparkle:releaseNotesLink xml:lang="en">http://coteditor.com/releasenotes/#{version}.en.html</sparkle:releaseNotesLink>
			<sparkle:releaseNotesLink xml:lang="ja">http://coteditor.com/releasenotes/#{version}.ja.html</sparkle:releaseNotesLink>
			<pubDate>#{date}</pubDate>
			<sparkle:minimumSystemVersion>10.8</sparkle:minimumSystemVersion>
			<sparkle:version>#{version}</sparkle:version>
            <link>http://coteditor.com/</link>
		</item>
	APPCAST_ITEM
else
	# normal appcast
	latest_item = <<-APPCAST_ITEM
		<item>
			<title>CotEditor #{version}</title>
			<sparkle:releaseNotesLink xml:lang="en">http://coteditor.com/releasenotes/#{version}.en.html</sparkle:releaseNotesLink>
			<sparkle:releaseNotesLink xml:lang="ja">http://coteditor.com/releasenotes/#{version}.ja.html</sparkle:releaseNotesLink>
			<pubDate>#{date}</pubDate>
			<sparkle:minimumSystemVersion>10.8</sparkle:minimumSystemVersion>
			<enclosure url="https://github.com/coteditor/CotEditor/releases/download/#{version}/CotEditor_#{version}.dmg"
			           sparkle:version="#{version}"
			           sparkle:dsaSignature="#{dsa}"
			           length="#{length}"
			           type="application/octet-stream"/>
		</item>
	APPCAST_ITEM
end


# Output appcast
open(APPCAST_PATH, "w") { |file|
file.puts <<APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
	<channel>
		<title>CotEditor update information</title>
		<link>http://coteditor.com/releasenotes/appcast.xml</link>
		<description>CotEditor update information</description>
#{latest_item}
		<item>
			<title>CotEditor 2.0.3</title>
			<sparkle:releaseNotesLink xml:lang="en">http://coteditor.com/releasenotes/2.0.3.en.html</sparkle:releaseNotesLink>
			<sparkle:releaseNotesLink xml:lang="ja">http://coteditor.com/releasenotes/2.0.3.ja.html</sparkle:releaseNotesLink>
			<pubDate>Sun, 14 Dec 2014 21:19:19 +0900</pubDate>
			<sparkle:minimumSystemVersion>10.7</sparkle:minimumSystemVersion>
			<enclosure url="https://github.com/coteditor/CotEditor/releases/download/2.0.3/CotEditor_2.0.3.dmg"
			           sparkle:version="2.0.3"
			           sparkle:dsaSignature="MC0CFQC/u3nS+yqNHrr1+EghgQksnBlF2AIUfJ5SyL10uO1jSK01ZQgXM3xBE5s="
			           length="14414610"
			           type="application/octet-stream"/>
		</item>
	</channel>
</rss>
APPCAST
}

puts "Created appcast for #{version}."
