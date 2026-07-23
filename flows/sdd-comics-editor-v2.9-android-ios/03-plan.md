# Implementation Plan: comics-editor-v2.9 — iOS/Android + системные файловые диалоги

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-23
> Specifications: [02-specifications.md](02-specifications.md) (APPROVED)

## Summary

Порядок выбран риск-вперёд: сначала NativeAOT-ядро и «AOT-ворота» на хосте (главный риск — Newtonsoft/$type под AOT), затем системные диалоги на десктопе (проверяемо сразу), затем мобильные раннеры и мобильный Save/Export. Git не трогаем; `native/` C#-исходники не изменяются (только новый обвязочный проект).

## Task Breakdown

### Phase 1: FFI-ядро и AOT-ворота

#### Task 1.1: Проект Comics.Editor.Native
- **Description**: Новый csproj (`net10.0`, `AssemblyName=Comics.Editor`, `PublishAot`): линк тех же исходников, что у Headless (Models, FileManager, ZipUtils, IWS-утилиты, Rpc.cs, WpfShims.cs — линком из Headless-проекта), `NativeApi.cs` (`comics_call`/`comics_free`, UnmanagedCallersOnly, UTF-8 маршалинг), `rd.xml` (Comics.Editor.Models.* + Newtonsoft.Json). Добавить в `Comics.slnx`.
- **Files**: `native/Comics.Editor.Native/{Comics.Editor.Native.csproj,NativeApi.cs,rd.xml}` — Create; `native/Comics.slnx` — Modify
- **Dependencies**: None
- **Verification**: `dotnet build` проекта — 0 ошибок
- **Complexity**: Medium

#### Task 1.2: Публикация osx-dylib + скрипт build_native.sh
- **Description**: `tool/build_native.sh` с таргетами: `osx` (dylib для тестов), `ios` (ios-arm64 static .a → ios/ComicsCore/), `android` (linux-bionic-arm64/x64 .so → jniLibs). На этом шаге реализуется и проверяется только `osx`; ios/android-ветки — заготовки, включаются в 3.x.
- **Files**: `tool/build_native.sh` — Create
- **Dependencies**: 1.1
- **Verification**: `tool/build_native.sh osx` создаёт `publish/osx-arm64/Comics.Editor.dylib` (или libComicsCore.dylib)
- **Complexity**: Medium

#### Task 1.3: Dart-абстракция ComicsCore + FfiCore
- **Description**: `comics_core.dart` (интерфейс + фабрика по платформе, env-override пути dylib для тестов), `ffi_core.dart` (DynamicLibrary, comics_call/comics_free, Isolate.run), `core_client.dart` → `ProcessCore implements ComicsCore` (минимальный рефакторинг, поведение десктопа неизменно), контроллер использует фабрику.
- **Files**: `lib/src/bridge/comics_core.dart`, `lib/src/bridge/ffi_core.dart` — Create; `lib/src/bridge/core_client.dart`, `lib/src/ui/controller.dart` — Modify
- **Dependencies**: None (параллельно 1.1)
- **Verification**: `flutter analyze` чистый; существующие тесты зелёные (десктоп-путь не сломан)
- **Complexity**: Medium

#### Task 1.4: AOT-ворота — FFI round-trip на хосте
- **Description**: Тест `test/ffi_core_test.dart`: FfiCore с osx-dylib (путь через env/резолвер) → ping, open→edit→save→reopen на sample.comics (зеркало существующего headless-теста). Итерации по rd.xml до зелёного статуса. Это ворота: без них Phase 3 не начинается.
- **Files**: `test/ffi_core_test.dart` — Create; `native/Comics.Editor.Native/rd.xml` — Modify по необходимости
- **Dependencies**: 1.2, 1.3
- **Verification**: `flutter test` — все зелёные, включая новый
- **Complexity**: High (главный риск проекта)

### Phase 2: Системные файловые диалоги (десктоп — проверяемо сразу)

#### Task 2.1: file_picker: Open на всех платформах
- **Description**: `file_picker` в pubspec; в Open-диалоге Browse… → `pickFiles(custom, ['comics','puzzle'])` → `openPath`; `showOpenPathDialog` удаляется. macOS entitlements: проверка `com.apple.security.files.user-selected.read-write` (debug/release plist).
- **Files**: `pubspec.yaml`, `lib/src/ui/widgets/dialogs.dart`, `macos/Runner/*.entitlements` — Modify
- **Dependencies**: None
- **Verification**: на macOS: Open → системный диалог → sample.comics открывается
- **Complexity**: Low

#### Task 2.2: Export/Save As (десктоп)
- **Description**: `controller.exportWithDialog()`: `FilePicker.saveFile(fileName: <имя>.comics)` → путь → `saveComics`. Кнопка Export в top bar (desktop = «Save As»).
- **Files**: `lib/src/ui/controller.dart`, `lib/src/ui/widgets/top_bar.dart` — Modify
- **Dependencies**: 2.1
- **Verification**: на macOS: Export → диалог → файл создан и повторно открывается
- **Complexity**: Low

### Phase 3: Мобильные платформы

#### Task 3.1: Раннеры ios/ и android/
- **Description**: `flutter create . --platforms ios,android` (org по образцу существующих раннеров); Android: minSdk 26; iOS: iPad включён по умолчанию (проверить TARGETED_DEVICE_FAMILY 1,2).
- **Files**: `ios/**`, `android/**` — Create; `pubspec/analysis` без изменений
- **Dependencies**: None (но подключение ядра — после 1.4)
- **Verification**: `flutter build apk --debug` и `flutter build ios --no-codesign` собираются (пока без ядра — с баннером «core unavailable»)
- **Complexity**: Low

#### Task 3.2: Android: .so + jniLibs + intent-filter
- **Description**: `build_native.sh android` (linux-bionic-arm64 + x64, NDK) → `android/app/src/main/jniLibs/{arm64-v8a,x86_64}/libcomicscore.so`; FfiCore открывает `libcomicscore.so`; manifest: intent-filter VIEW для `.comics`/`.puzzle`.
- **Files**: `tool/build_native.sh` — Modify; `android/app/src/main/AndroidManifest.xml` — Modify; jniLibs — артефакты
- **Dependencies**: 1.4, 3.1
- **Verification**: `flutter build apk --debug` с библиотеками; при наличии эмулятора — open/save smoke
- **Complexity**: High (NDK/bionic для NativeAOT)

#### Task 3.3: iOS: static .a + подключение в Runner + UTI
- **Description**: `build_native.sh ios` (ios-arm64, при необходимости `dotnet workload install ios`; simulator-RID — если поддержан) → vendored pod `ios/ComicsCore/` (`-force_load` в podspec) или link phase; FfiCore на iOS → `DynamicLibrary.process()`; Info.plist: CFBundleDocumentTypes + UTExportedTypeDeclarations.
- **Files**: `tool/build_native.sh` — Modify; `ios/ComicsCore/ComicsCore.podspec`, `ios/Podfile`, `ios/Runner/Info.plist` — Create/Modify
- **Dependencies**: 1.4, 3.1
- **Verification**: `flutter build ios --no-codesign` собирается с ядром; при наличии симулятора — smoke
- **Complexity**: High

#### Task 3.4: Мобильный Save в песочницу + Export + recents
- **Description**: `documents.dart`: каталог `<app documents>/comics/`, список локальных документов; controller: на mobile Save → песочница, Export → saveComics во временный файл → байты → `FilePicker.saveFile(bytes:)`; Open-диалог на mobile показывает локальные документы + Browse….
- **Files**: `lib/src/bridge/documents.dart` — Create; `lib/src/ui/controller.dart`, `lib/src/ui/widgets/dialogs.dart` — Modify
- **Dependencies**: 1.3 (интерфейс), 2.1
- **Verification**: unit-тест documents-store (на хосте); мобильный smoke — с 3.2/3.3
- **Verification**: юнит-тест на хосте + smoke на эмуляторе при наличии
- **Complexity**: Medium

#### Task 3.5: TempFolder/HOME на мобильных
- **Description**: при старте FfiCore — `ping` и проверка `tempFolder`; если путь вне песочницы/невалиден — выставить `HOME`/`XDG_DATA_HOME` (через setenv в NativeApi: экспорт `comics_set_env` или установка из Dart до первого вызова).
- **Files**: `lib/src/bridge/ffi_core.dart`, при необходимости `native/Comics.Editor.Native/NativeApi.cs` — Modify
- **Dependencies**: 1.4
- **Verification**: проверка tempFolder в FFI-тесте; на эмуляторе — фактический путь
- **Complexity**: Low

### Phase 4: Финализация

#### Task 4.1: Регрессия + инварианты
- **Description**: `flutter test` (все), `dotnet build native/Comics.slnx`, `flutter build macos|apk|ios --no-codesign`; проверка read-only зон и `.git`.
- **Dependencies**: всё
- **Verification**: чек-лист в 04-implementation-log.md
- **Complexity**: Low

#### Task 4.2: README + отложенные проверки
- **Description**: README: разделы iOS/Android (сборка библиотек, workloads/NDK, ассоциации файлов), чек-лист проверок на реальных устройствах (если недоступны сейчас).
- **Files**: `README.md` — Modify
- **Dependencies**: всё
- **Verification**: шаги воспроизводимы
- **Complexity**: Low

## Dependency Graph

```
1.1 ─→ 1.2 ─┐
1.3 ────────┴─→ 1.4 (AOT-ворота) ─┬─→ 3.2 (Android)
2.1 ─→ 2.2                        ├─→ 3.3 (iOS)
3.1 ──────────────────────────────┘   3.5
2.1 ─→ 3.4                        все ─→ 4.1 ─→ 4.2
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Newtonsoft/$type не заводится под NativeAOT | Med | High | AOT-ворота (1.4) на хосте до мобильной работы; итерации rd.xml; при провале — стоп и вопрос пользователю (fallback Dart-I/O только с его решения) |
| linux-bionic NativeAOT требует специфичной настройки NDK | Med | Med | Документировать точные шаги; при недоступности NDK — задача 3.2 откладывается с чек-листом |
| iOS workload/симулятор недоступны на машине | Med | Med | `--no-codesign` сборка как минимум; полный smoke — отложенный чек-лист |
| file_picker на macOS требует entitlements | High | Low | Явно включить user-selected.read-write в оба .entitlements |
| Регрессия десктопного пути при рефакторинге CoreClient | Low | Med | ProcessCore сохраняет код; существующие тесты — ворота |

## Rollback Strategy

1. Новые файлы/папки (`Comics.Editor.Native`, `ios/`, `android/`, bridge-файлы, скрипт) — удалить; правки controller/dialogs/top_bar/pubspec — откатить по diff (история git у пользователя).
2. Десктопный путь не меняется поведенчески — регрессия ловится существующими тестами.

## Checkpoints

- [ ] После 1.4: AOT-ворота зелёные — решение о продолжении Phase 3
- [ ] После каждой фазы: `flutter analyze`/`flutter test`/`dotnet build` зелёные; read-only зоны и `.git` не тронуты
- [ ] Отклонения — в 04-implementation-log.md

## Open Implementation Questions

- [ ] Точная механика iOS-подключения (.a: pod vs link phase) и надобность `dotnet workload install ios` — выяснится на 3.3.
- [ ] Наличие Android SDK/NDK и iOS-симулятора на машине — проверяется в начале Phase 3; отсутствие → соответствующие smoke-проверки уходят в отложенный чек-лист README.

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «plan approved».
