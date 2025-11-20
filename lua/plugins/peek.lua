-- another github-flavored markdown previewrer. Requires Deno available on the
-- system and works kinda meh. I'm keeping it as a fallback, but in general
-- prefer wallpants/github-preview
-- default markdown preview in lazyvim-extras is abandonware at this point
if true then
  return {}
end
return {
  {
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup({
        app = "browser",
      })
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
}
