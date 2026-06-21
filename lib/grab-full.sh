#!/usr/bin/env bash
# grab-full.sh <进程名> [out.png]
# 【整屏截图(从0,0,含菜单栏)→ 在软件里裁出目标窗口那块】。
# 为什么:直接 `screencapture -R <窗口>` 截 iPhone 镜像窗口,会被镜像 relay 成「截手机屏」、
# 触发 iOS/App 的截屏检测(如美团弹『截屏分享』浮窗盖住底部按钮、吃掉随后的点击)。
# 整屏截再裁,就是普通的 Mac 桌面截图,不被当成「截手机」。通用,不依赖某 App 的开关。
# 输出图与 grab.sh 完全一致(窗口那块,2x),坐标换算不变:像素÷2=窗口相对,绝对=+窗口position。
set -uo pipefail
APP="${1:?usage: grab-full.sh <ProcessName> [out.png]}"
OUT="${2:-/tmp/${APP}_g.png}"
geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "拿不到 $APP 窗口几何(没窗口?)" >&2; exit 1; }
FS="/tmp/_fs_$$.png"
screencapture -x "$FS"     # 整屏,从(0,0),含菜单栏
python3 - "$x" "$y" "$w" "$h" "$OUT" "$FS" <<'PY'
import sys
from PIL import Image
x, y, w, h, out, fs = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5], sys.argv[6]
im = Image.open(fs)
s = im.size[0] / 1440 if False else 2   # 这台 Retina 2x;窗口点→像素=×2
im.crop((s * x, s * y, s * (x + w), s * (y + h))).save(out)
PY
rm -f "$FS"
echo "$OUT  rect=${x},${y},${w},${h}  (整屏截+裁; 像素÷2=窗口相对, 绝对=该偏移+${x},${y})"
