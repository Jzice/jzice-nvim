#!/usr/bin/env lua

-- freefly/init.lua
-- Copyright (C) 2021 justice <justice@zhouzhenyideMacBook-Pro.local>
--
-- Distributed under terms of the MIT license.
--
local M = {}

local fn = vim.fn
local cmd = vim.cmd
local g = vim.g

-- options --
local options = {
    theme = 'molokai',
    settings = {
        mapleader = ',',            -- <leader>为,
        so = 999,                    -- 滚动居中

        molokai_original = 1,
        rehash256 = 1,
        nobg256 = 1,

        cursorhold_updatetime = 100,
        startify_session_dir = '~/.vim/session',

        -- leetcode --
        leetcode_china = 1,
        leetcode_username = "<leetcode_username>",
        leetcode_solution_filetype = "python3",
        leetcode_browser = "chrome",

        -- any-jump --
        any_jump_disable_default_keybindings = 0,              --默认快捷键
        any_jump_references_only_for_current_filetype = 1,     --只查找同类型文件
        any_jump_ignored_files = { '*.tmp', '*.temp', 'vendor/*', "node_modules/*" },

        --- startify ---
        startify_custom_header = {'Startify:'},
        startify_list_order = {
            { '   Recently directory:' },
            'dir',
            { '   Recent files' },
            'files',
            {'   Sessions:'},
            'sessions',
            {'   Bookmarks:'},
            'bookmarks',
        },

        -- symbols-outline
        symbols_outline = { width = 20, },

        -- undotree --
        undotree_WindowLayout = 3,  -- right panel

        -- vim-rooter
        rooter_patterns = {'.git', 'node_modules', 'Cargo.toml', '.svn', 'Makefile', 'README.md'},
        rooter_change_directory_for_non_project_files = 'current',

        -- git-blame.nvim --
        gitblame_enabled = 0,

        -- goldenview --
        goldenview__enable_at_startup = 0,
        goldenview__enable_default_mapping = 0,

        -- limelight
        goyo_width = '90%',
        limelight_conceal_ctermfg = 'gray',
        limelight_conceal_guifg = 'DarkGray',
        limelight_default_coefficient = 0.7,
        limelight_paragraph_span = 1,

        -- vim-rest-client --
        vrc_trigger = '<C-i>',
        vrc_elasticsearch_support = 1,
        vrc_output_buffer_name = '__VRC_OUTPUT.json',
        vrc_connect_timeout = 10,
        vrc_split_request_body = 0,
        vrc_auto_format_uhex = 1,          --"汉字,

        -- floaterm --
        floaterm_keymap_toggle = '<Leader>tt',         -- 切换浮动终端
        floaterm_keymap_new = '<Leader>tc',            -- 新建浮动终端
        floaterm_keymap_prev = '<Leader>tp',           -- 前一个终端窗口
        floaterm_keymap_next = '<Leader>tn',           -- 后一个终端窗口
    },

    packer = {
        git = {
            default_url_format = 'git@github.com:%s',
        },
    }
}

--- packer init ---
local function packer_init()
    local packer_git_url = 'https://github.com/wbthomason/packer.nvim'
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
          packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', packer_git_url, install_path})
    end
    cmd 'packadd packer.nvim'
end

packer_init()

--- basic settings ---
local function basic_settings()
    --- options.settings ---
    for k, v in pairs(options.settings) do
        g[k] = v
    end
    -- vim.o.termguicolors = false

    -- cmd 'autocmd FileType startify normal zR'
    cmd('colorscheme '..options.theme)

    cmd [[
        augroup Limelight
            autocmd! User GoyoEnter Limelight
            autocmd! User GoyoLeave Limelight!
        augroup END
    ]]

    -- nvim-lightbulb --
    cmd 'autocmd CursorHold,CursorHoldI * lua require"nvim-lightbulb".update_lightbulb() '
end

--- dap settings ---
local function dap_setup()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_virtual_text = require("nvim-dap-virtual-text")

    dap_virtual_text.setup()

    dapui.setup({ sidebar = { position = "right" } })
    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
        dap.repl.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
        dap.repl.close()
    end

    local dap_config = {
        --python = require("dap.python"),
        --go = require("dap.go"),
    }

    for dap_name, dap_options in pairs(dap_config) do
        dap.adapters[dap_name] = dap_options.adapters
        dap.configurations[dap_name] = dap_options.configurations
    end

    vim.fn.sign_define("DapBreakpoint", {text = "⊚", texthl = "TodoFgFIX", linehl = "", numhl = ""})

 end

-- lsp config --
local function lsp_setup()
    local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

    local lsp_installer = require("nvim-lsp-installer")
    lsp_installer.setup {
        ensure_installed = {'sumneko_lua', 'gopls', 'rust_analyzer', 'clangd', 'vimls', 'bashls'},
        automatic_installation = true,
    }
    local lsp_servers = require('nvim-lsp-installer.servers').get_installed_server_names()
    local lsp_cfg = require('lspconfig')
    local lsp_signature = require('lsp_signature')
    for _, lsp_name in pairs(lsp_servers) do
        lsp_cfg[lsp_name].setup{
            on_attach = function(client, bufnr)
                lsp_signature.on_attach(client, bufnr)
            end,
            capabilities = capabilities,
            flags = {
                debounce_text_changes = 150,
            }
        }
    end
end

local function nvim_cmp_setup()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    local lspkind = require('lspkind')
    local cmp_under_comparator = require("cmp-under-comparator")
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')

    local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({  map_char = { tex = '' } }))
    cmp.setup({
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body) -- For `luasnip` users.
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ['<C-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
            ['<C-k>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
            ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
            ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.config.disable,
            ['<C-e>'] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close(), }),
            ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true, })
        }),
        sorting = {
            comparators = {
                cmp.config.compare.offset,
                cmp.config.compare.exact,
                cmp.config.compare.score,
                cmp.config.compare.recently_used,
                cmp_under_comparator.under,
                cmp.config.compare.kind,
                cmp.config.compare.sort_text,
                cmp.config.compare.length,
                cmp.config.compare.order
            }
        },
        formatting = {
            format = lspkind.cmp_format({
                with_text = true,
                maxwidth = 50,
                before = function(entry, vim_item)
                    vim_item.menu = "[" .. string.upper(entry.source.name) .. "]"
                    return vim_item
                end
            })
        },
        preselect = cmp.PreselectMode.Item,
        sources = cmp.config.sources({
            { name = 'orgmode' },
            { name = 'buffer' },
            { name = 'cmdline' },
            { name = 'luasnip' },
            { name = 'nvim_lsp' },
            { name = 'path' },
            -- { name = 'vsnip' }, -- For vsnip users.
            { name = 'nvim_lsp_signature_help' }, -- For vsnip users.
        })
    })
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({{ name = 'path' }}, {{ name = 'cmdline' }})
    })

end

-- register plugin --
local registered_plugins = {}
local function register_plugin(plugin, config)
    config = config or {}
    table.insert(registered_plugins, {['name']=plugin, ['config']=config})
end

-- setup registered_plugins
local function setup_plugins()
    for _, plugin in pairs(registered_plugins) do
        local ok, m = pcall(require, plugin['name'])
        if not ok then
            vim.notify('Setup '..plugin['name']..' failed', 'error')
        else
            m.setup()
        end
    end
end

--- plugin config ---
local function plugin_config()
    nvim_cmp_setup()
    lsp_setup()
    dap_setup()

    setup_plugins()

    -- nvim-tree --
    require("nvim-tree").setup({
        auto_close = true,
        update_cwd = true,
        update_focused_file = {
            enable = true,
            update_cwd = true
        },
    })

    -- buffer label --
    require("bufferline").setup({
        options = {
            numbers = "ordinal",
            diagnostics = "nvim_lsp",
            separator_style = "thin",
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    highlight = "Directory",
                    text_align = "left"
                }
            },
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local s = " "
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and " " or (e == "warning" and " " or "")
                    s = s .. n .. sym
                end
                return s
            end
        }
    })

    -- telescope config --
    local telescope_actions = require("telescope.actions")
    require("telescope").setup{
        extensions = {
            ["ui-select"] = {
                require("telescope.themes").get_dropdown {
                },
            },
        },
        defaults = {
            mappings = {
                i = {
                    ["<C-j>"] = telescope_actions.move_selection_next,
                    ["<C-k>"] = telescope_actions.move_selection_previous,
                },
            },
        }
    }
    require('telescope').load_extension('ui-select')
    require('telescope').load_extension('lazygit')

    require('lspsaga').init_lsp_saga()

    -- nvim.treesitter --
    require('nvim-treesitter.configs').setup{
        ensure_installed = { 'org', 'markdown', 'rst', "go", "lua", "toml", "yaml", "json", "bash", "cpp", "python", "rust", "vim"},
        sync_install = false,
        ignore_install = { "javascript" },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = {'org'},
        },
        matchup = { enable = true,}, --matchup
        rainbow = {
            enable = true,
            extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
            max_file_lines = nil, -- Do not enable for files with more than n lines, int
        }
    }

    require("lsp_signature").setup({
        bind = true,
        handler_opts = { border = "rounded" },
        floating_window = true,         -- 自动触发
        toggle_key = '<C-j>',           --
        hint_enable = true,             -- 虚拟提示关闭
        hi_parameter = "LspSignatureActiveParameter"
    })

     -- comment --
    local comment_string = require("ts_context_commentstring")
    require("Comment").setup(
        {
            toggler = { line = "<leader>cc", block = "<leader>bc" }, -- 切换行/块注释
            opleader = { line = "<leader>c<space>", block = "<leader>b<space>" },     -- 可视模式下的行/块注释
            extra = { above = "<leader>ca", below = "<leader>cb", eol = "<leader>cl" }, -- 在当前行上/下/尾方新增行注释
            pre_hook = function(ctx)
                if vim.bo.filetype == "typescriptreact" then
                    local U = require("Comment.utils")
                    local type = ctx.ctype == U.ctype.line and "__default" or "__multiline"
                    local location = nil
                    if ctx.ctype == U.ctype.block then
                        location = comment_string.utils.get_cursor_location()
                    elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
                        location = comment_string.utils.get_visual_start_location()
                    end
                    return comment_string.calculate_commentstring(
                    {
                        key = type,
                        location = location
                    }
                    )
                end
            end
        }
    )

    -- orgmode --
    local orgmode = require('orgmode')
    orgmode.setup_ts_grammar()
    orgmode.setup({
        org_agenda_files = {'~/notebook/org/*'},
        org_default_notes_file = '~/notebook/org/refile.org',
        mappings = {
            global = {
                org_agenda = {'<Leader>oa'},
                org_capture = {'<Leader>oc'}
            }
        }
    })

    -- notify --
    vim.notify = require("notify")
    vim.notify.setup({
        stages = "fade_in_slide_out",
        timeout = 2000,
        background_colour = "#ffffff",
    })

end

--- keymap ---
local function keymap_config()
    local keymap = vim.api.nvim_set_keymap
    local silent_opts = { noremap= true,silent=true}

    -- basic --
    keymap('n', '<F2>', ':NvimTreeToggle<CR>', silent_opts)         -- 切换文件浏览
    keymap('n', '<F3>', ':SymbolsOutline<CR>', silent_opts)         -- 切换符号大纲
    keymap('n', '<F4>', ':UndotreeToggle<CR>', silent_opts)         -- 操作历史

    keymap('n', '<leader>k', ':WhichKey<CR>', silent_opts)             -- WhichKey
    keymap('n', '<leader><space>', ':FixWhitespace<CR>', silent_opts)   -- 清除尾部空格

    -- telescope --
    keymap('n', '<C-p>', ':Telescope find_files<CR>', silent_opts)                      -- 查找文件
    keymap('n', '<C-]>', ':Telescope lsp_definitions<CR>', silent_opts)                 -- 跳转到定义
    keymap('n', '<leader>gr', ':Telescope lsp_references<CR>', silent_opts)             -- 跳转到引用
    keymap('n', '<leader>gi', ':Telescope lsp_implementations<CR>', silent_opts)        -- 跳转到实现
    keymap('n', '<leader>fw', ':Telescope lsp_workspace_symbols theme=dropdown<CR>', silent_opts)  --查找workspace symbols
    keymap('n', '<leader>ff', ':Telescope live_grep<CR>', silent_opts)                  -- 查找输入单词
    keymap('n', '<leader>fg', ':Telescope grep_string<CR>', silent_opts)                -- 查找光标下单词
    keymap('n', '<leader>fb', ':Telescope buffers theme=dropdown<CR>', silent_opts)     -- 查找buffer
    keymap('n', '<leader>fc', ':Telescope command_history theme=dropdown<CR>', silent_opts)    -- 查找命令
    keymap('n', '<leader>fC', ':Telescope commands theme=dropdown<CR>', silent_opts)    -- 查找命令

    -- anyjump --
    keymap('n', '<leader>gj', ':AnyJump<CR>', silent_opts)                              -- anyjump grep 跳转
    keymap('v', '<leader>gj', ':AnyJumpVisual<CR>', silent_opts)                        -- 跳转
    keymap('n', '<leader>gb', ':AnyJumpBack<CR>', silent_opts)
    keymap('n', '<leader>gl', ':AnyJumpLastResult<CR>s', silent_opts)

    -- lspsaga --
    keymap('n', 'K', ':Lspsaga hover_doc<CR>', silent_opts)                             -- 显示文档
    keymap('n', '<leader>rn', ':Lspsaga rename<CR>', silent_opts)                       -- 重命名
    keymap('n', '<leader>fl', ':Lspsaga lsp_finder<CR>', silent_opts)                   -- lsp 查找
    keymap('n', '<leader>fi', ':Lspsaga implement<CR>', silent_opts)                    -- 查找实现
    keymap('n', '<leader>fd', ':Lspsaga preview_definition<CR>', silent_opts)
    keymap('n', '<leader>fh', ':Lspsaga signature_help<CR>', silent_opts)

    -- hop --
    keymap('n', 'ff', "<cmd>HopWord<CR>", silent_opts)        -- 跳转到word, ff
    keymap('n', 'fl', "<cmd>HopLine<CR>", silent_opts)        -- 跳转到line, fl
    keymap('n', 'fc', "<cmd>HopChar1<CR>", silent_opts)       -- 跳转到char, fc

    -- buffer --
    keymap('n', '<leader>bn', "<cmd>BufferLineCycleNext<CR>", silent_opts)
    keymap('n', '<leader>bp', "<cmd>BufferLineCyclePrev<CR>", silent_opts)
    keymap('n', '<leader>bh', "<cmd>BufferLineCloseLeft<CR>", silent_opts)
    keymap('n', '<leader>bl', "<cmd>BufferLineCloseRight<CR>", silent_opts)
    keymap('n', '<leader>bd', "<cmd>Bdelete!<CR>", silent_opts)

    -- translator --
    keymap('n', '<leader>tw', "<Plug>TranslateW", silent_opts)
    keymap('v', '<leader>tw', "<Plug>TranslateWV", silent_opts)
    keymap('n', '<leader>tr', "<Plug>TranslateR", silent_opts)
    keymap('v', '<leader>tr', "<Plug>TranslateWRV", silent_opts)

    -- todo --
    keymap('n', '<leader>to', "<cmd>TodoTelescope theme=dropdown<CR>", silent_opts)

    -- vim-easy-align
    keymap('v', '<leader>a', "<Plug>(EasyAlign)", silent_opts)
    keymap('n', '<leader>a', "<Plug>(EasyAlign)", silent_opts)

    -- vim-expand-region
    keymap('v', 'v', "<Plug>(expand_region_expand)", silent_opts)  --扩展选择范围
    keymap('v', 'V', "<Plug>(expand_region_shrink)", silent_opts)  --缩小选择范围

    -- dap --
    keymap('n', '<leader>dt', "<cmd>lua require'dapui'.toggle()<CR>", silent_opts) -- 显示或隐藏调试界面
    keymap('n', '<leader>db', "<cmd>lua require'dap'.toggle_breakpoint()<CR>", silent_opts) -- 打断点
    keymap('n', '<leader>dc', "<cmd>lua require'dap'.continue()<CR>", silent_opts) -- 开启调试或到下一个断点处
    keymap('n', '<leader>dn', "<cmd>lua require'dap'.step_into()<CR>", silent_opts) -- 单步进入执行（会进入函数内部，有回溯阶段）
    keymap('n', '<leader>do', "<cmd>lua require'dap'.step_out()<CR>", silent_opts) -- 步出当前函数
    keymap('n', '<leader>dv', "<cmd>lua require'dap'.step_over()<CR>", silent_opts) -- 单步跳过执行（不进入函数内部，无回溯阶段）
    keymap('n', '<leader>dr', "<cmd>lua require'dap'.run_last()<CR>", silent_opts) -- 重启调试
    keymap('n', '<leader>dc', "<cmd>lua require'dap'.close()<CR><cmd>lua require'dap.repl'.close()<CR><cmd>lua require'dapui'.close()<CR><cmd>DapVirtualTextForceRefresh<CR>", silent_opts) -- 退出调试（关闭调试，关闭 repl，关闭 ui，清除内联文本）

end

--- setup ---
function M.setup(opts)
	options = vim.tbl_deep_extend('force', options, opts or {})
    require("packer").startup({
        config = {
            compile_on_sync = false,
            git = { default_url_format = options.packer.git.default_url_format },
            display = {
                open_fn = function()
                    return require("packer.util").float({ border = 'single' })
                end
            },
        },
        function()
            --- packer ---
            use {'wbthomason/packer.nvim' }

            --- basic setting --
            use {
                'ZhuZhengyi/vim-colorschemes',      -- theme
                'ZhuZhengyi/vim-better-default',    -- basic default
            }

            --- ui --
            use {
                {'airblade/vim-rooter'},                            -- 切换project 目录
                {'antoinemadec/FixCursorHold.nvim'},                -- fix cursor perferm bug
                {'mhinz/vim-startify'},                                 -- 个性化启动画面
                {'lukas-reineke/indent-blankline.nvim'},                -- 缩进对齐线
                {'p00f/nvim-ts-rainbow'},                               -- rainbow
                {'simrat39/symbols-outline.nvim' },                     --符号大纲
                {'liuchengxu/vista.vim', opt=true, cmd={'Vista', 'Vista!!'}},     -- 大纲列表
                {'nvim-lualine/lualine.nvim', requires = {'kyazdani42/nvim-web-devicons'}, register_plugin('lualine')},  -- 状态栏
                {'kyazdani42/nvim-tree.lua', requires = {'kyazdani42/nvim-web-devicons'}}, -- file explorer
                {"akinsho/bufferline.nvim", requires = {"famiu/bufdelete.nvim" }}, --buffer
                {"lewis6991/gitsigns.nvim", requires = {"nvim-lua/plenary.nvim" }, register_plugin('gitsigns') },
                {"rcarriga/nvim-notify" },                               -- 通知
                {'Jzice/nvim-lsp-notify', requires={'rcarriga/nvim-notify'}, register_plugin('nvim-lsp-notify') },           -- lsp notify
            }

            --- lsp ---
            use {
                'neovim/nvim-lspconfig',            -- lsp配置
                'williamboman/nvim-lsp-installer',  -- lsp installer
                'onsails/lspkind.nvim',             -- lsp图标
                'nvim-treesitter/nvim-treesitter',  -- lsp语法高亮
                'kosayoda/nvim-lightbulb',          -- "灯泡提示
                'ray-x/lsp_signature.nvim',         -- lsp签名

                'tami5/lspsaga.nvim',               -- lsp 显示
                'pechorin/any-jump.vim',            -- any jump

                {'nvim-telescope/telescope.nvim', requires = {'nvim-lua/plenary.nvim'} },                   -- 查找()
                {'nvim-telescope/telescope-symbols.nvim', requires = {'nvim-telescope/telescope.nvim'}, },  --
                {'nvim-telescope/telescope-ui-select.nvim', requires = {'nvim-telescope/telescope.nvim'}},
            }

            --- complete ---
            use {
                -- nvim-cmp --
                'hrsh7th/nvim-cmp',                     -- nvim自动补全

                -- cmp source --
                'hrsh7th/cmp-nvim-lsp',                 -- cmp lsp source
                'hrsh7th/cmp-buffer',                   -- cmp buffer source
                'hrsh7th/cmp-path',                     -- cmp path source
                'hrsh7th/cmp-cmdline',                  -- cmp cmdline source
                'hrsh7th/cmp-nvim-lsp-signature-help',  -- cmp signature_help source
                'hrsh7th/cmp-vsnip',                    -- cmp snip source
                'saadparwaiz1/cmp_luasnip',

                'lukas-reineke/cmp-under-comparator',   -- sort comparator

                -- snippet --
                'L3MON4D3/LuaSnip',                     -- lua snip
                'hrsh7th/vim-vsnip',                    -- vs snip
                'rafamadriz/friendly-snippets',         -- friendly snip

                'mfussenegger/nvim-jdtls',
                {'simrat39/rust-tools.nvim', register_plugin('rust-tools')},
            }

            --- tools ---
            use {
                {'kenn7/vim-arsync', cmd = {'ARSyncUp', 'ARSyncDown', 'ARSyncUpDelete'} },  -- remote rsync
                {'nvim-orgmode/orgmode' },          -- orgmode
                {'voldikss/vim-floaterm',},         -- "浮动终端
                {'hrsh7th/vim-eft', },              -- Faster jump with j,k

                {'tpope/vim-fugitive'} ,            -- git 增强
                {'f-person/git-blame.nvim'},        -- git blame
                {'kdheepak/lazygit.nvim'},          -- lazygit
                {'mattn/gist-vim'},                 -- gist
                {'mbbill/undotree'},                -- undo列表, :UndoTree

                {'zhaocai/GoldenView.Vim'},     -- "分割窗口优化
                {'junegunn/goyo.vim', requires={'junegunn/limelight.vim'}, cmd={'Goyo'}},    -- "专注模式: Goyo
                {'amix/vim-zenroom2', requires={'junegunn/goyo.vim'}},          -- "ia writer
            }

            -- - others ---
            use {
                {'takac/vim-hardtime'},             -- 增强jk
                {'junegunn/vim-easy-align' },       -- 快速对齐
                {'terryma/vim-expand-region'},      -- "区域选择, v/V改变选取大小
                {'sbdchd/neoformat'},               -- "代码格式化 :Neoformat
                {"numToStr/Comment.nvim", requires = {"JoosepAlviste/nvim-ts-context-commentstring"} },
                {'ianding1/leetcode.vim'},          -- "leetcode
                {'chrisbra/NrrwRgn', },             --"选择部分区域编辑
                {'voldikss/vim-translator'},        -- "翻译: <Leader>tw
                {'tpope/vim-surround'},               -- "标签替换, cs'
                {'tpope/vim-repeat'},                 -- "重复命令， .'
                {'vim-scripts/DrawIt'},               -- "绘图
                {'mg979/vim-visual-multi'},           -- 多光标编辑
                {'t9md/vim-choosewin'},               -- "win 跳转,
                {"phaazon/hop.nvim", register_plugin('hop')},  --快速跳转光标位置, <leader>hw

                {'tpope/vim-dispatch', opt = true, cmd = {'Dispatch', 'Make', 'Focus', 'Start'}},
                {'andymass/vim-matchup', event = 'VimEnter'},    -- 匹配
                {'windwp/nvim-autopairs', register_plugin('nvim-autopairs') },    -- 自动增加匹配符号
                -- {'norcalli/nvim-colorizer.lua', register_plugin('colorizer') },   -- 显示彩色
                {'folke/which-key.nvim', register_plugin('which-key')},     -- 显示快捷键
                {"folke/todo-comments.nvim", requires = {'nvim-lua/plenary.nvim'}, register_plugin('todo-comments') }, -- TODO: 列表
                { 'bronson/vim-trailing-whitespace', },     -- "消除行尾空格, <CTRL+SPACE>
                { 'Konfekt/FastFold', },                    -- "加速代码折叠
                { 'pseewald/vim-anyfold', },                -- "代码折叠
            }

            -- filetype --
            use {
                {'vimwiki/vimwiki' },              --{'for': ['vimwiki']}
                {'NoorWachid/VimVLanguage', ft = {'v', 'vlang'}},
                {'saltstack/salt-vim', ft = {'sls', 'salt'}},
                {'Glench/Vim-Jinja2-Syntax', ft = {'sls', 'jinja2', 'html'} },    --
            }

            -- dap --
            use {
                {"mfussenegger/nvim-dap"},     -- debug adapters
                {"theHamsta/nvim-dap-virtual-text", requires = { "mfussenegger/nvim-dap" }, },
                {"rcarriga/nvim-dap-ui", requires={"mfussenegger/nvim-dap"}, },
                {"leoluz/nvim-dap-go", requires={'mfussenegger/nvim-dap'}, register_plugin("dap-go") },
                {"mfussenegger/nvim-dap-python", requires={'mfussenegger/nvim-dap'} , register_plugin("dap-python")},
            }
        end
    })

    basic_settings()
    plugin_config()
    keymap_config()
end

return M
