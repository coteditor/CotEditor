#!/usr/bin/env python
"""Copy missing resolutions in .iconset directories.
"""

import os
import shutil


resolution_map = {
    '512x512': '256x256@2x',
    '256x256': '128x128@2x',
}


def main():
    """Copy missing resolutions in .iconset directories.
    """
    current_directory = os.path.dirname(__file__)
    
    for (root, dirs, files) in os.walk(current_directory):
        for (key, value) in resolution_map.items():
            src_path = os.path.join(root, icon_name(key))
            dist_path = os.path.join(root, icon_name(value))

            if os.path.isfile(src_path):
                shutil.copy2(src_path, dist_path)


def icon_name(resolution):
    """Create file name from image resolution.

    Args:
        resolution (str): resolution of the image.
    Returns:
        icon_name (str): File name of an icon for .iconset.
    """
    return 'icon_' + resolution + '.png'


if __name__ == '__main__':
    main()
