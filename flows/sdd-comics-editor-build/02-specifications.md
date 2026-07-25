# Specifications: comics-editor-build — Docker-контейнеризация Linux/Android сборки

> Version: 1.1
> Status: APPROVED
> Last Updated: 2026-07-25
> Requirements: [01-requirements.md](01-requirements.md) (APPROVED)

## Overview

**Два раздельных процесса сборки** (правка от 2026-07-25, см. requirements — «Архитектурная правка»), не один изменённый:

1. **Native Build** (`build.yml`) — **без изменений**, тот же нативный CI на каждый push/PR, что и сейчас (`apt-get install`, `subosito/flutter-action`, `actions/setup-dotnet`, `actions/setup-java` — как есть).
2. **Docker Build** (`docker-build.yml`, новый) — два узких Docker-образа (`linux-build`, `android-build`) с зафиксированным тулчейном; исходники не запечены в образ, монтируются при `docker run` (bind mount), так что образ пересобирается только при смене версий тулчейна. Запускается **только** на `push: main`, nightly-расписании и `release: published` — не на каждый PR. Результат — публикуемые артефакты (дольше хранятся, чем verification-артефакты Native Build; при триггере `release` — прикрепляются к самому GitHub Release).

Тот же образ используется и в CI (`docker/build-push-action` с GH Actions layer cache), и локально (`tool/docker-build.sh`) — оба пути идентичны, различается только окружение запуска.

`release.yml` не затрагивается (`build.yml` fastlane-jobs для fastlane/подписи в сторы — вне рамок этого flow).

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `docker/linux-build.Dockerfile` | Create | Ubuntu 24.04 + Flutter 3.44.6 + .NET SDK 10.0.302 + GTK3/CMake/ninja/clang |
| `docker/android-build.Dockerfile` | Create | Ubuntu 24.04 + Flutter 3.44.6 + Temurin JDK 17 + Android SDK (platform 36, build-tools 36.0.0) |
| `tool/docker-build.sh` | Create | Обёртка: `tool/docker-build.sh <linux\|android> [command...]` — build образа + `docker run` с bind-mount репозитория |
| `.github/workflows/docker-build.yml` | Create | Новый workflow: `docker-build-linux`/`docker-build-android`, триггеры `push:main`/`schedule`/`release`, публикация артефактов |
| `.github/workflows/build.yml` | **Не меняется** | Native Build остаётся как есть — отдельный, более быстрый CI-контур на каждый push/PR |
| `docker/README.md` | Create | Как собрать/запустить образы локально, разница Native vs Docker Build, что контейнеризовано и что нет, как использовать для диагностики CI-специфичных багов |

Не затрагиваются: `tool/build_headless.sh|ps1`, `tool/build_native.sh` (вызываются изнутри контейнера как есть, не дублируются); `build.yml`; `release.yml`; C#/Dart-код приложения.

## Architecture

```
apps/comics-editor-v2.9/
├── docker/
│   ├── linux-build.Dockerfile     # тулчейн-образ: Flutter + .NET + GTK/CMake
│   ├── android-build.Dockerfile   # тулчейн-образ: Flutter + JDK + Android SDK
│   └── README.md
├── tool/
│   ├── docker-build.sh            # локальный запуск: build image → docker run -v .:/workspace
│   ├── build_headless.sh|ps1      # без изменений, вызывается внутри контейнера
│   └── build_native.sh            # без изменений (архивный NativeAOT-путь)
└── .github/workflows/
    ├── build.yml                  # Native Build — БЕЗ ИЗМЕНЕНИЙ, каждый push/PR
    ├── docker-build.yml           # Docker Build — НОВЫЙ, main/nightly/release
    └── release.yml                # без изменений
```

### Поток выполнения (CI, docker-build-linux)

```
триггер: push→main | schedule(nightly) | release(published)
checkout → docker/build-push-action (context: docker/, file: linux-build.Dockerfile,
           cache-from/to: type=gha, load: true, tags: comics-editor-linux-build:ci)
         → docker run --rm -v $GITHUB_WORKSPACE:/workspace -w /workspace \
             comics-editor-linux-build:ci bash -c "<та же verification-последовательность,
             что использует build.yml — flutter pub get && dotnet build ... && flutter build
             linux --release && tool/build_headless.sh && flutter test ...>"
         → upload-artifact (retention 90 дней — дольше, чем 14 у Native Build)
         → если триггер == release: прикрепить .deb-бандл к GitHub Release
             (softprops/action-gh-release или gh release upload)
```

Локально идентично: `tool/docker-build.sh linux` — `docker build` (с локальным Docker layer cache) + `docker run -v $(pwd):/workspace ...` с тем же дефолтным набором команд; можно переопределить последней позицией аргументов (`tool/docker-build.sh linux bash` → интерактивный шелл внутри того же окружения, что и CI — полезно для диагностики CI-специфичных багов, например текущего Linux headless-краша). Локальный запуск не публикует артефакты никуда — только `build.yml`/`docker-build.yml` в CI решают вопрос публикации.

## Interfaces

### `docker/linux-build.Dockerfile` (ключевые решения)

- База: `ubuntu:24.04` (совпадает с ОС `ubuntu-latest`-раннера на момент написания — GH Actions лог подтверждает `Ubuntu 24.04.4 LTS`).
- `.NET SDK` — `dotnet-install.sh --version 10.0.302` (точная версия, а не floating `10.0.x` как сейчас в `actions/setup-dotnet` — более детерминированно, чем сегодняшний CI).
- `Flutter` — `flutter_linux_3.44.6-stable.tar.xz` (тот же официальный дистрибутив, что скачивает `subosito/flutter-action`), путь добавлен в `PATH`; `flutter precache --linux` выполняется **на этапе сборки образа** (кладётся в слой), чтобы `docker run` не тянул артефакты каждый раз.
- Debian-пакеты: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev` — ровно тот список, что сейчас в `build.yml` шаге `apt-get install`.
- `WORKDIR /workspace` — точка монтирования исходников; в образе исходников нет.
- Без `ENTRYPOINT`/`CMD` — команда передаётся при `docker run`, чтобы один образ обслуживал и «полный verification-прогон», и произвольные ad-hoc команды для отладки.

### `docker/android-build.Dockerfile` (ключевые решения)

- База: `ubuntu:24.04`.
- JDK — Eclipse Temurin 17 через официальный APT-репозиторий Adoptium (`packages.adoptium.net`), не generic `openjdk-17-jdk` — для точного соответствия `actions/setup-java` (`distribution: temurin`).
- Android SDK — `commandlinetools-linux` (Google), `sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0"` (36 — актуальный `compileSdkVersion`/`targetSdkVersion` из Flutter Gradle Plugin 3.44.6), `sdkmanager --licenses` принимается автоматически на этапе сборки образа. **NDK не устанавливается** — Android больше не использует NativeAOT (см. `sdd-comics-editor-v2.9-android-ios`, пивот на `DartIoCore`).
- `Flutter` — тот же дистрибутив, `flutter precache --android` на этапе сборки образа.
- `ANDROID_HOME`/`ANDROID_SDK_ROOT` — `/opt/android-sdk`.

### `tool/docker-build.sh`

```bash
tool/docker-build.sh <linux|android> [command...]
# Без command — прогоняет дефолтную verification-последовательность (та же, что в build.yml).
# С command — выполняет её вместо дефолтной (напр. `bash` для интерактивной отладки).
```

Локальный запуск монтирует контейнер с `--user "$(id -u):$(id -g)"` (только вне CI — на GH-раннерах не нужно, они одноразовые), чтобы артефакты сборки на хосте не становились root-owned на Linux-машинах разработчиков.

### `.github/workflows/docker-build.yml` (новый, отдельно от `build.yml`)

```yaml
on:
  push:
    branches: [main]
  schedule:
    - cron: "0 3 * * *"   # nightly, 03:00 UTC — легко поменять
  release:
    types: [published]
```

Два job (`docker-build-linux`, `docker-build-android`), независимые (без `needs`, параллельны). Каждый: `docker/build-push-action@v6` (сборка образа с `cache-from/to: type=gha`, без публикации образа в registry — соответствует Q4) + один `run: docker run ...` шаг с той же командной последовательностью, что верификационно использует `build.yml` для соответствующей платформы (`flutter pub get && dotnet build ... && flutter build ... --release && ... && flutter test ...`) — просто выполняется внутри контейнера, а не на хосте раннера. `actions/upload-artifact` — с увеличенным `retention-days` (90, а не 14 как в `build.yml`) и отдельным именем (`linux-release-build`/`android-release-apk`), чтобы не путать с verification-артефактами Native Build. Дополнительный шаг **только при `github.event_name == 'release'`**: прикрепление собранного артефакта к самому GitHub Release (`softprops/action-gh-release@v2` с `files:`).

`build.yml` (Native Build) в этом flow не редактируется вообще.

## Behavior Specifications

### Happy Path

1. Разработчик/CI вызывает `tool/docker-build.sh linux` (или CI — эквивалентный workflow-шаг).
2. Образ собирается (или берётся из кэша слоёв — Docker locally / GHA cache в CI) — тулчейн не меняется между запусками, кэш почти всегда валиден.
3. Контейнер запускается с смонтированным репозиторием, выполняет `flutter pub get → dotnet build (Headless) → flutter build linux --release → tool/build_headless.sh → flutter test ...` — та же последовательность, что сейчас в `build.yml`.
4. Артефакты (`build/linux/x64/release/bundle/`) оказываются на хосте (volume mount), т.к. процесс внутри контейнера пишет напрямую в смонтированный каталог.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Docker не установлен локально | `tool/docker-build.sh` без Docker | Скрипт явно проверяет `command -v docker`, печатает понятную ошибку со ссылкой на docker.com, а не сырой `command not found` |
| Смена версии Flutter/.NET/JDK | Обновление `build.yml`/`Dockerfile` | Кэш слоёв инвалидируется автоматически (версии — часть Dockerfile → меняется хэш слоя); дополнительных действий не требуется |
| Локальная машина — Apple Silicon (arm64), образ — Linux amd64 | `docker build`/`run` без `--platform` | Docker собирает/эмулирует нужную архитектуру автоматически (`buildx`); **известное ограничение этой машины** — QEMU/Rosetta-эмуляция amd64 в Docker Desktop здесь нестабильна (см. `sdd-comics-editor-v2.9-android-ios`, диагностика Linux headless-краша) — образ и Dockerfile платформо-независимы (сработают на amd64 CI-раннере), но полная локальная верификация amd64-специфичного поведения на этой машине не гарантирована; arm64-образ (`--platform linux/arm64`) работает нативно и достаточен для большинства проверок (не для x64-специфичных багов) |
| Bind-mount и root-owned файлы (Linux-хост) | Локальный запуск на Linux-машине разработчика | `tool/docker-build.sh` передаёт `--user $(id -u):$(id -g)`, если не в CI (`$CI` не установлена) |
| `flutter pub get` требует сеть | Контейнер без доступа в интернет | Не наш случай (CI/локальная машина имеют сеть по умолчанию); не решается на уровне этого flow |
| Изменение исходников между запусками | Повторный `docker run` без пересборки образа | Работает как обычно — образ не содержит исходников, mount всегда актуален; пересборка образа не нужна |

### Error Handling

Ошибки сборки/тестов внутри контейнера всплывают как ненулевой exit-код `docker run`, что уже приводит к падению CI-шага (`run:` в GitHub Actions завершается с ошибкой при ненулевом коде дочернего процесса) — поведение идентично сегодняшнему (просто раньше падал `flutter build`/`dotnet build` напрямую, теперь — обёрнутый в `docker run`, код возврата пробрасывается без изменений).

## Dependencies

### Requires

- Docker (локально — Docker Desktop/Engine; в CI — предустановлен на `ubuntu-latest` GH-раннерах, отдельной установки не требует).
- `docker/build-push-action@v6` (официальный GitHub Action от Docker) — для сборки с GHA layer cache в CI.

### Blocks

- Ничего в пределах этого репозитория; сборка Windows/macOS/iOS/release.yml не зависит от этого flow.

## Testing Strategy

### Manual Verification

- [ ] `tool/docker-build.sh linux` локально (arm64-образ на этой машине) — воспроизводит те же шаги, что `build-linux` в CI, завершается без ошибок на новом коде (полный x64-репро CI-бага не гарантирован — см. Edge Cases).
- [ ] `tool/docker-build.sh android` локально — собирает APK, гоняет `flutter test` (widget + dart_io_core).
- [ ] `build.yml` после правки: оба job (`build-linux`, `build-android`) зелёные в реальном CI-прогоне (финальная проверка — только в GitHub Actions, не локально).
- [ ] Артефакты (`linux-build`, `android-build` в `actions/upload-artifact`) не пустые и по структуре совпадают с текущими.

## Open Design Questions

- [ ] Версия `commandlinetools-linux` (Android SDK) — зафиксировать конкретный номер сборки Google на этапе Plan/Implementation (в Dockerfile нельзя оставлять «latest» — ломает воспроизводимость; нужно явно запинить, как и остальные версии).

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-07-25
- [x] Notes: «specs approved».
