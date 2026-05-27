This is a small filter to allow you to set up value boxes in any Quarto document.

## Installation

You can add this extension to your project by running

```
quarto add bergam0t/quarto-value-box
```

## Usage

First, you must make sure the filter is added to the list of extensions in your document header.

:::warning
Note that it is called 'value-box' when added to your document - not 'quarto-value-box'
:::

```yml
---
format:
  revealjs: default  # this will also work with other web-based formats, such as html
filters:
  - value-box
---
```

:::tip
You could also do

```yml
---
filters:
  - bergam0t/value-box
---
```

if you have another filter extension with the same name!

:::

Now you can create value boxes like so:

```md
::: {.value-box value=60}
Number of bibbles bobbled this week
:::
```

```md
::: {.value-box icon="bi-arrow-down-up" color="bg-blue" width="60%" align="center"}
Here's a more advanced type of box with an icon and some formatting
:::
```


## Customisation

### Colours

A range of colours are supported.

To override in your project, add your own SCSS file and include it after the extension in your _quarto.yml. Quarto loads styles in order, so yours will win:

```yml
format:
  revealjs:
    css: my-colours.scss
```

(swapping revealjs for whatever format you are using, like html)

Your overrides and new colours should be specified like this.

background-color specifies the colour of the box.
color is used for text and icons within the box.

```scss
// Override extension defaults
.bg-blue  { background-color: #1a3f6f; color: white; }

// Add entirely new colours not in the extension
.bg-brand { background-color: #c8102e; color: white; }
```

You can also use SCSS variables if you want to define your palette once and reuse it across your project:
```scss
// my-colours.scss
$brand-primary:   #c8102e;
$brand-secondary: #003087;
$brand-neutral:   #4a4f57;

.bg-brand-primary   { background-color: $brand-primary;   color: white; }
.bg-brand-secondary { background-color: $brand-secondary; color: white; }
.bg-brand-neutral   { background-color: $brand-neutral;   color: white; }
```

### Icon Types

Supported icon types are bootstrap icons (bi) font-awesome (fa), local scalable vector graphics (svg), and local portable network graphics (png).

:::note
If using font-awesome, you will need to include this in your _quarto.yml (or a specific page if you would prefer).

e.g.

```yml
project:
  type: website
  #etc

website:
  title: lokigi
  # etc

format:
  html:
    include-in-header:
      - text: |
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

```

or

```yml
title: "My page"
format:
    html:
        include-in-header:
        - text: |
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
```

:::



### Adding custom background colours





### Contributing



### Generative AI use disclosure and policy

This filter has been written with the help of Claude Sonnet 4.6 and Gemini 3.1 Pro.

All AI-generated code has been thoroughly reviewed and tested before inclusion.

We are happy to accept AI-supported contributions to the extension, but reserve the right to reject wholly AI generated pull requests which are not felt to add value to the project.
