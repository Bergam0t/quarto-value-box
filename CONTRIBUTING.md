# Contributing

We welcome contributions to `quarto_value_box`. You can either:

## Reporting Issues

If you find a bug or have a feature request, please [open an issue](https://github.com/bergam0t/quarto_value_box/issues) and include:

- A minimal reproducible example (a short `.qmd` file is ideal)
- The output format you are targeting (e.g. `revealjs`, `html`)
- Your Quarto version (`quarto --version`) and operating system

## Making Changes

1. **Fork** the repository and create a branch from `main`.

2. **Make your changes** to the Lua filter (`value-box.lua`) and/or stylesheet (`value-box.css`).

3. **Test your changes** against a range of cases before submitting.
    - Run the test suite: `bash tests/run-tests.sh` (add `--no-pdf` to skip the slow LaTeX leg). It renders a set of fixtures to every supported output format and checks the results. CI runs the same script.
    - Add a case to `tests/fixtures/` covering your change, and an assertion for it. **[tests/README.md](tests/README.md) explains how the suite works and how to write a check that can actually fail — it assumes no prior testing experience, so start there if this is unfamiliar.**
    - Preview `example.qmd` too, and add any additional examples to it to demonstrate your new features.

4. **Update the README.md** if you have added any new parameters or features.

5. **Commit** with a short, descriptive message.

6. **Open a pull request** against `main` with a description of what you changed and why.

> [!NOTE]
> We are happy to accept AI-supported contributions to the extension, but reserve the right to reject wholly AI generated pull requests which are not felt to add value to the project.



### Code Style

- Keep the filter self-contained in `value-box.lua` — avoid introducing external Lua dependencies.
- Prefer explicit fallbacks and `stderr` warnings over silent failures, consistent with the existing error handling pattern.
- Match the existing indentation and spacing conventions.
- Add a comment if a block of logic is non-obvious.

### Scope

This filter is intentionally lightweight. Please open an issue to discuss larger changes before investing time in a PR — it is worth aligning on whether a proposed feature fits the project's goals first.

### Licence

By submitting a contribution you agree that your changes will be made available under the same licence as the rest of this project.
