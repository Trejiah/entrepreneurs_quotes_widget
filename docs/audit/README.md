# Code audit

This folder hosts honest, written-down audits of the project's largest files.
The intent is to make the refactor backlog **visible** — not to ship the refactor
itself in one commit.

Each audit follows the same structure:

1. **Snapshot** — current size, top-level shape, what the file does today.
2. **Pain points** — concrete smells (mixed concerns, duplicated logic, dead
   code, unclear ownership, etc.).
3. **Refactor plan** — split into tiers:
   - **Tier 1 — low risk**: dead-code removal, `print` → `debugPrint`,
     extract self-contained widgets, normalize naming. Already done in the
     same commit that introduces the audit.
   - **Tier 2 — medium risk**: extract pure helpers / value objects, move
     bootstrap to a dedicated file, isolate the deep-link channel.
   - **Tier 3 — high risk**: introduce Riverpod controllers / state notifiers,
     break the screen into feature folders. Deferred to a dedicated branch
     because it touches behaviour.

Audited files:

- [`main.dart.md`](main.dart.md) — app bootstrap (~1.2k lines today).
- [`home_page.dart.md`](home_page.dart.md) — main screen (~4.7k lines today).

These documents are **living**: every time a tier is shipped, tick the matching
box and move the leftover work down.
