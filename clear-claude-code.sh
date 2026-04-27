#!/usr/bin/env bash
#
# clear-claude-code.sh
# Claude Code(CLI/Desktop)의 모든 흔적을 찾아서 제거합니다.
#
# 사용법:
#   ./clear-claude-code.sh        탐색 결과 확인 후 yes 입력 시 모두 삭제
#   ./clear-claude-code.sh -y     확인 없이 즉시 삭제
#   ./clear-claude-code.sh -n     무엇을 지울지 보기만 (삭제 안 함)
#

set -u
set -o pipefail

YES=0; DRY=0
for arg in "$@"; do
    case "$arg" in
        -y) YES=1 ;;
        -n) DRY=1 ;;
        -h|--help) sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "알 수 없는 옵션: $arg" >&2; exit 2 ;;
    esac
done

[[ "${EUID:-$(id -u)}" -eq 0 ]] && { echo "root로 실행하지 마세요." >&2; exit 1; }

if [[ -t 1 ]]; then R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'
else R=""; G=""; Y=""; B=""; N=""; fi

# ── 1) 모든 후보 경로 수집 ─────────────────────────────────────────────────
PATHS=()
add() { for p in "$@"; do [[ -e "$p" || -L "$p" ]] && PATHS+=("$p"); done; }
glob() { local m; for m in $(compgen -G "$1" 2>/dev/null); do PATHS+=("$m"); done; }

# 사용자 데이터·설정·캐시
add "$HOME/.claude" "$HOME/.claude.json" "$HOME/.claude.json.backup" "$HOME/.claude.json.lock"
add "$HOME/.config/claude" "$HOME/.config/claude-code"
add "$HOME/.cache/claude" "$HOME/.cache/claude-code"

# 네이티브 인스톨러
glob "$HOME/.local/bin/claude"
glob "$HOME/.local/bin/claude-code"
glob "$HOME/.local/share/claude"
glob "$HOME/.local/share/claude-code"
glob "$HOME/.local/state/claude"
glob "$HOME/.local/state/claude-code"

# Bun
glob "$HOME/.bun/bin/claude"
glob "$HOME/.bun/install/global/node_modules/@anthropic-ai/claude-code"

# macOS Library
LIB="$HOME/Library"
add "$LIB/Caches/claude-cli-nodejs" "$LIB/Caches/com.anthropic.claudecode" "$LIB/Caches/Claude"
add "$LIB/Application Support/Claude" "$LIB/Application Support/claude-code"
add "$LIB/Logs/Claude" "$LIB/Logs/claude-code"
add "$LIB/HTTPStorages/com.anthropic.claudecode" "$LIB/WebKit/com.anthropic.claudecode"
glob "$LIB/Preferences/com.anthropic.claude*.plist"
glob "$LIB/Saved Application State/com.anthropic.claude*.savedState"
glob "$LIB/Group Containers/*.com.anthropic.claude*"
glob "$LIB/Containers/com.anthropic.claude*"

# Desktop 앱
add "$HOME/Applications/Claude.app" "/Applications/Claude.app"

# PATH 상의 모든 claude 바이너리
while IFS= read -r p; do [[ -n "$p" ]] && add "$p"; done < <(command -v -a claude 2>/dev/null; command -v -a claude-code 2>/dev/null)

# 시스템 전역 바이너리
add "/usr/local/bin/claude" "/usr/local/bin/claude-code"
add "/usr/local/lib/node_modules/@anthropic-ai/claude-code"
add "/opt/homebrew/bin/claude" "/opt/homebrew/bin/claude-code"
add "/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code"

# 중복 제거
if (( ${#PATHS[@]} > 0 )); then
    IFS=$'\n' PATHS=($(printf '%s\n' "${PATHS[@]}" | awk '!seen[$0]++'))
    unset IFS
fi

# 패키지 매니저 글로벌 패키지
PKG="@anthropic-ai/claude-code"
PMS=()
command -v npm  >/dev/null 2>&1 && npm  list -g --depth=0 --silent 2>/dev/null | grep -q "$PKG" && PMS+=("npm")
command -v yarn >/dev/null 2>&1 && yarn global list --depth=0 2>/dev/null | grep -q "$PKG" && PMS+=("yarn")
command -v pnpm >/dev/null 2>&1 && pnpm list -g --depth=0 2>/dev/null | grep -q "$PKG" && PMS+=("pnpm")
command -v bun  >/dev/null 2>&1 && bun  pm ls -g 2>/dev/null | grep -q "$PKG" && PMS+=("bun")

BREWS=()
if command -v brew >/dev/null 2>&1; then
    while IFS= read -r l; do [[ -n "$l" ]] && BREWS+=("$l"); done < <(
        { brew list --formula 2>/dev/null; brew list --cask 2>/dev/null; } | grep -E '^claude(-code|-desktop)?$'
    )
fi

# ── 2) 결과 표시 ───────────────────────────────────────────────────────────
TOTAL=$(( ${#PATHS[@]} + ${#PMS[@]} + ${#BREWS[@]} ))
if (( TOTAL == 0 )); then
    printf "%s시스템에 Claude Code 흔적이 없습니다.%s\n" "$G" "$N"
    exit 0
fi

printf "\n%s═══ 발견된 Claude Code 흔적 ═══%s\n\n" "$B" "$N"

if (( ${#PATHS[@]} > 0 )); then
    echo "[파일/디렉토리]"
    for p in "${PATHS[@]}"; do
        if   [[ -L "$p" ]]; then sz="→ $(readlink "$p")"
        elif [[ -d "$p" ]]; then sz=$(du -sh -- "$p" 2>/dev/null | awk '{print $1}')
        else                     sz=$(du -h  -- "$p" 2>/dev/null | awk '{print $1}')
        fi
        printf "  %s  %s(%s)%s\n" "$p" "$Y" "$sz" "$N"
    done
    echo
fi
(( ${#PMS[@]}   > 0 )) && { echo "[패키지 매니저] ${PMS[*]} → $PKG"; echo; }
(( ${#BREWS[@]} > 0 )) && { echo "[Homebrew] ${BREWS[*]}"; echo; }

# ── 3) dry-run 종료 ────────────────────────────────────────────────────────
if (( DRY )); then
    printf "%s[-n] 삭제하지 않고 종료합니다.%s\n" "$Y" "$N"
    exit 0
fi

# ── 4) 확인 ────────────────────────────────────────────────────────────────
if (( ! YES )); then
    printf "%s모두 삭제합니다. 되돌릴 수 없습니다.%s '%syes%s' 입력: " "$Y" "$N" "$B" "$N"
    IFS= read -r r || r=""
    [[ "$r" != "yes" ]] && { echo "취소되었습니다."; exit 0; }
fi

# ── 5) 실행 중인 프로세스 종료 ─────────────────────────────────────────────
pgrep -f claude-code >/dev/null 2>&1 && pkill -f claude-code 2>/dev/null
pgrep -x claude      >/dev/null 2>&1 && pkill -x claude      2>/dev/null
sleep 1

# ── 6) 패키지 매니저로 제거 ────────────────────────────────────────────────
RC=0
for pm in "${PMS[@]:-}"; do
    case "$pm" in
        npm)  npm  uninstall -g "$PKG" >/dev/null 2>&1 || sudo npm uninstall -g "$PKG" >/dev/null 2>&1 ;;
        yarn) yarn global remove "$PKG" >/dev/null 2>&1 ;;
        pnpm) pnpm remove -g "$PKG" >/dev/null 2>&1 ;;
        bun)  bun  remove -g "$PKG" >/dev/null 2>&1 ;;
    esac
    if [[ $? -eq 0 ]]; then printf "%s✓%s %s 제거: %s\n" "$G" "$N" "$pm" "$PKG"
    else printf "%s✗%s %s 제거 실패: %s\n" "$R" "$N" "$pm" "$PKG"; RC=1; fi
done
for f in "${BREWS[@]:-}"; do
    if brew uninstall --force "$f" >/dev/null 2>&1; then printf "%s✓%s brew 제거: %s\n" "$G" "$N" "$f"
    else printf "%s✗%s brew 제거 실패: %s\n" "$R" "$N" "$f"; RC=1; fi
done

# ── 7) 파일 삭제 (시스템 경로는 sudo 자동 시도) ────────────────────────────
for p in "${PATHS[@]:-}"; do
    if rm -rf -- "$p" 2>/dev/null; then
        printf "%s✓%s 삭제: %s\n" "$G" "$N" "$p"
    elif sudo rm -rf -- "$p" 2>/dev/null; then
        printf "%s✓%s 삭제(sudo): %s\n" "$G" "$N" "$p"
    else
        printf "%s✗%s 삭제 실패: %s\n" "$R" "$N" "$p"; RC=1
    fi
done

echo
if (( RC == 0 )); then printf "%s%s완료: 모든 흔적이 제거되었습니다.%s\n" "$B" "$G" "$N"
else printf "%s%s일부 항목 제거 실패. 위 로그 확인.%s\n" "$B" "$Y" "$N"; fi

exit $RC
