# Specifications: comics-editor-v2.9 — iOS/Android + системные файловые диалоги

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-23
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

Три направления работ в `apps/comics-editor-v2.9`:

1. **Мобильные раннеры**: `flutter create --platforms ios,android` + конфигурация (iPad, ориентации, intent-filter/UTI для `.comics`/`.puzzle`).
2. **FFI-ядро (NativeAOT)**: новый обвязочный проект `native/Comics.Editor.Native` — те же линкованные C#-исходники, что в Headless, но с C-экспортами (`UnmanagedCallersOnly`) и публикацией NativeAOT-библиотек: iOS — статическая `.a`, Android — `.so`, macOS — `.dylib` (для проверки AOT-пути на хосте). Протокол не меняется: JSON-запрос → JSON-ответ, те же методы (`ping`/`openComics`/`saveComics`/`exportPackage`/`imageInfo`).
3. **Файловые диалоги + мобильный Save**: пакет `file_picker`; единая абстракция транспорта ядра в Dart (процесс на десктопе, FFI на мобильных); Save на мобильных — в песочницу, Export/Share — системным диалогом.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `native/Comics.Editor.Native/` | Create (обвязка) | csproj + NativeApi.cs (C-экспорты) + rd.xml; линк Rpc.cs/WpfShims.cs из Headless и не-UI исходников редактора |
| `native/Comics.slnx` | Modify | + Comics.Editor.Native |
| `ios/`, `android/` | Create | flutter create + конфигурация (UTI/intent-filter, iPad, jniLibs) |
| `ios/ComicsCore/` (или Frameworks) | Create | Подключение статической библиотеки в Runner (vendored pod / link phase) |
| `android/app/src/main/jniLibs/<abi>/libcomicscore.so` | Create (артефакт) | Копируется скриптом сборки |
| `lib/src/bridge/comics_core.dart` | Create | Абстракция `ComicsCore` (call/dispose) + фабрика по платформе |
| `lib/src/bridge/core_client.dart` | Modify | Становится `ProcessCore implements ComicsCore` (код переиспользуется) |
| `lib/src/bridge/ffi_core.dart` | Create | dart:ffi клиент (`comics_call`/`comics_free`), вызовы в фоновом isolate |
| `lib/src/bridge/documents.dart` | Create | Мобильный store: Save в песочницу (`<documents>/comics/`), список локальных документов |
| `lib/src/ui/controller.dart` | Modify | `openWithDialog()`, `exportWithDialog()`, Save-логика по платформе |
| `lib/src/ui/widgets/dialogs.dart` | Modify | Open-диалог: Browse… → file_picker; убрать поле пути |
| `lib/src/ui/widgets/top_bar.dart` | Modify | + Export/Share (mobile/desktop «Save As») |
| `pubspec.yaml` | Modify | + `file_picker` |
| `tool/build_native.sh` | Create | Публикация NativeAOT RID-ов + раскладка артефактов |
| `test/` | Modify/Create | FFI round-trip на macOS-dylib; существующие тесты не ломаются |
| `README.md` | Modify | Разделы iOS/Android, сборка нативных библиотек |

Не затрагиваются: `Comics.Editor` (WPF), `Comics.Core`, `Comics.Editor.Headless` (десктоп-процесс остаётся), `Comics.Editor.Flutter`, `windows/`.

## Architecture

```
                         Flutter (Dart)
  ┌───────────────────────────────────────────────────────────┐
  │ UI (макет, adaptive phone/tablet/desktop)                  │
  │   Open ──► file_picker (все платформы)                     │
  │   Save ──► desktop: путь документа │ mobile: песочница     │
  │   Export ► file_picker.saveFile (системный диалог)         │
  │                                                            │
  │            ComicsCore (абстракция: call(method, params))   │
  │           ┌───────────────┴───────────────┐                │
  │      ProcessCore (desktop)          FfiCore (iOS/Android)  │
  │      NDJSON ↔ stdio-процесс         dart:ffi, фон. isolate │
  └───────────┼─────────────────────────────┼──────────────────┘
              ▼                             ▼
   Comics.Editor.Headless        Comics.Editor.Native (НОВОЕ, обвязка)
   (self-contained exe)          NativeAOT: ios-arm64 .a │ android .so │ osx .dylib
              └────────── одни и те же линкованные исходники ──────────┘
                Rpc.cs + Models/ + FileManager/ZipUtils + WpfShims
```

## Interfaces

### C-API (`Comics.Editor.Native/NativeApi.cs`)

```c
// UTF-8 JSON in/out; результат освобождается вызывающим через comics_free.
char* comics_call(const char* method, const char* params_json);
void  comics_free(char* ptr);
```

- Реализация: `[UnmanagedCallersOnly(EntryPoint = "comics_call")]` → `Rpc.Dispatch(method, args)` (линкованный из Headless) → JSON-строка (`{"result":…}` | `{"error":{…}}`); маршал в unmanaged UTF-8.
- **AssemblyName = `Comics.Editor`** (то же требование `$type`, что и у Headless).
- `rd.xml` (TrimmerRootDescriptor): корневание `Comics.Editor.Models.*` и Newtonsoft.Json — иначе NativeAOT срежет типы, нужные reflection-сериализации.

### Dart

```dart
abstract class ComicsCore {
  Future<dynamic> call(String method, [Map<String, dynamic>? params]);
  Future<void> dispose();
}
ComicsCore createComicsCore(); // Platform.isIOS/isAndroid → FfiCore, иначе ProcessCore

class FfiCore implements ComicsCore {
  // DynamicLibrary: iOS → process() (статическая линковка), Android → open('libcomicscore.so')
  // call(): Isolate.run(() => sync ffi call) — не блокировать UI-поток
}
```

### Публикация нативных библиотек (`tool/build_native.sh`)

| Target | RID | Вид | Куда |
|--------|-----|-----|------|
| iOS device | `ios-arm64` | static `.a` (`NativeLib=Static`) | `ios/ComicsCore/` (vendored в Runner) |
| iOS simulator | `iossimulator-arm64` | static `.a` | то же (по конфигурации) |
| Android device | `linux-bionic-arm64` | shared `.so` (`NativeLib=Shared`) | `android/app/src/main/jniLibs/arm64-v8a/` |
| Android emulator | `linux-bionic-x64` | shared `.so` | `.../x86_64/` |
| macOS (тест AOT-пути) | `osx-arm64` | shared `.dylib` | `native/Comics.Editor.Native/publish/` (только для тестов) |

Примечания: Android — через `linux-bionic-*` RID (NDK toolchain, без mobile-workload); iOS требует Xcode (и, возможно, `dotnet workload install ios` — уточняется при реализации; оба пути описываются в README).

## Behavior Specifications

### Open (все платформы)

1. Open-диалог макета → Browse… → `FilePicker.pickFiles(type: custom, extensions: ['comics','puzzle'])`.
2. Получен путь (на мобильных — копия во временной папке пикера) → `controller.openPath(path)` → `core.call('openComics')` (транспорт по платформе) → UI.
3. Текстовое поле ручного ввода пути удаляется (`showOpenPathDialog` заменяется системным диалогом).

### Save / Export

- **Desktop**: Save → `saveComics` в путь открытого файла (как сейчас). Export/«Save As» → `FilePicker.saveFile()` → путь → `saveComics` по нему.
- **Mobile**: Save → `saveComics` в `<app documents>/comics/<имя>.comics` (без диалогов; `documents.dart` ведёт список). Export → ядро сохраняет во временный файл → байты → `FilePicker.saveFile(bytes: …)` (iOS Files / Android SAF).
- Open-диалог на мобильных дополнительно показывает список локальных документов из песочницы (recents становятся реальными).

### Файловые ассоциации (Should Have)

- iOS `Info.plist`: `CFBundleDocumentTypes` + `UTExportedTypeDeclarations` для `.comics`/`.puzzle`.
- Android manifest: intent-filter `VIEW` по расширению (`pathPattern` `.comics`/`.puzzle`).
- Обработка входящего открытия (openURL/intent → openPath) — минимальный хук; при сложностях выделяется в отдельную отложенную задачу плана.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Newtonsoft под NativeAOT срезал типы | round-trip на sample.comics через osx-dylib | Дополнять rd.xml до зелёного теста; тест — ворота: без него мобильный транспорт не считается готовым |
| `FileManager.TempFolder` на iOS/Android | LocalApplicationData в песочнице | Проверить фактический путь через `ping` (возвращает tempFolder); при необходимости выставить `HOME`/`XDG_DATA_HOME` из Dart до первого вызова (setenv-обвязка, C# не меняется) |
| Долгий open на слабом устройстве | большой .comics | FFI-вызов в `Isolate.run` + индикатор в UI |
| Пользователь отменил диалог | pickFiles/saveFile → null | Состояние не меняется, ошибок нет |
| Android-эмулятор x86_64 | нет .so нужного ABI | Собираются оба ABI; при отсутствии — понятный баннер «core unavailable» |
| iOS: линкер выкинул comics_call из .a | сборка Runner | `-force_load` в OTHER_LDFLAGS (podspec/xcconfig); проверяется при сборке |
| Нет ImageMagick на мобильных | imageInfo | Метод возвращает error; мобильный UI его не вызывает (v1) |

### Error Handling

Как в текущем ядре: `{"error":{"message","type"}}` → `CoreException` → диалог/баннер. FfiCore дополнительно: null-указатель/пустой ответ → `CoreException('Native core call failed')`.

## Dependencies

- Dart: `file_picker` (единственный новый пакет).
- Сборка: Xcode (iOS), Android SDK+NDK, .NET 10 SDK; возможно `dotnet workload install ios`.
- Устройства: симулятор/эмулятор при наличии; иначе отложенный чек-лист в README (как с Windows-interop).

## Testing Strategy

- [ ] **AOT-ворота (главное)**: publish `osx-arm64` dylib → FFI round-trip open→edit→save→reopen на `sample.comics` — новый тест на хосте, доказывает Newtonsoft+rd.xml под NativeAOT без устройств.
- [ ] Существующие тесты (`flutter test`, headless round-trip) — без регрессий.
- [ ] `flutter build ios --no-codesign`, `flutter build apk --debug` — собираются.
- [ ] Симулятор/эмулятор (при наличии): системный Open, Save в песочницу, Export.
- [ ] `dotnet build native/Comics.slnx` — 0 ошибок.

## Open Design Questions

- [ ] iOS-подключение `.a`: vendored CocoaPod (предпочтение — скриптуется) vs прямое добавление в Xcode link phase — финализируется при реализации.
- [ ] Мобильные «recents»: простой листинг файлов песочницы (предлагается) vs отдельный индекс.

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-23
- [x] Notes: «specs approved».
