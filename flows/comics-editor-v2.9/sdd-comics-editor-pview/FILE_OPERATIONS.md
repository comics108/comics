# Детальный список файловых операций: Flutter Comics Editor

> Дата: 2026-07-19
> Связано с: 02-specifications.md

## Легенда

- ✅ **ОСТАВИТЬ** - файл остается как есть, без изменений
- 📝 **РЕДАКТИРОВАТЬ** - файл будет изменен/дополнен
- 🔄 **ПЕРЕМЕСТИТЬ** - файл будет перемещен в другое место
- ❌ **УДАЛИТЬ** - файл больше не нужен
- ➕ **СОЗДАТЬ (новый)** - новый файл, написанный с нуля
- 🔁 **ПЕРЕПИСАТЬ (C# → Dart)** - взять логику из C# и переписать на Dart

---

## 1. FLUTTER DART КОД

### 1.1. lib/ (Основной код плагина)

#### Существующие файлы:

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `lib/editor.dart` | 📝 **РЕДАКТИРОВАТЬ** | Сейчас: экспорт FFI функций sum(). Станет: экспорт ComicsEditorWidget, EditorController, моделей |
| `lib/editor_bindings_generated.dart` | 📝 **РЕДАКТИРОВАТЬ** | Будет перегенерирован ffigen с новыми C функциями для редактора |

#### Новые файлы (создать с нуля):

| Файл | Операция | Описание |
|------|----------|----------|
| `lib/src/editor_widget.dart` | ➕ **СОЗДАТЬ** | Главный виджет ComicsEditorWidget (StatefulWidget) |
| `lib/src/editor_controller.dart` | ➕ **СОЗДАТЬ** | Контроллер для управления состоянием редактора (ChangeNotifier) |
| `lib/src/ffi_bridge.dart` | ➕ **СОЗДАТЬ** | Обертка над FFI вызовами к C/C# |
| `lib/src/constants.dart` | ➕ **СОЗДАТЬ** | Константы плагина |
| `lib/src/models/layer.dart` | 🔁 **ПЕРЕПИСАТЬ** | Модель Layer из C# (native/Comics.Editor/Models/Layer.cs) |
| `lib/src/models/episode.dart` | ➕ **СОЗДАТЬ** | Модель Episode (логика на основе C# Comics.cs) |
| `lib/src/models/animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Базовая модель анимации (из C# Anim.cs) |
| `lib/src/models/animations/alpha_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# AlphaAnim.cs |
| `lib/src/models/animations/rotate_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# RotateAnim.cs |
| `lib/src/models/animations/scale_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# ScaleAnim.cs |
| `lib/src/models/animations/translate_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# TranslateAnim.cs |
| `lib/src/models/animations/pivot_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# PivotAnim.cs |
| `lib/src/models/sound.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# Sound.cs |
| `lib/src/models/sound_animation.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# SoundAnim.cs |
| `lib/src/models/image.dart` | 🔁 **ПЕРЕПИСАТЬ** | Из C# Image.cs |

### 1.2. example/lib/ (UI Demo приложение)

#### Существующие файлы:

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `example/lib/main.dart` | 📝 **ПЕРЕПИСАТЬ ПОЛНОСТЬЮ** | Сейчас: демо sum(). Станет: полноценное приложение редактора с UI |

#### Новые файлы (UI компоненты - писать с нуля):

**Основное**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/screens/editor_screen.dart` | ➕ **СОЗДАТЬ** | Главный экран редактора с layout |

**Панели инструментов**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/toolbar/toolbar_widget.dart` | ➕ **СОЗДАТЬ** | Верхняя панель инструментов |
| `example/lib/widgets/toolbar/tool_button.dart` | ➕ **СОЗДАТЬ** | Кнопка инструмента |

**Панели параметров**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/panels/parameter_panel.dart` | ➕ **СОЗДАТЬ** | Панель параметров слоя (позиция, размер, поворот, прозрачность) |
| `example/lib/widgets/panels/layers_panel.dart` | ➕ **СОЗДАТЬ** | Список слоев |
| `example/lib/widgets/panels/timeline_panel.dart` | ➕ **СОЗДАТЬ** | Таймлайн анимации |
| `example/lib/widgets/panels/properties_panel.dart` | ➕ **СОЗДАТЬ** | Свойства выбранного элемента |
| `example/lib/widgets/panels/sounds_panel.dart` | ➕ **СОЗДАТЬ** | Панель звуков |

**Селекторы**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/selectors/image_selector.dart` | ➕ **СОЗДАТЬ** | Выбор изображения из файла |
| `example/lib/widgets/selectors/sound_selector.dart` | ➕ **СОЗДАТЬ** | Выбор звука из файла |
| `example/lib/widgets/selectors/color_picker.dart` | ➕ **СОЗДАТЬ** | Выбор цвета |

**Canvas**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/widgets/canvas/editor_canvas_wrapper.dart` | ➕ **СОЗДАТЬ** | Обертка над ComicsEditorWidget с zoom/pan |

**Утилиты**
| Файл | Операция | Описание |
|------|----------|----------|
| `example/lib/utils/file_helpers.dart` | ➕ **СОЗДАТЬ** | Помощники для работы с файлами |

### 1.3. Конфигурационные файлы

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | Изменить name: editor → flutter_comics_editor, добавить зависимости (path_provider и др.) |
| `example/pubspec.yaml` | 📝 **РЕДАКТИРОВАТЬ** | Обновить ссылку на плагин |
| `README.md` | 📝 **РЕДАКТИРОВАТЬ** | Документация по новой структуре |
| `CHANGELOG.md` | 📝 **РЕДАКТИРОВАТЬ** | Добавить запись о рефакторинге |
| `analysis_options.yaml` | ✅ **ОСТАВИТЬ** | Без изменений |
| `ffigen.yaml` | 📝 **РЕДАКТИРОВАТЬ** | Обновить для генерации новых FFI биндингов |

---

## 2. NATIVE C FFI СЛОЙ

### 2.1. src/ (C код для FFI)

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `src/editor.h` | 📝 **ПЕРЕПИСАТЬ ПОЛНОСТЬЮ** | Сейчас: sum() функции. Станет: API для редактора (editor_create, editor_add_layer, и т.д.) |
| `src/editor.c` | 📝 **ПЕРЕПИСАТЬ ПОЛНОСТЬЮ** | Сейчас: sum() реализация. Станет: мост к C# через COM/P/Invoke или другой механизм |
| `src/CMakeLists.txt` | 📝 **РЕДАКТИРОВАТЬ** | Возможно потребуется настройка линковки с C# DLL |

**Новые файлы (если потребуется):**
| Файл | Операция | Описание |
|------|----------|----------|
| `src/csharp_interop.h` | ➕ **СОЗДАТЬ** (возможно) | Заголовки для взаимодействия с C# |
| `src/csharp_interop.c` | ➕ **СОЗДАТЬ** (возможно) | Реализация взаимодействия с C# |

---

## 3. C# NATIVE HANDLER

### 3.1. native/Comics.Editor/ (WPF приложение)

**ВАЖНО:** Эти файлы **НЕ ТРОГАЕМ** - они остаются для референса!

| Директория/Файл | Операция | Комментарий |
|-----------------|----------|-------------|
| `native/Comics.Editor/Models/*.cs` | ✅ **ОСТАВИТЬ (референс)** | Используем как референс для Dart моделей |
| `native/Comics.Editor/ViewModel/*.cs` | ✅ **ОСТАВИТЬ (референс)** | Логика будет частично перенесена в Dart контроллер |
| `native/Comics.Editor/Controls/*.xaml` | ✅ **ОСТАВИТЬ (референс)** | UI референс для Flutter виджетов |
| `native/Comics.Editor/App.xaml` | ✅ **ОСТАВИТЬ (референс)** | - |
| `native/Comics.Editor/App.xaml.cs` | ✅ **ОСТАВИТЬ (референс)** | - |

### 3.2. native/Comics.Web/

| Директория | Операция | Комментарий |
|------------|----------|-------------|
| `native/Comics.Web/*` | ✅ **ОСТАВИТЬ (референс)** | Оставляем для референса, как указано в требованиях |

### 3.3. native/Comics.Core/

| Директория | Операция | Комментарий |
|------------|----------|-------------|
| `native/Comics.Core/*` | ✅ **ОСТАВИТЬ (референс)** | Core бизнес-логика, может понадобиться для референса |

---

## 4. PLATFORM-SPECIFIC BUILD FILES

### 4.1. Windows

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `windows/CMakeLists.txt` | 📝 **РЕДАКТИРОВАТЬ** (возможно) | Настройка сборки для Windows |
| `windows/editor_plugin.h` | ✅ **ОСТАВИТЬ** | Генерируется автоматически |
| `windows/editor_plugin.cpp` | ✅ **ОСТАВИТЬ** | Генерируется автоматически |

### 4.2. macOS

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `macos/editor.podspec` | 📝 **РЕДАКТИРОВАТЬ** (возможно) | Обновить описание |
| `macos/Classes/editor.c` | 📝 **РЕДАКТИРОВАТЬ** | Синхронизировать с src/editor.c |

### 4.3. Linux

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `linux/CMakeLists.txt` | 📝 **РЕДАКТИРОВАТЬ** (возможно) | Настройка сборки для Linux |

### 4.4. Example platform folders

| Файл | Операция | Комментарий |
|------|----------|-------------|
| `example/windows/*` | ✅ **ОСТАВИТЬ** | Генерируется Flutter |
| `example/macos/*` | ✅ **ОСТАВИТЬ** | Генерируется Flutter |
| `example/linux/*` | ✅ **ОСТАВИТЬ** | Генерируется Flutter |

---

## ИТОГОВАЯ СТАТИСТИКА

### По операциям:

- ✅ **ОСТАВИТЬ БЕЗ ИЗМЕНЕНИЙ**: ~40+ файлов (весь C# код, build файлы)
- 📝 **РЕДАКТИРОВАТЬ**: 8 файлов (editor.dart, pubspec.yaml, README.md, src/editor.h, src/editor.c, и др.)
- ➕ **СОЗДАТЬ НОВЫЕ**: ~25 файлов (виджеты, контроллеры, UI компоненты)
- 🔁 **ПЕРЕПИСАТЬ C# → Dart**: ~13 файлов (модели данных)
- ❌ **УДАЛИТЬ**: 0 файлов
- 🔄 **ПЕРЕМЕСТИТЬ**: 0 файлов

### По типам файлов:

**Dart файлы:**
- Создать новые: ~25 файлов
- Отредактировать: 2 файла (lib/editor.dart, example/lib/main.dart)
- Переписать с C#: ~13 моделей

**Native файлы:**
- Переписать: 2 файла (src/editor.h, src/editor.c)
- Оставить: вся директория native/Comics.Editor/ (~200+ файлов)

**Конфигурация:**
- Отредактировать: 5 файлов (pubspec.yaml, README.md, CHANGELOG.md, ffigen.yaml, CMakeLists.txt)

---

## ПРИОРИТЕТ РЕАЛИЗАЦИИ

### Фаза 1: Базовая структура (создание скелета)
1. Создать структуру директорий lib/src/
2. Создать структуру директорий example/lib/
3. Обновить pubspec.yaml

### Фаза 2: Модели данных (переписать с C#)
1. Layer, Episode, Animation и подтипы
2. Sound, Image
3. Вспомогательные модели

### Фаза 3: Плагин core
1. EditorController
2. EditorWidget (заглушка)
3. FFI Bridge (заглушка)

### Фаза 4: Native FFI слой
1. Переписать src/editor.h
2. Переписать src/editor.c
3. Настроить взаимодействие с C#

### Фаза 5: UI Demo (example)
1. EditorScreen основной layout
2. Toolbar и основные панели
3. Селекторы файлов
4. Canvas wrapper

### Фаза 6: Интеграция
1. Связать Flutter UI → Controller → FFI → C#
2. Тестирование
3. Документация

---

## ФАЙЛЫ ДЛЯ ПЕРЕПИСЫВАНИЯ C# → DART (детально)

### Модели из native/Comics.Editor/Models/

| C# файл | → | Dart файл | Сложность |
|---------|---|-----------|-----------|
| `Layer.cs` | → | `lib/src/models/layer.dart` | Средняя |
| `Comics.cs` | → | `lib/src/models/episode.dart` | Средняя |
| `Anim.cs` | → | `lib/src/models/animation.dart` | Средняя |
| `AlphaAnim.cs` | → | `lib/src/models/animations/alpha_animation.dart` | Низкая |
| `RotateAnim.cs` | → | `lib/src/models/animations/rotate_animation.dart` | Низкая |
| `ScaleAnim.cs` | → | `lib/src/models/animations/scale_animation.dart` | Низкая |
| `TranslateAnim.cs` | → | `lib/src/models/animations/translate_animation.dart` | Низкая |
| `PivotAnim.cs` | → | `lib/src/models/animations/pivot_animation.dart` | Низкая |
| `Sound.cs` | → | `lib/src/models/sound.dart` | Низкая |
| `SoundAnim.cs` | → | `lib/src/models/sound_animation.dart` | Низкая |
| `Image.cs` | → | `lib/src/models/image.dart` | Низкая |

**Примечание:** ViewModels (ComicsViewModel, LayerViewModel и т.д.) НЕ переписываем напрямую - их логика будет адаптирована в EditorController.

---

## ВОПРОСЫ ДЛЯ УТОЧНЕНИЯ

1. **Взаимодействие FFI ↔ C#**: Нужно ли создавать отдельный C# wrapper DLL для FFI, или использовать существующий Comics.Editor.exe?
2. **Платформы**: Фокус только на Windows, или также macOS/Linux?
3. **Фазированность**: Делаем все сразу или сначала минимальный MVP?
