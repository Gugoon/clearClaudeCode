#!/usr/bin/env bash
#
# clear-claude-code.sh
# Claude Code의 흔적을 단계별로 제거합니다.
#
# 사용법:
#   ./clear-claude-code.sh        대화형 메뉴로 단계 선택
#   ./clear-claude-code.sh -1     [Level 1] 사용 흔적만 (로그인 유지)
#   ./clear-claude-code.sh -2     [Level 2] Level 1 + 로그인/설정 제거
#   ./clear-claude-code.sh -3     [Level 3] Level 2 + 완전 언인스톨
#
#   추가 옵션 (다른 옵션과 조합 가능):
#     -y    확인 없이 즉시 진행
#     -n    미리보기 — 무엇을 지울지 보여주고 종료
#     -h    도움말
#
# 예시:
#   ./clear-claude-code.sh -1 -n     Level 1 미리보기
#   ./clear-claude-code.sh -3 -y     완전 제거를 확인 없이 즉시
#

set -u
set -o pipefail

# ── 옵션 파싱 ───────────────────────────────────────────────────────────────
LEVEL=0; YES=0; DRY=0
for arg in "$@"; do
    case "$arg" in
        -1) LEVEL=1 ;;
        -2) LEVEL=2 ;;
        -3) LEVEL=3 ;;
        -y) YES=1 ;;
        -n) DRY=1 ;;
        -h|--help) sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "알 수 없는 옵션: $arg" >&2; exit 2 ;;
    esac
done

[[ "${EUID:-$(id -u)}" -eq 0 ]] && { echo "root로 실행하지 마세요." >&2; exit 1; }

# ── 색상 ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[1m'; D=$'\033[2m'; N=$'\033[0m'
else R=""; G=""; Y=""; B=""; D=""; N=""; fi

# ── 대화형 메뉴 (옵션 미지정 시) ───────────────────────────────────────────
if (( LEVEL == 0 )); then
    cat <<EOF

${B}어떤 단계까지 정리하시겠습니까?${N}

  ${B}1)${N} 사용 흔적만 제거          ${D}— 히스토리·세션·캐시 등 사용 데이터${N}
                                ${D}  로그인·설정 유지, 재로그인 불필요${N}

  ${B}2)${N} 로그인 정보까지 제거       ${D}— 1번 + 인증 토큰·설정·MCP 구성${N}
                                ${D}  다음 사용 시 재로그인 필요${N}

  ${B}3)${N} Claude Code 완전 제거     ${D}— 1, 2번 + 바이너리·앱 자체${N}
                                ${D}  Claude Code가 시스템에서 사라짐${N}

EOF
    printf "선택 [1/2/3, q=취소]: "
    IFS= read -r choice || choice="q"
    case "$choice" in
        1) LEVEL=1 ;;
        2) LEVEL=2 ;;
        3) LEVEL=3 ;;
        q|Q|"") echo "취소되었습니다."; exit 0 ;;
        *) echo "잘못된 선택: $choice" >&2; exit 2 ;;
    esac
    echo
fi

LEVEL_NAME=""
case "$LEVEL" in
    1) LEVEL_NAME="Level 1: 사용 흔적만" ;;
    2) LEVEL_NAME="Level 2: 사용 흔적 + 로그인 정보" ;;
    3) LEVEL_NAME="Level 3: 완전 제거 (언인스톨)" ;;
esac

# ── 경로/패키지 수집 ────────────────────────────────────────────────────────
PATHS=()
PMS=()
BREWS=()

add() { for p in "$@"; do [[ -e "$p" || -L "$p" ]] && PATHS+=("$p"); done; }
glob() { local m; for m in $(compgen -G "$1" 2>/dev/null); do PATHS+=("$m"); done; }

# ── Level 1: 사용 흔적만 (~/.claude/ 안의 데이터 디렉토리만 골라서 삭제) ──
if (( LEVEL == 1 )); then
    add "$HOME/.claude/history.jsonl"
    add "$HOME/.claude/projects"
    add "$HOME/.claude/sessions"
    add "$HOME/.claude/file-history"
    add "$HOME/.claude/todos"
    add "$HOME/.claude/tasks"
    add "$HOME/.claude/plans"
    add "$HOME/.claude/shell-snapshots"
    add "$HOME/.claude/paste-cache"
    add "$HOME/.claude/cache"
    add "$HOME/.claude/debug"
    add "$HOME/.claude/telemetry"
    add "$HOME/.claude/backups"
    add "$HOME/.claude/downloads"
    add "$HOME/.claude/session-env"
    add "$HOME/.claude/mcp-needs-auth-cache.json"
fi

# ── 외부 캐시·로그 (모든 레벨 공통) ────────────────────────────────────────
add "$HOME/.cache/claude" "$HOME/.cache/claude-code"
add "$HOME/Library/Caches/claude-cli-nodejs"
add "$HOME/Library/Caches/com.anthropic.claudecode"
add "$HOME/Library/Caches/Claude"
add "$HOME/Library/Logs/Claude"
add "$HOME/Library/Logs/claude-code"
add "$HOME/Library/HTTPStorages/com.anthropic.claudecode"
add "$HOME/Library/WebKit/com.anthropic.claudecode"

# ── Level 2: 로그인/설정 (~/.claude 통째로 + 인증/설정 파일) ───────────────
if (( LEVEL >= 2 )); then
    add "$HOME/.claude"           # 통째로 (settings, plugins, ide, statsig, projects 모두)
    add "$HOME/.claude.json"      # 인증 토큰, MCP 설정
    add "$HOME/.claude.json.backup"
    add "$HOME/.claude.json.lock"
    add "$HOME/.config/claude" "$HOME/.config/claude-code"
    add "$HOME/Library/Application Support/Claude"
    add "$HOME/Library/Application Support/claude-code"
    glob "$HOME/Library/Preferences/com.anthropic.claude*.plist"
    glob "$HOME/Library/Saved Application State/com.anthropic.claude*.savedState"
    glob "$HOME/Library/Group Containers/*.com.anthropic.claude*"
    glob "$HOME/Library/Containers/com.anthropic.claude*"
fi

# ── Level 3: 언인스톨 (바이너리·앱·패키지 매니저) ──────────────────────────
if (( LEVEL >= 3 )); then
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
    # Desktop 앱
    add "$HOME/Applications/Claude.app" "/Applications/Claude.app"
    # 시스템 바이너리
    add "/usr/local/bin/claude" "/usr/local/bin/claude-code"
    add "/usr/local/lib/node_modules/@anthropic-ai/claude-code"
    add "/opt/homebrew/bin/claude" "/opt/homebrew/bin/claude-code"
    add "/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code"
    # PATH 보강
    while IFS= read -r p; do [[ -n "$p" ]] && add "$p"; done < <(
        command -v -a claude 2>/dev/null
        command -v -a claude-code 2>/dev/null
    )
    # 패키지 매니저
    PKG="@anthropic-ai/claude-code"
    command -v npm  >/dev/null 2>&1 && npm  list -g --depth=0 --silent 2>/dev/null | grep -q "$PKG" && PMS+=("npm")
    command -v yarn >/dev/null 2>&1 && yarn global list --depth=0 2>/dev/null | grep -q "$PKG" && PMS+=("yarn")
    command -v pnpm >/dev/null 2>&1 && pnpm list -g --depth=0 2>/dev/null | grep -q "$PKG" && PMS+=("pnpm")
    command -v bun  >/dev/null 2>&1 && bun  pm ls -g 2>/dev/null | grep -q "$PKG" && PMS+=("bun")
    # Homebrew
    if command -v brew >/dev/null 2>&1; then
        while IFS= read -r l; do [[ -n "$l" ]] && BREWS+=("$l"); done < <(
            { brew list --formula 2>/dev/null; brew list --cask 2>/dev/null; } | grep -E '^claude(-code|-desktop)?$'
        )
    fi
fi

# 중복 제거
if (( ${#PATHS[@]} > 0 )); then
    IFS=$'\n' PATHS=($(printf '%s\n' "${PATHS[@]}" | awk '!seen[$0]++'))
    unset IFS
fi

# ── 결과 표시 ───────────────────────────────────────────────────────────────
TOTAL=$(( ${#PATHS[@]} + ${#PMS[@]} + ${#BREWS[@]} ))
printf "%s═══ Claude Code 정리 — %s ═══%s\n\n" "$B" "$LEVEL_NAME" "$N"

if (( TOTAL == 0 )); then
    printf "%s제거할 항목이 없습니다.%s\n" "$G" "$N"
    exit 0
fi

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
(( ${#PMS[@]}   > 0 )) && { echo "[패키지 매니저] ${PMS[*]} → @anthropic-ai/claude-code"; echo; }
(( ${#BREWS[@]} > 0 )) && { echo "[Homebrew] ${BREWS[*]}"; echo; }

# ── dry-run 종료 ────────────────────────────────────────────────────────────
if (( DRY )); then
    printf "%s[-n] 미리보기 모드 — 삭제하지 않고 종료합니다.%s\n" "$Y" "$N"
    exit 0
fi

# ── 확인 ────────────────────────────────────────────────────────────────────
if (( ! YES )); then
    printf "%s위 항목을 모두 삭제합니다. 되돌릴 수 없습니다.%s '%syes%s' 입력: " "$Y" "$N" "$B" "$N"
    IFS= read -r r || r=""
    [[ "$r" != "yes" ]] && { echo "취소되었습니다."; exit 0; }
fi

# ── 실행 중인 프로세스 종료 ────────────────────────────────────────────────
pgrep -f claude-code >/dev/null 2>&1 && pkill -f claude-code 2>/dev/null
pgrep -x claude      >/dev/null 2>&1 && pkill -x claude      2>/dev/null
sleep 1

# ── 패키지 매니저로 제거 (Level 3 전용) ────────────────────────────────────
RC=0
for pm in "${PMS[@]:-}"; do
    case "$pm" in
        npm)  npm  uninstall -g "@anthropic-ai/claude-code" >/dev/null 2>&1 \
              || sudo npm uninstall -g "@anthropic-ai/claude-code" >/dev/null 2>&1 ;;
        yarn) yarn global remove "@anthropic-ai/claude-code" >/dev/null 2>&1 ;;
        pnpm) pnpm remove -g "@anthropic-ai/claude-code" >/dev/null 2>&1 ;;
        bun)  bun  remove -g "@anthropic-ai/claude-code" >/dev/null 2>&1 ;;
    esac
    if [[ $? -eq 0 ]]; then printf "%s✓%s %s 글로벌 패키지 제거\n" "$G" "$N" "$pm"
    else printf "%s✗%s %s 제거 실패\n" "$R" "$N" "$pm"; RC=1; fi
done
for f in "${BREWS[@]:-}"; do
    if brew uninstall --force "$f" >/dev/null 2>&1; then printf "%s✓%s brew 제거: %s\n" "$G" "$N" "$f"
    else printf "%s✗%s brew 제거 실패: %s\n" "$R" "$N" "$f"; RC=1; fi
done

# ── 파일 삭제 (시스템 경로는 sudo 자동 폴백) ───────────────────────────────
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
if (( RC == 0 )); then
    printf "%s%s완료: %s 정리가 끝났습니다.%s\n" "$B" "$G" "$LEVEL_NAME" "$N"
    case "$LEVEL" in
        1) printf "%s설정·로그인은 그대로 — claude를 다시 실행하면 정상 동작합니다.%s\n" "$D" "$N" ;;
        2) printf "%sclaude를 다시 실행하면 로그인 화면이 뜹니다.%s\n" "$D" "$N" ;;
        3) printf "%sClaude Code가 시스템에서 완전히 제거되었습니다.%s\n" "$D" "$N" ;;
    esac
else
    printf "%s%s일부 항목 제거 실패. 위 로그 확인.%s\n" "$B" "$Y" "$N"
fi

exit $RC
