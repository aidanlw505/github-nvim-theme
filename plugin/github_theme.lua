local api = vim.api

api.nvim_create_user_command('GithubThemeCompile', function(_info)
  require('github-theme').compile(true)
end, { desc = 'Forcefully recompile settings and persist to fs', force = true })

api.nvim_create_user_command('GithubThemeInteractive', function(_info)
  require('github-theme.interactive').attach()
end, { desc = 'Reload on buffer save', force = true })

local auto_group = api.nvim_create_augroup('github-theme.auto', { clear = true })
api.nvim_create_autocmd('OptionSet', {
  desc = 'Reload github theme on background change',
  pattern = 'background',
  group = auto_group,
  nested = true,
  callback = function()
    if not vim.g.github_theme_auto then
      return
    end

    vim.schedule(function()
      vim.cmd.colorscheme('github')
    end)
  end,
})
