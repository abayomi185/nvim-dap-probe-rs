---@mod dap-probe-rs Probe-rs extension for nvim-dap

local api = vim.api
local M = {}

--- Test runner to use by default.
--- The default value is dynamic and depends on `pytest.ini` or `manage.py` markers.
--- If neither is found "unittest" is used. See |dap-python.test_runners|
--- Override this to set a different runner:
--- ```
--- require('dap-python').test_runner = "pytest"
--- ```
---@type (string|fun():string) name of the test runner
M.test_runner = nil

local function prune_nil(items)
  return vim.tbl_filter(function(x)
    return x
  end, items)
end

local is_windows = function()
  return vim.fn.has("win32") == 1
end

local default_setup_opts = {
  console = "integratedTerminal",
  pythonPath = nil,
}

local function load_dap()
  local ok, dap = pcall(require, "dap")
  assert(ok, "nvim-dap is required to use dap-python")
  return dap
end

local function get_module_path()
  if is_windows() then
    return vim.fn.expand("%:.:r:gs?\\?.?")
  else
    return vim.fn.expand("%:.:r:gs?/?.?")
  end
end

--- Register the probe-rs debug adapter
---@param adapter_probe_rs_path string|nil Path to the python interpreter. Path must be absolute or in $PATH and needs to have the debugpy package installed. Default is `python3`
---@param opts SetupOpts|nil See |dap-python.SetupOpts|
function M.setup(adapter_probe_rs_path, opts)
  local dap = load_dap()

  adapter_probe_rs_path = adapter_probe_rs_path and vim.fn.expand(vim.fn.trim(adapter_probe_rs_path), true)
      or "probe-rs"

  opts = vim.tbl_extend("keep", opts or {}, default_setup_opts)

  dap.adapters["probe-rs-debug"] = function(cb, config)
    if config.request == "launch" then
      cb({
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = adapter_probe_rs_path,
          args = { "dap-server", "--port", "${port}", "--vscode" },
        },
      })
    end
  end

  if opts.include_configs then
    local configs = dap.configurations["probe-rs-debug"] or {}
    dap.configurations["probe-rs-debug"] = configs
    table.insert(configs, {
      name = "Attach to probe-rs process",
      type = "probe-rs-debug",
      request = "attach",
      pid = require("dap.utils").pick_process,
      args = {},
    })
  end
end

local function get_nodes(query_text, predicate)
  local end_row = api.nvim_win_get_cursor(0)[1]
  local ft = api.nvim_buf_get_option(0, "filetype")
  assert(ft == "python", "test_method of dap-python only works for python files, not " .. ft)
  local query = (
    vim.treesitter.query.parse and vim.treesitter.query.parse(ft, query_text)
    or vim.treesitter.parse_query(ft, query_text)
  )
  assert(query, "Could not parse treesitter query. Cannot find test")
  local parser = vim.treesitter.get_parser(0)
  local root = (parser:parse()[1]):root()
  local nodes = {}
  for _, node in query:iter_captures(root, 0, 0, end_row) do
    if predicate(node) then
      table.insert(nodes, node)
    end
  end
  return nodes
end

local function get_function_nodes()
  local query_text = [[
    (function_definition
      name: (identifier) @name) @definition.function
  ]]
  return get_nodes(query_text, function(node)
    return node:type() == "identifier"
  end)
end

local function get_class_nodes()
  local query_text = [[
    (class_definition
      name: (identifier) @name) @definition.class
  ]]
  return get_nodes(query_text, function(node)
    return node:type() == "identifier"
  end)
end

local function get_node_text(node)
  local row1, col1, row2, col2 = node:range()
  if row1 == row2 then
    row2 = row2 + 1
  end
  local lines = api.nvim_buf_get_lines(0, row1, row2, true)
  if #lines == 1 then
    return (lines[1]):sub(col1 + 1, col2)
  end
  return table.concat(lines, "\n")
end

local function get_parent_classname(node)
  local parent = node:parent()
  while parent do
    local type = parent:type()
    if type == "class_definition" then
      for child in parent:iter_children() do
        if child:type() == "identifier" then
          return get_node_text(child)
        end
      end
    end
    parent = parent:parent()
  end
end

local function closest_above_cursor(nodes)
  local result
  for _, node in pairs(nodes) do
    if not result then
      result = node
    else
      local node_row1, _, _, _ = node:range()
      local result_row1, _, _, _ = result:range()
      if node_row1 > result_row1 then
        result = node
      end
    end
  end
  return result
end

--- Strips extra whitespace at the start of the lines
--
-- >>> remove_indent({'    print(10)', '    if True:', '        print(20)'})
-- {'print(10)', 'if True:', '    print(20)'}
local function remove_indent(lines)
  local offset = nil
  for _, line in ipairs(lines) do
    local first_non_ws = line:find("[^%s]") or 0
    if first_non_ws >= 1 and (not offset or first_non_ws < offset) then
      offset = first_non_ws
    end
  end
  if offset > 1 then
    return vim.tbl_map(function(x)
      return string.sub(x, offset)
    end, lines)
  else
    return lines
  end
end

---@class ProbersLaunchConfig
---@field module string|nil Name of the module to debug
---@field program string|nil Absolute path to the program
---@field code string|nil Code to execute in string form
---@field python string[]|nil Path to python executable and interpreter arguments
---@field args string[]|nil Command line arguments passed to the program
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
---@field cwd string|nil Absolute path to the working directory of the program being debugged.
---@field env table|nil Environment variables defined as key value pair
---@field stopOnEntry boolean|nil Stop at first line of user code.

---@class DebugOpts
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
-- -@field config DebugpyConfig Overrides for the configuration

---@class SetupOpts
---@field include_configs boolean|nil Include default configurations. Default is `true`
---@field console DebugpyConsole See |dap-python.DebugpyConsole|
---@field probersPath string|nil Path to probe-rs binary. Uses `adapter_python_path` by default

---@alias DebugpyConsole "internalConsole"|"integratedTerminal"|"externalTerminal"|nil

return M
