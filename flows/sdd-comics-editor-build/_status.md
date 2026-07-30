# Status: sdd-comics-editor-build

## Current Phase

IMPLEMENTATION

## Phase Status

Docker Build (Phase 1-4) — DONE, см. `04-implementation-log.md` Progress Tracker. Windows CI MSB1008 — РЕШЕНО (не багфикс, custom target отключён от `ALL` как неиспользуемый — см. Blockers).

## Last Updated

2026-07-25 by Claude

## Blockers

- Нет активных блокеров. Windows CI MSB1008: после 4 раундов диагностики выяснилось, что сгенерированный `<Command>` в `.vcxproj` синтаксически корректен (root cause в MSBuild/CMake на `windows-2025-vs2026` toolset так и не подтверждён), но публикуемая custom-target'ом `Comics.Editor.Flutter.dll` **ничем не потребляется** — hostfxr/nethost interop в `editor_plugin.cpp` ещё не реализован (явный TODO/`not_implemented`-заглушка). Решение (подтверждено пользователем): `add_custom_target(editor_plugin_csharp ALL ...)` закомментирован в `windows/editor_plugin/CMakeLists.txt` (не удалён), temporary diagnostic-шаг убран из `build.yml`. Вернуть custom target, когда появится реальный hostfxr-вызов, и на этот раз сразу проверять реальным Windows CI, не полагаясь на macOS-локальную верификацию.

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-25)
- [x] Specifications drafted
- [x] Specifications approved (2026-07-25)
- [x] Plan drafted
- [x] Plan approved (2026-07-25)
- [x] Implementation started
- [x] Task 1.1 `docker/linux-build.Dockerfile` — собран и полностью верифицирован (`tool/docker-build.sh linux` — все 6 тестов зелёные)
- [x] Task 1.2 `docker/android-build.Dockerfile` — пересобран (`--system`/`chmod` + pre-baked NDK/CMake/platform-35) и полностью верифицирован
- [x] Task 2.1 `tool/docker-build.sh` — создан, `--platform linux/amd64`, `HOME`/`GRADLE_USER_HOME`/`JAVA_TOOL_OPTIONS`, персистентный Gradle-кэш (`.docker-cache/gradle/`)
- [x] Task 2.1 верификация: `tool/docker-build.sh linux` полный прогон на реальном репозитории — **пройден полностью** (все 6 тестов, включая `core_client_test.dart`)
- [x] Task 2.1 верификация: `tool/docker-build.sh android` полный прогон — **пройден полностью** (APK собран, тесты зелёные; `assembleRelease` 700s→92s после pre-bake SDK-компонентов)
- [x] Task 3.1/3.2 `.github/workflows/docker-build.yml` — создан (`docker-build-linux`/`docker-build-android`, триггеры main/nightly/release, публикация артефактов; `build.yml` не тронут)
- [x] Task 4.1 `docker/README.md` — создан
- [x] Task 4.2 финальное обновление `_status.md`/`04-implementation-log.md` — сделано
- [x] Implementation complete (Docker Build, Plan scope) — финальная приёмка `docker-build.yml` ждёт реального CI-прогона (не выполнимо локально агентом)
- [x] **Windows CI MSB1008** — root cause не подтверждён, но выяснено, что custom target публикует неиспользуемый артефакт (hostfxr interop — TODO). Custom target закомментирован в `CMakeLists.txt`, diagnostic-шаг убран из `build.yml`. Ждём коммита/пуша пользователем и финального зелёного CI-прогона для подтверждения.

## Context Notes

Key decisions and context for resuming:

- Цель: выделить всю сборку (локальную + GitHub Actions) `apps/comics-editor-v2.9` в отдельный flow; контейнеризировать через Docker то, что реально можно (Linux + Android), задокументировать остальное (Windows/macOS/iOS — нативные, Docker неприменим).
- База: два предыдущих flow (`sdd-comics-editor-v2.9`, `sdd-comics-editor-v2.9-android-ios`) оставили сборочную логику как побочный продукт — `.github/workflows/build.yml`+`release.yml`, `tool/build_headless.sh|ps1`, `tool/build_native.sh` в `apps/comics-editor-v2.9` (отдельный git-репозиторий, не трогать git).
- Незакрытый смежный вопрос из `sdd-comics-editor-v2.9-android-ios`: Linux headless-процесс падает на CI сразу на `ping` — диагностика улучшена (stderr+exit code в CoreException), причина ещё не найдена; воспроизвести локально на macOS через Docker amd64-эмуляцию не вышло (Rosetta в Docker Desktop на этой машине сломана). Контейнеризация Linux-сборки может дать воспроизводимую среду для этого бага, но это не основная цель этого flow.
- Docker локально подтверждён рабочим (Docker Desktop 28.5.1). Уточнение (в ходе Implementation): `docker build/run --platform linux/amd64` **работает** на этой машине через VM-механизм Docker Desktop (не через qemu-binfmt, который ломается при смешанной архитектуре) — реальная x64-верификация (совпадающая с архитектурой раннеров GH Actions) доступна и локально, не только на CI. `tool/docker-build.sh` жёстко фиксирует `platform=linux/amd64`.

### Решение: два раздельных процесса сборки (2026-07-25, в ходе Implementation)

Пользователь скорректировал архитектуру после того, как Task 1.1/1.2 (оба Dockerfile) были собраны и проверены: вместо замены шагов `build.yml` на Docker — **два независимых, параллельно живущих процесса**:

- **Native Build** (`.github/workflows/build.yml`) — как было, без изменений. Все 6 job (`analyze`, `build-windows`, `build-macos`, `build-linux`, `build-android`, `build-ios`), без Docker, на каждый push/PR/`workflow_dispatch`. Быстрая обратная связь.
- **Docker Build** (`.github/workflows/docker-build.yml`, новый, ещё не создан) — воспроизводимая сборка на образах `docker/linux-build.Dockerfile`/`docker/android-build.Dockerfile`. Триггеры: **только** `push: main`, nightly-расписание (cron), `release: published` — не на обычный PR/feature-push. Публикует финальные артефакты (`upload-artifact`, увеличенный retention; плюс прикрепление к GitHub Release при триггере `release`).

Оба процесса независимы (нет `needs` между ними), оба живут постоянно (не одноразовая миграция).

### Решение: Windows/macOS/iOS в Docker Build не добавляются (2026-07-25, уточнено при возврате к flow)

Пользователь спросил, можно ли аналогично вынести подготовительные этапы macOS/iOS + Windows в такой же Reproducible Docker Build (main/nightly/release + публикация артефактов). Решение — **нет**, оставить как в исходных requirements (`Won't Have`):
- **macOS/iOS**: у Docker нет понятия «macOS-контейнер» в принципе — не вопрос лицензии/обхода, контейнеризировать нечего. Единственное, что технически можно вынести (`flutter pub get`, CocoaPods) — секунды работы без дорогого тулчейна, выигрыша нет.
- **Windows**: Windows-контейнеры существуют и технически способны собирать WPF/MSVC/NativeAOT, GH `windows-latest` раннеры их поддерживают — но локальная машина разработчика (macOS) в принципе не может запускать Windows-контейнеры (Docker Desktop for Mac — только Linux-гости). Смысл всего flow («одна и та же среда локально и на CI») для Windows недостижим в любом случае.

Итог: scope Docker Build остаётся Linux + Android, как в исходно утверждённых requirements/specs/plan — правка не требуется, только явно зафиксировано здесь как подтверждённое решение (не переоткрывать вопрос повторно).

### Отладка: полный прогон `tool/docker-build.sh linux` (2026-07-25)

Ряд независимых проблем, обнаруженных и устранённых по пути к первому полностью зелёному прогону:

1. **Docker Desktop I/O-ошибка / диск хоста забит** — `commit failed: ... metadata.db: input/output error`, затем ENOSPC. Пользователь почистил диск хоста; дополнительно удалены неиспользуемые Docker-образы (`comics-editor-linux-build:amd64test`, dangling-слой) — освободило ~9GB. Не помогло полностью: containerd-состояние осталось повреждённым (зависшие `docker ps`/`docker version`).
2. **Docker Desktop зависший демон** — полный `quit`/`kill -9`/relaunch Docker Desktop восстановил работоспособность CLI.
3. **`HOME` не задан для `--user UID:GID`** — Flutter падал на `Error: Flutter failed to create a directory at "/.config/flutter"` (HOME резолвился в `/`, недоступный для записи). Фикс: `tool/docker-build.sh` теперь явно передаёт `--env HOME=/tmp` в `docker run` (см. файл).
4. **`UseVirtualizationFrameworkRosetta: false`** — после форс-рестарта Docker Desktop настройка Rosetta для amd64-эмуляции на Apple Silicon оказалась выключена → `--platform linux/amd64` контейнеры выполнялись через qemu-user binfmt вместо Rosetta, и `.NET`-рантайм падал (`qemu: uncaught target signal 6 (Aborted)` на любой реальной JIT/threading-нагрузке, не только на `--version`). Пользователь включил Rosetta вручную (Docker Desktop → Settings → General → «Use Rosetta for x86_64/amd64 emulation on Apple Silicon»). После этого `.NET`-сборка проходит.
5. **`Unexpected EINTR errno` в Dart VM (`file_linux.cc:492`)** — известное взаимодействие Dart VM/Rosetta (сигналы прерывают блокирующие файловые syscalls), не баг в этом репозитории. Транзиентно — повторный запуск `flutter build linux --release` прошёл без ошибки.
6. **`CoreClient.resolveBinary()` выбирал бинарник чужой ОС** (dev-режимный fallback без проверки `Platform.operatingSystem`, реальный баг в прикладном коде) — вынесено и исправлено в отдельном flow **`sdd-comics-editor-v2.9-fixes1`** (не здесь, т.к. это правка бизнес-логики, вне scope этого flow). После фикса + удаления устаревшего `publish/osx-arm64/` — `tool/docker-build.sh linux` полностью зелёный (все 6 тестов).

Итог: `docker/linux-build.Dockerfile` + `tool/docker-build.sh` работают корректно и воспроизводимо на этой машине под `--platform linux/amd64` (Rosetta), реальная x64-верификация действительно доступна локально, как и предполагалось изначально.

## Fork History

- Новый flow (не форк), создан 2026-07-25.

## Next Actions

1. **Windows MSB1008**: пользователь коммитит/пушит `windows/editor_plugin/CMakeLists.txt` + `.github/workflows/build.yml` (проверить `git status`/`git diff` перед пушем), перезапускает `build-windows` — ожидается зелёный прогон (custom target больше не в `ALL`)
2. Когда будет реализован hostfxr/nethost interop в `editor_plugin.cpp` — раскомментировать custom target в `CMakeLists.txt`, проверить СРАЗУ реальным Windows CI
3. Docker Build (Phase 1-4) завершён — ничего не осталось после подтверждения п.1

## Pinned Versions (зафиксировано на Plan)

- Ubuntu: 24.04
- Flutter: 3.44.6 (flutter_linux_3.44.6-stable.tar.xz)
- .NET SDK: 10.0.302 (точная версия, не floating)
- JDK: Temurin 17 (через Adoptium APT-репозиторий)
- Android: platforms;android-36, build-tools;36.0.0, commandlinetools-linux-9862592_latest.zip (проверено — HTTP 200, актуальная сборка из repository2-3.xml Google); дополнительно pre-baked для Flutter Gradle-плагина (иначе качалось бы заново на каждом `docker run`): platforms;android-35, build-tools;35.0.0, ndk;28.2.13676358, cmake;3.22.1

## Decisions (2026-07-25)

- Docker — только verification (build/test), не интерактивная разработка.
- Свой Dockerfile, точный пин версий (Flutter 3.44.6, .NET 10.0.302, JDK 17).
- Два узких образа: linux-build, android-build.
- release.yml не трогаем.
- Образ собирается заново на каждый CI-прогон (без ghcr.io публикации) — дефолт, легко поменять позже.
