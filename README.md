# typst-cmp
Small Neovim plugin for creating snippets from imported files

This is a small plugin that finds the imported files and pases them to find top level functions that return components and create luasnip snippets out of them. They are then inserted into the nvim-cmp completion engine.
The plugin supports `#import "@local/test:0.1.0": *` and `#import "test.typ": *` imports

# To install it

If you use Lazy, just add the following lines to your config:
```lua
return {
  'olivierbma/typst-cmp',
  dependencies = {'L3MON4D3/LuaSnip', 'hrsh7th/nvim-cmp'},
}
```

# How to configure

The configuration is very simple, you just need to add this to your config (preferably in your ftplugin folder for typst files)
```lua

require('typst-cmp').setup()

```

# What I want to add

- [x] Recursive imports
- [ ] More configuration options
- [ ] Support for `#import "@preview/test:0.1.1": *`
- [ ] Better support of partial imports (right now `#import "@preview/test:0.1.1": foo` is treated as `#import "@preview/test:0.1.1": *`
- [ ] Async loading and parsing of files
