local options = {
    ensure_installed = { "lua" },

    highlight = {
        enable = true,
        use_languagetree = true,
    },

    indent = { enable = true },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "<Enter>",
            node_incremental = "<Enter>",
            node_decremental = "<BS>",
        },
    },
}

return options
