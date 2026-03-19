#!/usr/bin/env bash
# 将各桌面主题从独立 Git 仓库克隆到 3rdparty/<目录名>/
# 用法：在仓库根目录执行  ./3rdparty/fetch-themes.sh
#       或在 3rdparty 内执行  ./fetch-themes.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRD_PARTY="$SCRIPT_DIR"
MANIFEST="$THIRD_PARTY/themes.repos"

usage() {
    echo "用法: $0 [--shallow] [--update]"
    echo "  --shallow  使用 --depth 1 浅克隆（体积小、速度快）"
    echo "  --update   对已存在的仓库执行 git pull（需已为 git 仓库）"
}

SHALLOW=0
UPDATE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --shallow) SHALLOW=1 ;;
        --update) UPDATE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

if ! command -v git >/dev/null 2>&1; then
    echo "错误: 未找到 git，请先安装 Git。" >&2
    exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
    echo "错误: 找不到清单文件 $MANIFEST" >&2
    exit 1
fi

clone_one() {
    local name="$1"
    local url="$2"
    local target="$THIRD_PARTY/$name"

    if [[ -d "$target/.git" ]]; then
        if [[ "$UPDATE" -eq 1 ]]; then
            echo "更新 $name ..."
            git -C "$target" pull --ff-only
        else
            echo "跳过 $name（已存在 Git 仓库，使用 --update 可拉取最新）"
        fi
        return
    fi

    if [[ -e "$target" ]]; then
        echo "警告: $target 已存在且不是 Git 仓库，跳过克隆。" >&2
        return
    fi

    echo "克隆 $name <- $url"
    local depth_args=()
    if [[ "$SHALLOW" -eq 1 ]]; then
        depth_args=(--depth 1)
    fi
    git clone "${depth_args[@]}" "$url" "$target"
}

while IFS= read -r line || [[ -n "$line" ]]; do
    # 去首尾空白
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    # 支持 Tab 或多个空格分隔
    read -r name url _ <<<"$line"
    if [[ -z "$name" || -z "$url" ]]; then
        echo "警告: 无法解析行: $line" >&2
        continue
    fi
    clone_one "$name" "$url"
done <"$MANIFEST"

echo "完成。主题目录位于: $THIRD_PARTY"
