# Implementation Log: comics-editor-build

> Started: 2026-07-25
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| 1.1 `docker/linux-build.Dockerfile` | Done | Собран и полностью верифицирован на реальном репозитории |
| 1.2 `docker/android-build.Dockerfile` | Done | Пересобран (фиксы `--system`/`chmod` + pre-baked NDK/CMake/platform-35) и полностью верифицирован |
| 2.1 `tool/docker-build.sh` | Done | `--platform linux/amd64`, `HOME`/`GRADLE_USER_HOME`/`JAVA_TOOL_OPTIONS`, персистентный Gradle-кэш |
| 2.1 verify (linux) | Done | Полный прогон на реальном репозитории — все 6 тестов зелёные |
| 2.1 verify (android) | Done | APK собран, все тесты зелёные, `assembleRelease` 700s → 92s после pre-bake SDK |
| 3.1/3.2 `docker-build.yml` | Done | `docker-build-linux`/`docker-build-android`, триггеры main/nightly/release, публикация артефактов |
| 4.1 `docker/README.md` | Done | |
| 4.2 Final status update | Done | |
| — Windows CI MSB1008 (внесценарийный баг, см. ниже) | In Progress | Не входит в AC Docker Build; отслеживается здесь по решению пользователя |

## Session Log

### Session 2026-07-25 — Claude (Windows CI MSB1008 investigation)

**Started at**: обнаружен реальный failing CI-лог `build-windows` (Native Build, `build.yml`), вставленный пользователем при `resume`.
**Context**: Flow был в процессе Docker Build (Phase 1-2, см. трекер выше — работа предыдущей сессии). Пользователь вставил новый Windows CI-лог с ошибкой `MSB1008: Only one project can be specified` в custom-build-step `editor_plugin_csharp`.

#### Discoveries
- Эта же ошибка уже была «исправлена» в `sdd-comics-editor-v2.9-android-ios` (см. `_status.md:45` того flow) переносом `dotnet publish <csproj> -c Release -f ... -o ... --verbosity minimal` из CMake `COMMAND` в отдельный `windows/editor_plugin/publish_csharp.cmd`.
- Тот фикс (коммит `889b5ef`) **никогда не проверялся реальным Windows CI-прогоном** — в implementation-log того flow фигурируют только `dotnet build`/`flutter test`, выполнимые на macOS; `flutter build windows` требует реальной Windows-машины. `git log` подтверждает: файлы `CMakeLists.txt`/`publish_csharp.cmd` не менялись после `889b5ef`, значит вставленный пользователем CI-лог — по сути первый реальный прогон этого кода на Windows CI, и он падает.
- Изначальный диагноз в комментарии (887b5ef) — «многотокенная команда ломает VS-генератор» / «баг сериализации, когда путь к dotnet.exe содержит пробел» — не подтверждён: перенос в `.cmd`-файл семантически не меняет число токенов и не проверялся. Диагноз был предположением, не подтверждённым фактом.
- Найдена конкретная аномалия: `publish_csharp.cmd` имел **LF-only line endings** (проверено `xxd`/`grep -c $'\r'` — 0 из 16 строк), тогда как единственный другой `.cmd`-файл в репозитории, `android/gradlew.bat` (стандартный Gradle wrapper), полностью CRLF (90/90). Для Windows batch-файла это аномалия.
- CMake вызывал `publish_csharp.cmd` по имени напрямую (`COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/publish_csharp.cmd" ...`). CMake Visual Studio generator оборачивает custom build step в собственный batch-скрипт — вызов вложенного `.cmd`/`.bat` **по имени, без `call`**, из уже выполняющегося batch-скрипта в cmd.exe не гарантированно возвращает управление вызывающему скрипту (документированная особенность cmd.exe, а не догадка).
- Точный root cause `MSB1008` **не подтверждён**. Решено не гадать в третий раз, а внести defensive-фиксы, корректные независимо от того, была ли это точная причина, плюс диагностику для следующего реального прогона.

#### Completed
- Правка `apps/comics-editor-v2.9/windows/editor_plugin/publish_csharp.cmd`:
  - Нормализованы line endings LF → CRLF.
  - Добавлены `echo`-диагностика резолвленных `SCRIPT_DIR`/`CSPROJ`/`OUT_DIR`, `dotnet --version`, и полной команды `dotnet publish` перед запуском.
  - `--verbosity minimal` → `--verbosity normal` (больше сигнала в логе, не настолько объёмно как `diagnostic`).
  - Файлы изменены: `apps/comics-editor-v2.9/windows/editor_plugin/publish_csharp.cmd`.
- Правка `apps/comics-editor-v2.9/windows/editor_plugin/CMakeLists.txt`:
  - `COMMAND "<path>\publish_csharp.cmd" "<outdir>"` → `COMMAND cmd /c call "<path>\publish_csharp.cmd" "<outdir>"`.
  - Файлы изменены: `apps/comics-editor-v2.9/windows/editor_plugin/CMakeLists.txt`.
- Документация: дополнение в `01-requirements.md` (раздел «Дополнение: Windows CI баг MSB1008 отслеживается в этом flow»), этот лог.
- Verified by: **не проверено на реальной Windows-машине** (агент работает на macOS, `flutter build windows`/MSBuild недоступны локально). Проверка — только следующим реальным CI-прогоном на GitHub Actions после того, как пользователь закоммитит/запушит вручную (git — только руками пользователя, см. memory `git-manual-only`).

#### In Progress
- Ожидание: пользователь коммитит/пушит правки, перезапускает `build-windows` в `build.yml`, присылает новый лог.
- Если ошибка повторится — теперь в логе будет виден точный резолвленный путь/команда (`echo`), что даст реальную зацепку вместо третьей догадки.

### Session 2026-07-25 (продолжение) — Claude (round 2: CRLF/call/echo fix не помог)

**Started at**: пользователь закоммитил round-1 фикс (`af34f61 fix3`) и прислал новый CI-лог того же прогона `build-windows` на коммите `3bed5c9`.

#### Discoveries
- **Идентичная ошибка**, тот же `MSB1008` в том же `editor_plugin_csharp.vcxproj`, то же место в логе.
- **Решающая находка**: ни одна из добавленных `echo`-диагностик из `publish_csharp.cmd` не появилась в логе — ни `[publish_csharp] ...` строк, ни даже обычного `dotnet publish`-вывода (`Determining projects to restore...` и т.п., которые видны в логе для ДРУГИХ `dotnet`-шагов той же job). Значит наш скрипт **вообще не запускается** — падение происходит раньше, на уровне обработки MSBuild самого `editor_plugin_csharp.vcxproj` (custom-build-step), а не внутри команды, которую мы туда передаём.
- Это отменяет round-1 фиксы как нерелевантные (не вредные, но и не решающие): что вызов по имени, что через `cmd /c call` — команда до выполнения не доходит в обоих случаях, значит дело не в контроле передачи внутри cmd.exe и не в line endings скрипта.
- Оригинальный текст ошибки (`MSB1008: Only one project can be specified`) в обоих прогонах идентичен и всегда указывает на файл именно этого `.vcxproj`, без каких-либо промежуточных сообщений — характерно для сбоя во время построения/оценки самого custom-build-step MSBuild'ом, а не во время исполнения его `<Command>`.

#### Completed
- `apps/comics-editor-v2.9/.github/workflows/build.yml`: добавлен временный диагностический шаг (`if: failure()`) после `flutter build windows --release`, который дампит содержимое сгенерированных `build/windows/**/editor_plugin_csharp*` файлов (включая `.vcxproj`) при падении — чтобы увидеть реальный `<Command>`/структуру custom-build-step, а не гадать дальше. Помечен как temporary — удалить после нахождения причины.

#### In Progress
- Ожидание: пользователь коммитит/пушит, перезапускает `build-windows`, присылает лог — теперь с дампом реального `.vcxproj`.
- Round-1 фиксы (CRLF, `call`) оставлены в коде — не мешают, могут ещё пригодиться, когда/если скрипт всё же начнёт выполняться.

**Ended at**: диагностика (vcxproj dump) добавлена, ждём результата.
**Handoff notes**: следующий анализ — читать именно содержимое `<CustomBuildStep>`/`<Command>`/`<Message>`/`<Outputs>` в дампнутом vcxproj; сверить с тем, что ожидалось от `CMakeLists.txt` (`cmd /c call "..." "..."`). Если Command пустой/обрезанный/задвоенный — вот и root cause.

### Session 2026-07-25 (продолжение 2) — Claude (round 3: build.yml не был закоммичен; затем скрипт-диагностика упал на директории)

**Started at**: пользователь спросил «какой файл был изменён в GitHub Actions? Я запушил новый код. Почему ошибка та же?» — без нового CI-лога.

#### Discoveries
- `git status` показал `.github/workflows/build.yml` как **незакоммиченный** (`M`, не в `af34f61`/`3bed5c9`) — диагностический шаг (dump vcxproj при падении) физически не попал в пуш пользователя. Поэтому CI использовал старый workflow без диагностики, и лог выглядел «той же ошибкой» — это и была та же ошибка, на той же неизменённой workflow-конфигурации.
- Сообщено пользователю; после его следующего пуша прислан новый лог (коммит `2f57863`) — на этот раз diagnostic-шаг **запустился** (значит `build.yml` в этот раз закоммичен и запушен).
- Diagnostic-шаг сам упал: `Get-ChildItem -Filter "editor_plugin_csharp*"` без `-File` заматчил в том числе **директорию** `editor_plugin_csharp.dir` (наряду с файлами `.rule`/`.vcxproj`), `Get-Content` на директории кинул terminating error, скрипт остановился, не дойдя до дампа `.vcxproj` — единственное, что успело вывестись: `editor_plugin_csharp.rule`, и его содержимое — **пустой маркер** (`# generated from CMake`), никакой полезной информации.

#### Completed
- `apps/comics-editor-v2.9/.github/workflows/build.yml`: diagnostic-шаг исправлен — добавлен `-File` (исключает директории из `Get-ChildItem`), плюс отдельно дампится `editor_plugin.vcxproj` (соседний, «нормальный» target той же `CMakeLists.txt`) для сравнения структуры.

#### In Progress
- Ожидание: пользователь коммитит/пушит **именно этот файл** (`build.yml`) и перезапускает `build-windows` — попросить явно проверить `git status`/`git diff` перед пушем в этот раз, т.к. это уже второй раз, когда путаница именно в том, что реально ушло в пуш.

**Ended at**: diagnostic-шаг починен (добавлен `-File`), ждём результата с реальным содержимым `.vcxproj`.
**Handoff notes**: если в следующем логе появится реальный `<CustomBuildStep>` — сравнить `<Command>` с ожидаемым (`cmd /c call "...publish_csharp.cmd" "...\dotnet"`) и `editor_plugin.vcxproj` (для контраста, чтобы понять, чем структурно отличается «работающий» custom-build от «падающего»/непроверенного до этого момента custom-target-without-outputs.

#### Deviations from Plan
- Это не часть Plan (`03-plan.md`, APPROVED, scope = Docker Linux/Android) — Windows/`build.yml` явно вне scope Docker-контейнеризации. Ведётся в этом же flow по прямому решению пользователя (не форкать отдельный SDD), задокументировано как дополнение к Requirements, не как изменение Acceptance Criteria Docker Build.

#### Discoveries (meta)
- `04-implementation-log.md` этого flow оставался нетронутым шаблоном, несмотря на то что `_status.md` фиксировал Task 1.1/1.2/2.1 как выполненные — предыдущая сессия не вела лог параллельно с работой. Восстановлено ретроспективно (см. таблицу Progress Tracker выше) по данным `_status.md`; детали самой Docker-верификации (вывод `docker build`, конкретные версии в образах) в этом логе не восстанавливались — они не были записаны нигде и недоступны постфактум.

**Ended at**: Windows CI баг — фиксы применены, ждём реального CI-прогона. Docker Build (Phase 2 verification, Phase 3-4) — не продолжались в этой сессии, остаются как в трекере выше.
**Handoff notes**:
1. Windows: после коммита/пуша и повторного прогона `build-windows` — прислать новый лог. Если снова `MSB1008`, `echo`-диагностика в логе покажет точный `CSPROJ`/`OUT_DIR`/собранную команду — сверить с ожидаемым, это должно локализовать причину куда точнее.
2. Docker Build: продолжить с `tool/docker-build.sh linux` verification (Task 2.1), затем Task 2.1 android re-verify, затем Phase 3 (`docker-build.yml`), Phase 4 (документация) — см. `_status.md` Next Actions.

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Log вести параллельно с Docker-работой (Task 1.1/1.2/2.1) | Не велся до этой сессии | Предыдущая сессия обновляла только `_status.md`, не этот файл — восстановлено ретроспективно, без детализации внутренних шагов сборки образов |
| Windows/`build.yml` — вне scope этого flow (Plan) | Диагностика/фикс MSB1008 ведутся здесь же | Прямое решение пользователя: все build-процессы обсуждаются только в этом SDD, не форкать новый flow |

## Learnings

- Комментарий в коде, объясняющий «почему» какой-то фикс был применён, не заменяет верификацию — предыдущий фикс MSB1008 был закоммичен с уверенным объяснением, но никогда не проходил через реальный сценарий (Windows CI), который он должен был чинить. Тесты/сборки, доступные на машине разработчика (macOS), не покрывали платформо-специфичный путь (`flutter build windows`, MSBuild custom-build-step) — стоит явно помечать в implementation-log, что именно проверено, а что нет, а не только «тесты зелёные».

## Completion Checklist

- [ ] All tasks completed or explicitly deferred
- [ ] Tests passing
- [ ] No regressions
- [ ] Documentation updated if needed
- [ ] Status updated to COMPLETE
