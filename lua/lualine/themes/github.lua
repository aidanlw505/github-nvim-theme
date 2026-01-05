local function resolve_theme()
  if vim.g.github_theme_auto_variant then
    return vim.g.github_theme_auto_variant
  end

  local ok, config = pcall(require, 'github-theme.config')
  if ok then
    local opts = config.options or {}
    local light = opts.light_variant or 'github_light'
    local dark = opts.dark_variant or 'github_dark'

    if config.auto_theme or vim.g.github_theme_auto or vim.g.colors_name == 'github' then
      return vim.o.background == 'light' and light or dark
    end

    if config.theme then
      return config.theme
    end
  end

  return vim.o.background == 'light' and 'github_light' or 'github_dark'
end

return require('github-theme.util.lualine')(resolve_theme())
