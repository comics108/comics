# Specifications: flutter-comics-viewer-example-build

> Version: 1.1  
> Status: APPROVED  
> Last Updated: 2026-08-05  
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Добавить отдельный, детерминированный build-контур для
`libs/comics_viewer/flutter_comics_viewer/example`, не меняя runtime-поведение
viewer и не смешивая example artifacts с публикацией пакета на pub.dev.

Контур состоит из трёх частей:

1. локальных thin wrappers для POSIX shell и PowerShell;
2. документации в example README с прямыми эквивалентными командами;
3. отдельного GitHub Actions workflow с validation job и шестью независимыми
   platform jobs.

Все команды выполняются относительно корня отдельного репозитория
`flutter_comics_viewer`, а Flutter закрепляется на версии `3.44.6`.

## Affected Files

### Create

- `.github/workflows/example-build.yml` — validation, platform builds и upload
  artifacts.
- `tool/build-example.sh` — локальный POSIX entry point для платформ,
  поддерживаемых текущим host OS.
- `tool/build-example.ps1` — локальный PowerShell entry point, прежде всего для
  Windows.

### Modify

- `example/README.md` — prerequisites, checkout layout, wrappers, прямые
  команды, outputs и ограничения.

### Preserve

- `.github/workflows/build.yml` — существующие package validation и Android/iOS
  checks не удаляются и не ослабляются в этой итерации.
- `.github/workflows/publish.yml` — OIDC pub.dev publishing не меняется.
- `example/integration_test/plugin_integration_test.dart` — известный устаревший
  import фиксируется как follow-up и не включается в обязательный gate.
- пользовательский untracked `example/android/build/` не удаляется и не
  модифицируется намеренно.

## Local Build Interface

### Common contract

Wrappers принимают ровно один target:

`android`, `ios`, `linux`, `macos`, `windows`, `web` или `all`.

- Без target или с неизвестным target wrapper печатает usage и завершается с
  ненулевым exit code.
- Wrapper определяет свой location и вычисляет repository root независимо от
  текущей рабочей директории пользователя.
- Перед сборкой wrapper проверяет наличие `flutter` и запускает `flutter pub
  get` в `example`.
- Ошибка любой команды немедленно завершает wrapper с тем же ненулевым
  результатом.
- Wrapper не очищает `build/`, не выполняет `flutter clean` и не удаляет
  пользовательские файлы.
- `all` собирает только targets, нативно поддерживаемые текущей ОС, в
  документированном порядке; неподдерживаемый явно запрошенный target даёт
  понятную ошибку, а не молча пропускается.

### Host-to-target support

| Host | Supported local targets | `all` order |
|---|---|---|
| Linux | Android, Linux, Web | Android → Linux → Web |
| macOS | Android, iOS, macOS, Web | Android → iOS → macOS → Web |
| Windows | Android, Windows, Web | Android → Windows → Web |

POSIX wrapper поддерживает Linux/macOS; PowerShell wrapper поддерживает
Windows. Прямые команды из README остаются fallback для нестандартной shell
среды.

### Build commands and modes

| Target | Command from `example/` | Verification output |
|---|---|---|
| Android | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS | `flutter build ios --debug --no-codesign --simulator` | `build/ios/iphonesimulator/Runner.app` |
| Linux | `flutter build linux --release` | `build/linux/<arch>/release/bundle/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/viewer_example.app` |
| Windows | `flutter build windows --release` | `build/windows/<arch>/runner/Release/` |
| Web | `flutter build web --release` | `build/web/` |

`<arch>` нельзя жёстко считать всегда `x64` в локальной документации. Workflow
использует ожидаемую архитектуру runner, а artifact step выбирает bundle через
ограниченный platform-specific glob и падает, если output отсутствует.

### Android checkout precondition

Текущий `android/settings.gradle.kts` подключает
`../../comics-viewer-android`. Поэтому перед Android build должно существовать:

```text
<parent>/
├── flutter_comics_viewer/
└── comics-viewer-android/
```

Локальный wrapper проверяет каталог до `flutter build` и сообщает ожидаемый
путь и repository URL. Он не клонирует внешний repository автоматически.

### Local prerequisites

README указывает:

- Flutter `3.44.6` и совместимый Dart `3.12.x`;
- Android SDK и JDK 17 для Android;
- Xcode 16 и macOS для iOS/macOS;
- стандартные Flutter Linux desktop packages (`clang`, `cmake`, `ninja-build`,
  `pkg-config`, `libgtk-3-dev`, `liblzma-dev`) для Linux;
- Visual Studio с Desktop development with C++ для Windows;
- network access для pub packages и iOS SwiftPM dependency.

## GitHub Actions Design

### Workflow boundary and triggers

Новый `.github/workflows/example-build.yml` имеет отдельное имя
`Example Build` и triggers:

- push в `main`;
- tags `v*.*.*`;
- pull request в `main`;
- ручной `workflow_dispatch`.

Concurrency group строится из workflow и ref; `cancel-in-progress: true`.
Workflow не имеет publish/deploy permissions и использует минимальные default
read permissions.

### Shared toolchain policy

Каждый job:

- использует `actions/checkout@v4`;
- настраивает `subosito/flutter-action@v2` с `flutter-version: 3.44.6`,
  `channel: stable` и `cache: true`;
- запускает команды из repository root или с явным
  `working-directory: example`;
- не полагается на outputs другого platform job.

Android — исключение по layout: plugin checkout размещается в
`flutter_comics_viewer`, а `comics108/comics-viewer-android` — соседним
`comics-viewer-android`. Все последующие Android paths учитывают этот prefix.

### Jobs

| Job | Runner | Additional setup | Command |
|---|---|---|---|
| `validate-example` | `ubuntu-24.04` | none | format check, analyze и non-integration Flutter tests |
| `build-android` | `ubuntu-24.04` | sibling Android checkout, JDK 17 Zulu with Gradle cache | `flutter build apk --release` |
| `build-ios` | `macos-15` | select `/Applications/Xcode_16.app` | `flutter build ios --debug --no-codesign --simulator` |
| `build-linux` | `ubuntu-24.04` | install Linux desktop packages | `flutter build linux --release` |
| `build-macos` | `macos-15` | select `/Applications/Xcode_16.app` | `flutter build macos --release` |
| `build-windows` | `windows-latest` | runner-provided Visual Studio workload | `flutter build windows --release` |
| `build-web` | `ubuntu-24.04` | none | `flutter build web --release` |

Platform jobs не используют `needs: validate-example`: это сохраняет
независимую диагностику и позволяет увидеть состояние всех платформ за один
run. Повторный `flutter pub get`, автоматически выполняемый `flutter build`,
допустим и изолирован кэшем.

### Validation scope

Validation запускается из `example/`:

1. `flutter pub get`;
2. `dart format --output=none --set-exit-if-changed lib test`;
3. `flutter analyze lib test`;
4. `flutter test test`.

`flutter test integration_test` намеренно отсутствует: текущий файл использует
устаревший `package:viewer/viewer.dart`/`Viewer` и требует отдельного изменения
поведения тестового набора. Package-level tests и dry-run publish продолжают
выполняться существующим `build.yml`.

### Artifacts

Успешный platform build использует `actions/upload-artifact@v4` с
`if-no-files-found: error`, `retention-days: 14` и следующими именами:

| Job | Artifact name | Uploaded path/content |
|---|---|---|
| Android | `viewer-example-android-release-apk` | `app-release.apk` |
| iOS | `viewer-example-ios-simulator-debug` | archived `Runner.app` |
| Linux | `viewer-example-linux-x64-release` | release bundle |
| macOS | `viewer-example-macos-release` | archived `viewer_example.app` |
| Windows | `viewer-example-windows-x64-release` | complete Release directory |
| Web | `viewer-example-web-release` | complete `build/web` directory |

Apple `.app` directories архивируются стандартным runner tool до upload, чтобы
не потерять bundle structure и executable permissions. Linux, Windows и Web
загружаются как полные bundles, а не только executable. Artifact generation не
подписывает и не notarize outputs.

## Failure Handling and Diagnostics

- Отсутствующий Android sibling checkout должен быть обнаружен до Gradle и
  сопровождаться ожидаемым absolute/relative path.
- Unsupported local host/target combination должен перечислить разрешённые
  targets для текущей ОС.
- CI package installation, toolchain setup, build и artifact upload остаются
  отдельными именованными steps, чтобы причина падения была видна без поиска в
  общем shell script.
- Artifact step с отсутствующим output падает и тем самым обнаруживает изменение
  Flutter output layout.
- Workflow не маскирует exit codes через `continue-on-error`.

## Compatibility and Security

- Runtime API, Dart models, method channels, native plugin interfaces и UI не
  меняются.
- Никакие secrets не требуются; production signing отсутствует.
- External checkout использует public repository и default read-only
  `GITHUB_TOKEN` semantics.
- SwiftPM продолжает разрешать `comics-viewer-ios` из существующего remote
  branch `main`; pinning этой зависимости находится вне текущего scope.
- Existing package and publish workflows остаются рабочими и независимыми.

## Verification Criteria

Спецификация считается реализованной, когда:

1. оба wrappers корректно обрабатывают usage, unsupported targets и ошибки;
2. доступный на машине host target успешно собирается через wrapper;
3. YAML workflow проходит синтаксическую/структурную проверку;
4. example format, analyze и `flutter test test` проходят локально;
5. CI показывает семь независимых jobs и шесть artifacts при полном успехе;
6. Android CI checkout layout соответствует Gradle relative dependency;
7. существующие `build.yml` и `publish.yml` не изменены;
8. README позволяет воспроизвести прямую команду без wrapper.

## Deferred Work

- Исправление и включение integration test в обязательный gate.
- Code signing, notarization, stores и deployment.
- Pinning `comics-viewer-ios` SwiftPM dependency на tag/commit.
- Замена Android sibling source dependency опубликованным Maven artifact.

---

## Approval

- [x] Reviewed by: user
- [x] Approved on: 2026-08-05
- [x] Notes: User explicitly replied `specs approved`; no corrections were
  requested.
