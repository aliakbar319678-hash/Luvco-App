import re
import os

svg_path = 'assets/images/luvco_logo_white.svg'
output_path = 'android/app/src/main/res/drawable/luvco_logo_vector.xml'

if not os.path.exists(os.path.dirname(output_path)):
    os.makedirs(os.path.dirname(output_path))

with open(svg_path, 'r') as f:
    content = f.read()

paths = re.findall(r'd="([^"]+)"', content)

with open(output_path, 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?>\n')
    f.write('<vector xmlns:android="http://schemas.android.com/apk/res/android"\n')
    f.write('    android:width="242dp"\n')
    f.write('    android:height="100dp"\n')
    f.write('    android:viewportWidth="242"\n')
    f.write('    android:viewportHeight="100">\n')
    # The first path is the main logo text.
    # The next two are smaller parts.
    # The others are gradients/shadows which we can skip for a clean native splash.
    for p in paths[:3]:
        f.write(f'    <path android:fillColor="#FFFFFF" android:pathData="{p}" />\n')
    f.write('</vector>')
