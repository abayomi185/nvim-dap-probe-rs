---@mod dap-probe-rs Probe-rs extension for nvim-dap

local M = {}

local default_setup_opts = {}

local function load_dap()
  local ok, dap = pcall(require, "dap")
  assert(ok, "nvim-dap is required to use dap-probe-rs")
  return dap
end

--- Register the probe-rs debug adapter
---@param adapter_probe_rs_path string|nil Path to probe-rs binary. Path must be absolute or in $PATH. Default is `probe-rs`
---@param opts SetupOpts|nil See |dap-probe-rs.SetupOpts|
function M.setup(adapter_probe_rs_path, opts)
  local dap = load_dap()

  adapter_probe_rs_path = adapter_probe_rs_path and vim.fn.expand(vim.fn.trim(adapter_probe_rs_path), true)
      or "probe-rs"

  opts = vim.tbl_extend("keep", opts or {}, default_setup_opts)

  dap.adapters["probe-rs-debug"] = function(callback, config)
    if config.request == "launch" then
      callback({
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

---@class ProbersLaunchConfig
---@field module string|nil Name of the module to debug
---@field program string|nil Absolute path to the program
---@field code string|nil Code to execute in string form
---@field args string[]|nil Command line arguments passed to the program
---@field cwd string|nil Absolute path to the working directory of the program being debugged.
---@field env table|nil Environment variables defined as key value pair
---@field stopOnEntry boolean|nil Stop at first line of user code.

---@class SetupOpts
---@field include_configs boolean|nil Include default configurations. Default is `true`

return M
