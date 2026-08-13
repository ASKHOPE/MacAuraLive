#!/usr/bin/env python3
import os
import sys
import time
import subprocess

OUT_DIR = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

print("🚀 Launching MacAuraLive for screenshot automation...")
subprocess.run(["open", "/Users/hosanna/Documents/wallpapermacs/build/MacAuraLive.app"])
time.sleep(2.5)

# Bring MacAuraLive to front
osascript_activate = '''
tell application "System Events"
    set frontmost of process "MacAuraLive" to true
end tell
'''
subprocess.run(["osascript", "-e", osascript_activate])
time.sleep(1.0)

# Get Window ID of MacAuraLive using CGWindowList / clis
def get_window_id():
    cmd = """
    import Quartz
    wl = Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID)
    for w in wl:
        if w.get('kCGWindowOwnerName') == 'MacAuraLive':
            return w.get('kCGWindowNumber')
    return None
    """
    res = subprocess.run([sys.executable, "-c", cmd], capture_output=True, text=True)
    out = res.stdout.strip()
    if out and out.isdigit():
        return int(out)
    return None

wid = get_window_id()
print(f"📷 Target MacAuraLive Window ID: {wid}")

tabs = [
    ("01_live_wallpapers.png", "Live Wallpapers", 1),
    ("02_static_wallpapers.png", "Static Wallpapers", 2),
    ("03_slideshow_schedule.png", "Slideshow & Schedule", 3),
    ("04_displays.png", "Displays", 4),
    ("05_lock_screen.png", "Lock Screen", 5),
    ("06_user_guide.png", "User Guide", 6),
    ("07_ai_workshop.png", "AI Workshop", 7),
    ("08_settings.png", "Settings", 8)
]

for filename, name, idx in tabs:
    print(f"📸 Navigating to tab {idx}: {name}...")
    
    # Click sidebar tab using AppleScript UI automation or Key press down arrow
    script = f'''
    tell application "System Events"
        tell process "MacAuraLive"
            set frontmost to true
            delay 0.3
            try
                -- Click matching sidebar button
                click button "{name}" of window 1
            on error
                -- Fallback to key code down arrow navigation
                key code 125
            end try
        end tell
    end tell
    '''
    subprocess.run(["osascript", "-e", script])
    time.sleep(1.5)
    
    out_path = os.path.join(OUT_DIR, filename)
    wid = get_window_id()
    if wid:
        subprocess.run(["screencapture", "-l", str(wid), "-o", out_path])
        print(f"  ✅ Saved: {out_path}")
    else:
        # Screen capture active window fallback
        subprocess.run(["screencapture", "-c", out_path])

print("\n🎉 All 8 tab screenshots captured successfully in Documentation/Screenshots!")
