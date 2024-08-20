# buck-vim-plugin

A plugin for VIM and NeoVim to simplify working with buck files

## Features

### Vim

- allows navigation to buck targets

### Neovim

- allows navigation to buck targets
- adds completion extension for nvim-cmp

## Install

### Vim

1. Install this as a plugin into your vim using pathogen on something like that. Or simply copy all the contents to your .vimrc

2. Define a hotkey for jumping to a target under cursor, e.g. add following to your .vimrc to bind Ctrl+b for this:

`map <C-b> :exec("BuckOpenTarget")<CR>`

### Neovim

It is easiest to use some package manager. Feel free to add snippets here for other package managers
#### LazyVim
{
  "srv-meta/buck-vim-plugin",
  config = function()
    vim.keymap.set('n', '<leader>T', vim.fn.BuckOpenTarget, { desc = 'GoTo [T]arget under cursor' })
  end,
},


## Buck target autocompletion support
The plugin contains an extention for nvim-cmp. To enable it, add "srv-meta/buck-vim-plugin" as a dependency to nvim-cmp and add 'buck' into its sources list like:
cmp.setup {
    ...
    source = {
        { name = 'nvim_lsp' },
        { name = 'buck' }, -- Should be before 'path' if you use it
        { name = 'path' },
    }
}

## Known issues and TODO:

1. Target name needs to have match 'repo//path/to:target'. If there is no repo in the target name, plugin will not now how to find it. This can be fixed by supporting default_repo_path option.

2. Currently plugin implements very simple heuristic to find a path for the repo. It uses path of the current buffer and look for a directory name in it matching 'repo'. This works well when you work in a single repo, but will fail otherwise. To fix this, support for a custom lookup table in the parameters can be added. Or maybe even some smart repo discovery logic.

3. Only targets declared directly in TARGETS or BUCK files are found. If a target constructed dynamically using macro, the plugin will not find it. This can be solved by using 'buck targets' command to discover targets, but it will be quite slow. It is possible to add an option enabling this mode.

4. Target details popup contains first few lines of the file where it is declared. This should contain part of the file with target definition instead.

## Contributing

You are welcome to submit issues, propose ideas and submit PRs. I'd be very especially happy to approve PRs fixing the issued from above. 
