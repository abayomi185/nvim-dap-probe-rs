# nvim-dap-probe-rs

An extension for [nvim-dap][1] providing default configurations for probe-rs for embedded Rust.

## Installation

- Requires Neovim >= 0.5
- Requires [nvim-dap][1]
- Install like any other neovim plugin:
  - If using [vim-plug][6]: `Plug 'abayomi185/nvim-dap-probe-rs'`
  - If using [packer.nvim][7]: `use 'abayomi185/nvim-dap-probe-rs'`
  - If using [lazy.nvim][8]: `{ 'abayomi185/nvim-dap-probe-rs' }`

Load launch.json if using `.vscode/launch.json`, an alternative to DAP configurations.
See `:help dap-launch.json`.

```lua
require("dap.ext.vscode").load_launchjs(nil, { rt_lldb = { "rust" }, ["probe-rs-debug"] = { "rust" } })
```

The mapping from "probe-rs-debug" to "rust" is required.

## Usage

1. Call `setup` in your `init.vim` to register the adapter and configurations:

```vimL
lua require('dap-probe-rs').setup()
```

2. Use nvim-dap as usual.

- Call `:lua require('dap').continue()` to start debugging.
- See `:help dap-mappings` and `:help dap-api`.

### Documentation

See `:help dap-probe-rs`

## Custom configuration

If you call the `require('dap-python').setup` method it will create a few `nvim-dap` configuration entries. These configurations are general purpose configurations suitable for many use cases, but you may need to customize the configurations.

To add your own entries, you can extend the `dap.configurations["probe-rs-debug"]` list after calling the `setup` function:

```vimL
lua << EOF
require('dap-probe-rs').setup()
table.insert(require('dap').configurations["probe-rs-debug"], {
  type = 'probe-rs-debug',
  request = 'launch',
  name = 'My custom Probe-rs launch configuration',
  program = '${file}',
  -- ... more options, see https://probe.rs/docs/tools/debugger/#launch%3A-supported-configuration-options.
})
EOF
```

[1]: https://github.com/mfussenegger/nvim-dap
[4]: https://github.com/nvim-treesitter/nvim-treesitter
[5]: https://github.com/tree-sitter/tree-sitter-python
[6]: https://github.com/junegunn/vim-plug
[7]: https://github.com/wbthomason/packer.nvim
[8]: https://github.com/folke/lazy.nvim
