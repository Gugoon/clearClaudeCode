# clearClaudeCode

macOS(및 Linux 호환)에서 **Claude Code의 흔적을 단계별로 제거**하는 단일 셸 스크립트입니다.

상황에 맞게 **3단계 중 원하는 깊이를 선택**할 수 있습니다.

| 단계 | 무엇을 정리하나 | 언제 쓰나 |
|---|---|---|
| **Level 1** | 사용 흔적만 (히스토리·세션·캐시) | 깨끗한 상태로 다시 쓰고 싶을 때. **로그인 유지** |
| **Level 2** | Level 1 + 로그인/설정/MCP 구성 | 계정을 바꾸거나 설정을 초기화하고 싶을 때 |
| **Level 3** | Level 2 + 바이너리·앱·패키지 매니저 글로벌 | Claude Code를 시스템에서 **완전히 제거** |

---

## 빠른 시작

```bash
git clone https://github.com/Gugoon/clearClaudeCode.git
cd clearClaudeCode
chmod +x clear-claude-code.sh
./clear-claude-code.sh
```

옵션 없이 실행하면 **대화형 메뉴**로 단계를 선택할 수 있습니다.

```
어떤 단계까지 정리하시겠습니까?

  1) 사용 흔적만 제거          — 히스토리·세션·캐시 등 사용 데이터
                                로그인·설정 유지, 재로그인 불필요

  2) 로그인 정보까지 제거       — 1번 + 인증 토큰·설정·MCP 구성
                                다음 사용 시 재로그인 필요

  3) Claude Code 완전 제거     — 1, 2번 + 바이너리·앱 자체
                                Claude Code가 시스템에서 사라짐

선택 [1/2/3, q=취소]:
```

---

## 사용법

### 단계 옵션 (택 1)
| 옵션 | 동작 |
|---|---|
| `-1` | **Level 1** — 사용 흔적만 제거 |
| `-2` | **Level 2** — Level 1 + 로그인/설정 |
| `-3` | **Level 3** — Level 2 + 완전 언인스톨 |
| (없음) | 대화형 메뉴 표시 |

### 모드 옵션 (조합 가능)
| 옵션 | 동작 |
|---|---|
| (없음) | 발견된 항목을 보여주고 `yes` 확인 후 진행 |
| `-y` | 확인 프롬프트 없이 즉시 실행 |
| `-n` | **미리보기** — 무엇을 지울지 보여주고 종료 (삭제 안 함) |
| `-h` | 도움말 |

### 예시
```bash
./clear-claude-code.sh              # 메뉴로 단계 선택 → 확인 후 삭제
./clear-claude-code.sh -1           # Level 1을 확인 후 삭제
./clear-claude-code.sh -1 -n        # Level 1 미리보기
./clear-claude-code.sh -3 -y        # Level 3을 확인 없이 즉시 실행
```

### 권장 워크플로
```bash
# 1) 미리보기로 확인
./clear-claude-code.sh -2 -n

# 2) (선택) 백업
tar -czf ~/claude-backup-$(date +%F).tar.gz ~/.claude ~/.claude.json

# 3) 실제 실행
./clear-claude-code.sh -2
```

---

## Level 1 — 사용 흔적만 제거

> 💡 **로그인·설정·플러그인은 그대로 유지**됩니다. claude를 다시 실행하면 재로그인 없이 바로 사용 가능합니다.

### 삭제되는 항목
| 경로 | 내용 |
|---|---|
| `~/.claude/history.jsonl` | 전체 명령·대화 히스토리 |
| `~/.claude/projects/` | 프로젝트별 대화·세션 기록 + 영구 메모리 |
| `~/.claude/sessions/` | 세션 상태 |
| `~/.claude/file-history/` | 파일 편집 이력 |
| `~/.claude/todos/`, `tasks/`, `plans/` | 작업·계획 데이터 |
| `~/.claude/shell-snapshots/`, `paste-cache/` | 셸·페이스트 캐시 |
| `~/.claude/cache/`, `debug/`, `telemetry/` | 일반 캐시·디버그·텔레메트리 |
| `~/.claude/backups/`, `downloads/`, `session-env/` | 자체 백업·다운로드·세션 환경 |
| `~/.claude/mcp-needs-auth-cache.json` | MCP 인증 캐시 |
| `~/.cache/claude*` | XDG 캐시 |
| `~/Library/Caches/claude-cli-nodejs` | macOS 캐시 |
| `~/Library/Caches/com.anthropic.claudecode` | macOS 캐시 (Desktop) |
| `~/Library/Caches/Claude` | macOS 캐시 (Desktop) |
| `~/Library/Logs/Claude*` | macOS 로그 |
| `~/Library/HTTPStorages/com.anthropic.claudecode` | HTTP 저장소 |
| `~/Library/WebKit/com.anthropic.claudecode` | WebKit 데이터 |

### 보존되는 항목 (`~/.claude/` 내부)
- `settings.json` — 사용자 설정 (테마·모델 등)
- `plugins/` — 설치된 플러그인
- `ide/` — IDE 통합 데이터
- `statsig/` — 사용자 식별자
- `~/.claude.json` — **로그인 토큰** (이게 남아있어야 재로그인 불필요)

---

## Level 2 — 로그인 정보까지 제거

> ⚠️ **다음 사용 시 재로그인이 필요**합니다. MCP 서버 설정도 사라집니다.

### Level 1에 추가로 삭제되는 항목
| 경로 | 내용 |
|---|---|
| `~/.claude/` (통째로) | settings·plugins·ide·statsig·projects 등 모든 사용자 데이터 |
| `~/.claude.json` | **인증 토큰, MCP 서버 설정** |
| `~/.claude.json.backup`, `~/.claude.json.lock` | 백업·잠금 파일 |
| `~/.config/claude*` | XDG 설정 |
| `~/Library/Application Support/Claude` | macOS 앱 데이터 |
| `~/Library/Application Support/claude-code` | CLI 앱 데이터 |
| `~/Library/Preferences/com.anthropic.claude*.plist` | macOS 환경설정 |
| `~/Library/Saved Application State/com.anthropic.claude*.savedState` | 앱 저장 상태 |
| `~/Library/Group Containers/*.com.anthropic.claude*` | 그룹 컨테이너 |
| `~/Library/Containers/com.anthropic.claude*` | 샌드박스 컨테이너 |

---

## Level 3 — Claude Code 완전 제거 (언인스톨)

> ⚠️ **Claude Code가 시스템에서 사라집니다.** 다시 사용하려면 재설치가 필요합니다.

### Level 2에 추가로 삭제되는 항목

#### 네이티브 인스톨러
- `~/.local/bin/claude`, `~/.local/bin/claude-code`
- `~/.local/share/claude*` *(수백 MB의 실제 바이너리)*
- `~/.local/state/claude*`

#### Bun
- `~/.bun/bin/claude`
- `~/.bun/install/global/node_modules/@anthropic-ai/claude-code`

#### Claude Desktop 앱
- `~/Applications/Claude.app`
- `/Applications/Claude.app` *(sudo 자동 폴백)*

#### 시스템 전역 바이너리 (sudo 자동 폴백)
- `/usr/local/bin/claude`, `/usr/local/bin/claude-code`
- `/usr/local/lib/node_modules/@anthropic-ai/claude-code`
- `/opt/homebrew/bin/claude`, `/opt/homebrew/bin/claude-code`
- `/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code`

#### 패키지 매니저 글로벌 패키지 (`@anthropic-ai/claude-code`)
- **npm** — `npm uninstall -g` (실패 시 `sudo` 자동 폴백)
- **yarn** — `yarn global remove`
- **pnpm** — `pnpm remove -g`
- **bun** — `bun remove -g`

#### Homebrew (formula / cask)
- `claude`, `claude-code`, `claude-desktop`

#### PATH 보강
- `command -v -a claude`, `command -v -a claude-code`로 발견되는 모든 추가 경로

---

## 영향받지 **않는** 것 (모든 레벨)

- ☁️ **Anthropic 서버의 계정·구독** — 재설치/재로그인하면 그대로 사용 가능
- 🔑 **셸 환경변수** (`ANTHROPIC_API_KEY`, `CLAUDE_*` 등) — `~/.zshrc` 등에 있다면 직접 제거 필요
- ☁️ **클라우드에 동기화된 데이터**(예: 원격 routines)
- 📂 **사용자 작업 코드** — 이 스크립트는 `~/.claude/` 외부의 프로젝트 코드는 절대 건드리지 않습니다

---

## 안전 장치

- ✅ **root 실행 거부** — 일반 사용자로만 동작 (시스템 경로는 내부에서 `sudo`로 처리)
- ✅ **화이트리스트 기반** — 미리 정의된 경로/패턴 외에는 절대 손대지 않음
- ✅ **글롭 범위 제한** — 모든 와일드카드 매칭은 `$HOME` 또는 `/Library` 표준 위치 안으로만 한정
- ✅ **확인 프롬프트** — 기본 모드에서 정확히 `yes`를 입력해야 진행 (`-y`로 건너뛸 수 있음)
- ✅ **dry-run 지원** — `-n`으로 삭제 없이 무엇이 지워질지만 확인 가능
- ✅ **sudo 자동 폴백** — `rm`이 권한 부족으로 실패하면 `sudo rm`으로 한 번 더 시도
- ✅ **단계 선택** — 필요한 만큼만 정리, 과도한 삭제 방지

---

## 작동 원리

```
┌─ 1. 단계 선택 ────────────────────────────────────────┐
│  옵션(-1/-2/-3) 또는 대화형 메뉴로 Level 결정         │
└────────────────────────────────────────────────────────┘
                        ↓
┌─ 2. 탐색 ─────────────────────────────────────────────┐
│  • Level별로 정의된 경로 검사 (파일/디렉토리/심볼릭)  │
│  • 글롭 패턴(plist, Group Containers 등) 매칭        │
│  • Level 3: npm/yarn/pnpm/bun/brew 글로벌 패키지 조회│
│  • Level 3: command -v -a 로 PATH 보강 검색          │
└────────────────────────────────────────────────────────┘
                        ↓
┌─ 3. 표시 ─────────────────────────────────────────────┐
│  발견된 항목과 각 크기 출력                            │
└────────────────────────────────────────────────────────┘
                        ↓
┌─ 4. 확인 ─────────────────────────────────────────────┐
│  -y 없으면 'yes' 입력 요구                            │
│  -n 이면 여기서 종료                                  │
└────────────────────────────────────────────────────────┘
                        ↓
┌─ 5. 실행 ─────────────────────────────────────────────┐
│  • 실행 중인 claude 프로세스 종료                     │
│  • (Level 3) 패키지 매니저로 글로벌 패키지 제거       │
│  • (Level 3) Homebrew formula/cask 제거              │
│  • rm -rf로 모든 경로 삭제 (필요 시 sudo 폴백)       │
└────────────────────────────────────────────────────────┘
```

---

## 출력 예시 (Level 1)

```
═══ Claude Code 정리 — Level 1: 사용 흔적만 ═══

[파일/디렉토리]
  /Users/me/.claude/history.jsonl  (196K)
  /Users/me/.claude/projects  (209M)
  /Users/me/.claude/sessions  (4.0K)
  /Users/me/.claude/file-history  (23M)
  ...
  /Users/me/Library/Caches/claude-cli-nodejs  (4.9M)

위 항목을 모두 삭제합니다. 되돌릴 수 없습니다. 'yes' 입력: yes

✓ 삭제: /Users/me/.claude/history.jsonl
✓ 삭제: /Users/me/.claude/projects
...

완료: Level 1: 사용 흔적만 정리가 끝났습니다.
설정·로그인은 그대로 — claude를 다시 실행하면 정상 동작합니다.
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
> - 보존하고 싶은 데이터는 **실행 전에 직접 백업**하세요.
> - 어떤 항목이 지워질지 **확신이 없다면 `-n`으로 미리 확인**하세요.
> - Anthropic **계정 자체는 영향받지 않으므로**, 재설치/재로그인하면 정상 사용 가능합니다.

---

## 기여

이슈·풀 리퀘스트 환영합니다. Claude Code가 새로운 위치에 데이터를 저장하기 시작했다면 알려주세요.
