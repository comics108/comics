# Status: sdd-comics-editor-v2.9-android-ios

## Current Phase

IMPLEMENTATION

## Phase Status

COMPLETE (оба мобильных блокера — iOS и Android — разрешены одним и тем же архитектурным решением: Dart-I/O fallback вместо NativeAOT+FFI)

## Last Updated

2026-07-25 by Claude

## Blockers

- Нет активных архитектурных блокеров. iOS и Android оба используют `DartIoCore` — работают без внешних .NET-артефактов.
- Xcode 26.5 platform-компонент на этой машине не установлен — влияет только на реальный запуск/тест iOS-сборки локально (не блокирует CI, не блокирует DartIoCore).

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-23)
- [x] Specifications drafted
- [x] Specifications approved (2026-07-23)
- [x] Plan drafted
- [x] Plan approved (2026-07-23)
- [x] Implementation started
- [x] Implementation complete  ← current

## Context Notes

Key decisions and context for resuming:

- База: завершённый flow `sdd-comics-editor-v2.9` (Flutter desktop + headless C#-ядро процессом + UI макета; git не трогать — правило пользователя).
- Задача: + iPhone/iPad/Android-телефоны/планшеты; + системные диалоги Open/Save на всех платформах.
- Решение Q1 (2026-07-23): изначально утверждено **.NET NativeAOT + FFI** для Android/macOS.
- **iOS-блокер (2026-07-23)**: после `sudo dotnet workload install ios` выяснилось — CoreCLR NativeAOT не публикуется для `ios-arm64` в .NET 10 (workload даёт Mono-AOT пайплайн для App-бандлов, не голые библиотеки с C-экспортами). Пользователь выбрал предусмотренный в Q1 fallback: **Dart-I/O для iOS** (`DartIoCore`).
- **Android-блокер (2026-07-25, GitHub Actions лог)**: `tool/build_native.sh android` падал с `error : The PrivateSdkAssemblies ItemGroup is required for _ComputeAssembliesToCompileToNative` — сначала на macOS (списано на кросс-ОС), затем **на настоящем Ubuntu CI-раннере** (та же ошибка) — диагноз «кросс-компиляция» был неверным. Проверка `Microsoft.NETCoreSdk.BundledVersions.props` в .NET 10 SDK показала: `ILCompilerRuntimeIdentifiers` не содержит ни одного bionic/android RID, а `RuntimePackExcludedRuntimeIdentifiers="android;linux-bionic"` — явное исключение в конфиге SDK. Причина та же, что у iOS: **`.NET for Android` тоже построен на Mono, не CoreCLR** — CoreCLR NativeAOT архитектурно не поддерживает ни одну мобильную платформу в .NET 10, независимо от NDK/workload/хоста сборки.
- **Решение пользователя (2026-07-25)**: применить тот же Dart-I/O fallback к Android, что и к iOS (вариант 1 из предложенных). `createComicsCore()` теперь: iOS и Android → `DartIoCore`, desktop → `CoreClient`.
- **`FfiCore`/`Comics.Editor.Native` не удалены**, помечены в коде как архивные/неиспользуемые — задел на случай, если Microsoft когда-нибудь опубликует NativeAOT-поддержку мобильных RID (тогда потребуется поменять только фабрику в `comics_core.dart`). `ffi_core_test.dart` продолжает проходить в CI (macos job) как регрессионный тест архивного пути, не влияет на прод-конфигурацию.
- CI (`build.yml`, `release.yml`): у `build-android`/`release-android` убраны шаги `setup-dotnet`, Install Android NDK, `tool/build_native.sh android` — Android job больше не трогает .NET вообще, только Flutter + Java (для Gradle) + подпись.
- **Найден и исправлен конфликт инструментария (Android, независимо от NativeAOT)**: file_picker 11 + AGP 9.0.1 (дефолт Flutter 3.44) несовместимы с шаблонным `builtInKotlin=false`, а `builtInKotlin=true` ломает `flutter_plugin_android_lifecycle`. Решение: AGP закреплён на 8.13.1 в `android/settings.gradle.kts`.
- Bundle id/applicationId везде заменён с плейсхолдера на `net.nativemind.comics.editor` (2026-07-24), подтверждено сборкой (aapt/PlistBuddy).
- Windows CI: падал с `MSB1008: Only one project can be specified` в CMake custom-build-step (сериализация многотокенной команды `dotnet publish` через VS generator). Вынесено в отдельный `windows/editor_plugin/publish_csharp.cmd`.
- `flutter analyze` в CI требует exit 0 (падает на любом `warning`, не только `error`) — почищены все находки (2 unused_import, 2 prefer_initializing_formals, 3 withOpacity→withValues).
- Desktop (macOS/Linux/Windows) — по-прежнему использует `CoreClient` (headless-процесс `Comics.Editor.Headless`), не затронут этим пивотом.
- **Все тесты**: `flutter test` — 8/8 зелёных. `flutter analyze` — 0 ошибок. `dotnet build native/Comics.slnx` — 0 ошибок.

## Fork History

- Новый flow (не форк), создан 2026-07-23. Продолжение sdd-comics-editor-v2.9.

## Next Actions

1. Дождаться зелёного прогона GitHub Actions (build.yml: все 6 job; release.yml — только вручную, ждёт реальных секретов)
2. (опционально) Xcode: установить platform-компонент iOS локально — только если нужен реальный запуск/архивация iOS-сборки на этой машине
3. Smoke-тест на реальных iPhone/iPad/Android при появлении устройств
4. Если в будущем .NET SDK добавит публичную поддержку ILCompiler для мобильных RID — можно вернуться к NativeAOT+FFI, поменяв фабрику в `comics_core.dart` (архивный код уже готов и протестирован)

## Key Design Points (реализовано)

- `ComicsCore` абстракция: `CoreClient` (desktop, headless-процесс) / `DartIoCore` (iOS **и** Android, package:archive) — единый интерфейс `call(method, params)`, UI не знает о транспорте.
- `DartIoCore`: тот же протокол/JSON-формат, что у C#-ядра; `models_mapping.dart` формирует и потребляет одинаковую JSON-схему независимо от транспорта; формат архива — стандартный zip, файлы взаимно совместимы между всеми платформами.
- `FfiCore`/`Comics.Editor.Native` — архивный, неиспользуемый в проде код (C-экспорты `comics_call`/`comics_free`/`comics_set_env`, `UnmanagedCallersOnly`); работает на macOS (проверено тестом), но не годится ни для iOS, ни для Android в текущем .NET 10.
- file_picker 11.0.2: статический API (`FilePicker.pickFiles/saveFile`, без `.platform`).
- Save на мобильных → `<Documents>/comics/`; Open-диалог на мобильных показывает реальные локальные файлы; Export → bytes через системный диалог.
- `dart_test.yaml` (`concurrency: 1`): тесты, использующие общий C#-TempFolder (core_client_test, ffi_core_test), должны идти последовательно; dart_io_core_test использует изолированный workDirPath и от этого не зависит.
