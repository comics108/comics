# Requirements: comics-editor-build — выделенная сборочная инфраструктура (локально + GitHub Actions), контейнеризация через Docker

> Version: 1.2
> Status: APPROVED
> Last Updated: 2026-07-25

## Problem Statement

Сборка `apps/comics-editor-v2.9` (Flutter + C#/.NET, 6 платформ) сейчас существует как побочный продукт двух предыдущих флоу:

- `sdd-comics-editor-v2.9` — исходная миграция на Flutter, там же появились `.github/workflows/build.yml`, `.github/workflows/release.yml`, `tool/build_headless.sh|ps1`.
- `sdd-comics-editor-v2.9-android-ios` — добавление мобильных платформ, там же по ходу чинились сборочные баги (Windows CMake `MSB1008`, Android/iOS NativeAOT→Dart-I/O пивот, диагностика зависшего Linux headless-процесса — не решена до конца).

Сборочная логика раскидана по implementation-log'ам фич-флоу, changes вносились реактивно (по одному падающему CI-логу за раз), нет отдельного места, где сборка документирована и спроектирована как система. Также: локальная сборка (macOS-машина разработчика) и CI (GitHub-hosted раннеры: windows-2025, macos-latest, ubuntu-latest) используют разные окружения — версии Flutter/.NET/Android SDK фиксируются только в workflow-файлах, локально разработчик полагается на то, что стоит на его машине. Это уже приводило минимум к одному классу проблем (Linux headless-процесс падает на CI, но воспроизвести локально на macOS через Docker с эмуляцией amd64 не вышло — среда отличается).

**Цель этого flow**: выделить сборку (локальную и CI) в отдельный, спроектированный сборочный контур; там, где возможна одинаковая среда локально и на раннерах — контейнеризировать через Docker, чтобы «работает у меня» и «работает в CI» были одним и тем же окружением, а не двумя.

### Архитектурная правка (2026-07-25, в ходе Implementation)

Изначально план — заменить шаги установки тулчейна в `build.yml`-job'ах `build-linux`/`build-android` на Docker (Task 3.1/3.2 плана). По ходу реализации (после Task 1.1/1.2 — оба Dockerfile собраны и проверены) пользователь скорректировал архитектуру: **два раздельных процесса сборки**, не замена одного другим:

- **Native Build** (`build.yml`, как есть) — быстрый нативный CI на каждый push/PR, без Docker. **Не трогается вообще** (на момент правки ещё не был изменён — подтверждено `git status`).
- **Docker Build** (новый `docker-build.yml`) — воспроизводимая контейнеризованная сборка на тех же двух Docker-образах; запускается **только** для `main`, nightly (по расписанию) и релизов — не на каждый PR; результат — **публикуемые финальные артефакты** (а не просто verification-прогон).

Эта правка отменяет AC #2 в исходной редакции (замена `build.yml`) — см. пересмотренный AC #2 ниже.

### Дополнение: Windows CI баг MSB1008 отслеживается в этом flow (2026-07-25, в ходе Implementation)

Реальный прогон `build-windows` в `build.yml` (Native Build) упал с `MSB1008: Only one project can be specified` в custom-build-step `editor_plugin_csharp` (публикация `Comics.Editor.Flutter` через `dotnet publish` из `windows/editor_plugin/publish_csharp.cmd`). Это тот же баг, который `sdd-comics-editor-v2.9-android-ios` считал закрытым (см. `flows/sdd-comics-editor-v2.9-android-ios/_status.md:45`) — но тот фикс (перенос многотокенной команды из CMake `COMMAND` в отдельный `.cmd`) никогда не проверялся реальным Windows CI-прогоном (`flutter build windows`), только `dotnet build`/`flutter test` на macOS. Ошибка воспроизвелась на первом же реальном прогоне после того «фикса».

Это не относится к scope Docker Build (Windows не контейнеризируется, см. таблицу платформ ниже) — но пользователь решил (2026-07-25): «все процессы сборки, локальные и GitHub Actions, обсуждаются только в этом SDD» — т.е. **не форкать отдельный flow**, вести диагностику/фикс и его документацию здесь, в `04-implementation-log.md`, без изменения Acceptance Criteria/Plan Docker-контейнеризации.

Статус: см. `04-implementation-log.md` — применены defensive-фиксы (CRLF line endings в `publish_csharp.cmd`, явный `call` при вызове .cmd из CMake custom-build-step, диагностический `echo` резолвленных путей/команды) без подтверждённого точного root cause; ждём результата следующего реального Windows CI-прогона.

## Известные факты о платформах (входные данные для проектирования)

| Платформа | Тулчейн | Можно контейнеризировать? |
|---|---|---|
| **Linux** (desktop app + headless-ядро) | Flutter Linux desktop (GTK3/CMake/ninja/clang) + .NET 10 SDK | **Да** — чистый Linux-тулчейн, GH `ubuntu-latest` раннеры сами по себе Linux, локально — Docker |
| **Android** (APK/AAB) | Flutter + Gradle + JDK 17 + Android SDK/cmdline-tools | **Да** — та же логика, Android SDK/Gradle прекрасно работают в Linux-контейнере; NDK для NativeAOT больше не нужен (см. `sdd-comics-editor-v2.9-android-ios`: Android перешёл на `DartIoCore`) |
| **Windows** (desktop app: WPF + Flutter) | Visual Studio 2022/2026 (MSVC, CMake), .NET 10 SDK, Flutter Windows desktop | **Нет** — нативная сборка WPF/CMake+MSVC требует реальной Windows; Windows-контейнеры существуют, но работают только на Windows-хосте (не решают «одинаково локально на macOS и на раннере») |
| **macOS** (desktop app) | Xcode command line tools, Flutter macOS desktop, .NET 10 SDK | **Нет** — Docker не поддерживает macOS-гостей; и раннер, и локальная машина разработчика — нативный macOS, поэтому это уже «одинаково» без контейнера |
| **iOS** | Xcode, Flutter iOS, code signing | **Нет** — та же причина, что macOS; плюс сборка не требует .NET (см. Dart-I/O fallback) |

Т.е. контейнеризация целиком закрывает **Linux и Android** (и, по обеим, gradle/dotnet-часть релизных job); Windows/macOS/iOS остаются нативными по объективным причинам — задача явно это не «сделать всё в Docker», а «то, что можно — контейнеризировать».

## User Stories

### Primary

**As a** разработчик, работающий над `comics-editor-v2.9`
**I want** собирать Linux- и Android-таргеты локально в том же Docker-образе, что использует CI
**So that** «зелёный CI» и «собралось у меня» значат одно и то же, и не нужно гадать про версии тулчейна

### Secondary

**As a** мейнтейнер CI
**I want** единое, задокументированное место, описывающее весь сборочный контур (что собирается, чем, на каких платформах, где живут версии тулчейна)
**So that** при добавлении новой платформы/смене версии Flutter или .NET не нужно перечитывать implementation-log трёх разных флоу

**As a** разработчик, отлаживающий CI-специфичный баг (например, текущий Linux headless-краш)
**I want** прогнать ровно тот же образ/контейнер, что использует GitHub Actions, на своей машине
**So that** диагностика идёт в идентичной среде, а не в «похожей»

## Acceptance Criteria

### Must Have

1. **Given** два Dockerfile в репозитории `apps/comics-editor-v2.9` — `docker/linux-build.Dockerfile` и `docker/android-build.Dockerfile`
   **When** `docker build`/`docker run` выполняется локально и делает `flutter build linux`/`flutter build apk` + связанные шаги `dotnet build`/`publish`
   **Then** результат идентичен тому, что производит соответствующий job в `build.yml`.

2. **Given** `.github/workflows/build.yml` (Native Build) — **не изменяется**
   **When** push/PR запускает CI как раньше
   **Then** все 6 job (`analyze`, `build-windows`, `build-macos`, `build-linux`, `build-android`, `build-ios`) работают ровно как до этого flow — без Docker, без изменения триггеров/шагов.

2а. **Given** новый `.github/workflows/docker-build.yml` (Docker Build)
   **When** событие — push в `main`, nightly-расписание, или публикация релиза (**не** обычный PR/feature-branch push)
   **Then** запускаются `docker-build-linux`/`docker-build-android` на образах из `docker/*.Dockerfile`, результат — собранные артефакты (`.deb`-бандл, APK) публикуются: `actions/upload-artifact` с увеличенным сроком хранения на всех триггерах, и дополнительно — прикрепление к GitHub Release при триггере `release`.

3. **Given** разработчик без предустановленных Flutter/.NET/Android SDK, но с Docker
   **When** он выполняет задокументированную команду (`docker build` + `docker run` или обёрточный скрипт)
   **Then** он получает собранный `.deb`-бандл/APK и может прогнать тесты (`flutter test`, `dotnet build`) — без установки чего-либо на хост, кроме Docker.

4. **Given** платформы, которые не контейнеризируются (Windows/macOS/iOS)
   **When** документация сборки описывает эти платформы
   **Then** явно сказано «нативная сборка, Docker неприменим» и почему — без попытки притвориться, что это тоже контейнеризировано.

5. **Given** существующие сборочные скрипты (`tool/build_headless.sh|ps1`, `tool/build_native.sh`)
   **When** сборка переносится на Docker для Linux/Android
   **Then** эти скрипты продолжают работать (вызываются из Dockerfile/entrypoint или остаются точкой входа внутри контейнера) — логика публикации ядра не дублируется вторым источником правды.

6. **Given** весь сборочный контур
   **When** документация этого flow завершена
   **Then** она описывает оба процесса: 6 job Native Build (`build.yml`, без изменений) и 2 job Docker Build (`docker-build.yml`, новый) — с чёткой границей, когда какой запускается и зачем нужны оба (быстрая обратная связь vs воспроизводимость + публикуемые артефакты).

### Should Have

- Docker-образы закешированы/переиспользуются в CI (стандартный Docker layer cache GitHub Actions), чтобы не терять время на переустановку тулчейна на каждый запуск.
- Скрипт-обёртка с понятными командами (`tool/docker-build.sh linux`, `tool/docker-build.sh android`) — не требовать от разработчика помнить длинные `docker run` флаги; полезна и для локальной проверки, и для отладки CI-специфичных багов в идентичном окружении.
- Nightly-расписание документировано (конкретное время UTC) и легко поменять.

### Won't Have (This Iteration)

- Контейнеризация Windows/macOS/iOS сборок (см. таблицу платформ — технически нецелесообразно/невозможно).
- Изменение бизнес-логики приложения, C#-кода, Dart-кода фич — только сборочная инфраструктура.
- Перевод интерактивной разработки (`flutter run` с hot reload) в Docker — решено не делать (Q1).
- Переработка `release.yml`/fastlane — решено не трогать (Q5).
- Публикация Docker-образов в registry (ghcr.io) — образ собирается заново на каждый прогон (Q4, дефолт).
- Решение текущего бага «Linux headless-процесс падает на CI» как отдельная гарантированная цель — но контейнеризация может дать воспроизводимую среду для его диагностики как побочный эффект.

## Constraints

- **Git**: агент не выполняет git-команды (правило пользователя, `apps/comics-editor-v2.9` — отдельный git-репозиторий, управляется пользователем вручную).
- **Рабочая зона**: `apps/comics-editor-v2.9` (Dockerfile/workflows/scripts) + этот flow-каталог. Другие приложения/либы монорепо не трогаются.
- **Не переписывать бизнес-логику**: этот flow — только про сборку/CI/Docker, не про функциональность редактора.
- **Обратная совместимость**: `flutter build`/`dotnet build` и т.п. команды должны продолжать работать «как есть» вне Docker тоже (не у всех разработчиков будет Docker обязательным требованием, если не решено иное).

## Open Questions

Все вопросы решены пользователем 2026-07-25:

- [x] **Q1. Объём контейнеризации локальной разработки**: **только verification** — `flutter build`/`flutter test`/`dotnet build`/`publish`, т.е. ровно то, что делает CI. Интерактивная разработка (`flutter run`, hot reload) остаётся нативной, через локально установленный Flutter SDK — Docker её не касается.
- [x] **Q2. Базовый образ**: **собственный `Dockerfile`** с точным пином версий, зафиксированных уже в `build.yml` (Flutter 3.44.6, .NET 10.0.302, JDK 17 temurin) — без зависимости от стороннего образа.
- [x] **Q3. Единый образ или два**: **два узких образа** — `linux-build` (Flutter + GTK3/CMake/ninja/clang + .NET 10, без Android SDK) и `android-build` (Flutter + JDK 17 + Android SDK/cmdline-tools, без GTK-зависимостей). Меньше размер и время сборки каждого, чёткое разделение ответственности.
- [x] **Q5. Область — `release.yml`**: **не трогать**. Этот flow ограничен `build.yml` (verification-сборка) и `tool/`. `release-android`/`release-ios` (fastlane, подпись, публикация в сторы) остаются как есть — вне рамок этого flow.

**Q4 (публикация образа в registry) — не поднимался явно, применяю рекомендованный дефолт**: образ собирается заново на каждый CI-прогон (`docker build` внутри job, с использованием стандартного Docker layer cache GitHub Actions), без публикации в `ghcr.io`. Это самый простой вариант без отдельного pipeline обновления образа; публикация в registry — не исключается на будущее, но не в этой итерации (если решение потребуется поменять — это локализованное изменение в `build.yml`, не архитектурный вопрос).

## References

- `apps/comics-editor-v2.9/.github/workflows/build.yml`, `release.yml`
- `apps/comics-editor-v2.9/tool/build_headless.sh|ps1`, `tool/build_native.sh`
- `flows/sdd-comics-editor-v2.9/04-implementation-log.md` — история Windows CMake фикса
- `flows/sdd-comics-editor-v2.9-android-ios/04-implementation-log.md` — история Android/iOS DartIoCore-пивота и незавершённой Linux-диагностики

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «requirements approved». Q1–Q3, Q5 — рекомендованные варианты; Q4 — дефолт (без registry).
