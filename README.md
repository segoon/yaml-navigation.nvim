The goal of the plugin is to provide simple navigation through "gd" for $refs in YAML files.


# Quickstart

## Installation

If you use vim-plug, write the following into your `init.lua` config file:

```lua
plug('segoon/yaml-navigate.nvim')
...
vim.call('plug#end')

require("yaml-navigation").setup()
```

## Usage

Just press gd while being located at $ref value.
