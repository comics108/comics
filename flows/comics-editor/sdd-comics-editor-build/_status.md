# Status: sdd-comics-editor-build

## Current Phase

IMPLEMENTATION

## Phase Status

Docker Build (Phase 1-4) — DONE. CI repair round 9 applied from the 2026-08-05 Windows rerun: C# publication now invokes the MSBuild `Publish` target directly, bypassing the .NET 10.0.302 `dotnet publish` parser that converted both `-o` and `-p:PublishDir` into positional tokens. Round 8's Linux plugins-base dependency and round 9's Windows command require real CI verification.

**Важно**: `apps/comics-editor-v2.9/` переименован пользователем в `apps/comics-editor/` (тот же проект, `pubspec.yaml` `name: comics_editor`) — не найдя старый путь, искать по новому.

## Last Updated

2026-08-10 by Claude

## Related Flows

- `flows/sdd-comics-editor-publish/` — spun out 2026-07-31 (user request) to own store publishing
  (screenshots, metadata, fastlane wiring). This flow (`sdd-comics-editor-build`) stays scoped to
  CI/build verification only (Docker Build, native Windows/macOS/Linux build fixes like the
  Windows MSB1008 thread below) — any future publishing-pipeline work belongs in the new flow, not
  here, matching how `vdd-comics-editor-jhanava` was split out of `vdd-comics-editor-uiux-lettering`.

## Blockers

- **Windows and Linux platform verification**: a second 2026-08-05 Windows run proved that `dotnet publish` also strips `-p:PublishDir` into a bare positional token. Round 9 now bypasses that parser with `dotnet msbuild -restore -target:Publish`; Windows must confirm it populates `runner/Release/dotnet`. Linux must still confirm `gstreamer-app-1.0` discovery after installing `libgstreamer-plugins-base1.0-dev`.
- **Real `build.yml` CI run (2026-08-07) surfaced 4 failing jobs** (see `04-implementation-log.md`'s
  2026-08-07 session for full detail):
  - `flutter analyze` — **fixed, verified locally**: `_TypeCard.enabled` was dead (never passed at
    any call site); removed it and its lock-icon/disabled branch.
  - Linux `desktop-file-validate` — **fixed**: was validating the `.desktop.in` template directly;
    newer `desktop-file-utils` on `ubuntu-24.04` rejects non-`.desktop`-suffixed filenames.
    Reordered to validate the real rendered file `install-user.sh` already produces.
  - Android Gradle `:comics-viewer-android` project not found — **root-caused, not fixed**:
    `flutter_comics_viewer` is now a pub.dev package (`^1.0.0`, per `pubspec.lock`), but its
    published `android/build.gradle.kts` still hard-depends on a sibling Gradle *project*
    `:comics-viewer-android` that only exists as a local path in this monorepo. User is fixing this
    at the `flutter_comics_viewer` publish source themselves (proper AAR dependency) — no change
    made here.
  - macOS `flutter build macos --release` — no "Apple Development" signing identity — **fixed,
    unverified**: added a "Configure signing" step to `build-macos` reusing the same
    `MACOS_CERT_APP_P12_BASE64`/`MACOS_CERT_APP_PASSWORD`/`MACOS_PROVISIONING_PROFILE_BASE64`/
    `SIGNING_KEYCHAIN_PASSWORD`/`APPLE_TEAM_ID` secrets `sdd-comics-editor-publish`'s `release-macos`
    already uses (per user's explicit direction — reuse existing publish keys, don't disable
    signing). Overrides are appended to a CI-only *working copy* of `Release.xcconfig`, never
    committed — `project.pbxproj` and the repo's actual xcconfig are untouched, so the local Xcode
    Archive path that produced the real App Store upload (in `sdd-comics-editor-publish`) is
    unaffected. **Not confirmed by a real run** — genuine uncertainty whether `CODE_SIGN_STYLE=Manual`
    + a "3rd Party Mac Developer Application" identity is accepted by a plain `xcodebuild build`
    action (vs. archive/export). Also flagged: this same root cause likely blocks
    `sdd-comics-editor-publish`'s untested `release-macos` fastlane lane too, since its own Step 1
    is the identical bare `flutter build macos --release` call.
- **`pubspec_overrides.yaml` introduced (2026-08-10, user request)**: `pubspec.yaml`'s
  `dependency_overrides` (pointing `flutter_comics` at the local monorepo path
  `../../libs/flutter_comics` for active local development) moved into a new
  `pubspec_overrides.yaml` — the standard Dart/Flutter mechanism, auto-merged by `flutter pub get`,
  now gitignored (`.gitignore` updated). This is exactly the same class of bug already found once
  this flow (the Android `comics-viewer-android` Gradle path only existing in the monorepo, not the
  standalone CI repo) — local-only override paths no longer live in the tracked `pubspec.yaml` at
  all, so CI/the standalone `comics108/comics-editor` mirror only ever sees the real, published
  dependency versions declared in `dependencies:`. Verified: `flutter pub get` explicitly reports
  `flutter_comics 0.2.0 from path ../../libs/flutter_comics (overridden in
  ./pubspec_overrides.yaml)`; `flutter analyze` still clean (1 unrelated pre-existing lint in
  `test/layer_batch_actions_test.dart`, not touched, out of scope); `git status` confirms
  `pubspec_overrides.yaml` stays untracked.
- **`flutter_comics_viewer` added to the same override (2026-08-10, user follow-up)**: same
  rationale — genuinely published to pub.dev (`^1.1.0`) but under active local development at
  `libs/comics_viewer/flutter_comics_viewer`. Note this is a *separate* concern from that package's
  own real Android Gradle bug (hard `implementation(project(":comics-viewer-android"))` dependency
  that only resolves in this monorepo, see the 2026-08-07 session above) — this override only
  affects which Dart source `flutter analyze`/editing/local `flutter build` use on this machine, it
  doesn't touch or fix the Gradle issue (still the user's to fix at the package-publish source).
  Verified: `flutter pub get` reports both `flutter_comics ... (overridden in
  ./pubspec_overrides.yaml)` and `flutter_comics_viewer 1.1.0 from path
  ../../libs/comics_viewer/flutter_comics_viewer (overridden in ./pubspec_overrides.yaml)`;
  `flutter analyze` shows 4 pre-existing unrelated style lints (`curly_braces_in_flow_control_structures`
  in `process_cutting_client.dart`/`ffi_core.dart`/`cutting_canvas.dart`/`lottie_import_dialog.dart`)
  — not touched, out of scope for this request.
- **Local build verification (2026-08-10)**: `flutter build ios --release --no-codesign` and
  `flutter build macos --release` both succeeded after the `pubspec_overrides.yaml` change; fast
  test suite (widget/dart_io_core/core_client/document_open_coordinator/file_association_metadata,
  20 tests) all green. Confirms the override move didn't break anything.
- **`tool/build_headless.sh` gained an optional explicit app-path 2nd argument (2026-08-10)**: the
  script's existing autodetect glob only ever finds a plain `flutter build macos` output
  (`build/macos/Build/Products/*/comics_editor.app`) — `xcodebuild archive` builds into a completely
  separate DerivedData location, so the script previously couldn't be used to embed the headless
  core into a real release archive at all (this flow's earlier real Mac App Store upload,
  `sdd-comics-editor-publish` 2026-08-07, had to do the publish+copy manually instead of via this
  script). When an explicit path is given, the ad-hoc re-sign step is now skipped (caller is
  expected to do real distribution signing afterward) — auto-detect path behavior (CI verification
  builds) is unchanged/backward compatible.
- **New `tool/publish_macos_appstore.sh` and `tool/publish_ios_appstore.sh` (2026-08-10, user
  request)**: wrap the exact real, working local archive→upload sequences from
  `sdd-comics-editor-publish`'s 2026-08-07 sessions into reusable scripts, now using
  `tool/build_headless.sh`'s new explicit-path support for the macOS core-embedding step instead of
  duplicating that logic inline. Both use `xcodebuild archive` + `xcodebuild -exportArchive
  destination:upload -allowProvisioningUpdates` (no fastlane, no API key — reuses whatever Apple ID
  is already signed into Xcode). macOS script additionally signs the embedded headless core with
  `macos/Runner/HeadlessCore.entitlements` before the final export, per the real sandbox-entitlement
  bug found and fixed in that same 2026-08-07 session. **Not yet re-verified by a real run as
  scripts** — the underlying command sequences are each individually proven (real uploads
  succeeded when run manually), but the scripts themselves (as complete, unattended files) haven't
  been executed end-to-end yet.

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
- [x] Round 7 code changes applied for analyzer, standalone macOS tests, Windows publication boundary, and initial Linux GStreamer dependency
- [x] Local verification: `flutter analyze`; focused `multimodal_paths_test.dart`
- [x] 2026-08-05 CI: Windows reached direct batch publication but failed MSB1008 because `-o` became a bare `PublishDir` token; Linux failed discovery of `gstreamer-app-1.0`
- [x] Round 8 code changes: explicit `-p:PublishDir=...`; `libgstreamer-plugins-base1.0-dev` in native and Docker Linux environments
- [x] Round 8 local checks: workflow YAML parses; .NET 10.0.302 accepts and resolves the explicit `PublishDir` property
- [x] 2026-08-05 Windows rerun: `dotnet publish` still failed MSB1008 because its parser stripped `-p:PublishDir` before invoking MSBuild
- [x] Round 9 code change: invoke `dotnet msbuild -restore -target:Publish` with native MSBuild property switches
- [x] Round 9 local check: exact direct-MSBuild command published a disposable .NET 10 project and produced the requested DLL
- [ ] Real Native Build rerun green on Windows, Linux, macOS, and analyze jobs

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

1. User commits/pushes the scoped `apps/comics-editor` and flow changes, then reruns Native Build.
2. Confirm Linux passes `gstreamer-app-1.0` package discovery and Windows's direct MSBuild `Publish` target writes `Comics.Editor.Flutter` into the uploaded `Release/dotnet` directory.
3. If Windows still fails, diagnose the new MSBuild-target error from its logged command/output; do not return publication to CMake custom commands or the `dotnet publish` parser.

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
