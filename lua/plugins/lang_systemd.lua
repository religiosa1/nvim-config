-- Configuration for systemd unit files.
-- Builtin detection only covers files inside systemd dirs (/etc/systemd, ~/.config/systemd, ...),
-- this also catches units lying around elsewhere (e.g. in a project's deploy/ dir).

local unit_sections = {
  Unit = true,
  Install = true,
  Service = true,
  Socket = true,
  Timer = true,
  Mount = true,
  Automount = true,
  Swap = true,
  Path = true,
  Slice = true,
  Scope = true,
  Container = true,
  Volume = true,
  Pod = true,
  Kube = true,
}

-- Some extensions (.path, .target, .mount) are generic, so require a known first section header.
local function detect_unit(_, bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
    local section = line:match("^%s*%[([%w-]+)%]%s*$")
    if section then
      return unit_sections[section] and "systemd" or nil
    end
  end
end

local unit_extensions = {
  "service",
  "socket",
  "timer",
  "mount",
  "automount",
  "swap",
  "path",
  "slice",
  "scope",
  "target",
  -- podman quadlets
  "container",
  "volume",
  "pod",
  "kube",
}

local extension = {}
for _, ext in ipairs(unit_extensions) do
  extension[ext] = detect_unit
end
vim.filetype.add({ extension = extension })

-- No dedicated systemd grammar in nvim-treesitter; unit files are ini-shaped.
vim.treesitter.language.register("ini", "systemd")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "ini" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- https://github.com/JFryy/systemd-lsp
        systemd_lsp = {},
      },
    },
  },
}
