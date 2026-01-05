lua << EOF
local resolver = require('github-theme.util.statusline')
require('github-theme.util.airline')(resolver.resolve_theme())
EOF
