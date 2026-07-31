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
| — Windows CI MSB1008 (внесценарийный баг, см. ниже) | In Progress (round 5, unverified) | Не входит в AC Docker Build; отслеживается здесь по решению пользователя |
| — macOS CI: `dataset_backward_compat_test.dart` crashing `flutter test` | Done | Не относится к Docker Build; регрессия из другого flow (`vdd-comics-editor-uiux-lettering`), исправлена здесь по той же логике («все build-процессы обсуждаются только в этом SDD») |

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

### Session 2026-07-25 (продолжение 3) — Claude (round 4: реальный vcxproj получен → решение отключить custom target)

**Started at**: пользователь прислал новый CI-лог с полным дампом `editor_plugin_csharp.vcxproj` (diagnostic-шаг сработал).

#### Discoveries
- **Сгенерированный `<Command>` полностью корректен** — стандартный CMake-boilerplate (`setlocal` / `cmd /c call D:/.../publish_csharp.cmd D:/.../dotnet` / errorlevel-forwarding), сверен построчно с соседним рабочим `<CustomBuild>` в том же файле (regenerate-check правило вызова `cmake.exe --check-stamp-file`) — идентичная форма, никаких синтаксических отличий, кавычки/пути в порядке. Т.е. проблема не в том, ЧТО мы передаём в CMake COMMAND — предыдущие 3 раунда фиксов (CRLF, `call`, echo-диагностика) были не по адресу, потому что сама команда никогда не была источником ошибки.
- Раннер — `windows-2025-vs2026`: `ToolsVersion="18.0"`, `PlatformToolset=v145`, `VCToolsVersion=14.51.36231` — это новейший/preview-тулсет Visual Studio (VS "18"/2026). Похоже на нестабильность/баг именно в обработке `<CustomBuild>`-элементов custom-build-степов в этом конкретном (очень новом) MSBuild/CMake-generator сочетании — причина так и не подтверждена даже с полным XML на руках.
- **Ключевая находка, снявшая вопрос «чинить или нет»**: проверено, что публикуемая `Comics.Editor.Flutter.dll` **вообще ничем не потребляется** на сегодня:
  - `windows/editor_plugin/editor_plugin.cpp:11-16` — явный `// TODO(Windows): interop к .NET — вариант A (рекомендуемый): hostfxr / nethost...`, `HandleMethodCall` безусловно возвращает `result->Error("not_implemented", ...)`.
  - `lib/src/bridge/wpf_editor_view.dart:8-9` — «Пока слой не собран на Windows-машине... виджет показывает заглушку».
  - Т.е. custom target собирал артефакт, который прямо сейчас не грузится никаким кодом — блокировал 100% Windows CI ради ещё не реализованной фичи.
- Пользователь подтвердил (`AskUserQuestion`): отключить custom target из `ALL`, не продолжать чинить баг MSBuild дальше.

#### Completed
- `apps/comics-editor-v2.9/windows/editor_plugin/CMakeLists.txt`: `add_custom_target(editor_plugin_csharp ALL ...)` + `add_dependencies(...)` закомментированы (не удалены — вернуть, когда появится реальный hostfxr/nethost-вызов в `editor_plugin.cpp`, который реально грузит `Comics.Editor.Flutter.dll`). Комментарий обновлён с полной историей (4 раунда, находка про stub, ссылка на конкретные файлы/строки TODO).
- `apps/comics-editor-v2.9/.github/workflows/build.yml`: temporary diagnostic-шаг (`Dump generated custom-build vcxproj`) удалён — свою задачу выполнил.
- `publish_csharp.cmd` — оставлен в репозитории как есть (не используется сейчас, пригодится при реализации interop).

#### In Progress
- Ожидание: пользователь коммитит/пушит (`CMakeLists.txt`, `build.yml`), перезапускает `build-windows` — должен пройти, т.к. custom target с проблемным custom-build-step больше не входит в `ALL`.

**Ended at**: MSB1008 investigation закрыт — не багфикс, а отключение неиспользуемого custom target.
**Handoff notes**: когда кто-то будет реализовывать hostfxr/nethost interop в `editor_plugin.cpp` (см. TODO там) — раскомментировать `add_custom_target`/`add_dependencies` в `windows/editor_plugin/CMakeLists.txt` и на этот раз **сразу проверить реальным Windows CI-прогоном** (не полагаться на macOS-локальную верификацию) — история этого бага началась именно с того, что предыдущий фикс (`sdd-comics-editor-v2.9-android-ios`) никогда не был проверен на реальной Windows-машине. Если MSB1008 повторится тогда — этот implementation-log (raunds 1-4) содержит полную историю попыток и подтверждённый факт, что сам `<Command>` синтаксически корректен, так что имеет смысл сразу смотреть в сторону версии MSBuild/VS toolset на раннере, а не в сторону содержимого команды.

#### Deviations from Plan
- Это не часть Plan (`03-plan.md`, APPROVED, scope = Docker Linux/Android) — Windows/`build.yml` явно вне scope Docker-контейнеризации. Ведётся в этом же flow по прямому решению пользователя (не форкать отдельный SDD), задокументировано как дополнение к Requirements, не как изменение Acceptance Criteria Docker Build.

#### Discoveries (meta)
- `04-implementation-log.md` этого flow оставался нетронутым шаблоном, несмотря на то что `_status.md` фиксировал Task 1.1/1.2/2.1 как выполненные — предыдущая сессия не вела лог параллельно с работой. Восстановлено ретроспективно (см. таблицу Progress Tracker выше) по данным `_status.md`; детали самой Docker-верификации (вывод `docker build`, конкретные версии в образах) в этом логе не восстанавливались — они не были записаны нигде и недоступны постфактум.

**Ended at**: Windows CI баг — фиксы применены, ждём реального CI-прогона. Docker Build (Phase 2 verification, Phase 3-4) — не продолжались в этой сессии, остаются как в трекере выше.
**Handoff notes**:
1. Windows: после коммита/пуша и повторного прогона `build-windows` — прислать новый лог. Если снова `MSB1008`, `echo`-диагностика в логе покажет точный `CSPROJ`/`OUT_DIR`/собранную команду — сверить с ожидаемым, это должно локализовать причину куда точнее.
2. Docker Build: продолжить с `tool/docker-build.sh linux` verification (Task 2.1), затем Task 2.1 android re-verify, затем Phase 3 (`docker-build.yml`), Phase 4 (документация) — см. `_status.md` Next Actions.

### Session 2026-07-25 (продолжение 2) — Claude (Docker Build: полная верификация + Phase 3-4)

**Started at**: Phase 2 verification (Task 2.1 linux), диск хоста только что почищен пользователем.
**Context**: Продолжение с того места, где предыдущая сессия остановилась на Docker Desktop I/O-ошибке/ENOSPC.

#### Completed
- Диагностика и устранение (см. также `_status.md`, «Отладка: полный прогон tool/docker-build.sh linux»): Docker Desktop I/O-ошибка/ENOSPC → зависший демон (полный restart) → отсутствующий `HOME` для `--user` (`--env HOME=/tmp`) → `UseVirtualizationFrameworkRosetta: false` (пользователь включил вручную) → транзиентный Dart VM `EINTR` (retry).
- **Найден и исправлен реальный баг в прикладном коде**, заблокировавший верификацию: `CoreClient.resolveBinary()` выбирал бинарник ядра без учёта `Platform.operatingSystem`, из-за чего Linux-контейнер пытался запустить macOS-бинарник. Не относится к scope этого flow (business logic) — вынесено и исправлено в отдельном flow `sdd-comics-editor-v2.9-fixes1` по решению пользователя, здесь только зафиксирован факт и ссылка.
- `tool/docker-build.sh linux` — **полный зелёный прогон** на реальном репозитории (все 6 тестов, включая `core_client_test.dart`).
- Тот же класс проблемы (`--user` без passwd-записи) для Android/Java: `user.home` резолвился JVM в буквальное `"?"` → Gradle писал кэш в несуществующий путь. Фикс: `GRADLE_USER_HOME`/`JAVA_TOOL_OPTIONS=-Duser.home=/tmp`.
- Второй Docker Desktop hang (тот же класс — диск снова забился, на этот раз раздутыми локальными образами `comics-editor-{linux,android}-build:local`, выросшими до 11-12GB каждый из-за накопленного за сессию build cache) — restart + `docker rmi` + `docker builder prune -af` освободили ~40GB.
- `tool/docker-build.sh android` — **полный зелёный прогон** (APK собран, тесты зелёные), но `assembleRelease` занял ~700s из-за холодного скачивания NDK/CMake/Build-Tools 35/Platform 35 (запрашивает сам Flutter Gradle-плагин, `flutter.ndkVersion`/`flutter.compileSdkVersion` — независимо от того, что наш код NDK не использует).
  - **Оптимизация**: (a) персистентный bind-mounted Gradle-кэш (`.docker-cache/gradle/`, gitignored) вместо `GRADLE_USER_HOME=/tmp` (стирался на каждом `--rm`-запуске); (b) `docker/android-build.Dockerfile` теперь ставит NDK 28.2.13676358/CMake 3.22.1/platform-35/build-tools 35.0.0 на этапе сборки образа, не полагаясь на Gradle auto-download в рантайме. После пересборки образа — `assembleRelease` 700s → 92s, повторный прогон снова полностью зелёный.
- Task 3.1/3.2: создан `.github/workflows/docker-build.yml` — два независимых job (`docker-build-linux`, `docker-build-android`), триггеры `push:main`/`schedule` (cron `0 3 * * *`)/`release:published`, `docker/build-push-action@v6` с `cache-from/to: type=gha`, `upload-artifact` (`retention-days: 90`), условное прикрепление к GitHub Release при `github.event_name == 'release'`. `build.yml` не тронут. YAML-синтаксис проверен (`python3 -c "import yaml..."`).
- Task 4.1: создан `docker/README.md` — таблица Native vs Docker Build, таблица платформ, быстрый старт, известные ограничения машины (Rosetta/qemu, EINTR), описание файлов и Gradle-кэша.
- Verified by: реальные прогоны `tool/docker-build.sh linux`/`android` на этой машине (`--platform linux/amd64` через Rosetta) — оба полностью зелёные; `docker-build.yml` — синтаксическая валидация + построчная сверка команд с `tool/docker-build.sh` (финальная приёмка — реальный CI-прогон, как и предполагалось в Plan).

#### Deviations from Plan
- Task 1.2/2.1 verification обнаружили баг в прикладном коде (`resolveBinary()`), не предусмотренный Plan — исправлен в отдельном flow (`sdd-comics-editor-v2.9-fixes1`), не здесь, чтобы не смешивать build-инфраструктуру с business logic.
- Добавлена оптимизация Android-образа (pre-baked NDK/CMake/platform-35), не описанная явно в исходном Plan/Specifications — естественное продолжение Task 1.2/2.1 (тот же файл, тот же smoke-test), не отдельная фича.

#### Discoveries
- Локальная x64-верификация (через Rosetta, не qemu) на Apple Silicon реально работает и ловит реальные баги (resolveBinary, MSB4184/qemu-несовместимость), которые не были видны раньше — подтверждает изначальную гипотезу requirements о ценности одинаковой среды локально/CI.
- Docker Desktop на этой машине дважды зависал по одной и той же причине (диск хоста забивается образами/build cache быстрее, чем ожидалось, из-за итеративной отладки) — оба раза чинилось полным restart (`quit`+`kill -9`+relaunch) + освобождением места. Не баг в этом репозитории, но стоит иметь в виду при следующей похожей отладке.

**Ended at**: Phase 1-4 Docker Build — все задачи Plan выполнены и верифицированы локально.
**Handoff notes**: финальная приёмка `docker-build.yml` — реальный CI-прогон (push в main или ручной `workflow_dispatch`, если понадобится добавить триггер для ручного теста) — не заблокирован, но не выполнен агентом (нет доступа к git/CI). Windows CI MSB1008 — отдельная, не относящаяся к Docker Build нить, остаётся открытой (см. предыдущие session log записи выше).

---

## Deviations Summary

| Planned | Actual | Reason |
|---------|--------|--------|
| Log вести параллельно с Docker-работой (Task 1.1/1.2/2.1) | Не велся до этой сессии | Предыдущая сессия обновляла только `_status.md`, не этот файл — восстановлено ретроспективно, без детализации внутренних шагов сборки образов |
| Windows/`build.yml` — вне scope этого flow (Plan) | Диагностика/фикс MSB1008 ведутся здесь же | Прямое решение пользователя: все build-процессы обсуждаются только в этом SDD, не форкать новый flow |
| `resolveBinary()` баг найден при Docker Build verification | Исправлен в отдельном flow `sdd-comics-editor-v2.9-fixes1`, не здесь | Business logic вне scope Plan этого flow — только диагностика/факт зафиксированы здесь |
| Android SDK — только `platforms;android-36`/`build-tools;36.0.0` (Plan) | Добавлены также `platforms;android-35`/`build-tools;35.0.0`/`ndk;28.2.13676358`/`cmake;3.22.1` | Обнаружено в ходе verification: сам Flutter Gradle-плагин запрашивает свои дефолты независимо от нашего пина — без pre-bake Gradle качал бы их заново на каждом запуске (~700s) |

## Learnings

- Комментарий в коде, объясняющий «почему» какой-то фикс был применён, не заменяет верификацию — предыдущий фикс MSB1008 был закоммичен с уверенным объяснением, но никогда не проходил через реальный сценарий (Windows CI), который он должен был чинить. Тесты/сборки, доступные на машине разработчика (macOS), не покрывали платформо-специфичный путь (`flutter build windows`, MSBuild custom-build-step) — стоит явно помечать в implementation-log, что именно проверено, а что нет, а не только «тесты зелёные».
- `--user UID:GID` без соответствующей `/etc/passwd`-записи ломает любой инструмент, читающий домашнюю директорию через системный вызов (`getpwuid`), а не через `$HOME` напрямую — задело и Flutter (`HOME` резолвился в `/`), и JVM/Gradle (`user.home` резолвился в буквальное `"?"`). Не intuitivно из одного лишь симптома — стоит проверять оба класса причин сразу при следующем похожем баге.
- Диск — реальный, наблюдаемый риск локальной Docker-верификации на этой машине: итеративная отладка (пересборки образов, build cache) быстро съедает десятки GB и дважды приводила к зависанию демона. `docker system df`/`df -h` стоит проверять проактивно при длинных отладочных сессиях, не только когда что-то уже упало.

## Completion Checklist

- [x] Docker Build (Task 1.1–4.2, Plan scope) — все задачи выполнены, верифицированы локально
- [x] Tests passing (`tool/docker-build.sh linux`/`android`, оба полностью зелёные)
- [x] No regressions (нативные тесты на macOS тоже перепроверены после `resolveBinary()` фикса)
- [x] Documentation updated (`docker/README.md`, `_status.md`, этот лог)
- [x] Status updated to COMPLETE (Docker Build часть; Windows CI MSB1008 — отдельная незакрытая нить, не блокирует этот flow)

### Session 2026-07-30 — Claude (round 5: MSB1008 recurred after reactivation; new macOS regression)

**Started at**: пользователь вставил два новых CI-лога (macOS и Windows), оба failing, из другой сессии/контекста (лог был приложен к незнакомой команде вместе с описанием). Resume этого flow по имени.

#### Discoveries — macOS failure (новый баг, не MSB1008)
- Отдельная, не связанная с Windows причина: `flutter test` (bare, без списка файлов) в job `build-macos` крашится на `loading .../test/dataset_backward_compat_test.dart (failed)` — `Directory listing failed, path = '/Users/runner/work/dataset/'`.
- Файл добавлен в другом flow (`vdd-comics-editor-uiux-lettering`, Task 7.1) в той же сессии, где пользователь переключился сюда — использовал `Directory(Directory.current.path).parent.parent` для поиска `dataset/`, что резолвится корректно только в полном monorepo-чекауте.
- Подтверждено (`git remote -v`, `git rev-parse --show-toplevel` внутри `apps/comics-editor-v2.9`): это отдельный git-репозиторий (`comics108/comics-editor-v2.9`), чей tree никогда не включал monorepo-level `dataset/` — путь `../../dataset` "работал" только по случайному совпадению структуры каталогов на машине разработчика.
- Другие jobs (Linux/Windows/Android/iOS) используют явный список тестовых файлов (`flutter test test/widget_test.dart test/dart_io_core_test.dart [...]`) — этот новый файл никогда не попадал в их прогон, поэтому только macOS (единственный job с bare `flutter test`, специально ради `ffi_core_test.dart`) вообще его коснулся.
- Пользователь также спросил про источник `dataset/`-файлов в другом репозитории (`comics108/comics-admin-v2012/asp.net/Files`) и предложил вынести такие тесты в общий CI-job. Ответ: вынос не даёт эффекта для ЭТОГО конкретного файла (он всё равно skip'нется в любом job'е standalone-репозитория, т.к. `dataset/` там принципиально недоступен) — граница в том, что тесты типа `core_client_test`/`ffi_core_test` нуждаются в только что собранном платформенном бинарнике и НЕ МОГУТ централизоваться, а pure-Dart тесты (`widget_test`/`dart_io_core_test`/этот) уже частично централизованы в `analyze`. Живой fetch из `comics-admin-v2012` в CI сознательно не подключался — сетевая зависимость/нестабильность ради инструмента, чьё назначение — локальная/ручная регрессионная проверка, не гейт каждого прогона.

#### Completed — macOS fix
- `apps/comics-editor-v2.9/test/dataset_backward_compat_test.dart`: добавлена проверка `datasetDir.existsSync()`; при отсутствии — `datasetFiles = []`, sanity-тест помечен `skip: '...'` с явной причиной вместо падения на `listSync()`. Верифицировано **в обе стороны** локально: с `dataset/` на месте — 28/28 зелёных (без регрессий); с `dataset/` временно переименованной (симуляция standalone-репозитория) — `~1: All tests skipped`, никакого краша.
- `apps/comics-editor-v2.9/.github/workflows/build.yml`: `dataset_backward_compat_test.dart` явно добавлен в список `analyze` job'а (pure Dart, без платформенных артефактов) — для видимости в CI-выводе, наравне с `widget_test.dart`/`dart_io_core_test.dart` (там тоже будет skip, это ожидаемо).
- Verified by: `flutter test` (полный набор, локально, dataset/ доступен) — 156/156 зелёных.

#### Discoveries — Windows MSB1008 (round 5)
- Идентичная ошибка (`MSB1008: Only one project can be specified` в `editor_plugin_csharp.vcxproj`), но НОВЫЙ контекст: custom target был реактивирован в `sdd-comics-editor-v2.9-fixes2` (Track A) — `editor_plugin.cpp` теперь реально грузит `Comics.Editor.Flutter.dll` через hostfxr (`hostfxr_bootstrap.cpp`), т.е. round 4's решение («просто отключить target, он не используется») больше не применимо.
- Проверил реальный vendored Flutter SDK (`flutter-action@v2` его же скачивал в этой сессии для тестов) на предмет способа переключить CMake generator на Ninja (approved пользователем как первая гипотеза через AskUserQuestion): `flutter_tools/lib/src/windows/visual_studio.dart`'s `cmakeGenerator` getter жёстко возвращает `'Visual Studio 18 2026'`/`'Visual Studio 17 2022'`/`'Visual Studio 16 2019'` по определённой версии VS, без каких-либо env var или CLI-переопределений (`grep` по `build_windows.dart`/`visual_studio.dart` на `CMAKE_GENERATOR`/`Platform.environment` — ничего). Т.е. Ninja **недостижим** через `flutter build windows` без замены всей оркестрации сборки Windows на ручную (out of scope для CI-багфикса) — сообщено пользователю, который согласился на альтернативу.
- **Реальная находка**: тот же vendored SDK содержит `flutter_tools/lib/src/migrations/cmake_custom_command_migration.dart` — миграция, которая добавляет `VERBATIM` ко ВСЕМ `add_custom_command()` в СОБСТВЕННОМ сгенерированном CMake-файле Flutter, с явной ссылкой на flutter/flutter#67270 (Visual Studio generator неправильно экранирует custom-команды без `VERBATIM`). Это Flutter'овский, задокументированный, прецедентный фикс именно ЭТОГО класса бага — не догадка.
- Эта миграция трогает только flutter-managed файлы (`windows/flutter/CMakeLists.txt`), никогда не наш `windows/editor_plugin/CMakeLists.txt` — наш `add_custom_target(${PLUGIN_NAME}_csharp ALL ...)` никогда не имел `VERBATIM`.
- Важно: раунды 1-4 (сохранены в записи выше) сравнивали УЖЕ СГЕНЕРИРОВАННЫЙ `<Command>` в итоговом `.vcxproj` и не нашли синтаксических отличий от рабочего custom-build-step — но отсутствие `VERBATIM` влияет на то, КАК generator экранирует команду ПРИ ГЕНЕРАЦИИ, что могло не проявиться в поверхностном построчном сравнении финального XML (раунды не сверяли байт-в-байт, полагались на визуальное сравнение). Это не противоречит находке раунда 4, а объясняет, почему та проверка могла её пропустить.

#### Completed — Windows fix (round 5, unverified)
- `apps/comics-editor-v2.9/windows/editor_plugin/CMakeLists.txt`: добавлен `VERBATIM` в `add_custom_target(${PLUGIN_NAME}_csharp ALL ...)`. Комментарий над блоком расширен: полная история round 5 (находка про VERBATIM, ссылка на flutter/flutter#67270 и `cmake_custom_command_migration.dart`, явное объяснение почему Ninja недостижим, явная пометка "не проверено реальным CI").
- Verified by: **не проверено** — агент работает на macOS, `flutter build windows`/MSBuild недоступны локально. Требуется реальный Windows CI-прогон после коммита/пуша пользователем (git — только руками, см. memory `git-manual-only`).

#### In Progress
- Ожидание: пользователь коммитит/пушит (`CMakeLists.txt` в `windows/editor_plugin/`, `test/dataset_backward_compat_test.dart`, `.github/workflows/build.yml`), перезапускает оба job'а (`build-windows`, `build-macos`), присылает новые логи.
- macOS: ожидается зелёный прогон (fix верифицирован в обе стороны локально, включая симуляцию отсутствия `dataset/`).
- Windows: если `VERBATIM` не помогает — round 5's вывод («generator-level экранирование, не содержимое команды») остаётся в силе; следующий шаг — сверить `.vcxproj` **до и после** этого фикса байт-в-байт (не только визуально), а не гадать дальше вслепую.

**Ended at**: macOS fix применён и верифицирован локально (обе ветки). Windows round 5 fix применён, ждёт реального CI.
**Handoff notes**: если Windows fix не сработает — не начинать round 6 с нуля; конкретно сравнить `<Command>`/весь `.vcxproj` до/после `VERBATIM` (diff, не глазами) на следующем реальном прогоне с диагностическим dump-шагом (паттерн уже есть в round 2-3 выше, `Get-ChildItem -File` версия).

#### Deviations from Plan
- Обе правки (macOS test, Windows CMakeLists.txt) — вне scope `03-plan.md` (Docker Build), ведутся здесь по тому же прецеденту, что и round 1-4 Windows-фиксов: «все build-процессы обсуждаются только в этом SDD, не форкать новый flow» (см. Context Notes в `_status.md`).
