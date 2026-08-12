#!/usr/bin/env bash
#
# Render every fixture in tests/fixtures to a matrix of output formats and
# assert invariants on the results.
#
#   tests/run-tests.sh              # everything
#   tests/run-tests.sh --no-pdf     # skip the PDF leg (much faster, needs no LaTeX)
#   tests/run-tests.sh --only html  # a single format
#
# Two classes of problem are covered:
#
#   1. Formats that fail to build at all. Note that the PDF leg must render to
#      "pdf", not "latex" — Quarto exits 0 after writing a .tex file that will
#      not compile, so only the real compile catches a corrupted preamble.
#   2. Output that builds but is silently wrong — duplicated stylesheet links,
#      raw HTML leaking into non-HTML formats, invalid CSS, missing content.
#
# Each format renders in its own directory under tests/_work, because several
# formats write the same output filename (html and revealjs both produce
# .html; pdf and typst both produce .pdf).
# ---8<--- end of help text

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$repo_root/tests/_work"

# latex renders alongside pdf: pdf proves it compiles, latex leaves a readable
# .tex behind to assert against.
all_formats=(html revealjs latex pdf typst docx)
formats=()
skip_pdf=0

while [ $# -gt 0 ]; do
  case "$1" in
    --no-pdf) skip_pdf=1 ;;
    --only)
      shift
      [ $# -gt 0 ] || { echo "--only needs a format" >&2; exit 2; }
      # Validate before this ever reaches the rm -rf in stage().
      case " ${all_formats[*]} " in
        *" $1 "*) formats+=("$1") ;;
        *) echo "unknown format: $1 (want one of: ${all_formats[*]})" >&2; exit 2 ;;
      esac
      ;;
    -h|--help) sed -n '2,/^# ---8<---/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ ${#formats[@]} -eq 0 ]; then
  formats=("${all_formats[@]}")
fi

if [ "$skip_pdf" -eq 1 ]; then
  remaining=()
  for f in "${formats[@]}"; do
    [ "$f" = "pdf" ] || remaining+=("$f")
  done
  formats=("${remaining[@]}")
fi

# e.g. `--only pdf --no-pdf`. The demo-deck check at the end would otherwise
# still register passes and make an empty matrix look like a successful run.
if [ ${#formats[@]} -eq 0 ]; then
  echo "no formats selected — nothing to test" >&2
  exit 2
fi

if [ -t 1 ]; then
  green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; reset=$'\033[0m'
else
  green=""; red=""; dim=""; reset=""
fi

passed=0
failed=0
failures=()

ok() {
  passed=$((passed + 1))
  printf '  %sPASS%s %s\n' "$green" "$reset" "$1"
}

fail() {
  failed=$((failed + 1))
  failures+=("$1")
  printf '  %sFAIL%s %s\n' "$red" "$reset" "$1"
  if [ -n "${2:-}" ]; then
    printf '       %s%s%s\n' "$dim" "$2" "$reset"
  fi
}

# All three helpers match fixed strings, not regexes (grep -F). Icon CDN URLs
# are full of characters a regex would reinterpret, and a pattern that silently
# stops matching is a test that silently stops testing.

# assert_count <expected> <pattern> <file> <description>
assert_count() {
  local expected=$1 pattern=$2 file=$3 desc=$4 actual
  # -s not -f: an empty output file must never satisfy an assertion. The latex
  # leg in particular contains only absence checks, which a truncated .tex
  # would otherwise pass cleanly.
  if [ ! -s "$file" ]; then
    fail "$desc" "missing or empty file: ${file#"$repo_root"/}"
    return
  fi
  # -o counts occurrences rather than matching lines: Quarto emits several head
  # elements on one line, so a line-based count would miss real duplicates.
  actual=$(grep -o -F -- "$pattern" "$file" | wc -l | tr -d '[:space:]')
  if [ "$actual" -eq "$expected" ]; then
    ok "$desc"
  else
    fail "$desc" "expected $expected occurrence(s) of '$pattern', found $actual"
  fi
}

# assert_absent <pattern> <file> <description>
assert_absent() {
  local pattern=$1 file=$2 desc=$3 actual
  # -s not -f: an empty output file must never satisfy an assertion. The latex
  # leg in particular contains only absence checks, which a truncated .tex
  # would otherwise pass cleanly.
  if [ ! -s "$file" ]; then
    fail "$desc" "missing or empty file: ${file#"$repo_root"/}"
    return
  fi
  actual=$(grep -o -F -- "$pattern" "$file" | wc -l | tr -d '[:space:]')
  if [ "$actual" -eq 0 ]; then
    ok "$desc"
  else
    fail "$desc" "expected no '$pattern', found $actual"
  fi
}

# assert_present <pattern> <file> <description>
assert_present() {
  local pattern=$1 file=$2 desc=$3
  # -s not -f: an empty output file must never satisfy an assertion. The latex
  # leg in particular contains only absence checks, which a truncated .tex
  # would otherwise pass cleanly.
  if [ ! -s "$file" ]; then
    fail "$desc" "missing or empty file: ${file#"$repo_root"/}"
    return
  fi
  if grep -q -F -- "$pattern" "$file"; then
    ok "$desc"
  else
    fail "$desc" "expected to find '$pattern'"
  fi
}

# assert_no_empty_css <file> <description>
#
# Scoped to style attributes rather than the whole document. A document-wide
# scan couples this check to Quarto's boilerplate (a future `href="javascript:;"`
# would trip it) and to the fixtures' own prose — the fixture that documents
# this very defect writes "font-size:;" in its body text.
assert_no_empty_css() {
  local file=$1 desc=$2 actual
  if [ ! -s "$file" ]; then
    fail "$desc" "missing or empty file: ${file#"$repo_root"/}"
    return
  fi
  actual=$(grep -o 'style="[^"]*"' "$file" | grep -c -E ':[[:space:]]*;')
  if [ "$actual" -eq 0 ]; then
    ok "$desc"
  else
    fail "$desc" "found $actual empty CSS declaration(s) in style attributes"
  fi
}

# Stage a directory with its own copy of the extension, the fixtures and the
# image assets the fixtures reference. The extension is copied rather than
# resolved in place because this repo has no _quarto.yml, so Quarto looks for
# _extensions only in the input file's own directory — and copying exercises
# the same layout a user gets from `quarto add`. Local icon paths likewise
# resolve relative to the fixture, so the images must sit beside it.
stage() {
  local dir=$1
  case "$dir" in
    "$work"/*) ;;
    *) echo "refusing to remove a path outside $work: $dir" >&2; return 1 ;;
  esac
  rm -rf "$dir"
  mkdir -p "$dir"
  cp -r "$repo_root/_extensions" "$dir/"
  cp "$repo_root/example-icon.svg" "$repo_root/example-icon.png" "$dir/"
}

# render <dir> <format> <basename> -> 0 on success
render() {
  local dir=$1 fmt=$2 fixture=$3
  local log="$dir/$fixture.$fmt.log"
  (cd "$dir" && quarto render "$fixture.qmd" --to "$fmt") > "$log" 2>&1
  return $?
}

# Derived from the directory rather than hardcoded: a fixture that was staged
# but never listed would otherwise be silently skipped.
fixtures=()
for f in "$repo_root"/tests/fixtures/*.qmd; do
  fixtures+=("$(basename "$f" .qmd)")
done

echo "value-box test matrix"
echo "  quarto $(quarto --version)"
echo "  formats: ${formats[*]}"
echo

# Clear the whole work tree once, so stale output from an earlier run with a
# different format list cannot be mistaken for this run's.
rm -rf "$work"

for fmt in "${formats[@]}"; do
  echo "[$fmt]"
  stage "$work/$fmt" || { fail "stage $fmt" "could not stage $work/$fmt"; continue; }
  cp "$repo_root/tests/fixtures/"*.qmd "$work/$fmt/"

  for fixture in "${fixtures[@]}"; do
    if render "$work/$fmt" "$fmt" "$fixture"; then
      ok "$fixture renders to $fmt"
    else
      fail "$fixture renders to $fmt" "see tests/_work/$fmt/$fixture.$fmt.log"
      # Assertions below would only produce noise once the render itself failed.
      continue
    fi

    log="$work/$fmt/$fixture.$fmt.log"
    assert_absent "value-box warning" "$log" "$fixture/$fmt emits no filter warnings"

    case "$fmt" in
      html|revealjs)
        out="$work/$fmt/$fixture.html"

        # An unset attribute must not produce "height:;" — an invalid
        # declaration browsers discard silently. Both spellings appeared in
        # real output before css_decl was introduced.
        assert_no_empty_css "$out" "$fixture/$fmt emits no empty CSS declarations"

        # The extension's own stylesheet ships as an HTML dependency. Quarto
        # dedupes it by name, so this is a presence check, not a dedupe one.
        assert_present "value-box.css" "$out" "$fixture/$fmt links value-box.css"

        if [ "$fixture" = "icons" ]; then
          # Regression guard: these were once emitted once per box, not once
          # per document.
          assert_count 1 "bootstrap-icons.min.css"  "$out" "$fixture/$fmt links Bootstrap Icons once"
          assert_count 1 "font-awesome/6.5.1"       "$out" "$fixture/$fmt links Font Awesome once"
          assert_count 1 "tabler-icons.min.css"     "$out" "$fixture/$fmt links Tabler once"
          # Assert per-URL rather than per-family. A total of two Material or
          # Phosphor links cannot distinguish "two variants, deduped" from
          # "one variant, duplicated" — checking each variant appears exactly
          # once pins down both halves.
          assert_count 1 "Material+Symbols+Outlined" "$out" "$fixture/$fmt links Material Outlined once"
          assert_count 1 "Material+Symbols+Rounded"  "$out" "$fixture/$fmt links Material Rounded once"
          assert_count 1 "phosphor-icons/web@2.1.2/src/regular" "$out" "$fixture/$fmt links Phosphor regular once"
          assert_count 1 "phosphor-icons/web@2.1.2/src/bold"    "$out" "$fixture/$fmt links Phosphor bold once"
          assert_present "<svg"                     "$out" "$fixture/$fmt inlines the local SVG"
          assert_present 'src="example-icon.png"'   "$out" "$fixture/$fmt references the local PNG"
        fi

        if [ "$fixture" = "minimal" ]; then
          assert_present "Bibbles bobbled"          "$out" "$fixture/$fmt keeps the details text"
          assert_present ">60<"                     "$out" "$fixture/$fmt keeps the value"
        fi

        # The layout fixture drives almost the whole styling surface. These are
        # the checks that make a refactor of the style-building code reviewable
        # rather than a leap of faith.
        if [ "$fixture" = "layout" ]; then
          assert_count 1 "flex-direction:row-reverse"  "$out" "$fixture/$fmt icon-position=right reverses the row"
          assert_count 1 "justify-content:flex-start"  "$out" "$fixture/$fmt valign=top"
          assert_count 1 "justify-content:flex-end"    "$out" "$fixture/$fmt valign=bottom"
          assert_count 1 "margin-right:-0.12em"        "$out" "$fixture/$fmt align=right gets the right optical bearing"
          assert_present 'class="value-box bg-teal"'   "$out" "$fixture/$fmt colour class reaches the wrapper"
          assert_present 'data-fragment-index="2"'     "$out" "$fixture/$fmt fragment index passes through"
          assert_present "fragment fade-in-then-semi-out" "$out" "$fixture/$fmt fragment=true expands to the default effect"
          assert_present "fragment fade-in-then-out"   "$out" "$fixture/$fmt explicit fragment effect passes through"
          assert_present '<a href="https://example.com"' "$out" "$fixture/$fmt href wraps the box in an anchor"
          # These five must be anchored to filter-generated markup. Pandoc
          # echoes unrecognised div attributes back out as data-* attributes,
          # so asserting on the bare user string (e.g. "opacity:0.5") passes
          # even with the filter removed entirely — it tests Pandoc, not us.
          # Each pattern below spans the boundary between something the filter
          # generated and the user's string.
          assert_present "text-align:left; border:2px solid red;" "$out" "$fixture/$fmt outer-extra-style merges into the wrapper style"
          assert_present "font-size:3em; color:white; opacity:0.5;" "$out" "$fixture/$fmt icon-extra-style merges into the icon style"
          assert_present '<div class="vb-content" style="letter-spacing:1px;"' "$out" "$fixture/$fmt content-extra-style merges into the content style"
          assert_present '<div class="details" style="color:white; font-style:italic;"' "$out" "$fixture/$fmt details-extra-style merges into the details style"
          assert_present '<div class="value" style="font-size:2.2rem; color:white; text-decoration:underline;"' "$out" "$fixture/$fmt value-extra-style merges into the value style"

          # Blanked attributes must not suppress a default into "font-size:;".
          assert_present 'style="font-size:3em;  margin-left:-0.12em;"' "$out" "$fixture/$fmt blank icon-color omits the declaration"
        fi
        ;;

      latex)
        out="$work/$fmt/$fixture.tex"

        # Raw HTML must never reach a non-HTML writer. A <link> tag in the
        # preamble is what broke PDF renders before the stylesheets moved to
        # HTML dependencies.
        assert_absent "<link"             "$out" "$fixture/$fmt has no HTML link tags"
        # Currently inert: Pandoc's LaTeX writer drops html RawBlocks outright.
        # It becomes a live check once a native LaTeX representation exists.
        assert_absent 'class="value-box'  "$out" "$fixture/$fmt has no HTML div markup"

        if [ "$fixture" = "minimal" ]; then
          # Body content survives today. The value does not — value boxes have
          # no non-HTML representation yet, so this records current behaviour
          # and should gain a matching value assertion when that lands.
          assert_present "Bibbles bobbled" "$out" "$fixture/$fmt keeps the details text"
        fi
        ;;

      docx)
        if [ "$fixture" = "minimal" ]; then
          # A .docx is a zip; read the document part out of it to assert on.
          xml="$work/$fmt/$fixture.docx.xml"
          unzip -p "$work/$fmt/$fixture.docx" word/document.xml > "$xml" 2>/dev/null
          assert_present "Bibbles bobbled" "$xml" "$fixture/$fmt keeps the details text"
        fi
        ;;
    esac
  done
  echo
done

# The project's long-standing test bar: the demo deck must still build. Staged
# and rendered in the work tree so a test run never touches the tracked
# index.html at the repo root.
echo "[demo deck]"
if stage "$work/demo"; then
  cp "$repo_root/example.qmd" "$work/demo/"
  if render "$work/demo" revealjs example; then
    ok "example.qmd renders to revealjs"
    assert_absent "value-box warning" "$work/demo/example.revealjs.log" "example.qmd emits no filter warnings"
  else
    fail "example.qmd renders to revealjs" "see tests/_work/demo/example.revealjs.log"
  fi
else
  fail "example.qmd renders to revealjs" "could not stage $work/demo"
fi
echo

echo "─────────────────────────────"
printf '%d passed, %d failed\n' "$passed" "$failed"

# A run that checked nothing must not look like a run that passed.
if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
  echo "no checks ran — refusing to report success" >&2
  exit 2
fi

if [ "$failed" -gt 0 ]; then
  echo
  echo "failed checks:"
  for f in "${failures[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
