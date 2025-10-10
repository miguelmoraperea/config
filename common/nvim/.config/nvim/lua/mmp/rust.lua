-- Rust-specific configuration for reportify-rs project
-- This file enhances the existing LSP setup with project-specific features

local M = {}

-- Project-specific Cargo commands
local project_config = {
  cargo_commands = {
    check = "cargo check --all-targets --all-features --workspace",
    test = "cargo test --workspace",
    clippy = "cargo clippy --all-targets --all-features --workspace -- -D warnings",
    build = "cargo build --workspace",
    fmt = "cargo fmt --all",
  },
}

-- Setup project-specific commands
function M.setup_commands()
  -- Reportify-rs specific cargo commands
  vim.api.nvim_create_user_command("ReportifyCheck", function()
    vim.cmd("!" .. project_config.cargo_commands.check)
  end, { desc = "Run cargo check for reportify-rs workspace" })

  vim.api.nvim_create_user_command("ReportifyTest", function()
    vim.cmd("!" .. project_config.cargo_commands.test)
  end, { desc = "Run cargo test for reportify-rs workspace" })

  vim.api.nvim_create_user_command("ReportifyClippy", function()
    vim.cmd("!" .. project_config.cargo_commands.clippy)
  end, { desc = "Run cargo clippy for reportify-rs workspace with project settings" })

  vim.api.nvim_create_user_command("ReportifyBuild", function()
    vim.cmd("!" .. project_config.cargo_commands.build)
  end, { desc = "Build reportify-rs workspace" })

  vim.api.nvim_create_user_command("ReportifyFmt", function()
    vim.cmd("!" .. project_config.cargo_commands.fmt)
  end, { desc = "Format reportify-rs workspace" })

  -- CLI-specific commands for reportify-rs
  vim.api.nvim_create_user_command("ReportifyCliRun", function(args)
    local cmd_args = args.args or ""
    vim.cmd("!cargo run -- " .. cmd_args)
  end, {
    desc = "Run reportify-rs CLI with arguments",
    nargs = "*"
  })

  -- Quick access to common reportify-rs CLI commands
  vim.api.nvim_create_user_command("ReportifyValidate", function(args)
    local config_file = args.args or "examples/base__core__products.yml"
    vim.cmd("!cargo run -- validate --config " .. config_file)
  end, {
    desc = "Validate reportify-rs pipeline configuration",
    nargs = "?"
  })

  vim.api.nvim_create_user_command("ReportifySchema", function(args)
    local config_file = args.args or "examples/base__core__products.yml"
    vim.cmd("!cargo run -- schema preview --config " .. config_file)
  end, {
    desc = "Preview reportify-rs pipeline schema",
    nargs = "?"
  })
end

-- Setup project-specific keymaps
function M.setup_keymaps()
  -- Only active when in reportify-rs directory
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*/reportify-rs/*",
    callback = function()
      local opts = { buffer = true, silent = true }

      -- Project-specific commands
      vim.keymap.set("n", "<leader>rc", ":ReportifyCheck<CR>", vim.tbl_extend("force", opts, { desc = "Reportify Check" }))
      vim.keymap.set("n", "<leader>rt", ":ReportifyTest<CR>", vim.tbl_extend("force", opts, { desc = "Reportify Test" }))
      vim.keymap.set("n", "<leader>rl", ":ReportifyClippy<CR>", vim.tbl_extend("force", opts, { desc = "Reportify Clippy" }))
      vim.keymap.set("n", "<leader>rb", ":ReportifyBuild<CR>", vim.tbl_extend("force", opts, { desc = "Reportify Build" }))
      vim.keymap.set("n", "<leader>rf", ":ReportifyFmt<CR>", vim.tbl_extend("force", opts, { desc = "Reportify Format" }))

      -- CLI shortcuts
      vim.keymap.set("n", "<leader>rv", ":ReportifyValidate<CR>", vim.tbl_extend("force", opts, { desc = "Validate Pipeline" }))
      vim.keymap.set("n", "<leader>rs", ":ReportifySchema<CR>", vim.tbl_extend("force", opts, { desc = "Preview Schema" }))

      -- Quick run with common patterns
      vim.keymap.set("n", "<leader>rr", function()
        vim.ui.input({ prompt = "CLI args: " }, function(args)
          if args then
            vim.cmd("!cargo run -- " .. args)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Run CLI with args" }))
    end,
  })
end

-- Setup workspace detection and environment
function M.setup_workspace()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*/reportify-rs/*",
    callback = function()
      -- Set environment variables for reportify-rs development
      vim.env.RUST_LOG = vim.env.RUST_LOG or "debug"
      vim.env.RUST_BACKTRACE = vim.env.RUST_BACKTRACE or "1"

      -- Project root detection
      local file_path = vim.fn.expand("%:p")
      local project_root = string.match(file_path, "(.*/reportify%-rs)")

      if project_root then
        -- Change to project root
        vim.cmd("cd " .. project_root)

        -- Set up project-specific settings
        vim.opt_local.textwidth = 100
        vim.opt_local.colorcolumn = "100"

        -- Display project info (only once per session)
        if vim.g.reportify_rs_welcome ~= true then
          vim.g.reportify_rs_welcome = true
          vim.notify("🦀 Reportify RS project detected! Available commands: :Reportify<Tab>", vim.log.levels.INFO)
        end
      end
    end,
  })
end

-- Main setup function
function M.setup()
  M.setup_commands()
  -- M.setup_keymaps()
  M.setup_workspace()
end

return M
