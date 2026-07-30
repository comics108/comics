# Implementation Plan: comics-editor-v2.9-fixes2 — четыре независимых доработки

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-25
> Specifications: [02-specifications.md](02-specifications.md) (APPROVED)

## Summary

Четыре независимых трека (A/B/C/D), без зависимостей друг между другом — можно реализовывать и принимать в любом порядке. Внутри каждого трека — своя последовательность задач. Порядок ниже (A → C → D → B) выбран по убыванию уверенности в дизайне и предсказуемости объёма работы: A/C/D имеют полный дизайн из Specifications, B намеренно начинается с чистого расследования (дизайн фикса неизвестен до результата шага B.1).

Важный контекст, обнаруженный при планировании: **A и D затрагивают РАЗНЫЕ UI-пути** — `lib/main.dart` показывает `WpfEditorView` (A, легаси WPF-редактор в отдельном окне) на Windows и `EditorScope(child: EditorScreen())` (D, Flutter-нативный редактор — canvas/top_bar/timeline) на остальных платформах. Undo/Redo (D) сейчас недостижим на Windows не потому, что там что-то сломано, а потому что Windows вообще не показывает `EditorScreen` — это существующее, не меняемое этим flow архитектурное решение (см. `README`, `sdd-comics-editor-v2.9`), не баг.

Git — только руками пользователя (память `git-manual-only`), агент не коммитит/не пушит. Windows (A) и Linux CI (B) верифицируются только реальными CI-прогонами, присылаемыми пользователем — агент на macOS не может собрать/запустить ни то, ни другое напрямую.

## Task Breakdown

### Track A: Windows hostfxr/nethost interop

#### Task A.1: `windows/editor_plugin/hostfxr_bootstrap.h/.cpp`
- **Description**: Резолвинг `hostfxr.dll` (через `DOTNET_ROOT`/`C:\Program Files\dotnet` + перечисление `host\fxr\`), ручные typedef'ы нужных hostfxr-функций (`hostfxr_initialize_for_runtime_config`, `hostfxr_get_runtime_delegate`, `hostfxr_close`), ленивая `EnsureHostInitialized()` с кэшированием function pointer'ов, обёртки `CallHandleMethodCall`/`CallFreeResultString`.
- **Files**: `windows/editor_plugin/hostfxr_bootstrap.h` — Create; `windows/editor_plugin/hostfxr_bootstrap.cpp` — Create
- **Dependencies**: None
- **Verification**: Компилируется в составе `editor_plugin` (проверяется вместе с Task A.3 на реальном Windows CI — см. Task A.6)
- **Complexity**: High (единственная часть без прямого прецедента в этом репозитории; hostfxr ABI зафиксирован Microsoft, но ручное объявление typedef'ов — риск опечатки в сигнатуре)

#### Task A.2: `native/Comics.Editor.Flutter/NativeExports.cs`
- **Description**: `[UnmanagedCallersOnly]`-экспорты `HandleMethodCall(IntPtr methodPtr, IntPtr argsJsonPtr) -> IntPtr` и `FreeResultString(IntPtr ptr)` — тонкая обёртка над уже существующим `MethodChannelHandler.HandleMethodCall`, UTF-16 маршалинг через `Marshal.PtrToStringUni`/`Marshal.StringToHGlobalUni`/`Marshal.FreeHGlobal`.
- **Files**: `native/Comics.Editor.Flutter/NativeExports.cs` — Create
- **Dependencies**: None
- **Verification**: `dotnet build native/Comics.slnx -c Release` — чистая сборка (можно проверить локально на macOS, т.к. это чистый C#, без Windows-specific API)
- **Complexity**: Low

#### Task A.3: `windows/editor_plugin/editor_plugin.cpp` — реальный вызов вместо заглушки
- **Description**: `HandleMethodCall` вызывает `EnsureHostInitialized()`, затем `CallHandleMethodCall(method_name, args)`, парсит JSON-результат (минимально — наличие ключа `"error"`) → `result->Success()`/`result->Error()`. При ошибке инициализации хоста — `result->Error("interop_init_failed", ...)` вместо падения.
- **Files**: `windows/editor_plugin/editor_plugin.cpp` — Modify; `windows/editor_plugin/include/editor_plugin.h` — Modify (если нужны новые приватные методы)
- **Dependencies**: A.1, A.2
- **Verification**: Реальный Windows CI (Task A.6)
- **Complexity**: Medium

#### Task A.4: CMake — вернуть публикацию + добавить копирование в упакованное приложение
- **Description**: Раскомментировать `add_custom_target(editor_plugin_csharp ALL ...)`/`add_dependencies(...)` в `windows/editor_plugin/CMakeLists.txt` (были отключены в `sdd-comics-editor-build`). Добавить `add_custom_command(TARGET ${BINARY_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_BINARY_DIR}/dotnet" "$<TARGET_FILE_DIR:${BINARY_NAME}>/dotnet")` в `windows/runner/CMakeLists.txt` (иначе hostfxr не найдёт `Comics.Editor.Flutter.dll` рядом с `comics_editor.exe` — пробел, найденный на Specifications).
- **Files**: `windows/editor_plugin/CMakeLists.txt` — Modify; `windows/runner/CMakeLists.txt` — Modify
- **Dependencies**: None (можно делать параллельно с A.1-A.3)
- **Verification**: Реальный Windows CI (Task A.6)
- **Complexity**: Low

#### Task A.5: `lib/src/bridge/wpf_editor_view.dart` — вызов `dispose`
- **Description**: Переопределить `State.dispose()` в `_WpfEditorViewState` — fire-and-forget `WpfEditorView.channel.invokeMethod<void>('dispose')` (без await, синхронный контекст `dispose()`), вызвать `super.dispose()`.
- **Files**: `lib/src/bridge/wpf_editor_view.dart` — Modify
- **Dependencies**: None
- **Verification**: `flutter analyze` чистый; unit-тест с мок method channel (проверить наличие похожего паттерна мока в `test/` на старте задачи; если нет — минимальный `TestDefaultBinaryMessengerBinding.setMockMethodCallHandler`)
- **Complexity**: Low

#### Task A.6: Реальная верификация на Windows CI
- **Description**: Пользователь коммитит/пушит A.1-A.5, запускает `build-windows` в `build.yml`. Проверка: сборка проходит, `flutter test` (существующие тесты) не ломается. Ручная проверка (по возможности, не блокирует): открыть редактор на реальной Windows-машине, увидеть WPF-окно v2.8, закрыть приложение без падений.
- **Files**: Нет (только прогон CI)
- **Dependencies**: A.1, A.2, A.3, A.4, A.5
- **Verification**: Зелёный лог `build-windows`, присланный пользователем
- **Complexity**: Low (сама задача простая, но может потребовать несколько итераций фиксов по результатам реального лога — см. Risk Assessment)

### Track C: `Convert()` — комментарий вместо TODO

#### Task C.1: Заменить `// TODO remove convert functionality`
- **Description**: Точный текст — см. `02-specifications.md`, раздел C. Логика метода не меняется ни на символ.
- **Files**: `native/Comics.Editor/ViewModel/ComicsViewModel.cs` — Modify
- **Dependencies**: None
- **Verification**: `dotnet build native/Comics.slnx -c Release` чистый (можно проверить локально на macOS)
- **Complexity**: Low

### Track D: Undo/Redo

#### Task D.1: `lib/src/ui/edit_history.dart` — класс `EditHistory`
- **Description**: Стек снапшотов, см. `02-specifications.md` за полным кодом — `beginTransaction`/`commitTransaction`/`undo`/`redo`/`clear`, геттеры `canUndo`/`canRedo`.
- **Files**: `lib/src/ui/edit_history.dart` — Create
- **Dependencies**: None
- **Verification**: `test/edit_history_test.dart` (Task D.7) — можно писать сразу вместе с классом
- **Complexity**: Low

#### Task D.2: `EditorController` — интеграция истории
- **Description**: Добавить `EditHistory _history`, `canUndo`/`canRedo` геттеры, `undo()`/`redo()`, приватный хелпер `_withHistory(void Function())`. Обернуть каждый из дискретных мутаторов (`addLayer`, `moveLayer`, `deleteSelected`, `toggleVisible`, `setImageFile`, `setImagePopup`, `addSound`, `moveSound`, `addAnim`, `deleteAnim`, `editAnim`, `setCanvasSize`, `setLanguage`) в `_withHistory(...)` вместо самостоятельного `notifyListeners()`. Добавить `beginGestureHistory()`/`commitGestureHistory()` для `dragSelected` (без изменения тела `dragSelected` самого). Вызвать `_history.clear()` в начале `newDoc()` и `openRecent()`.
- **Files**: `lib/src/ui/controller.dart` — Modify
- **Dependencies**: D.1
- **Verification**: `flutter analyze` чистый; существующие тесты (`flutter test`) не ломаются
- **Complexity**: Medium (много мест правки, но каждое — механическая обёртка одного и того же вида; риск — пропустить один из ~15 методов)

#### Task D.3: `canvas_view.dart` — границы жеста для drag слоя
- **Description**: `onPanStart` (строка ~148) — добавить `c.beginGestureHistory()` после `c.selectLayer(i)`; добавить `onPanEnd: (_) => c.commitGestureHistory()`.
- **Files**: `lib/src/ui/widgets/canvas_view.dart` — Modify
- **Dependencies**: D.2
- **Verification**: Ручная проверка — drag слоя, затем один Ctrl+Z откатывает весь drag целиком (не по кадрам)
- **Complexity**: Low

#### Task D.4: Клавиатурные шорткаты Ctrl+Z / Ctrl+Shift+Z
- **Description**: Обернуть `Scaffold` в `EditorScreen.build()` (`lib/src/ui/screens/editor_screen.dart`) в `Shortcuts`/`Actions` (см. код в `02-specifications.md`). `Intent`-классы (`UndoIntent`/`RedoIntent`) — в том же файле или в `edit_history.dart`.
- **Files**: `lib/src/ui/screens/editor_screen.dart` — Modify
- **Dependencies**: D.2
- **Verification**: Ручная проверка — Ctrl+Z/Ctrl+Shift+Z работают в canvas; Ctrl+Z в фокусированном `TextField` (например, поле ширины/высоты в Settings) отменяет ТЕКСТ, а не документ (проверка на неперехват — см. Edge Case в specs)
- **Complexity**: Low

#### Task D.5: Кнопки Undo/Redo в `TopBar` (Should Have)
- **Description**: Добавить два `HsIconButton` (`Icons.undo`/`Icons.redo`, по образцу существующих в `top_bar.dart:85-97` — add/open/share) рядом с существующими действиями; `onTap: c.canUndo ? c.undo : null`/аналогично для redo (disabled-состояние встроено в `HsIconButton`, если не поддерживает `null onTap` — проверить сигнатуру на старте задачи и подстроиться).
- **Files**: `lib/src/ui/widgets/top_bar.dart` — Modify
- **Dependencies**: D.2
- **Verification**: Ручная проверка — кнопки неактивны на пустых стеках, активны после первого изменения
- **Complexity**: Low

#### Task D.6: Тесты
- **Description**: `test/edit_history_test.dart` (unit, `EditHistory` в изоляции) + расширение существующего теста контроллера (если есть) или новый тест: `addLayer()` → `undo()` → `doc.layers.isEmpty`; `redo()` → слой вернулся. Проверка независимости снапшота (замутировать `doc` после снятия снапшота, убедиться снапшот не изменился) — см. Edge Case в specs.
- **Files**: `test/edit_history_test.dart` — Create; существующий тестовый файл контроллера — Modify (уточнить точное имя на старте задачи)
- **Dependencies**: D.1, D.2
- **Verification**: `flutter test` — новые тесты зелёные, старые не сломаны
- **Complexity**: Medium

#### Task D.7: Ручная верификация всего трека D
- **Description**: Полный чеклист из `02-specifications.md` Testing Strategy — добавление/удаление/перемещение слоя, drag (один шаг истории на весь жест), Undo/Redo кнопки и шорткаты, независимость истории между документами (`newDoc`/`openRecent` очищает историю).
- **Files**: Нет
- **Dependencies**: D.1-D.6
- **Verification**: Пользователь подтверждает интерактивно (агент не может провести GUI-верификацию в песочнице — см. `sdd-comics-editor-v2.9-fixes1`, тот же прецедент)
- **Complexity**: Low

### Track B: Linux headless CI-краш на `ping`

#### Task B.1: Получить реальные диагностические данные
- **Description**: Без изменений кода — запустить `build-linux` (реальный CI) или `tool/docker-build.sh linux` (доступен локально пользователю через Rosetta) и получить фактическое содержимое `CoreException` (stderr + exit code) при падении на `ping`.
- **Files**: Нет
- **Dependencies**: None
- **Verification**: Реальный вывод получен и прочитан
- **Complexity**: Low (сама задача — просто прогон; результат непредсказуем)

#### Task B.2: Проанализировать находку, выбрать гипотезу
- **Description**: Сопоставить реальный stderr с 4 гипотезами из `02-specifications.md` (glibc/musl mismatch, гонка старта процесса, права на исполняемость, изоляция `flutter test`-раннера) — подтвердить одну или найти новую.
- **Files**: Нет
- **Dependencies**: B.1
- **Verification**: Причина названа конкретно, не «одна из гипотез»
- **Complexity**: Не оценивается заранее (зависит от находки)

#### Task B.3: Реализовать минимальный фикс
- **Description**: Проектируется по факту B.2 — не описывается заранее (см. `02-specifications.md`, Won't Have: не переписываем протокол `CoreClient` целиком).
- **Files**: TBD по B.2 (вероятно `native/Comics.Editor.Headless`, `lib/src/bridge/core_client.dart`, или `.github/workflows/build.yml`/`docker-build.yml`)
- **Dependencies**: B.2
- **Verification**: TBD
- **Complexity**: TBD

#### Task B.4: Верификация фикса реальным CI
- **Description**: `build-linux`/`docker-build-linux` — `core_client_test.dart` проходит.
- **Files**: Нет
- **Dependencies**: B.3
- **Verification**: Зелёный лог, присланный пользователем
- **Complexity**: Low

## Dependency Graph

```
Track A:  A.1 ─┬─→ A.3 ─┐
          A.2 ─┘        ├─→ A.6
          A.4 ──────────┤
          A.5 ──────────┘

Track C:  C.1 (самодостаточна)

Track D:  D.1 ─→ D.2 ─┬─→ D.3 ─┐
                       ├─→ D.4 ─┤
                       ├─→ D.5 ─┼─→ D.7
                       └─→ D.6 ─┘

Track B:  B.1 ─→ B.2 ─→ B.3 ─→ B.4
```

Треки A/B/C/D между собой не пересекаются — можно вести параллельно или в любом порядке.

## File Change Summary

| File | Action | Track |
|------|--------|-------|
| `windows/editor_plugin/hostfxr_bootstrap.h` | Create | A |
| `windows/editor_plugin/hostfxr_bootstrap.cpp` | Create | A |
| `native/Comics.Editor.Flutter/NativeExports.cs` | Create | A |
| `windows/editor_plugin/editor_plugin.cpp` | Modify | A |
| `windows/editor_plugin/include/editor_plugin.h` | Modify (возможно) | A |
| `windows/editor_plugin/CMakeLists.txt` | Modify | A |
| `windows/runner/CMakeLists.txt` | Modify | A |
| `lib/src/bridge/wpf_editor_view.dart` | Modify | A |
| `native/Comics.Editor/ViewModel/ComicsViewModel.cs` | Modify | C |
| `lib/src/ui/edit_history.dart` | Create | D |
| `lib/src/ui/controller.dart` | Modify | D |
| `lib/src/ui/widgets/canvas_view.dart` | Modify | D |
| `lib/src/ui/screens/editor_screen.dart` | Modify | D |
| `lib/src/ui/widgets/top_bar.dart` | Modify | D |
| `test/edit_history_test.dart` | Create | D |
| TBD (по итогам B.1/B.2) | TBD | B |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| hostfxr ABI/typedef ошибка (Task A.1) не проявится до реального Windows CI-прогона | Med | Med | Несколько раундов итерации с реальными логами уже отработаны на этом же приложении (`sdd-comics-editor-build`, MSB1008) — процесс известен: маленькие изменения, реальная верификация, не гадать |
| A.4 POST_BUILD copy — синтаксис CMake generator expression (`$<TARGET_FILE_DIR:...>`) может не сработать с первого раза | Low | Low | Тривиально проверяется по логу сборки (упавший COPY даст понятную ошибку, не тихий сбой) |
| Track D: пропущен один из ~15 мутаторов при обёртке `_withHistory` (Task D.2) | Med | Med | Чек-лист по списку методов в самом Task D.2; тесты (D.6) на несколько репрезентативных мутаторов, не только `addLayer` |
| Track D: `Shortcuts`/`Actions` (D.4) всё же перехватывает Ctrl+Z у фокусированного `TextField` | Low | Med | Явно проверяется в Task D.4 Verification — если перехватывает, придётся сузить `Shortcuts` до конкретного поддерева (canvas), не всего `EditorScreen` |
| Track B: находка (B.2) не совпадёт ни с одной из 4 гипотез | Med | Med | Специально не проектируем фикс заранее — B.3 адаптируется под реальную находку |
| Track A: реальный Windows CI недоступен агенту — каждая итерация фикса требует ручного коммита/пуша/прогона пользователем (медленный цикл) | High (известно заранее) | Low | Уже отработанный процесс с этим же пользователем на этом же приложении — не блокирует, просто медленнее |

## Rollback Strategy

- **Track A**: откатить 8 файлов из File Change Summary — `editor_plugin_csharp` custom target возвращается в закомментированное состояние (как сейчас), приложение продолжает показывать заглушку `not_implemented`. Не влияет на другие треки/платформы.
- **Track B**: если B.3 не даст стабильного фикса — оставить как есть (баг уже существует и задокументирован дважды; этот flow — третья попытка, не единственная возможность его закрыть).
- **Track C**: тривиально отменить (один комментарий).
- **Track D**: удалить `edit_history.dart`, откатить обёртки в `controller.dart` к прямому `notifyListeners()`, убрать `Shortcuts`/кнопки — Undo/Redo просто отсутствует, как сейчас.

## Checkpoints

- [ ] После Track A: реальный `build-windows` зелёный (Task A.6)
- [ ] После Track C: `dotnet build native/Comics.slnx` чистый
- [ ] После Track D: `flutter test`/`flutter analyze` чистые + ручная верификация пользователем (Task D.7)
- [ ] После Track B: реальный `build-linux`/`docker-build-linux` зелёный (Task B.4)
- [ ] Отклонения от плана — фиксировать в `04-implementation-log.md`

## Open Implementation Questions

- [ ] Track D: Undo во время preview-режима — решить по ходу Task D.4/D.7 (не блокирует старт реализации, см. `02-specifications.md`)
- [ ] Track B: полностью открыто до Task B.1 — намеренно (см. Summary)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «plan approved»
