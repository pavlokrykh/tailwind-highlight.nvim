# tailwind-highlight.nvim

Made by Opus 4.6 <3

Highlights Tailwind CSS utility classes inside `class="..."` attributes with a
distinct color, so your **custom classes stay visually separate**.

No color swatches, no virtual text — just a different highlight for classes that
Tailwind owns.

<img width="452" height="192" alt="Screenshot 2026-03-11 at 2 44 33 PM" src="https://github.com/user-attachments/assets/fbf0e1d0-8b77-4a16-87c5-9ae682a9d70f" />

## The Problem

```html
<button class="btn btn-success w-full px-4 text-white">
```

Every class looks the same. You can't tell which ones are Tailwind utilities
(`w-full`, `px-4`, `text-white`) and which are your own (`btn`, `btn-success`).

This plugin highlights only the Tailwind classes, leaving your custom ones in
the default string color.

## Install

### lazy.nvim

```lua
{
  "pavlokrykh/tailwind-highlight.nvim",
  ft = { "html", "htmlangular", "typescript", "vue", "svelte", "tsx", "jsx" },
  opts = {},
}
```

### LunarVim

Add to `lvim.plugins`:

```lua
{
  "pavlokrykh/tailwind-highlight.nvim",
  config = function()
    require("tailwind-highlight").setup()
  end,
}
```

## Configuration

All options with defaults:

```lua
require("tailwind-highlight").setup({
  color = "#6db3ab",      -- highlight color
  style = "bold",         -- "bold", "italic", "underline", or combine: "bold,italic"
  filetypes = {           -- file types to activate on
    "html", "htmlangular", "typescript",
    "vue", "svelte", "jsx", "tsx",
  },
})
```

### Popular color presets

| Theme | Hex | Description |
|-------|-----|-------------|
| Tailwind Sky (muted) | `#6db3ab` | (Default) Aqua-mint for dark themes |
| Gruvbox Yellow | `#fabd2f` |  Warm gold |
| Gruvbox Aqua | `#8ec07c` | Minty green |
| Catppuccin Teal | `#94e2d5` | Bright mint |
| Tokyo Night Blue | `#7aa2f7` | Cool blue |

## Commands

| Mapping | Action |
|---------|--------|
| `:lua require("tailwind-highlight").highlight_buffer()` | Refresh highlights |
| `:lua require("tailwind-highlight").clear()` | Clear highlights |
| `:lua require("tailwind-highlight").clear_cache()` | Reset class cache |

## How it works

Pattern matching against all known Tailwind utility prefixes (`flex-`, `bg-`,
`text-`, `p-`, `m-`, `w-`, etc.). Responsive (`sm:`, `lg:`) and state
(`hover:`, `focus:`) prefixes are stripped before matching. Results are cached
per class name for performance.

No LSP dependency — works immediately on file open.

## License

MIT
