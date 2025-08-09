{
  config,
  lib,
  pkgs,
  ...
}: {
  #console.font = "Lat2-Terminus16"; # todo pick
  environment.systemPackages = with pkgs; [
    binutils
    cryptsetup
    dnsutils
    e2fsprogs
    file
    htop
    jq
    libva-utils # for vainfo
    lm_sensors
    lsof
    ncdu
    nfs-utils
    nvd
    nvme-cli
    openssl
    parallel
    parted
    pciutils
    psmisc
    pv
    sbctl
    smartmontools
    tcpdump
    unzip
    usbutils
    virtiofsd
    wget
    wireguard-tools

    age
    ansible
    darkhttpd
    mosh
    nmap
    openvpn
    rsync
    socat
    sqlite
    vbindiff
    whois
    wol
    xclip
    zip

    alejandra
    black # python-black
    cargo
    cloc
    gcc
    git
    gnumake
    lua-language-server
    nil
    nodejs
    pkg-config
    pyright
    python3
    rustc
    rustup
    shellcheck
    tree-sitter
    nixpkgsUnstable.uv # the python package manager
    vim-language-server

    exiftool
    mediainfo

    # https://github.com/buckley310/nixos-config/blob/a05bdb3ee24674bd1df706f881296458f3339c6f/modules/cli.nix#L52
    (writeShellScriptBin "needs-restart" ''
      set -e
      booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
      built="$(readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"
      if [ "$booted" = "$built" ]
      then
          echo OK
          exit 0
      else
          echo REBOOT NEEDED
          exit 1
      fi
    '')
  ];

  nix = {
    generateRegistryFromInputs = true;
    nixPath = lib.attrsets.mapAttrsToList (name: _: "${name}=flake:${name}") config.nix.registry;
  };

  environment = {
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_DESKTOP_DIR = "$HOME/desktop";
      XDG_DOCUMENTS_DIR = "$HOME/library/documents";
      XDG_DOWNLOAD_DIR = "$HOME/downloads";
      XDG_MUSIC_DIR = "$HOME/library/music";
      XDG_PICTURES_DIR = "$HOME/library/pictures";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    variables = {
      HISTCONTROL = "ignoreboth";
      HISTSIZE = "5000";
      HISTTIMEFORMAT = "%Y.%m.%d %T ";
      PATH = "$HOME/.local/bin:$PATH";

      MOSH_TITLE_NOPREFIX = "1";
      PLGO_HOSTNAMEFG = "0";
      PLGO_HOSTNAMEBG = "114";
      KRB5CCNAME = "DIR:/tmp/krb5cc_\${UID}_d/";

      # Hack around lack of XDG base dir spec support
      ANDROID_SDK_HOME = "$XDG_CONFIG_HOME/android";
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
      GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
      GRADLE_USER_HOME = "$XDG_DATA_HOME/gradle";
      HISTFILE = "$XDG_STATE_HOME/bash/history";
      NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
      NODE_REPL_HISTORY = "$XDG_DATA_HOME/node_repl_history";
      NUGET_PACKAGES = "$XDG_CACHE_HOME/nuget-packages";
      PYTHON_HISTORY = "$XDG_STATE_HOME/python/history";
      PYTHONUSERBASE = "$XDG_DATA_HOME/python";
      RANDFILE = "$XDG_DATA_HOME/openssl/rnd";
      TERMINFO = "$XDG_DATA_HOME/terminfo";
      TERMINFO_DIRS = "$XDG_DATA_HOME/terminfo:$TERMINFO_DIRS";
      VIMINIT = ":source $XDG_CONFIG_HOME/vim/vimrc";
      WGETRC = "$XDG_CONFIG_HOME/wget/wgetrc";
      WINEPREFIX = "$XDG_DATA_HOME/wineprefixes/default";
    };
  };

  programs.mtr.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
  };

  programs.bash.interactiveShellInit = ''
    stty -ixon

    TMUXA="`tmux list-sessions -f '#{session_attached}' 2>/dev/null | wc -l`"
    TMUXU="`tmux list-sessions -f '#{?session_attached,0,1}' 2>/dev/null | wc -l`"
    [ "$TMUXA" -gt 0 ] && TMUXAS="\e[92m$TMUXA attached\e[0m"
    [ "$TMUXU" -gt 0 ] && TMUXUS="\e[93m$TMUXU unattached\e[0m"
    [ "$TMUXA" -gt 0 -a "$TMUXU" -gt 0 ] && TMUXAND=","
    [ "$((TMUXA+TMUXU))" -gt 1 -o '(' ! -v TMUX -a "$((TMUXA+TMUXU))" -gt 0 ')' ] && \
        echo -e "tmux sessions: $TMUXAS$TMUXAND $TMUXUS" | sed -re 's/ +/ /g'
    unset TMUXA TMUXU TMUXAS TMUXUS TMUXAND
  '';

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

  boot.binfmt.emulatedSystems = ["aarch64-linux"];
}
