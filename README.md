# buck-vim-plugin

A plugin for VIM and NeoVim to simplify working with buck files

## Features

### Vim

- allows navigation to buck targets

### Neovim

- allows navigation to buck targets
- adds completion extension for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

## Install

### Vim

1. Install this as a plugin into your vim using pathogen on something like that. Or simply copy plugin/buck.vim file to $HOME/.vim/plugin folder

2. Define a hotkey for jumping to a target under cursor, e.g. add following to your .vimrc to bind Ctrl+b for this:

`map <C-b> :exec("BuckOpenTarget")<CR>`

### Neovim

Here are copy-paste snippets for some package managers. Feel free to update the page with instructions for other package managers.
#### LazyVim
```
{
  "srv-meta/buck-vim-plugin",
  config = function()
    vim.keymap.set('n', '<leader>T', vim.fn.BuckOpenTarget, { desc = 'GoTo [T]arget under cursor' })
  end,
},
```


## Buck target autocompletion support
The plugin contains an extension for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp). To enable it, add "srv-meta/buck-vim-plugin" as a dependency to nvim-cmp in your package manager and add 'buck' into its sources list like this:
```
cmp.setup {
    ...
    source = {
        { name = 'nvim_lsp' },
        { name = 'buck' }, -- Should probably be before 'path'
        { name = 'path' },
    }
}
```


## Known issues and TODO:

1. Target name needs to look like 'repo//path/to:target'. If there is no repo in the target name, plugin will not know how to identify it with `buck2 root` command. Not sure if it is enough for all setups, maybe manually searching for .buckconfig is better.

2. Currently plugin implements very simple heuristic to find a path for the repo. It uses path of the current buffer and look for a directory name in it matching 'repo'. This works well when you work in a single repo, but will fail otherwise. To fix this, entries from `[repositories]` block of `.buckconfig` file need to be loaded.

3. Only targets declared directly in TARGETS or BUCK files are found. If a target constructed dynamically using macro, the plugin will not find it. This can be solved by using 'buck targets' command to discover targets, but it will be quite slow. It is possible to add an option enabling this mode.

## Contributing

You are welcome to submit issues, propose ideas and submit PRs. I'd be especially happy to approve PRs fixing the issues from above. 
