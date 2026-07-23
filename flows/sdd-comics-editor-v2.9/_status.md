# Status: sdd-comics-editor-v2.9

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING (awaiting answers to open questions + user approval)

## Last Updated

2026-07-23 by Claude

## Blockers

- Open questions Q2–Q5 in 01-requirements.md (reuse of flutter_comics_editor, nested .git, target .NET version, data layer for stage 2)

## Progress

- [x] Requirements drafted  ← current
- [ ] Requirements approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

- `apps/comics-editor-v2.9` = копия `legacy/comics-editor-v2.8` (WPF, .NET Framework 4.5.2, старые csproj + packages.config). v2.8 — read-only. В формулировке задачи опечатка «работы вести в v2.8» — принято как v2.9.
- Задача: обвязка + перемещение папок, C#-код не переписывать; .NET можно поднять до последнего, минорные фиксы разрешены.
- Существующий задел: `libs/comics_editor/flutter_comics_editor` — PlatformView-плагин (Windows-only), своя копия native C# + Comics.Editor.Flutter (net9.0-windows); C++/CLI-слой не завершён (нужен Windows). См. flows sdd-flutter-comics-editor-pview/-ffi.
- WPF не работает вне Windows. Решение пользователя (2026-07-23): двухэтапный план — этап 1: Windows, полный WPF как есть внутри Flutter (ничего не дописывать в C#); этап 2: macOS/Linux с Flutter-UI из `design/comics-editor-maket-dart-v3` (чистый Dart-макет, UI-паритет с v2.8).
- В `apps/comics-editor-v2.9` есть вложенный `.git` (артефакт копирования) — git показывает папку как один нетрекаемый путь.
- Текущая машина — macOS; WPF-сборку можно проверить только на Windows.

## Fork History

- Новый flow (не форк), создан 2026-07-23.

## Next Actions

1. Получить ответы на Q1–Q4 и внести в 01-requirements.md
2. Получить явное «requirements approved»
3. Перейти к 02-specifications.md
