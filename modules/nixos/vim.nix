{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    configure = {
      packages.sconfig.start = with pkgs.vimPlugins; [
        vim-bracketed-paste
        vim-gitgutter
        vim-nix

        ale
        nvim-cmp
        nvim-lspconfig
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lsp-document-symbol
        cmp-nvim-lsp-signature-help
        cmp-treesitter
        cmp-vsnip
        vim-vsnip
      ];
      customRC = ''
        scriptencoding utf-8
        set background=dark
        set colorcolumn=120
        set encoding=utf-8
        set expandtab
        set ignorecase
        set incsearch
        set list
        set list listchars=tab:»\ ,extends:›,precedes:‹,nbsp:␣
        set mouse=
        set nowrap
        set number
        set scrolloff=8
        let &showbreak='↪ '
        set sidescroll=1
        set sidescrolloff=15
        set smartcase
        set tabstop=4
        set textwidth=99
        set shiftwidth=4
        highlight ColorColumn ctermbg=0
        map <F8> <Esc>:w<CR>:!clear<CR>:! time ./%<CR>
        noremap <F1> <Esc>
        inoremap <F1> <Esc>
        autocmd FileType make setlocal noexpandtab
        let mapleader=","

        " Append modeline after last line in buffer
        " Use substitute() instead of printf() to handle '%%s' modeline in LaTeX files
        function! AppendModeline()
            let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
                    \ &tabstop, &shiftwidth, &textwidth, &expandtab ? "" : "no")
            let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
            call append(line("$"), l:modeline)
        endfunction
        nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

        highlight ExtraWhitespace ctermbg=red guibg=red
        match ExtraWhitespace /\s\+$/
        autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
        autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
        autocmd InsertLeave * match ExtraWhitespace /\s\+$/
        autocmd BufWinLeave * call clearmatches()

        let g:ale_fixers = { "python": ["black", "isort"] }

        lua <<EOF
          local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
          end
          local feedkey = function(key, mode)
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
          end

          local cmp = require 'cmp'
          cmp.setup({
            snippet = {
              expand = function(args)
                vim.fn["vsnip#anonymous"](args.body)
              end,
            },
            mapping = {
              --[[ ["<CR>"] = cmp.mapping({
                i = function(fallback)
                  if cmp.visible() and cmp.get_active_entry() then
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                  else
                    fallback()
                  end
                end,
                s = cmp.mapping.confirm({ select = true }),
                c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
              }), ]]
              ['<CR>'] = cmp.mapping.confirm({ select = false }),
              ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                  else
                    cmp.select_next_item()
                  end
                elseif vim.fn["vsnip#available"](1) == 1 then
                  feedkey("<Plug>(vsnip-expand-or-jump)", "")
                elseif has_words_before() then
                  cmp.complete()
                  if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                  end
                else
                  fallback()
                end
              end, { "i", "s" }),
              ["<S-Tab>"] = cmp.mapping(function()
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                  feedkey("<Plug>(vsnip-jump-prev)", "")
                end
              end, { "i", "s" }),
            },
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'vsnip' },
              { name = 'treesitter' },
              { name = 'nvim_lsp_signature_help' },
            }, {
              { name = 'buffer' },
            })
          })

          cmp.setup.cmdline({ '/', '?' }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'nvim_lsp_document_symbol' },
            }, {
              { name = 'buffer' },
            }),
          })
          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'path' },
            }, {
              { name = 'cmdline' },
            }),
            matching = { disallow_symbol_nonprefix_matching = false },
          })

          local capabilities = require('cmp_nvim_lsp').default_capabilities()
          vim.lsp.config('luals', { capabilities = capabilities })
          vim.lsp.enable('luals')
          vim.lsp.config('nil_ls', { capabilities = capabilities })
          vim.lsp.enable('nil_ls')
          vim.lsp.config('pyright', { capabilities = capabilities })
          vim.lsp.enable('pyright')
          vim.lsp.config('vimls', { capabilities = capabilities })
          vim.lsp.enable('vimls')
        EOF
      '';
    };
  };
}
