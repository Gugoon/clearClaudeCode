# clearClaudeCode

macOS(및 Linux 호환)에서 **Claude Code(CLI)와 관련된 모든 흔적**을 한 번에 찾아서 제거하는 단일 셸 스크립트입니다.

설치 방식(npm / yarn / pnpm / bun / Homebrew / 네이티브 인스톨러)에 관계없이 자동으로 탐지하며, 사용자 데이터·캐시·설정·바이너리·macOS 라이브러리 항목·데스크톱 앱까지 한 번의 명령으로 정리합니다.

---

## 빠른 시작

```bash
git clone https://github.com/Gugoon/clearClaudeCode.git
cd clearClaudeCode
chmod +x clear-claude-code.sh
./clear-claude-code.sh
```

---

## 사용법

스크립트는 단 3가지 모드로 동작합니다.

| 명령 | 동작 |
|---|---|
| `./clear-claude-code.sh` | 발견된 흔적을 표시하고, `yes` 입력 시 모두 삭제 (기본) |
| `./clear-claude-code.sh -y` | 확인 프롬프트 없이 즉시 삭제 |
| `./clear-claude-code.sh -n` | 미리보기 — 무엇을 지울지 보여주고 종료 (삭제 안 함) |
| `./clear-claude-code.sh -h` | 도움말 출력 |

### 권장 워크플로

```bash
# 1) 무엇이 지워질지 먼저 확인
./clear-claude-code.sh -n

# 2) (선택) 직접 백업
tar -czf ~/claude-backup-$(date +%F).tar.gz ~/.claude ~/.claude.json

# 3) 실제 삭제
./clear-claude-code.sh
```

---

## 제거되는 항목 상세

### 1. 사용자 데이터 (`~/.claude/`)

> ⚠️ 이 디렉토리 전체가 `rm -rf`로 삭제됩니다. **히스토리·메모리·세션이 모두 사라집니다.**

| 경로 | 내용 |
|---|---|
| `history.jsonl` | 전체 명령·대화 히스토리 |
| `projects/` | 프로젝트별 대화·세션 기록 |
| `projects/*/memory/` | 영구 메모리(사용자 프로필, 피드백 등) |
| `sessions/` | 세션 상태 |
| `file-history/` | 파일 편집 이력 |
| `todos/`, `tasks/`, `plans/` | 작업 데이터 |
| `settings.json` | 사용자 설정 |
| `plugins/`, `ide/` | 플러그인 / IDE 통합 데이터 |
| `shell-snapshots/`, `paste-cache/`, `cache/` | 셸/페이스트/일반 캐시 |
| `statsig/`, `telemetry/`, `debug/` | 텔레메트리 및 디버그 로그 |
| `backups/` | Claude Code가 만든 자체 백업 |

### 2. 설정·인증

- `~/.claude.json` — **인증 토큰, MCP 서버 설정 등**
- `~/.claude.json.backup`, `~/.claude.json.lock`
- `~/.config/claude`, `~/.config/claude-code`
- `~/.cache/claude`, `~/.cache/claude-code`

### 3. 바이너리 (네이티브 인스톨러)

- `~/.local/bin/claude`, `~/.local/bin/claude-code`
- `~/.local/share/claude`, `~/.local/share/claude-code` *(수백 MB)*
- `~/.local/state/claude`, `~/.local/state/claude-code`

### 4. 패키지 매니저 글로벌 패키지

`@anthropic-ai/claude-code`를 다음 매니저에서 자동 탐지·제거합니다.

- **npm** — `npm uninstall -g` (실패 시 `sudo` 자동 폴백)
- **yarn** — `yarn global remove`
- **pnpm** — `pnpm remove -g`
- **bun** — `bun remove -g`

### 5. Homebrew

다음 formula / cask를 자동 탐지·제거합니다.

- `claude`, `claude-code`, `claude-desktop`

### 6. 시스템 전역 바이너리 (sudo 자동 폴백)

- `/usr/local/bin/claude`, `/usr/local/bin/claude-code`
- `/usr/local/lib/node_modules/@anthropic-ai/claude-code`
- `/opt/homebrew/bin/claude`, `/opt/homebrew/bin/claude-code`
- `/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code`

### 7. macOS 라이브러리

- `~/Library/Caches/claude-cli-nodejs`
- `~/Library/Caches/com.anthropic.claudecode`
- `~/Library/Caches/Claude`
- `~/Library/Application Support/Claude`
- `~/Library/Application Support/claude-code`
- `~/Library/Logs/Claude`, `~/Library/Logs/claude-code`
- `~/Library/HTTPStorages/com.anthropic.claudecode`
- `~/Library/WebKit/com.anthropic.claudecode`
- `~/Library/Preferences/com.anthropic.claude*.plist`
- `~/Library/Saved Application State/com.anthropic.claude*.savedState`
- `~/Library/Group Containers/*.com.anthropic.claude*`
- `~/Library/Containers/com.anthropic.claude*`

### 8. Claude Desktop 앱

- `~/Applications/Claude.app`
- `/Applications/Claude.app`

### 9. PATH 상의 모든 `claude`/`claude-code` 실행 파일

`command -v -a claude` / `command -v -a claude-code`로 발견되는 모든 경로를 추가 수집하여 위에서 놓친 흔적도 포착합니다.

---

## 영향받지 **않는** 것

- ☁️ **Anthropic 서버의 계정·구독** — 재설치 후 로그인하면 그대로 사용 가능
- 🔑 **셸 환경변수** (`ANTHROPIC_API_KEY`, `CLAUDE_*` 등) — `~/.zshrc` 등에 있다면 직접 제거 필요
- ☁️ **클라우드에 동기화된 데이터**(예: 원격 routines)
- 📂 **사용자 작업 코드** — 이 스크립트는 `~/.claude/` 외부의 프로젝트 코드는 절대 건드리지 않습니다

---

## 안전 장치

스크립트는 의도치 않은 데이터 손실을 방지하기 위해 다음을 보장합니다.

- ✅ **root 실행 거부** — 일반 사용자로만 동작 (시스템 경로는 내부에서 `sudo`로 처리)
- ✅ **화이트리스트 기반** — 미리 정의된 경로/패턴 외에는 절대 손대지 않음
- ✅ **글롭 범위 제한** — 모든 와일드카드 매칭은 `$HOME` 또는 `/Library` 표준 위치 안으로만 한정
- ✅ **확인 프롬프트** — 기본 모드에서 정확히 `yes`를 입력해야 진행 (`-y`로 건너뛸 수 있음)
- ✅ **dry-run 지원** — `-n`으로 삭제 없이 무엇이 지워질지만 확인 가능
- ✅ **sudo 자동 폴백** — `rm`이 권한 부족으로 실패하면 `sudo rm`으로 한 번 더 시도

---

## 작동 원리

```
┌─ 1. 탐색 ──────────────────────────────────────┐
│  • 알려진 경로(파일/디렉토리/심볼릭 링크) 검사  │
│  • 글롭 패턴(macOS Library, plist 등) 매칭    │
│  • npm/yarn/pnpm/bun 글로벌 패키지 조회        │
│  • brew list (formula/cask) 조회              │
│  • command -v -a 로 PATH 보강 검색            │
└─────────────────────────────────────────────────┘
                      ↓
┌─ 2. 표시 ──────────────────────────────────────┐
│  발견된 모든 항목과 각 크기 출력                │
└─────────────────────────────────────────────────┘
                      ↓
┌─ 3. 확인 ──────────────────────────────────────┐
│  -y 없으면 'yes' 입력 요구                     │
│  -n 이면 여기서 종료                           │
└─────────────────────────────────────────────────┘
                      ↓
┌─ 4. 실행 ──────────────────────────────────────┐
│  • 실행 중인 claude 프로세스 종료              │
│  • 패키지 매니저로 글로벌 패키지 제거          │
│  • Homebrew formula/cask 제거                 │
│  • rm -rf로 모든 경로 삭제 (필요 시 sudo)     │
└─────────────────────────────────────────────────┘
```

---

## 출력 예시

```
[INFO] Claude Code 흔적을 탐색합니다...

═══ 발견된 Claude Code 흔적 ═══

[파일/디렉토리]
  /Users/me/.claude  (238M)
  /Users/me/.claude.json  (48K)
  /Users/me/.claude.json.backup  (4.0K)
  /Users/me/.local/bin/claude  (→ /Users/me/.local/share/claude/versions/2.1.119)
  /Users/me/.local/share/claude  (598M)
  /Users/me/Library/Caches/claude-cli-nodejs  (4.9M)

모두 삭제합니다. 되돌릴 수 없습니다. 'yes' 입력: yes

✓ 삭제: /Users/me/.claude
✓ 삭제: /Users/me/.claude.json
✓ 삭제: /Users/me/.local/share/claude
...

완료: 모든 흔적이 제거되었습니다.
```

---

## 시스템 요구사항

- macOS (주 타겟) 또는 Linux (호환)
- bash 3.2+ (macOS 기본 bash 동작)
- 기본 유틸리티: `rm`, `du`, `grep`, `awk`, `sed`, `find`, `pgrep`, `pkill`

---

## 주의사항

> ⚠️ **이 작업은 되돌릴 수 없습니다.**
>
> 실행 전, 보존하고 싶은 히스토리·메모리·세션이 있다면 반드시 백업하세요.
> Anthropic **계정 자체는 영향받지 않으므로**, 새로 설치하고 로그인하면 정상적으로 다시 사용할 수 있습니다.

---

## 기여

이슈·풀 리퀘스트 환영합니다. Claude Code가 새로운 위치에 데이터를 저장하기 시작했다면 알려주세요.
