# v1.6.0

- Add `.value-box-row` container: wrap a set of value boxes in `::: {.value-box-row}` for an equal-width, equal-height KPI strip, instead of hand-rolling `.columns`/`.column` scaffolding and hand-setting `height` on every box. With no `columns` attribute set, boxes lay out in a single non-wrapping row; set `columns="N"` to switch to a grid where extra boxes wrap onto further rows, with every row (not just each one individually) kept the same height. `gap` controls spacing (default `1.5rem`, matching a standalone box's own margin), and `extra-style` is an escape hatch for the row wrapper itself. Like `.value-box`, the row passes through its own `#id`, extra classes, and `data-*`/`aria-*`/`role`/`tabindex`/`lang` attributes
- Fix: `color` now accepts a raw CSS colour value (`#hex`, `rgb()`/`rgba()`, `hsl()`/`hsla()`, `var()`), applied as an inline `background-color`, matching what the README already documented. Previously any such value was concatenated straight into the `class` attribute and silently did nothing

# v1.5.0

- Add `delta` option for a small trend indicator next to the `value`, e.g. `delta="+12%"`, with `delta-color`, `delta-font-size`, `delta-extra-style` and `value-row-extra-style` to style it. The arrow glyph is picked by `delta-direction` (`up`/`down`/`flat`, matched case-insensitively) if set, otherwise inferred from a leading `+`/`-` in `delta`; an unrecognised `delta-direction` shows no arrow, with a warning. Colour is never inferred from direction — an "up" delta isn't always good news, so `delta-color` defaults to inheriting the surrounding text colour rather than a green/red guess

# v1.4.0

- Add support for the div's own `#id` and extra classes, plus `data-*`/`aria-*` attributes and `role`/`tabindex`/`lang`: these now pass through onto the rendered box instead of being silently dropped, so things like `{#kpi .value-box}` with `data-id` (revealjs auto-animate) or ARIA attributes work the same as they would on any other div. Anything outside that set is left off entirely rather than renamed to a `data-` attribute. A literal `style` attribute is dropped (with a warning) rather than colliding with the box's own `style`; a literal `data-fragment-index` attribute is dropped the same way if it would collide with the one generated from `index`
- Fix: every attribute value that reaches an HTML attribute (`href`, `icon`, `color`, `index`, and all six `*-extra-style` attributes, plus the sizing/alignment attributes) is now HTML-escaped. Previously only values in element *content* (`value`, `title`) were ever meant to contain markup, but nothing stopped a quote in, say, `href` or an `*-extra-style` value from breaking out of its attribute and injecting a new one

# v1.3.0

- Add `value-position` option (`top | bottom | left | right`) to control where the value is rendered relative to the details text, independently of `icon-position`
- Add `content-extra-style` option for the new wrapper around the value and details
- Fix: `icon-position` no longer affects where the value is placed — previously setting `icon-position` to `left`/`right` also pulled the value into a row alongside the icon and details
- Fix: icon-font icons (Bootstrap Icons / Font Awesome) with `icon-position="top"`/`"bottom"` no longer look indented relative to the value/details text under `align="left"`/`"right"` — compensates for the glyphs' built-in optical bearing ([#12](https://github.com/Bergam0t/quarto-value-box/issues/12))
- Add Material Symbols icon support (`icon-type="material"` / `material-outlined` / `material-rounded` / `material-sharp`). Unlike Font Awesome and Bootstrap Icons, the icon name (e.g. `home`) is not auto-detected from the `icon` value — `icon-type` must be set explicitly
- Add Tabler Icons support (`icon-type="tabler"`, auto-detected from a `ti-` prefixed `icon` value, e.g. `icon="ti-star"`)
- Add `title` option: a small label rendered above the `value`, with `title-color`, `title-font-size` and `title-extra-style` to style it. The default size comes from the extension's stylesheet rather than being set inline, so your own CSS can restyle titles without needing `!important`. When `value-position` is `left` or `right`, the title spans the full width above that row rather than becoming a third item in it
- Add Phosphor Icons support (`icon-type="phosphor"`, auto-detected from a `ph`/`ph-<weight>` prefixed `icon` value, e.g. `icon="ph ph-star"` or `icon="ph-bold ph-star"`). Loads the weight-specific stylesheet matching the icon's weight class
- Fix: icon stylesheets are now linked once per document instead of once per value box. A document with many boxes previously repeated the same `<link>` tag dozens of times in its `<head>`
- Fix: icon stylesheet `<link>` tags no longer leak into non-HTML output. Rendering a document containing a value box to PDF previously injected a raw `<link>` tag into the LaTeX preamble, which fails to compile
- Fix: unset or blank attributes no longer emit empty CSS declarations. A box with no `height` produced `height:;`, one with no `font-size` produced `font-size: ;`, and `icon-size=""` produced `font-size:;` on the icon — all invalid, and silently discarded by browsers
- Fix: `icon-size=""` now falls back to the default size rather than suppressing it (an empty string is truthy in Lua, so a blanked attribute read as a set one)
- Fix: boxes with an `href` no longer emit both `display:block` and `display:flex`. The duplicate was harmless only because the later declaration happened to win
- Increase minimum Quarto requirement to 1.4.0. This is only currently due to Typst usage in test suite but as in the long run it would be nice to support typst, doing this preemptively.

# v1.2.1

- Version numbering fix

# v1.2.0

- Add color parameters
    - icon-color
    - font-color
    - value-color

- Add font size parameters
    - font-size
    - value-font-size

- Add better support for additional style parameters beyond those defined in helper functions
    - outer-extra-style
    - icon-extra-style
    - details-extra-style
    - value-extra-style

# v1.1.1

- Set valign default to middle
- Remove outdated reference to scss files in config

# v1.1.0

- Add valign support
- Fix halign behaviour for png icons

# v1.0.0

Initial release
