## [1.1.0] - 2025-11-21

- Added schema-level `focusScale` plus tweened initialization so the renderer can smoothly focus and emit zoom events based on schema defaults.
- Upgraded `CoordinateAxisPlugin` with configurable major/minor ticks, value-aligned labels, viewport-aware scale readouts, and relative imports across plugins.
- Prevented unnecessary renderer rebuilds by keeping `interactivePlugins` outside the memoized controller dependency list.
- Ensured `tweenBack` emits a zoom event after animations and softened breathing animation scaling for a subtler pulse.
- Updated README branding to SchemaX.

## [1.0.0]

- Initial release.
