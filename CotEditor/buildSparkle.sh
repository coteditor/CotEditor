#!/bin/zsh

#  buildSparkle.sh
#
#  CotEditor
#  https://coteditor.com
#
#  Created by 1024jp on 2020-04-10.
#
#  ------------------------------------------------------------------------------
#
#  © 2018-2021 1024jp
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

cd $1

derivedData=$2

# build Sparkle
echo "📦 Building Sparkle"
xcodebuild -scheme Distribution -configuration Release -derivedDataPath $derivedData build

# copy results to Build/ directory
mkdir -p ../Build
items=(
    'org.sparkle-project.InstallerLauncher.xpc'
    'Sparkle.framework'
)
for item in ${items[@]}; do
    file="${derivedData}/Build/Products/Release/${item}"
    echo "🚛 Copying ${item}..."
    rm -r ../Build/${item}
    cp -R ${file}* ../Build
done

# remove duplicated items in Sparkle.framework
cd ../Build
rm -f Sparkle.framework/Autoupdate
rm -f Sparkle.framework/Updater
rm -f Sparkle.framework/Versions/A/Autoupdate
rm -rf Sparkle.framework/Versions/A/Updater.app
codesign -f -s "-" Sparkle.framework
codesign --verify --deep Sparkle.framework
