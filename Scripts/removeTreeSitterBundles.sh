#!/bin/sh

#  removeTreeSitterBundles.sh
#  
#  CotEditor
#  https://coteditor.com
#  
#  Created by 1024jp on 2026-02-28.
#
#  ------------------------------------------------------------------------------
#  
#  © 2026 1024jp
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

set -eu

appResources="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

if [ ! -d "${appResources}" ]; then
    exit 0
fi

is_removable_bundle() {
    bundlePath="$1"

    # Strip leading "bundlePath/" and validate remaining relative paths.
    # Allow only:
    # - Contents/Info.plist
    # - Contents/Resources/queries/*.scm
    while IFS= read -r absolutePath; do
        relativePath="${absolutePath#"${bundlePath}/"}"

        case "${relativePath}" in
            Contents/Info.plist)
                ;;
            Contents/Resources/queries/*.scm)
                ;;
            *)
                return 1
                ;;
        esac
    done <<EOF2
$(find "${bundlePath}" -type f)
EOF2

    return 0
}

removedCount=0

while IFS= read -r bundlePath; do
    [ -z "${bundlePath}" ] && continue

    if is_removable_bundle "${bundlePath}"; then
        echo "Removing ${bundlePath}"
        rm -rf "${bundlePath}"
        removedCount=$((removedCount + 1))
    else
        echo "warning: Skipping ${bundlePath} (contains non-query resources)"
    fi
done <<EOF2
$(find "${appResources}" -maxdepth 1 -type d -name 'TreeSitter*_TreeSitter*.bundle')
EOF2

if [ "${removedCount}" -eq 0 ]; then
    echo "warning: Removed no Tree-sitter bundles (check bundle path/pattern and bundle contents)"
fi
