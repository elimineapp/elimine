import cairosvg, os
WHITE = "M303 773C240 650 215 500 300 400C390 295 540 250 685 242C655 330 590 430 490 500C400 565 330 650 303 773Z"
DARK  = "M397 810C420 680 500 560 640 510C720 485 790 480 824 482C810 600 730 720 600 770C530 795 450 805 397 810Z"
CX, CY = 515, 526  # glyph centre
GRAD = '''<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#86D98C"/><stop offset=".45" stop-color="#58A6B4"/><stop offset="1" stop-color="#3A5FBD"/></linearGradient>
<radialGradient id="h" cx=".2" cy=".15" r=".8"><stop offset="0" stop-color="#fff" stop-opacity=".18"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>'''
def glyph(size, scale, white="#F7F6F1", dark="#1B2638"):
    t = f'translate({size/2} {size/2}) scale({scale}) translate({-CX} {-CY})'
    return f'<g transform="{t}"><path d="{WHITE}" fill="{white}"/><path d="{DARK}" fill="{dark}"/></g>'
def bg(size, rx=0):
    return f'<rect width="{size}" height="{size}" rx="{rx}" fill="url(#g)"/><rect width="{size}" height="{size}" rx="{rx}" fill="url(#h)"/>'
def svg(size, body, defs=True):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">{GRAD if defs else ""}{body}</svg>'
def png(s, path, px):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    cairosvg.svg2png(bytestring=s.encode(), write_to=path, output_width=px, output_height=px)
O = "out"
# master
full = svg(1024, bg(1024) + glyph(1024, 1.06))
open(f"{O}/source/icon.svg" if os.makedirs(f"{O}/source", exist_ok=True) is None else "", "w").write(full)
open(f"{O}/source/icon-rounded-preview.svg","w").write(svg(1024, bg(1024, 230)+glyph(1024,1.06)))
# iOS: square, opaque, iOS masks corners itself
png(full, f"{O}/ios/AppIcon.appiconset/AppIcon-1024.png", 1024)
open(f"{O}/ios/AppIcon.appiconset/Contents.json","w").write('''{
  "images" : [
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')
# Android adaptive layers (108dp canvas; glyph inside 66dp safe circle)
AS = 0.66*108/1024*1.0  # scale glyph relative to 108 canvas
ascale = 108/1024*0.66
fg = svg(108, glyph(108, ascale), defs=False)
bgs = svg(108, bg(108))
mono = svg(108, glyph(108, ascale, white="#000", dark="#000").replace('fill="#000"','fill="#000"'), defs=False)
dens = {"mdpi":1,"hdpi":1.5,"xhdpi":2,"xxhdpi":3,"xxxhdpi":4}
for d,k in dens.items():
    r = f"{O}/android/res/mipmap-{d}"
    png(fg, f"{r}/ic_launcher_foreground.png", int(108*k))
    png(bgs, f"{r}/ic_launcher_background.png", int(108*k))
    png(mono, f"{r}/ic_launcher_monochrome.png", int(108*k))
    # legacy (pre-API 26): 48dp, rounded square and circle
    leg = svg(108, bg(108, 20)+glyph(108, ascale)); png(leg, f"{r}/ic_launcher.png", int(48*k))
    rnd = svg(108, f'<clipPath id="c"><circle cx="54" cy="54" r="54"/></clipPath><g clip-path="url(#c)">{bg(108)}{glyph(108, ascale)}</g>'); png(rnd, f"{r}/ic_launcher_round.png", int(48*k))
png(svg(1024, bg(1024)+glyph(1024, 1.06)), f"{O}/android/play-store-512.png", 512)
# Vector drawables
def vpath(d, s): # transform path coords into 108 viewport
    import re
    nums = re.findall(r'[A-Z]|-?[\d.]+', d); out=[]; xy=0
    for n in nums:
        if n.isalpha(): out.append(n); xy=0; continue
        v=float(n); c = (v-CX)*s+54 if xy%2==0 else (v-CY)*s+54; xy+=1
        out.append(f"{c:.2f}")
    return " ".join(out)
os.makedirs(f"{O}/android/res/drawable", exist_ok=True); os.makedirs(f"{O}/android/res/mipmap-anydpi-v26", exist_ok=True)
vfg = lambda w,dk: f'''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="{w}" android:pathData="{vpath(WHITE, ascale)}"/>
    <path android:fillColor="{dk}" android:pathData="{vpath(DARK, ascale)}"/>
</vector>
'''
open(f"{O}/android/res/drawable/ic_launcher_foreground.xml","w").write(vfg("#F7F6F1","#1B2638"))
open(f"{O}/android/res/drawable/ic_launcher_monochrome.xml","w").write(vfg("#000000","#000000"))
open(f"{O}/android/res/drawable/ic_launcher_background.xml","w").write('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="0" android:startY="0" android:endX="108" android:endY="108">
                <item android:offset="0" android:color="#FF86D98C"/>
                <item android:offset="0.45" android:color="#FF58A6B4"/>
                <item android:offset="1" android:color="#FF3A5FBD"/>
            </gradient>
        </aapt:attr>
    </path>
</vector>
''')
adapt = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
'''
for n in ["ic_launcher","ic_launcher_round"]:
    open(f"{O}/android/res/mipmap-anydpi-v26/{n}.xml","w").write(adapt)
# previews
P=f"{O}/_preview"; os.makedirs(P, exist_ok=True)
png(svg(1024, bg(1024,230)+glyph(1024,1.06)), f"{P}/ios.png", 512)
png(svg(108, f'<clipPath id="c"><circle cx="54" cy="54" r="33"/></clipPath><g clip-path="url(#c)">{bg(108)}{glyph(108,ascale)}</g><circle cx="54" cy="54" r="33" fill="none" stroke="red" stroke-width=".3"/>'), f"{P}/android-circle.png", 512)
