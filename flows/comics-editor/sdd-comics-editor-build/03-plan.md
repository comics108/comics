# Implementation Plan: comics-editor-build — Docker-контейнеризация Linux/Android сборки

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-25
> Specifications: [02-specifications.md](02-specifications.md) (APPROVED)

## Summary

Порядок: сначала оба Dockerfile (можно проверить локально независимо от CI), затем обёртка `tool/docker-build.sh`, затем новый `docker-build.yml` (Native Build/`build.yml` не трогаем — правка от 2026-07-25, два раздельных процесса), затем документация. Проверка на этой машине изначально планировалась только arm64 (Apple Silicon), но выяснилось, что `--platform linux/amd64` тоже работает локально через Docker Desktop VM (не через ломающийся qemu-binfmt) — реальная x64-верификация доступна и локально; финальная приёмка `docker-build.yml` (GHA cache, триггеры) всё равно только реальным CI-прогоном. Git не трогаем; `build.yml`/`release.yml` не трогаем.

## Task Breakdown

### Phase 1: Docker-образы

#### Task 1.1: `docker/linux-build.Dockerfile`
- **Description**: Ubuntu 24.04 + `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev curl git unzip xz-utils ca-certificates`; `.NET SDK 10.0.302` через `dotnet-install.sh --version 10.0.302 --install-dir /usr/share/dotnet`; Flutter 3.44.6 через `flutter_linux_3.44.6-stable.tar.xz` в `/opt/flutter`; `PATH` включает `/opt/flutter/bin` и `/usr/share/dotnet`; `flutter precache --linux` на этапе сборки образа (слой); `flutter config --no-analytics`; `WORKDIR /workspace`; без `ENTRYPOINT`/`CMD`.
- **Files**: `docker/linux-build.Dockerfile` — Create
- **Dependencies**: None
- **Verification**: `docker build -f docker/linux-build.Dockerfile -t comics-editor-linux-build:local docker` — успешно, без сети на этапе `docker run` (кроме `flutter pub get`)
- **Complexity**: Medium

#### Task 1.2: `docker/android-build.Dockerfile`
- **Description**: Ubuntu 24.04 + Adoptium APT-репозиторий → `temurin-17-jdk`; Android cmdline-tools `commandlinetools-linux-9862592_latest.zip` в `/opt/android-sdk/cmdline-tools/latest`; `sdkmanager --licenses` (auto-accept через `yes`) + `sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`; `ANDROID_HOME=/opt/android-sdk`, `ANDROID_SDK_ROOT` — то же; Flutter 3.44.6 (тот же архив, что в 1.1); `flutter precache --android`; `WORKDIR /workspace`. NDK не ставим.
- **Files**: `docker/android-build.Dockerfile` — Create
- **Dependencies**: None (параллельно 1.1)
- **Verification**: `docker build -f docker/android-build.Dockerfile -t comics-editor-android-build:local docker` — успешно
- **Complexity**: Medium

### Phase 2: Локальный запуск

#### Task 2.1: `tool/docker-build.sh`
- **Description**: `tool/docker-build.sh <linux|android> [command...]`. Проверка `command -v docker` с понятным сообщением при отсутствии. `docker build` (образ, тег `comics-editor-<target>-build:local`). `docker run --rm -v "$(pwd):/workspace" -w /workspace $( [ -z "${CI:-}" ] && echo "--user $(id -u):$(id -g)" ) <image> <command или дефолтная verification-последовательность>`. Дефолтные последовательности — константы в скрипте, дословно совпадающие с шагами `build.yml` (см. Task 3.1/3.2 ниже — важно синхронизировать один раз и не дублировать логику по смыслу по-разному).
- **Files**: `tool/docker-build.sh` — Create
- **Dependencies**: 1.1, 1.2
- **Verification**: `tool/docker-build.sh linux` и `tool/docker-build.sh android` локально (arm64-образы на этой машине) проходят полностью; `tool/docker-build.sh linux bash` даёт интерактивный шелл
- **Complexity**: Low

### Phase 3: Новый workflow `docker-build.yml` (Native Build/`build.yml` не трогаем — правка от 2026-07-25)

#### Task 3.1: `docker-build.yml` — job `docker-build-linux`
- **Description**: Новый файл. Триггеры: `push: branches: [main]`, `schedule: cron "0 3 * * *"`, `release: types: [published]`. Job: `docker/build-push-action@v6` (`context: docker`, `file: docker/linux-build.Dockerfile`, `tags: comics-editor-linux-build:ci`, `load: true`, `cache-from/to: type=gha,scope=linux-build`) → один `run: docker run --rm -v ${{ github.workspace }}:/workspace -w /workspace comics-editor-linux-build:ci bash -c '...'` с той же командной цепочкой, что verification в `build.yml` (`flutter pub get && dotnet build native/Comics.Editor.Headless/... -c Release && flutter build linux --release && tool/build_headless.sh && flutter test ...`). `actions/upload-artifact` (`name: linux-release-build`, `retention-days: 90`). Финальный шаг — только при `github.event_name == 'release'`: `softprops/action-gh-release@v2` (`files: build/linux/x64/release/bundle/**`).
- **Files**: `.github/workflows/docker-build.yml` — Create
- **Dependencies**: 1.1
- **Verification**: синтаксическая валидация YAML + ручная сверка команды с Task 1.1/2.1; финальная проверка — реальный CI-прогон (push в main/nightly/release), т.к. `docker/build-push-action`/GHA cache — CI-специфичные
- **Complexity**: Medium

#### Task 3.2: `docker-build.yml` — job `docker-build-android`
- **Description**: Тот же файл, второй независимый job (без `needs` — параллельно с 3.1). `docker/build-push-action@v6` для `android-build.Dockerfile` (`cache scope: android-build`); `run: docker run ... bash -c 'flutter pub get && flutter build apk --release && flutter test test/widget_test.dart test/dart_io_core_test.dart'`. `upload-artifact` (`name: android-release-apk`, `retention-days: 90`). При `release`: то же прикрепление к GitHub Release (`files: build/app/outputs/flutter-apk/*.apk`).
- **Files**: `.github/workflows/docker-build.yml` — Modify (тот же файл, что 3.1)
- **Dependencies**: 1.2
- **Verification**: то же, что 3.1
- **Complexity**: Low

### Phase 4: Документация

#### Task 4.1: `docker/README.md`
- **Description**: Как собрать/запустить оба образа локально (`tool/docker-build.sh`), что контейнеризовано и что нет (таблица платформ из requirements), как получить интерактивный шелл для отладки CI-специфичных багов, известное ограничение этой машины (arm64 vs amd64-эмуляция).
- **Files**: `docker/README.md` — Create
- **Dependencies**: 1.1–3.2
- **Verification**: шаги воспроизводимы по описанию
- **Complexity**: Low

#### Task 4.2: Обновить `flows/sdd-comics-editor-build/_status.md` и implementation-log
- **Description**: Финальная фиксация: что сделано, что проверено локально (arm64), что ждёт реального CI-прогона (x64), список известных ограничений.
- **Files**: `flows/sdd-comics-editor-build/_status.md`, `04-implementation-log.md` — Modify
- **Dependencies**: всё выше
- **Verification**: —
- **Complexity**: Low

## Dependency Graph

```
1.1 ─┬─→ 2.1 ─→ 3.1 ─┐
1.2 ─┘         3.2 ──┴─→ 4.1 ─→ 4.2
```

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `docker/linux-build.Dockerfile` | Create | Тулчейн-образ Linux desktop + .NET |
| `docker/android-build.Dockerfile` | Create | Тулчейн-образ Android (Flutter + JDK + SDK) |
| `docker/README.md` | Create | Документация контейнеризованной сборки |
| `tool/docker-build.sh` | Create | Локальная обёртка `docker build` + `docker run` |
| `.github/workflows/docker-build.yml` | Create | `docker-build-linux`/`docker-build-android`, триггеры main/nightly/release, публикация артефактов |

Не меняются: `tool/build_headless.sh|ps1`, `tool/build_native.sh`, `.github/workflows/release.yml`, весь код приложения.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Расхождение команд между `tool/docker-build.sh` (дефолт), `build.yml` (verification) и `docker-build.yml` (Docker Build) | Med | Med | Все три последовательности пишутся дословно идентично в Task 2.1/3.1/3.2 одновременно, сверяются построчно |
| Docker layer cache (GHA `type=gha`) ведёт себя иначе, чем ожидается (напр. не переиспользуется между PR) | Low | Low | Не критично для корректности — только скорость; при проблеме CI всё равно проходит, просто медленнее (полная пересборка образа) |
| Полная локальная проверка невозможна (arm64-машина, CI — amd64) | High (известно заранее) | Low | Это ограничение зафиксировано в requirements/specs как принятое; финальная приёмка — через реальный CI-прогон, не блокирует implementation |
| Версии Android SDK/build-tools (36/36.0.0) окажутся несовместимы с чем-то в проекте | Low | Med | Те же версии, что уже стоят и работают на текущей локальной машине (проверено `ls ~/Library/Android/sdk`) |

## Rollback Strategy

1. Удалить `docker-build.yml` — `build.yml` не менялся, откатывать нечего.
2. Новые файлы (`docker/`, `tool/docker-build.sh`) — удалить, ничего в остальной части репозитория от них не зависит (изолированное дополнение).

## Checkpoints

- [ ] После Phase 1: оба образа собираются локально (arm64) без ошибок
- [ ] После Phase 2: `tool/docker-build.sh linux|android` проходят полный verification-прогон локально
- [ ] После Phase 3: YAML валиден, команды построчно сверены с Phase 2; окончательная приёмка — зелёный реальный CI-прогон (сообщает пользователь)
- [ ] Отклонения — в 04-implementation-log.md

## Open Implementation Questions

- [ ] Ничего не осталось не закрытым — версия `commandlinetools-linux` зафиксирована (`9862592`, проверена HTTP 200) в ходе Plan.

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «plan aproved» (approved).
