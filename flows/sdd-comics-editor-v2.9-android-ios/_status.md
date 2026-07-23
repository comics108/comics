# Status: sdd-comics-editor-v2.9-android-ios

## Current Phase

IMPLEMENTATION

## Phase Status

IN PROGRESS (Phase 1: FFI-ядро и AOT-ворота)

## Last Updated

2026-07-23 by Claude

## Blockers

- Ожидается «requirements approved»

## Progress

- [x] Requirements drafted
- [x] Requirements approved (2026-07-23)
- [x] Specifications drafted
- [x] Specifications approved (2026-07-23)
- [x] Plan drafted
- [x] Plan approved (2026-07-23)
- [x] Implementation started  ← current
- [ ] Implementation complete

## Context Notes

Key decisions and context for resuming:

- База: завершённый flow `sdd-comics-editor-v2.9` (Flutter desktop + headless C#-ядро процессом + UI макета; git не трогать — правило пользователя).
- Задача: + iPhone/iPad/Android-телефоны/планшеты; + системные диалоги Open/Save на всех платформах (вместо текстового поля пути).
- Ключевая проблема: на iOS запрещён запуск процессов → headless-процесс не работает.
- Решения пользователя (2026-07-23): Q1 — **.NET NativeAOT + FFI** (C-экспорты над теми же линкованными исходниками, JSON-протокол сохраняется, транспорт FFI; риски Newtonsoft/AOT признаны, проверка на sample.comics; fallback на Dart-I/O — только отдельным решением пользователя); Q2 — file_picker; Q3 — дефолты Flutter (iOS 13+/API 26+); Q4 — Save в песочницу + Export/Share системным диалогом.
- Макет уже адаптивный (phone/tablet/desktop breakpoints в lib/src/ui/responsive.dart).

## Fork History

- Новый flow (не форк), создан 2026-07-23. Продолжение sdd-comics-editor-v2.9.

## Next Actions

1. Получить «plan approved» (или правки)
2. Реализация: Phase 1 (Comics.Editor.Native, AOT-ворота), лог в 04-implementation-log.md

## Key Design Points (SPECIFICATIONS)

- Новый проект Comics.Editor.Native: C-экспорты comics_call/comics_free (UnmanagedCallersOnly), AssemblyName=Comics.Editor, rd.xml для Newtonsoft+Models.
- Транспортная абстракция ComicsCore: ProcessCore (desktop, существующий код) / FfiCore (mobile, Isolate.run).
- Android NativeAOT — RID linux-bionic-arm64/x64 (без mobile workload, нужен NDK); iOS — ios-arm64 NativeLib=Static.
- AOT-ворота: FFI round-trip на osx-arm64 dylib на хосте — главная проверка рисков до устройств.
- file_picker: open везде; save — путь на десктопе, bytes на мобильных. Save mobile → песочница <documents>/comics/, Export → системный диалог.
