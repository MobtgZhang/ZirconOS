#!/usr/bin/env bash
# 将各桌面主题从独立 Git 仓库克隆到 3rdparty/<目录名>/
# 用法：在仓库根目录执行  ./3rdparty/fetch-themes.sh
#       或在 3rdparty 内执行  ./fetch-themes.sh
#
# 默认主题: classic (ZirconOSClassic)
# 使用 --only=classic 可仅克隆默认主题
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRD_PARTY="$SCRIPT_DIR"
MANIFEST="$THIRD_PARTY/themes.repos"
DEFAULT_THEME="ZirconOSClassic"

usage() {
    echo "用法: $0 [--shallow] [--update] [--only=<theme>]"
    echo "  --shallow        使用 --depth 1 浅克隆（体积小、速度快）"
    echo "  --update         对已存在的仓库执行 git pull（需已为 git 仓库）"
    echo "  --only=<theme>   仅克隆指定主题（如 --only=classic 仅克隆 ZirconOSClassic）"
    echo ""
    echo "默认主题: classic (ZirconOSClassic)"
}

SHALLOW=0
UPDATE=0
ONLY_THEME=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --shallow) SHALLOW=1 ;;
        --update) UPDATE=1 ;;
        --only=*) ONLY_THEME="${1#--only=}" ;;
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

theme_matches() {
    local name="$1"
    local filter="$2"
    if [[ -z "$filter" ]]; then
        return 0
    fi
    local lower_name lower_filter
    lower_name="${name,,}"
    lower_filter="${filter,,}"
    if [[ "$lower_name" == *"$lower_filter"* ]]; then
        return 0
    fi
    return 1
}

default_cloned=0
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    read -r name url _ <<<"$line"
    if [[ -z "$name" || -z "$url" ]]; then
        echo "警告: 无法解析行: $line" >&2
        continue
    fi

    if [[ -n "$ONLY_THEME" ]]; then
        if ! theme_matches "$name" "$ONLY_THEME"; then
            continue
        fi
    fi

    if [[ "$name" == "$DEFAULT_THEME" ]]; then
        echo "★ 默认主题: $name"
        default_cloned=1
    fi
    clone_one "$name" "$url"
done <"$MANIFEST"

if [[ -z "$ONLY_THEME" && "$default_cloned" -eq 0 ]]; then
    echo "警告: 默认主题 $DEFAULT_THEME 未在清单中找到" >&2
fi

echo "完成。主题目录位于: $THIRD_PARTY"
echo "默认主题: $DEFAULT_THEME"
