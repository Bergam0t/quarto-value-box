# Contributing

We welcome contributions to `quarto_value_box`. You can either:

## Reporting Issues

If you find a bug or have a feature request, please [open an issue](https://github.com/bergam0t/quarto_value_box/issues) and include:

- A minimal reproducible example (a short `.qmd` file is ideal)
- The output format you are targeting (e.g. `revealjs`, `html`)
- Your Quarto version (`quarto --version`) and operating system

## Making Changes

1. **Fork** the repository and create a branch from `main`.

2. **Make your changes** to the Lua filter (`value-box.lua`) and/or stylesheet (`value-box.css`). See [Code Style](#code-style) below for a few conventions that aren't obvious from reading a single function in isolation.

3. **Test your changes** against a range of cases before submitting.
    - Run the test suite: `bash tests/run-tests.sh` (add `--no-pdf` to skip the slow LaTeX leg). It renders a set of fixtures to every supported output format and checks the results. CI runs the same script.
    - Add a case to `tests/fixtures/` covering your change, and an assertion for it. **[tests/README.md](tests/README.md) explains how the suite works and how to write a check that can actually fail — it assumes no prior testing experience, so start there if this is unfamiliar.** The single most common mistake: write an assertion, then delete the `filters:` key from a staged fixture and re-render to confirm your check actually goes red. Checks that pass with the filter not running at all are worthless, and it is very easy to accidentally write one without doing this.
    - Preview `example.qmd` too, and add any additional examples to it to demonstrate your new features.

4. **Update the docs.**
    - `README.md` — the customisation table, plus a short paragraph if the feature needs more than a table row (see the passthrough section for an example).
    - `CHANGELOG.md` — add a line under the section for the next unreleased version (or start a new section if none exists yet).
    - `_extensions/value-box/_extension.yml` — bump `version` to match the `CHANGELOG.md` section you added to.

5. **Preview the demo deck** if you touched `example.qmd`, `value-box.lua`, or `value-box.css`: `quarto preview example.qmd`. `index.html` and `example_files/` are no longer committed — a dedicated `deploy` job in `.github/workflows/ci.yml` renders and publishes them to GitHub Pages on every push to `main`, so there's nothing to re-render and stage locally before opening a PR.
    - `example.qmd` has a live `{python}` cell (the "Driven by computed data" example under Delta), so rendering it needs the deps in `requirements-docs.txt`. Two separate Python interpreters are involved, and both have to be sorted out: the **kernel** that actually executes the `{python}` cell, and the **driver** — a separate interpreter Quarto itself uses to run its own jupyter control script (`nbclient`/`notebook`), chosen independently before it ever looks at which kernel to launch. Relying on Quarto's own auto-detection for either is unreliable across shells, especially if you also have conda or another virtual environment tool that sets `VIRTUAL_ENV` on shell startup, since that can silently shadow whichever env you think is active. So both are pinned explicitly instead: the frontmatter targets the kernel by name (`quarto-value-box-docs`), and `QUARTO_PYTHON` pins the driver. One-time setup per machine:
      ```sh
      python -m venv .venv
      # macOS/Linux: source .venv/bin/activate
      # Windows (PowerShell): .venv\Scripts\Activate.ps1
      pip install -r requirements-docs.txt
      python -m ipykernel install --user --name quarto-value-box-docs --display-name "quarto-value-box docs"
      ```
      Then, once per terminal session, before running `quarto render`/`quarto preview`:
      ```sh
      # macOS/Linux: source ./activate-docs.sh
      # Windows (PowerShell): . .\activate-docs.ps1
      # Windows (cmd.exe): activate-docs.bat
      ```
      These scripts set `QUARTO_PYTHON` to `.venv`'s interpreter, resolved relative to the script's own location — no hardcoded paths, so it works regardless of where the repo is cloned. (A committed `_environment` file would be the more obvious place for this, but `QUARTO_PYTHON` specifically [is read too late in Quarto's startup to take effect there](https://github.com/quarto-dev/quarto-cli/issues/6162) — hence the script instead.) Re-run the `ipykernel install` command if you ever delete and recreate `.venv`, since the registered kernel hardcodes the path to its `python.exe`.

6. **Commit** with a short, descriptive message.

7. **Open a pull request** against `main` with a description of what you changed and why.

> [!NOTE]
> We are happy to accept AI-supported contributions to the extension, but reserve the right to reject wholly AI generated pull requests which are not felt to add value to the project.



### Code Style

- Keep the filter self-contained in `value-box.lua` — avoid introducing external Lua dependencies.
- Prefer explicit fallbacks and `stderr` warnings over silent failures, consistent with the existing error handling pattern.
- Match the existing indentation and spacing conventions.
- Add a comment if a block of logic is non-obvious.
- **A new attribute whose value reaches an HTML attribute must go through `escape_attr()`.** Everything read from `el.attributes` that ends up inside a `style="..."`, `class="..."`, `href="..."`, `src="..."` etc. is escaped at the point it's read — copy that pattern rather than interpolating a raw value. The two deliberate exceptions are `value` and `title`, which are inserted as raw HTML *content* (not an attribute) by design; don't add a third without discussing it first. `icon` is also read raw, because it doubles as a file path and a pattern-match target — see the comment above its declaration in `value-box.lua` before changing how it's handled.
- **A new sizing/styling attribute that can be unset should go through `css_decl(property, value)`**, not a raw `string.format("%s:%s;", ...)`. An empty or unset value passed straight into a style string produces an invalid `property:;` declaration that browsers silently discard — `css_decl` returns nothing at all in that case instead.
- **Avoid new attribute names starting with `data-`/`aria-`, or named `role`/`tabindex`/`lang`.** Those are reserved: any attribute in that set on a `.value-box` div passes straight through onto the rendered box (see the README's passthrough section) rather than being read as one of this filter's own options.

### Scope

This filter is intentionally lightweight. Please open an issue to discuss larger changes before investing time in a PR — it is worth aligning on whether a proposed feature fits the project's goals first.

### Licence

By submitting a contribution you agree that your changes will be made available under the same licence as the rest of this project.
