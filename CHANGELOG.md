# v1.6.0

- Add Phosphor Icons support (`icon-type="phosphor"`, auto-detected from a `ph`/`ph-<weight>` prefixed `icon` value, e.g. `icon="ph ph-star"` or `icon="ph-bold ph-star"`). Loads the weight-specific stylesheet matching the icon's weight class
- Fix: icon stylesheets are now linked once per document instead of once per value box. A document with many boxes previously repeated the same `<link>` tag dozens of times in its `<head>`
- Fix: icon stylesheet `<link>` tags no longer leak into non-HTML output. Rendering a document containing a value box to PDF previously injected a raw `<link>` tag into the LaTeX preamble, which fails to compile
- Fix: unset or blank attributes no longer emit empty CSS declarations. A box with no `height` produced `height:;`, one with no `font-size` produced `font-size: ;`, and `icon-size=""` produced `font-size:;` on the icon — all invalid, and silently discarded by browsers
- Fix: `icon-size=""` now falls back to the default size rather than suppressing it (an empty string is truthy in Lua, so a blanked attribute read as a set one)
- Fix: boxes with an `href` no longer emit both `display:block` and `display:flex`. The duplicate was harmless only because the later declaration happened to win

# v1.5.0

- Add Tabler Icons support (`icon-type="tabler"`, auto-detected from a `ti-` prefixed `icon` value, e.g. `icon="ti-star"`)

# v1.4.0

- Add Material Symbols icon support (`icon-type="material"` / `material-outlined` / `material-rounded` / `material-sharp`). Unlike Font Awesome and Bootstrap Icons, the icon name (e.g. `home`) is not auto-detected from the `icon` value — `icon-type` must be set explicitly

# v1.3.0

- Add `value-position` option (`top | bottom | left | right`) to control where the value is rendered relative to the details text, independently of `icon-position`
- Add `content-extra-style` option for the new wrapper around the value and details
- Fix: `icon-position` no longer affects where the value is placed — previously setting `icon-position` to `left`/`right` also pulled the value into a row alongside the icon and details
- Fix: icon-font icons (Bootstrap Icons / Font Awesome) with `icon-position="top"`/`"bottom"` no longer look indented relative to the value/details text under `align="left"`/`"right"` — compensates for the glyphs' built-in optical bearing ([#12](https://github.com/Bergam0t/quarto-value-box/issues/12))

# v1.1.1

- Set valign default to middle
- Remove outdated reference to scss files in config

# v1.1.0

- Add valign support
- Fix halign behaviour for png icons

# v1.0.0

Initial release
