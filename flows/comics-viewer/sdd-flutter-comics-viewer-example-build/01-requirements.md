# Requirements: flutter-comics-viewer-example-build

> Version: 1.1  
> Status: APPROVED  
> Last Updated: 2026-08-05

## Problem Statement

Для example-приложения Flutter-плагина `flutter_comics_viewer` нет единого,
явно описанного сборочного контура, одинаково понятного для локального запуска и
GitHub Actions.

Фактический проект находится в
`libs/comics_viewer/flutter_comics_viewer/example` (в исходном запросе каталог
`comics_viewer` был записан как `comics-viewer`). Example содержит generated
targets Android, iOS, Linux, macOS, Windows и Web, но текущий
`.github/workflows/build.yml` репозитория плагина собирает только Android APK и
iOS simulator app. Отдельных документированных локальных entry points для
сборки example и согласованной политики артефактов/платформ сейчас нет.

Нужен воспроизводимый build-контур, который:

- даёт разработчику короткие документированные локальные команды;
- проверяет те же поддерживаемые example-targets в GitHub Actions;
- учитывает нативные зависимости плагина, включая sibling checkout
  `comics-viewer-android` и remote SwiftPM dependency `comics-viewer-ios`;
- явно разделяет build verification, тестирование и публикацию пакета/приложения.

## Desired Outcomes

1. Разработчик может из checkout `flutter_comics_viewer` собрать выбранные
   example-targets по документированной процедуре и понять необходимые
   prerequisites.
2. GitHub Actions автоматически повторяет эти сборки на подходящих нативных
   runners и показывает независимый результат по каждой платформе.
3. Результаты CI доступны как скачиваемые build artifacts там, где это имеет
   смысл и разрешено требованиями.
4. Существующие package validation и publish workflows не теряют своих ворот и
   не смешиваются с deployment/store publishing example-приложения.

## User Stories

### Primary

**As a** разработчик `flutter_comics_viewer`  
**I want** локально собирать example теми же командами и версиями тулчейна, что
используются в CI  
**So that** изменения Dart- и native-частей плагина проверяются через реальное
host-приложение до merge/tag.

### Secondary

**As a** мейнтейнер репозитория  
**I want** видеть отдельный GitHub Actions result по каждой целевой платформе  
**So that** падение одной платформы не скрывает состояние остальных и быстро
локализуется.

**As a** пользователь CI artifacts  
**I want** скачивать собранный example artifact  
**So that** его можно вручную проверить без локальной пересборки.

## Acceptance Criteria

### Must Have

1. **Given** чистый checkout `flutter_comics_viewer` и установленные
   документированные prerequisites  
   **When** разработчик выполняет локальную build-команду для включённой в scope
   платформы  
   **Then** собирается `example` для этой платформы либо команда завершается с
   понятной диагностикой отсутствующей внешней зависимости.

2. **Given** push или pull request, соответствующий утверждённым triggers  
   **When** запускается GitHub Actions build workflow  
   **Then** example собирается на нативно подходящих runners отдельными jobs,
   без искусственной cross-compilation неподдерживаемых Apple/Windows targets.

3. **Given** Android example зависит от локального Gradle project
   `../../comics-viewer-android`  
   **When** Android собирается локально или в CI  
   **Then** sibling checkout размещён в ожидаемом каталоге и эта зависимость
   явно документирована/подготавливается workflow.

4. **Given** iOS implementation получает `comics-viewer-ios` через SwiftPM
   remote branch `main`  
   **When** iOS example собирается  
   **Then** workflow использует поддерживаемый macOS/Xcode runner и не требует
   code signing для verification build.

5. **Given** build job успешно создал утверждённый distributable output  
   **When** job завершается  
   **Then** artifact загружается с устойчивым именем, платформой/архитектурой в
   названии и утверждённым retention period.

6. **Given** в репозитории уже существуют package analyze/test/dry-run publish
   gates и отдельный OIDC publish workflow  
   **When** добавляется example build-контур  
   **Then** package publishing остаётся независимым, а существующие проверки не
   удаляются и не ослабляются без отдельного одобрения.

7. **Given** локальная и CI документация  
   **When** новый разработчик читает её  
   **Then** указаны поддерживаемые команды, рабочая директория, prerequisites,
   внешние checkout/network dependencies, расположение outputs и известные
   platform limitations.

### Should Have

- Закрепить версию Flutter вместо плавающего `channel: stable`, если это
  соответствует политике репозитория.
- Использовать кэш Flutter/pub/Gradle там, где он не делает сборку менее
  детерминированной.
- Не связывать независимые platform jobs через `needs`, если между ними нет
  реальной зависимости.
- Добавить `workflow_dispatch` для ручной проверки build-контура.
- Проверять formatting/analyze/unit tests до или параллельно platform builds,
  не дублируя дорогие операции без необходимости.

### Won't Have (This Iteration)

- Публикация example в App Store, Google Play, Microsoft Store или web hosting.
- Production code signing, notarization, provisioning profiles и управление
  store credentials.
- Изменение поведения viewer-плагина или UI example, кроме минимальных правок,
  необходимых именно для корректной сборки/тестового gate и отдельно
  утверждённых в specifications.
- Публикация `flutter_comics_viewer` на pub.dev — это остаётся ответственностью
  существующего `publish.yml`.
- Контейнеризация macOS/iOS/Windows сборок.

## Constraints

- **Repository boundary**: target является отдельным git-репозиторием в
  `libs/comics_viewer/flutter_comics_viewer`; изменения flow живут в monorepo
  `flows/`, а build-файлы — внутри этого repository boundary.
- **Working tree**: существующий untracked
  `example/android/build/` принадлежит пользователю и не должен быть удалён или
  принят за исходный файл.
- **Flutter/Dart**: package и example требуют Dart `^3.12.2`; `.metadata`
  указывает Flutter revision `ee80f08b...` stable.
- **Android**: JDK 17 и sibling checkout `comics-viewer-android` обязательны при
  текущем Gradle wiring; Maven coordinate пока не используется.
- **Apple**: iOS/macOS требуют macOS runner/Xcode; iOS verification должна быть
  без production signing.
- **Windows**: Windows desktop build требует Windows runner и Visual Studio
  workload, предоставляемый runner image.
- **Network**: iOS SwiftPM build зависит от доступности GitHub repository
  `comics108/comics-viewer-ios` branch `main`.
- **Git**: никакие commit/push/tag/release действия не входят в реализацию без
  отдельного прямого запроса пользователя.

## Approved Decisions

- [x] **Q1 — Platform scope:** локальная документация и Actions покрывают все
  шесть generated targets: Android, iOS, Linux, macOS, Windows и Web.
- [x] **Q2 — CI artifacts:** каждый platform job загружает свой результат:
  Android APK, iOS simulator `.app` archive, Linux bundle, macOS `.app` archive,
  Windows Release bundle и Web bundle.
- [x] **Q3 — Build modes:** release используется для Android, Linux, macOS,
  Windows и Web; iOS остаётся unsigned simulator verification build, для
  которого допустим debug mode.
- [x] **Q4 — Triggers:** `push` в `main`, `pull_request` в `main`, version tags
  `v*.*.*` и `workflow_dispatch`; nightly schedule не добавляется.
- [x] **Q5 — Toolchain pinning:** Flutter закрепляется на `3.44.6` в новом
  workflow и локальной документации.
- [x] **Q6 — Tests:** formatting, analyze и обычные unit/widget tests входят в
  gate. Устаревший integration test сначала должен быть исправлен и в этой
  итерации обязательным gate не является.
- [x] **Q7 — Local entry point:** добавляются Unix shell и PowerShell wrappers,
  а README описывает wrappers, прямые команды, prerequisites и outputs.
- [x] **Q8 — Existing workflow:** создаётся отдельный `example-build.yml`;
  существующие `build.yml` и `publish.yml` сохраняют ответственность и gates.

## References

- `libs/comics_viewer/flutter_comics_viewer/.github/workflows/build.yml`
- `libs/comics_viewer/flutter_comics_viewer/example/pubspec.yaml`
- `libs/comics_viewer/flutter_comics_viewer/android/settings.gradle.kts`
- `libs/comics_viewer/flutter_comics_viewer/ios/flutter_comics_viewer/Package.swift`
- `libs/comics_viewer/flutter_comics_viewer/example/integration_test/plugin_integration_test.dart`

---

## Approval

- [x] Reviewed by: user
- [x] Approved on: 2026-08-05
- [x] Notes: User explicitly replied `reqs approved`; recommended defaults
  Q1–Q8 were accepted without changes.
