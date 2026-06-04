## 1.0.0

- Initial release.
- `ChatSlot<T>` typedef + `ChatSlotOps` extension (`fill`, `swap`, `clearSlot`).
- `ChatListController<Item>` — item list ownership, scroll control, unread badge count.
- `ChatCoordinatorMixin<T>` — four ready-made slots on any `Coordinator<T>`.
- `ChatShell<T>` — z-ordered `Stack` layout rendering all four slots.
- `SlotBarView<T>` — content-sized bar-slot renderer.
- `ChatMetrics` — `InheritedWidget` exposing top/bottom bar insets to the body.
