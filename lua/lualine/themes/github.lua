local resolver = require('github-theme.util.statusline')

return require('github-theme.util.lualine')(resolver.resolve_theme())
