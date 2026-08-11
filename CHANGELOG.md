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
