# Implementation Log: comics-editor-v2.9 — iOS/Android + системные файловые диалоги

> Started: 2026-07-23
> Plan: [03-plan.md](03-plan.md) (APPROVED)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Comics.Editor.Native | Done | C-экспорты comics_call/free/set_env; rd.xml; AssemblyName=Comics.Editor |
| 1.2 build_native.sh + osx dylib | Done | NativeAOT dylib собрался с первого раза |
| 1.3 ComicsCore абстракция | Done | CoreClient implements ComicsCore; FfiCore (Isolate.run); контроллер через фабрику |
| 1.4 AOT-ворота | Done ✅ | FFI round-trip на sample.comics зелёный с первого прогона — главный риск закрыт |
| 2.1 file_picker Open | Done | v11 API (статические методы); entitlements user-selected.read-write |
| 2.2 Export/Save As | Done | exportWithDialog: путь на десктопе, bytes на мобильных; кнопка в top bar |
| 3.1 Раннеры ios/android | Done | minSdk 26; iPad (1,2) и iOS 13 по умолчанию; baseline-сборки см. 4.1 |
| 3.2 Android .so + jniLibs | Deferred (Linux) | NativeAOT не кросс-компилируется macOS→bionic; скрипт готов, intent-filter в манифесте |
| 3.3 iOS .a + Runner | Deferred (sudo) | Нужен `sudo dotnet workload install ios`; csproj/скрипт/podspec/UTI готовы |
| 3.4 Save в песочницу + recents | Done | documents.dart; Save→<Documents>/comics/; Open-диалог показывает локальные файлы |
| 3.5 TempFolder на мобильных | Done | FfiCore лениво ставит HOME/XDG_DATA_HOME в песочницу через comics_set_env |
| 4.1 Регрессия + инварианты | Pending | |
| 4.2 README | Pending | |

## Session Log

### Session 2026-07-23 - Claude

**Started at**: Phase 1, Task 1.1

#### Completed

- 1.1–1.2: `Comics.Editor.Native` (net10.0, PublishAot, линк тех же исходников + Rpc/WpfShims из Headless; rd.xml рутит Comics.Editor и Newtonsoft.Json целиком); `tool/build_native.sh osx` публикует `publish/osx-arm64/Comics.Editor.dylib`.
- 1.3: `comics_core.dart` (интерфейс + фабрика), `ffi_core.dart` (dart:ffi + package:ffi, вызовы через Isolate.run, env-инъекция comics_set_env), CoreClient → implements ComicsCore. Десктоп-поведение не изменилось (тесты зелёные).
- 1.4 ✅ **AOT-ворота пройдены**: FFI round-trip (open→edit→save→reopen на sample.comics) через NativeAOT-dylib — зелёный с первого прогона; rd.xml с `Dynamic="Required All"` для двух сборок оказался достаточным.
- 2.1: file_picker 11.0.2 (API v11 — статические методы, не `.platform`); Browse… → системный диалог; текстовый диалог пути удалён; macOS entitlements (debug+release) + user-selected.read-write.
- 2.2: `exportWithDialog()` в контроллере + кнопка Export (ios_share) в top bar.

#### Completed (Phase 3)

- 3.1: `flutter create --platforms ios,android`; minSdk 26 (Q3); iPad (TARGETED_DEVICE_FAMILY 1,2) и iOS 13.0 — дефолты подтверждены; baseline `flutter build apk --debug` прошёл.
- 3.2 (частично): intent-filter для .comics/.puzzle в манифесте; `build_native.sh android` готов (linux-bionic-arm64/x64 → jniLibs). **Артефакт .so отложен**: NativeAOT не кросс-компилируется macOS→Linux-bionic (ошибка PrivateSdkAssemblies) — сборка на Linux-хосте, шаги в README.
- 3.3 (частично): UTI/CFBundleDocumentTypes в Info.plist; `ios/ComicsCore/ComicsCore.podspec` (vendored .a, -force_load); csproj мульти-таргет `net10.0-ios` за флагом IncludeIos; `build_native.sh ios` готов. **Артефакт .a отложен**: `dotnet workload install ios` требует sudo (пользователь выполнит сам).
- 3.4: `documents.dart` (песочница `<Documents>/comics/`); Save на mobile → песочница; Export → bytes через `FilePicker.saveFile`; Open-диалог на mobile показывает реальные локальные документы (тап = открыть), mock-recents остаются только на десктопе.
- 3.5: FfiCore перед первым вызовом лениво выставляет HOME/XDG_DATA_HOME в getApplicationSupportDirectory() через экспорт `comics_set_env`.

#### Discoveries

- **Гонка тестов**: core_client_test и ffi_core_test делят один C#-TempFolder (`Comics Editor\Temp`) → при параллельных suite-ах round-trip-ы мешают друг другу. Решение: `dart_test.yaml` с `concurrency: 1` (+ регистрация тега core).
- file_picker v11 сменил API: `FilePicker.pickFiles`/`saveFile` — статические.
- **NativeAOT кросс-ОС**: macOS→linux-bionic невозможно (только кросс-арх внутри одной ОС); macOS→iOS возможно, но через TFM net10.0-ios + workload.

**Current**: Phase 4 (регрессия, сборки, README)
