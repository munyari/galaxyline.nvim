local vim,api = vim,vim.api
local common = require('galaxyline.common')
local M = {}

local function get_git_dir(dir)
  if dir == os.getenv('HOME') then return '' end
  if common.is_dir(dir..'/.git') then
    return dir
  else
    local d = vim.fn.fnamemodify(dir,':h')
    return get_git_dir(d)
  end
end

function M.get_git_branch()
  local current_dir = vim.fn.expand('%:p:h')
  local git_root = get_git_dir(current_dir)
  if string.len(git_root) == 0 then return end
  local git_dir = git_root .. '/.git'

  -- If git directory not found then we're probably outside of repo
  -- or something went wrong. The same is when head_file is nil
  local head_file = git_dir and io.open(git_dir..'/HEAD')
  if not head_file then return end

  local HEAD = head_file:read()
  head_file:close()

  -- if HEAD matches branch expression, then we're on named branch
  -- otherwise it is a detached commit
  local branch_name = HEAD:match('ref: refs/heads/(.+)')

  return branch_name .. ' '
end

-- get diff datas
-- support plugins: vim-gitgutter vim-signify coc-git
local function get_hunks_data()
  -- diff data 1:add 2:modified 3:remove
  local diff_data = {0,0,0}
  if vim.fn.exists('*GitGutterGetHunkSummary') == 1 then
    diff_data[1] = vim.fn.GitGutterGetHunkSummary()
    diff_data[2] = vim.fn.GitGutterGetHunkSummary()
    diff_data[3] = vim.fn.GitGutterGetHunkSummary()
    return diff_data
  elseif vim.fn.exists('*sy#repo#get_stats') == 1 then
    diff_data[1] = vim.fn['sy#repo#get_stats']()[1]
    diff_data[2] = vim.fn['sy#repo#get_stats']()[2]
    diff_data[3] = vim.fn['sy#repo#get_stats']()[3]
    return diff_data
  elseif vim.fn.exists('*coc#rpc#start_server') == 1 then
    local tmp_data = vim.fn.split(api.nvim_buf_get_var(0,'coc_git_status'),' ')
    local flags = {'+','~','-'}
    if #tmp_data ~= 0 then
      for _,v in pairs(tmp_data) do
        for k,flag in pairs(flags) do
          local pos = v:find(flag)
          if pos ~= nil then
            diff_data[k] = v:sub(pos+1,-1)
          end
        end
      end
    end
    return diff_data
  end
  return diff_data
end

function M.diff_add()
  if get_hunks_data()[1] == 0 then return '' end
  return get_hunks_data()[1] .. ' '
end

function M.diff_modified()
  if get_hunks_data()[2] == 0 then return '' end
  return get_hunks_data()[2] .. ' '
end

function M.diff_remove()
  if get_hunks_data()[3] == 0 then return '' end
  return get_hunks_data()[3]
end

return M
