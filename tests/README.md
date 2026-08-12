# Tests

```bash
bash tests/run-tests.sh              # everything
bash tests/run-tests.sh --no-pdf     # skip the PDF leg — much faster, no LaTeX needed
bash tests/run-tests.sh --only html  # a single format (repeatable)
```

Exits non-zero if any check fails, and exits 2 rather than 0 if the arguments
select nothing to test. Rendered output is left in `tests/_work/` (git-ignored)
for inspection, one directory per format (plus `demo/`), each with the render log
alongside.

---

# New to testing Quarto extensions? Read this first

You do not need prior testing experience to work on this suite. This section
explains what is being tested and why it is done this way, so that you can judge
whether a check is any good and write new ones with confidence.

## What this extension actually does

`value-box.lua` is a **Pandoc Lua filter**. When Quarto renders a document, it
parses your `.qmd` into a tree of elements, hands that tree to each filter in
turn, and lets the filter rewrite it before the output file is written.

Our filter looks for `Div` elements carrying the `value-box` class and replaces
them with a blob of raw HTML built by string concatenation:

```lua
'<div class="value-box %s%s" style="%s%s"%s>'
```

Two consequences follow, and between them they explain the entire design of this
suite:

1. **The output is a string, not a structure.** Nothing validates it. A typo
   produces a document that renders perfectly happily and looks wrong — or looks
   fine and is subtly invalid. There is no compiler to catch you.
2. **Raw HTML only means anything in HTML.** Quarto renders to PDF, Word and
   Typst too. Those writers do not understand an HTML string; they either drop it
   or choke on it. Anything that goes wrong there is invisible from an HTML
   render, which is the only render most people do while developing.

## The two questions a test here can ask

**"Did it build?"** Run `quarto render` and look at the exit code. Cheap, and it
catches whole formats being broken.

**"Is the output right?"** Render, then look inside the file that was produced.
This is the one that catches the quiet failures — a stylesheet linked seventeen
times, a value silently missing, invalid CSS that browsers discard without
complaint. All of those render "successfully".

Historically this project's entire test bar was "does `example.qmd` still
render?" — the first question only. That bar is genuine and still enforced (the
demo deck is built at the end of every run), but the bugs this suite was created
in response to all sailed straight past it.

## Why six formats, and the PDF/LaTeX subtlety

The filter emits HTML unconditionally, so every non-HTML format is a place where
things can go wrong unnoticed. We render to `html`, `revealjs`, `latex`, `pdf`,
`typst` and `docx`.

One detail is worth internalising because it is genuinely counter-intuitive, and
it is the reason a real bug survived in this repo:

> `quarto render --to latex` **exits 0** even when it has written a `.tex` file
> that could never compile. `quarto render --to pdf` **exits 1**, because it
> actually runs LaTeX.

The bug: icon stylesheet `<link>` tags were being injected into *every* format's
header, so a PDF render put a raw HTML tag into the LaTeX preamble and LaTeX died
with `Missing \begin{document}`. Rendering to `latex` would never have caught it.

So we render **both**. `pdf` is the *detector* — it tells you something is
broken. `latex` is the *diagnostic* — it leaves a readable `.tex` behind that we
can search for the offending tag. The two are not redundant.

## How a run actually works

For each format, the script:

1. **Stages a directory** at `tests/_work/<format>/` containing a copy of
   `_extensions/`, the fixtures, and the image assets.
2. **Renders each fixture** into it with `quarto render <fixture>.qmd --to <fmt>`,
   capturing the log, and records a pass or fail on the exit code.
3. **Runs assertions** against the resulting file — mostly "does this string
   appear, and how many times?".

Two things about step 1 look like clutter and are actually load-bearing:

- **The extension is copied, not referenced.** This repo has no `_quarto.yml`, so
  renders are standalone-file renders and Quarto looks for `_extensions/` *only
  in the input file's own directory* — not in parent directories. A fixture in
  `tests/fixtures/` simply cannot find the extension at the repo root. Copying it
  also means the tests exercise the same on-disk layout a user gets from
  `quarto add`.
- **Every format gets its own directory.** Several formats write the same output
  filename: `html` and `revealjs` both produce `.html`, `pdf` and `typst` both
  produce `.pdf`. Sharing one directory would have them overwrite each other and
  we would be asserting against the wrong file.

Image assets are copied beside the fixture because local icon paths
(`icon="example-icon.svg"`) resolve relative to the fixture, not the repo root.

## Searching output text: why that is a reasonable way to test this

Checking rendered HTML by searching for substrings is crude. For this project it
is the right trade-off: the filter's whole job is to produce a specific string,
the output surface is small, and the alternative — parsing the HTML and querying
it properly — would add tooling and dependencies out of proportion to a
290-line filter.

Be aware of what it costs you. A substring check cannot tell the difference
between markup and prose (a fixture that *mentions* `font-size:;` in its body
text will trip a naive search for it — this has already happened here), and it
will happily match Quarto's own boilerplate. Scope your patterns tightly enough
that only your filter's output can satisfy them.

## The one rule: a test that cannot fail is worse than no test

This is the thing to actually take away. A check that always passes is not
neutral — it is harmful, because it occupies the space where a real check should
be and it reports success while the code is broken.

Three real examples, all found in this suite *after* they were written and
believed to be good:

**A count that is right for the wrong reason.** An early check asserted "two
Phosphor stylesheet links". The fixture had two boxes with two different icon
weights. Two links is the answer whether deduplication works or not, so the check
could never fail. Fixed by making the fixture use one weight *twice*, and
asserting that each specific URL appears exactly once — which pins down both
halves: no duplicates, and no wrongly collapsing two variants into one.

**Testing Pandoc instead of testing us.** Five checks asserted that strings like
`opacity:0.5` appeared in the output, from a fixture setting
`icon-extra-style="opacity:0.5;"`. They passed with the filter **deleted
entirely** — because Pandoc echoes attributes it does not recognise back out as
`data-*` attributes. The fix is to anchor each pattern to something spanning the
boundary between markup the filter generated and the value you supplied, e.g.
`font-size:3em; color:white; opacity:0.5;` rather than the bare user string.

**An absence check on nothing at all.** `assert_absent` originally only checked
the file *existed*. An empty or truncated file contains no offending string, so
every absence check passed. The `latex` leg consists almost entirely of absence
checks, so a completely empty `.tex` scored full marks. Helpers now require the
file to be non-empty.

### How to prove a check can fail

Deliberately break the thing it is meant to catch, and watch it go red. Two
techniques used throughout this suite:

**Mutate the filter.** Change the code so the bug comes back, run the suite,
confirm the *expected* check fails, then restore. For example, changing the
optical-bearing constant from `0.12em` to `0.13em` should fail exactly one
layout check.

```bash
# edit _extensions/value-box/value-box.lua, then:
bash tests/run-tests.sh --only html
git checkout -- _extensions/value-box/value-box.lua   # restore
```

**Remove the filter entirely.** The strongest version. Delete the `filters:` key
from a staged fixture, re-render, and confirm your checks go red. If a check
still passes with no filter running, it is not testing this extension. This is
what exposed the five tautological checks above, and it is worth re-running after
any change to the runner.

## Worked example: testing a new attribute

Say you are adding a `title` attribute that renders a small heading above the
value. Here is the whole loop.

**1. Add a box to a fixture.** `layout.qmd` is the home for styling and layout
options; `icons.qmd` for icon handling; `minimal.qmd` for the bare path. Drop in:

```md
::: {.value-box title="Bibbles" value="60"}
Title attribute
:::
```

The fixture list is derived from the directory, so a brand-new `.qmd` file is
picked up automatically — nothing to register.

**2. Render once and look at what actually came out.** Do not guess the string.

```bash
bash tests/run-tests.sh --only html
grep -o '<div class="title"[^>]*>' tests/_work/html/layout.html
```

**3. Write the assertion from what you saw**, in the `html|revealjs` branch of
the `case` block in `run-tests.sh`. Using whatever step 2 printed — the string
below is illustrative, yours will differ:

```bash
assert_present '<div class="title" style="color:white; ">Bibbles</div>' \
  "$out" "$fixture/$fmt renders the title above the value"
```

Note this pattern includes `class="title"` and the generated `color:white;` —
markup only the filter can produce. Asserting on the bare word `Bibbles` would
pass whether or not your feature works, because the word is in the fixture.

**4. Prove it fails without your feature.** Comment out your new code in the
filter, re-run, and confirm that check — and ideally only that check — goes red.

**5. Run the whole suite** (`bash tests/run-tests.sh`) before you commit, so you
know the new attribute has not broken PDF, Word or Typst output.

## Choosing what is worth asserting

Not every line needs a check. In rough order of value:

- **Does it build in every format?** Free — you get it just by adding the fixture.
- **Did a regression we have already had come back?** The duplicate-stylesheet
  and preamble-leak checks exist because those bugs actually happened.
- **Is generated markup structurally right?** Positioning classes, the wrapper
  element, values landing in the right place.
- **Exact cosmetic values** (a specific pixel measurement) — assert these only
  where the number is meaningful, since they make deliberate changes noisy.

If you cannot think of a way for a check to fail, that is a signal, not a
reassurance.

---

# Reference

## Assertion helpers

| Helper | Use |
| --- | --- |
| `assert_count <n> <pattern> <file> <desc>` | Exactly `n` occurrences |
| `assert_present <pattern> <file> <desc>` | At least one occurrence |
| `assert_absent <pattern> <file> <desc>` | No occurrences |
| `assert_no_empty_css <file> <desc>` | No `prop:;` inside any `style` attribute |

**All of them match fixed strings, not regular expressions.** Icon CDN URLs are
full of characters (`.`, `+`, `@`) that a regex would reinterpret, and a pattern
that silently stops matching is a test that silently stops testing.

`assert_count` counts **occurrences, not matching lines** — Quarto emits several
head elements on a single line, so a line-based count would miss real duplicates.

All of them fail if the target file is missing *or empty*.

## Network and toolchain

The `html`, `revealjs`, `docx` and `typst` legs need no network: icon CDNs are
only ever *linked*, never fetched at render time. The **PDF leg does need
network** — TinyTeX installs missing LaTeX packages from CTAN on demand, which is
the most likely source of a flaky CI run. Use `--no-pdf` when working offline.

CI runs the whole matrix on Linux and Windows, against both the current Quarto
release and the pre-release.

## Known gaps

- `_extension.yml` declares `quarto-required: ">=1.3.0"`, but CI tests only
  `release` and `pre-release`, so that floor is unverified. Note Typst support
  only arrived in Quarto 1.4, so a 1.3 leg would need the typst format skipped.
- `docx` and `typst` are close to smoke-tests only. Before adding a non-HTML
  representation of the value, add content baselines to both (typst needs
  `keep-typ` to leave a greppable `.typ`) so the change shows up as a check going
  from red to green.
- Only `material` / `material-rounded` and two of six Phosphor weights are
  exercised; `material-sharp` and the unknown-weight fallback are not.
- No fixture covers a missing icon file, so the warning-text guard
  (`assert_absent "value-box warning"`) would not notice if the warning wording
  changed and it silently stopped matching.
- Everything renders in standalone-file mode; project-mode (`_quarto.yml`)
  rendering is untested.
- The `docx` leg needs `unzip` on PATH (present in Git Bash and on GitHub's
  runners).
- Two concurrent runs clobber each other: the work tree is cleared at startup.
