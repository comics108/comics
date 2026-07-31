# Status: sdd-comics-editor-build

## Current Phase

IMPLEMENTATION

## Phase Status

Docker Build (Phase 1-4) — DONE, см. `04-implementation-log.md` Progress Tracker. Windows CI MSB1008 — round 5 (`VERBATIM`) не помог, тот же лог подтвердил (3-й раз), что наш `publish_csharp.cmd` вообще не запускается. Round 6 (2026-07-31): структурный фикс — убрана отдельная custom-target-only `.vcxproj` (`add_custom_target(..._csharp ALL ...)`), публикация C#-слоя перенесена в `add_custom_command(TARGET editor_plugin POST_BUILD ...)` на уже существующей, заведомо рабочей библиотеке. Не проверено реальным CI. Отдельно: новая macOS-only регрессия (`dataset_backward_compat_test.dart` из `vdd-comics-editor-uiux-lettering`, Task 7.1) — исправлена и подтверждена локально в обе стороны (dataset/ есть/нет).

**Важно**: `apps/comics-editor-v2.9/` переименован пользователем в `apps/comics-editor/` (тот же проект, `pubspec.yaml` `name: comics_editor`) — не найдя старый путь, искать по новому.

## Last Updated

2026-07-31 by Claude

## Related Flows

- `flows/sdd-comics-editor-publish/` — spun out 2026-07-31 (user request) to own store publishing
  (screenshots, metadata, fastlane wiring). This flow (`sdd-comics-editor-build`) stays scoped to
  CI/build verification only (Docker Build, native Windows/macOS/Linux build fixes like the
  Windows MSB1008 thread below) — any future publishing-pipeline work belongs in the new flow, not
  here, matching how `vdd-comics-editor-jhanava` was split out of `vdd-comics-editor-uiux-lettering`.

## Blockers

- **macOS: `flutter test` (bare, no file list) failing on load** — `dataset_backward_compat_test.dart` (added 2026-07-30 in a different flow, `vdd-comics-editor-uiux-lettering`) crashed the whole file on `Directory.listSync()` because `dataset/` doesn't exist in this repo's own checkout. Root cause confirmed: `apps/comics-editor-v2.9` is pushed to its own separate git repo (`comics108/comics-editor-v2.9`, verified via `git remote -v`/`show-toplevel`) whose tree never includes the monorepo-level `dataset/` directory at all -- it only resolved in local dev by directory-nesting coincidence. **Fixed** (2026-07-30): the test now checks `datasetDir.existsSync()` and skips with a clear reason (not crash) when absent; verified locally both ways (with dataset/ present: 28/28 green; with it renamed away to simulate the CI-mirror-repo layout: `~1: All tests skipped`, correctly no crash). Also added explicitly to the `analyze` job's fast test list in `build.yml` (pure Dart, no native artifact) for visibility, alongside `widget_test.dart`/`dart_io_core_test.dart` -- it'll report skipped there too (analyze also runs against the standalone repo), which is expected and fine.
- **Windows MSB1008 — round 6 (unverified, needs real CI)**: round 5's `VERBATIM` fix did not help — the next real CI run (2026-07-31, commit `316cb80`) hit the identical error, and for the third time (rounds 2 and 6) the diagnostic `echo` lines inside `publish_csharp.cmd` never appeared in the log at all, confirming our script never starts executing. Since round 4 already confirmed the generated `<Command>` is syntactically identical to a working custom-build-step in the same file, five rounds of content-level fixes (CRLF, `call`, echo diagnostics, byte-level `<Command>` comparison, `VERBATIM`) are exhausted without success. Round 6 changes tack structurally instead: `add_custom_target(editor_plugin_csharp ALL ...)` forces CMake's Visual Studio generator to create a standalone `.vcxproj` whose only "source" is an auto-generated `.rule` stub (no real `ClCompile` items) -- on this runner's very new/preview toolset (`windows-2025-vs2026`, VS "18"/2026) that specific *class* of vcxproj (utility/custom-target-only) is the suspected trigger, not the command content. Replaced with `add_custom_command(TARGET editor_plugin POST_BUILD ...)`, attaching the publish step to the already-existing `editor_plugin` static-library target (a normal C++ project with real sources) instead of creating a new vcxproj at all. `windows/runner/CMakeLists.txt`'s copy-`dotnet`-folder step needed no changes -- build order is preserved because `runner` links `editor_plugin` and therefore builds after its POST_BUILD publish step. Syntax verified locally via a stub CMake project on macOS (reached CMake's Generate step cleanly). **Not verified** by real Windows CI. If it recurs a third time with this structural change too, the planned next step (noted in `04-implementation-log.md`) is to stop iterating on CMake/MSBuild entirely and invoke `dotnet publish` directly from a PowerShell step in `build.yml`, after `flutter build windows`.

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

1. **Windows MSB1008 (round 6)**: пользователь коммитит/пушит `apps/comics-editor/windows/editor_plugin/CMakeLists.txt`, перезапускает `build-windows` — присылает новый лог.
2. Если round 6 тоже не поможет — не пробовать очередной content-level фикс; вынести `dotnet publish` из CMake в отдельный PowerShell-шаг `build.yml` после `flutter build windows` (см. `04-implementation-log.md` round 6 "In Progress").
3. Docker Build (Phase 1-4) завершён — ничего не осталось после подтверждения Windows.

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
