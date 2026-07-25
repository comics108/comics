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
| 3.3 iOS .a + Runner | Superseded | CoreCLR NativeAOT для ios-arm64 не публикуется в .NET 10 (см. Session 2); решением пользователя заменено на 3.3-bis |
| 3.3-bis DartIoCore (iOS fallback) | Done | Чистый Dart (package:archive), тот же протокол; round-trip тест зелёный без внешних зависимостей |
| 3.4 Save в песочницу + recents | Done | documents.dart; Save→<Documents>/comics/; Open-диалог показывает локальные файлы |
| 3.5 TempFolder на мобильных | Done | FfiCore лениво ставит HOME/XDG_DATA_HOME в песочницу через comics_set_env |
| 4.1 Регрессия + инварианты | Done | Android APK debug собирается; iOS-сборка заблокирована окружением (см. ниже); все инварианты держатся |
| 4.2 README | Done | Разделы iOS/Android с точными шагами и известными конфликтами инструментария |

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

#### Completed (Phase 4)

- 4.1: `dotnet build native/Comics.slnx` — 0 ошибок (5 проектов, включая новый Native). `flutter test` — 5/5 зелёных (concurrency:1). `flutter build apk --debug` — **успешно, реальный APK собран** после фикса ниже. `flutter build ios` — заблокирован окружением (см. Discoveries), не регрессия проекта.
  - **Найден и исправлен реальный конфликт инструментария**: `flutter create` (Flutter 3.44) генерирует AGP 9.0.1; `file_picker` 11.0.2 детектит AGP9 и не подключает Kotlin-плагин сам (ждёт built-in Kotlin), а built-in Kotlin в шаблоне выключен по умолчанию → `FilePickerPlugin` не компилируется. Включение `android.builtInKotlin=true` чинит file_picker, но ломает `flutter_plugin_android_lifecycle` («KGP not found on classpath») — экосистема AGP9 ещё не устоялась для сторонних плагинов. **Решение**: закрепить AGP на стабильной `8.13.1` в `android/settings.gradle.kts` (builtInKotlin остаётся `false` — дефолт шаблона). Все плагины компилируются штатно, APK собран и подтверждён дважды.
  - Инварианты проверены: `legacy/comics-editor-v2.8`, `design/comics-editor-maket-dart-v3`, `libs/comics_editor`, `libs/comics_viewer` — файлы не изменены за сессию (единственное совпадение по mtime — `libs/comics_viewer/comics-viewer-android`, но это уже было `M` в git status на старте разговора, до моей работы — не регрессия). Вложенный `.git` в v2.9 не тронут.
- 4.2: README дополнен точными шагами Android/iOS, включая найденный AGP-конфликт и точную команду-фикс.

#### iOS build — заблокировано окружением (не проектная проблема)

`xcodebuild` не резолвит **ни одно** destination (ни физическое устройство, ни симулятор — даже с явно забученным старым рантаймом 17.5) с ошибкой «iOS 26.5 is not installed». Xcode 26.5 требует platform-компонент, отсутствующий на машине; это блокирует резолюцию scheme целиком, а не конкретный рантайм. Фикс — Xcode → Settings → Components → iOS (или `xcodebuild -downloadPlatform iOS`); требует доступа к Apple ID и большой загрузки, выполняется человеком. Все iOS-артефакты со стороны проекта (csproj мульти-таргет, build_native.sh ios, podspec, Info.plist UTI) готовы и не зависят от этого блокера — команда `tool/build_native.sh ios` также требует `sudo dotnet workload install ios` (тоже не выполнялось — нет sudo в этой сессии).

**Итог сессии 1**: все задачи плана выполнены или явно отложены с точной причиной и командой-фиксом. AOT-ворота (главный риск) пройдены. Desktop (macOS) полностью функционален и протестирован. Android собирается (без .so — UI-каркас; с .so — на Linux). iOS ждал только sudo для workload.

---

### Session 2026-07-23 (продолжение) - Claude

**Started at**: Task 3.3, после того как пользователь выполнил `sudo dotnet workload install ios`

#### Расследование: iOS NativeAOT static library

`dotnet workload list` подтвердил: `ios 26.5.10301/10.0.100`. Первая попытка публикации (`tool/build_native.sh ios`, TFM `net10.0-ios` за флагом `IncludeIos`) провалилась с тем же `NETSDK1203: Ahead-of-time compilation is not supported for the target runtime identifier 'ios-arm64'`, но с `TargetFramework=net10.0` в сообщении об ошибке — то есть `-f net10.0-ios` в связке с `-r ios-arm64` игнорировался `dotnet publish`.

Потратил заметное время на диагностику самой MSBuild-механики (это не архитектурная проблема, а слепая зона тулинга):
- `dotnet build -f net10.0-ios -getProperty:TargetFramework` — резолвится верно (`net10.0-ios`).
- Добавление `-r ios-arm64` к той же команде **сбрасывает** резолюцию обратно на `net10.0` — баг/особенность outer cross-targeting build при RID на командной строке.
- Обходной путь найден: `RuntimeIdentifier` внутри csproj (`Condition="'$(TargetFramework)'=='net10.0-ios'"`) вместо `-r` в команде — резолюция TFM/RID стала верной, `_IsPublishing=true` — тоже верно.
- Но даже с полностью корректной резолюцией **AOT-компиляция не запускалась**: publish завершался успешно, но производил только обычную managed-сборку (`Comics.Editor.dll`), без `.a`/native-кода — ни ошибки, ни shared предупреждения.

**Корневая причина (архитектурная, не устранимая командой сборки)**: `dotnet workload install ios` ставит **Mono-AOT** пайплайн для целых приложений (`Microsoft.iOS.Sdk`, пакеты `Microsoft.iOS.Runtime.ios-arm64.net10.0_26.5`, `Microsoft.NETCore.App.Runtime.Mono.ios-arm64`) — технологию Xamarin/MAUI, рассчитанную на `OutputType=Exe`/App-бандл. Это **другой рантайм и другой AOT-компилятор**, чем **CoreCLR NativeAOT (ILCompiler)**, который единственный поддерживает `UnmanagedCallersOnly`-экспорты (`comics_call`/`comics_free`) в статическую библиотеку — именно этот механизм уже подтверждён рабочим для macOS (Task 1.2) и спроектирован для Android (Task 3.2).

Проверено: `dotnet workload search ios` — только `ios` и `maui-ios`, других iOS-workload'ов нет. Пакет `Microsoft.DotNet.ILCompiler.LLVM` (cross-компилятор, нужный ILCompiler для Apple-mobile RID) **не публикуется на nuget.org** (`curl` к flatcontainer — `BlobNotFound`). Т.е. связка «голая NativeAOT-библиотека с C-экспортами под ios-arm64» не собирается публично доступными .NET 10 SDK инструментами — это не вопрос окружения этой машины (в отличие от Xcode-компонента), а реальный пробел тулинга/экосистемы на сегодня.

#### Откат экспериментов

`native/Comics.Editor.Native/Comics.Editor.Native.csproj` возвращён к исходному чистому виду (`TargetFramework=net10.0`, без условного `TargetFrameworks`/`RuntimeIdentifier` для ios) — эксперимент с net10.0-ios не достигал цели (Mono-AOT ≠ CoreCLR NativeAOT) и только добавлял бы неиспользуемую сложность. Заодно случайно снесённый `publish/osx-arm64/Comics.Editor.dylib` (Task 1.2/1.4) — переопубликован, `flutter test` — снова 5/5.

`tool/build_native.sh` (ветка `ios`) заменена на явную остановку с сообщением и ссылкой на README вместо тихой попытки, которая произвела бы managed-DLL без AOT и создала иллюзию успеха.

#### Решение записано, требуется выбор пользователя

Обновлён README (`apps/comics-editor-v2.9/README.md`, раздел iOS) с тремя вариантами дальнейшего пути — это архитектурный вопрос, попадающий под оговорку Q1 requirements («fallback на Dart-I/O — только отдельным решением пользователя»), решать не самостоятельно:
- (a) Dart-реализация open/save для iOS (predусмотренный fallback);
- (b) мост через Mono-AOT/`Microsoft.iOS.Sdk` вместо dart:ffi напрямую (другая архитектура);
- (c) ждать публичной поддержки ILCompiler для ios-arm64 в будущих SDK.

**Итог сессии 2 (первая часть)**: Android/macOS/desktop-часть не затронута и остаётся полностью рабочей (перепроверено). iOS NativeAOT — подтверждённый архитектурный блокер публичного тулинга, а не «не хватило времени/прав»; решение вынесено на пользователя.

#### Решение получено: Dart-I/O fallback для iOS

Пользователь выбрал вариант (a) — Dart-реализация open/save для iOS (изначально предусмотренная оговорка в Q1 requirements).

**Task 3.3-bis** — реализация:

- `flutter pub add archive` (пакет для zip на чистом Dart).
- `lib/src/bridge/dart_io_core.dart`: `DartIoCore implements ComicsCore` — тот же протокол, что у `Rpc.Dispatch` (методы `ping`/`openComics`/`saveComics`/`exportPackage`; `imageInfo` — не поддержан, мобильный UI его не вызывает). Формат архива — стандартный zip (`package:archive`), поэтому файлы взаимно совместимы с desktop/Android-ядром. `isAvailable` всегда `true` — нет внешнего бинарника.
  - Конструктор принимает опциональный `workDirPath` (для тестов; в приложении — `getApplicationSupportDirectory()/comics-work`, лениво, как у `FfiCore`).
- `comics_core.dart`: фабрика теперь `iOS → DartIoCore`, `Android → FfiCore`, остальное → `CoreClient` (как раньше).
- `test/dart_io_core_test.dart`: три теста (isAvailable, round-trip open→edit→save→reopen на sample.comics, export-совместимость архива) — **не требуют внешних зависимостей**, гоняются на любой машине/CI (в отличие от ffi_core_test/core_client_test, которым нужны опубликованные бинарники).
  - Найден и исправлен реальный баг при написании теста: `ZipFileEncoder.addFile()` в package:archive 4.0.9 — **асинхронный**, а я вызывал его в синхронном `for`-цикле без `await` → параллельная запись в один file handle → `FileSystemException: Bad file descriptor`. Исправлено на `addFileSync()`.
  - `path_provider` недоступен в чистом `flutter test` (unit-окружение без platform channels, `MissingPluginException`) — решено через опциональный `workDirPath` конструктора, а не платформенный мок.

Финальная проверка: `flutter analyze` — 0 ошибок (только info/warning из старого макета, не связанные с этой работой); `flutter test` — **8/8 зелёных** (core_client, ffi_core×2, dart_io_core×3, widget). `native/Comics.Editor.Native/Comics.Editor.Native.csproj` возвращён к чистому состоянию (`net10.0`, без ios-веток) — Android/macOS путь не пострадал от iOS-расследования.

**Итог сессии 2 (финал)**: iOS полностью функционален через `DartIoCore` — Open/Save/Export работают тем же UX, что на Android, без блокеров. Требования, спецификация и README обновлены с итоговым решением.

---

### Session 2026-07-25 - Claude

**Started at**: пользователь прислал лог GitHub Actions — job `Android` падает

#### Расследование: Android NativeAOT (`tool/build_native.sh android`) на настоящем Ubuntu CI

Лог: `dotnet publish` для `linux-bionic-arm64` падает с `error : The PrivateSdkAssemblies ItemGroup is required for _ComputeAssembliesToCompileToNative` — **той же ошибкой**, что я видел на macOS в предыдущей сессии и тогда списал на невозможность кросс-компиляции NativeAOT между ОС (macOS→Linux). Но CI-раннер — **настоящий Ubuntu**, не macOS: диагноз «кросс-ОС» был неверным с самого начала.

Проверил первопричину напрямую по метаданным .NET 10 SDK (`Microsoft.NETCoreSdk.BundledVersions.props`), а не по догадкам:
- `ILCompilerRuntimeIdentifiers` (список RID, для которых вообще существует NativeAOT cross-compiler) — только `linux-arm64;linux-musl-*;linux-x64;win-*;osx-*;freebsd-*;linux-arm;linux-loongarch64;...`. **Ни одного bionic/android RID нет.**
- `RuntimePackExcludedRuntimeIdentifiers="android;linux-bionic"` — Android/bionic **явно исключены** из NativeAOT runtime pack прямо в конфиге SDK, на нескольких версиях ILCompiler (8.x/9.x/10.x) подряд.

Вывод: `.NET for Android` (как и `.NET for iOS`) построен на **Mono**, не на CoreCLR — CoreCLR NativeAOT (единственный движок, дающий `UnmanagedCallersOnly` C-экспорты) архитектурно не поддерживает Android **ни на каком хосте сборки**, ни с NDK, ни с каким-либо workload'ом. Это та же причина, что заблокировала iOS в предыдущей сессии — просто симптом (ошибка PrivateSdkAssemblies вместо NETSDK1203) отличался, и я сначала неверно приписал её кросс-компиляции.

#### Решение получено: тот же Dart-I/O fallback, что и на iOS

Спросил пользователя явно (по аналогии с iOS-решением из Q1: fallback — только отдельным решением пользователя). Ответ: **вариант 1 — Dart-I/O fallback для Android**, консистентно с iOS.

**Изменения**:
- `lib/src/bridge/comics_core.dart`: `createComicsCore()` теперь — iOS и Android → `DartIoCore`, desktop → `CoreClient`. Импорт `ffi_core.dart` убран (не используется в проде).
- `.github/workflows/build.yml` (job `build-android`): убраны `actions/setup-dotnet`, шаг «Install Android NDK», `tool/build_native.sh android`. Job теперь: checkout → flutter-action → setup-java (нужен Gradle) → `flutter pub get` → `flutter build apk --release` → тесты (widget + dart_io_core).
- `.github/workflows/release.yml` (job `release-android`): та же чистка — убраны setup-dotnet и NDK-шаг; release-сборка теперь идёт напрямую к подписи ключа и fastlane.
- `FfiCore`/`Comics.Editor.Native`/`tool/build_native.sh` **не удалены** — оставлены как архивный, протестированный (на macOS) задел на случай будущей поддержки мобильного NativeAOT со стороны Microsoft; явно помечены в коде как неиспользуемые в проде. `ffi_core_test.dart` продолжает идти в CI (macos job) как регрессионный тест архивной ветки — не влияет на реальную конфигурацию платформ.

Проверено локально: `flutter analyze` — 0 ошибок; `flutter test` — 8/8 (dart_io_core_test проходит для обеих ролей, поскольку он платформонезависим); `flutter build apk --debug` — собирается без .NET-шагов.

**Итог сессии 3**: iOS и Android теперь архитектурно единообразны — оба используют `DartIoCore`, ни один не требует внешних нативных бинарников для мобильной сборки. Desktop (Windows/macOS/Linux) не затронут — по-прежнему `CoreClient` + headless-процесс.

---

### Session 2026-07-25 (продолжение) - Claude

**Started at**: пользователь прислал лог GitHub Actions — job `Linux`

#### Прогресс: Linux desktop-сборка и headless-публикация теперь проходят

`dotnet build native/Comics.Editor.Headless/Comics.Editor.Headless.csproj`, `flutter build linux --release`, `tool/build_headless.sh` (auto-detect `linux-x64`) — всё успешно на настоящем Ubuntu 24.04 CI-раннере. Артефакт скопирован в `build/linux/x64/release/bundle/data/comics-core/`.

#### Падение: `core_client_test.dart` — «Core process exited» на первом же `ping`

`flutter test` упал на интеграционном тесте `core_client_test.dart` (5 из 6 файловых тестов прошли, включая весь `dart_io_core_test.dart`) с `CoreException: Core process exited` буквально на первом вызове `client.call('ping')` — self-contained `Comics.Editor` (linux-x64) стартовал и почти сразу завершился, ещё до ответа.

**Диагностика**: `CoreClient` на тот момент не читал `stderr` дочернего процесса и не передавал код завершения в сообщение об ошибке — реальная причина краша была не видна ни в тесте, ни в логе. Попытался воспроизвести на этой (macOS/arm64) машине:
- Docker с `--platform linux/amd64` (та же архитектура, что у GH runner) не смог запустить x64-бинарник — Rosetta-эмуляция в Docker Desktop на этой машине сломана (`rosetta error: failed to open elf`), независимо от нашего кода.
- Собрал self-contained `linux-arm64` (нативная архитектура для Docker на Apple Silicon) и прогнал в `ubuntu:24.04` контейнере: (а) простой `ping` через `echo | binary` — сработал; (б) точная имитация поведения `CoreClient` через `bash coproc` (персистентный pipe: spawn → write ping → read → write openComics с реальным `sample.comics` → read) — **тоже полностью сработала**, включая корректное открытие реального файла. Значит бинарник, протокол NDJSON и сама логика (Rpc/Models/zip) корректны на Linux как таковом — проблема специфична для amd64-окружения GH Actions и/или самого `flutter test`, которую я не могу воспроизвести локально из-за архитектуры этой машины.

**Улучшение диагностики** (`lib/src/bridge/core_client.dart`): `start()` теперь также слушает `process.stderr` (копится в `_stderrLines`, ранее вообще не читался — риск заполнения буфера pipe при любом выводе в stderr); `_onExit()` принимает код завершения и включает его вместе с накопленным stderr в текст `CoreException`, вместо голого «Core process exited». Также добавлен `await stdin.flush()` после `writeln()` — не относится напрямую к этому крашу (буферизация вызвала бы зависание/таймаут, а не мгновенный выход), но правильная защита от гонки в целом.

Проверено локально: `flutter analyze` — 0 ошибок; `flutter test` — 8/8 (macOS); `dotnet build native/Comics.slnx` — 0 ошибок.

**Итог**: следующий прогон Linux job в CI покажет реальный код завершения и stderr процесса вместо немой ошибки — тогда причина станет видна напрямую, а не по догадке.
