local config = require('github-theme.config')
local override = require('github-theme.override')
local keys = { 'palettes', 'specs', 'groups' }
local did_setup = false
local M = {}

local function read_file(filepath)
  local file = io.open(filepath, 'r')
  if file then
    local content = file:read()
    file:close()
    return content
  end
end

local function write_file(filepath, content)
  local file = io.open(filepath, 'wb')
  if file then
    file:write(content)
    file:close()
  end
end

local function resolve_theme(theme, background)
  if theme == 'github' then
    local opts = config.options
    local bg = background or vim.o.background
    theme = bg == 'light' and opts.light_variant or opts.dark_variant
  end

  local themes = require('github-theme.palette').themes
  if not themes[theme] then
    error('invalid theme provided: ' .. tostring(theme))
  end

  return theme
end

function M.reset()
  require('github-theme.config').reset()
  require('github-theme.override').reset()
end

---Compiles all themes/styles with their current settings.
---@param force boolean don't check the saved hash, compile unconditionally (default true)
---@return nil
function M.compile(force)
  local util = require('github-theme.util')
  util.ensure_dir(config.options.compile_path)

  local cached_path = util.join_paths(config.options.compile_path, 'cache')
  local cached = read_file(cached_path)
  local git_path =
    vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1).source:sub(2)), ':p:h:h:h')
  local git = vim.fn.getftime(util.join_paths(git_path, '.git'))

  -- This is needed because neither `opts` nor `config` necessarily contain
  -- everything we need to hash. For example, `opts` may not contain all
  -- overrides and config currently in use (`setup()` might have been called
  -- before, or maybe overrides were set directly and outside of `setup()`), and
  -- `config` does not contain any of the overrides in use. Therefore, we need
  -- to create a new table which contains everything in-use.
  local dummy = { options = config.options }
  for _, k in ipairs(keys) do
    dummy[k] = override[k]
  end

  local hash = require('github-theme.lib.hash')(dummy) .. (git == -1 and git_path or git)

  -- Compile
  if force ~= false or cached ~= hash then
    require('github-theme.lib.log').clear()
    local compiler = require('github-theme.lib.compiler')
    local themes = require('github-theme.palette').themes
    local current_theme = config.theme

    for theme in pairs(themes) do
      -- Compile current theme last (see discussion in #290)
      if theme ~= current_theme then
        compiler.compile({ theme = theme })
      end
    end

    compiler.compile({ theme = current_theme })
    write_file(cached_path, hash)
  end

  getmetatable(override).__index.changed_since_last_compile = false
end

function M.load(opts)
  opts = opts or {}

  if vim.g.github_theme_debug then
    require('github-theme.util.reload')()
  end

  local requested = opts.theme or config.theme
  config.auto_theme = requested == 'github'
  vim.g.github_theme_auto = config.auto_theme or nil
  local theme = resolve_theme(requested, opts.background)
  require('github-theme.config').set_theme(theme)
  vim.g.github_theme_auto_variant = config.auto_theme and theme or nil
  opts.theme = theme

  local _, compiled_file = config.get_compiled_info(opts)
  local compiled_theme = loadfile(compiled_file)

  if not did_setup or override.changed_since_last_compile or not compiled_theme then
    M.setup()
    compiled_theme = loadfile(compiled_file)
  end

  ---@diagnostic disable-next-line: need-check-nil
  compiled_theme()
  if config.auto_theme then
    vim.g.colors_name = 'github'
  end
  require('github-theme.autocmds').set_autocmds()
end

---Applies any new config or overrides then (re)compiles if needed. Does not switch/load
---colorscheme.
---@param opts? GhTheme.Config
function M.setup(opts)
  opts = opts or {}
  did_setup = true

  -- New configs
  if opts.options then
    config.set_options(opts.options)
  end

  for _, k in ipairs(keys) do
    local v = opts[k]
    if v ~= nil then
      override[k] = v
    end
  end

  M.compile(not not vim.g.github_theme_force_compile)

  -- Use our 1 time to check for deprecations the first time `setup()` is called with
  -- opts, instead of the first time `setup()` is called at all.
  if next(opts) ~= nil then
    -- TODO: might be better to call this and emit notices whenever config changes and on
    -- 1st load/setup(), while filtering deprecation messages at the msg level instead of
    -- globally.
    require('github-theme.util.deprecation').check_deprecation(opts)
  end
end

-- Mainly for debugging, testing, development, etc.
for _, env in ipairs({ 'GITHUB_THEME_DEBUG', 'GITHUB_THEME_FORCE_COMPILE' }) do
  if vim.env[env] then
    vim.g[env:lower()] = true
  end
end

return M
