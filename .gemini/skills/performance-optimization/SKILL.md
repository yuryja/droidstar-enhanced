---
name: performance-optimization
description: Optimizes resource performance (CPU, Memory, Battery) for C++ and Qt applications.
---

# Performance Optimization Guidelines

When writing or reviewing code for this project, you MUST always adhere to the following performance optimization practices:

## 1. Resource Management (C++)
- **Smart Pointers**: Prefer `std::unique_ptr` and `std::shared_ptr` for automatic memory management to prevent memory leaks.
- **Move Semantics**: Use `std::move` and pass-by-reference-to-const (`const auto&`) wherever possible to avoid unnecessary deep copies.
- **Avoid Global State**: Minimize global variables to avoid unnecessary memory occupation and concurrency bottlenecks.

## 2. Qt-Specific Optimizations
- **Signals and Slots**: Use `Qt::QueuedConnection` appropriately when passing data between threads to prevent locking the main GUI thread.
- **Data Structures**: Use `QList`, `QVector`, and `QString` efficiently. Utilize `QStringBuilder` (`%` operator) instead of `+` for string concatenation if building large strings.
- **UI Rendering**: Avoid complex layouts or frequent updates in `paintEvent` functions. Group UI updates to avoid multiple repaints.

## 3. Concurrency
- Offload heavy tasks (like audio processing or network requests) to worker threads using `QThread`, `QRunnable`, or `std::thread`.
- Never block the main thread.

## 4. Hardware Optimization (Apple Silicon M1)
- Ensure compiler flags are set to leverage the M1 architecture (`-mcpu=apple-m1`).
- Optimize loop unrolling and take advantage of vectorization when processing audio streams (Codec2).

## Review Checklist
- [ ] Is there any unnecessary memory allocation?
- [ ] Are we blocking the main UI thread?
- [ ] Are we doing deep copies instead of passing by reference?
