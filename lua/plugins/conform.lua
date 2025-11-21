-- formatting settings
-- https://www.lazyvim.org/plugins/formatting
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        --
        prettier = {
          prepend_args = {
            -- https://prettier.io/docs/cli/#--config-precedence
            "--config-precedence=prefer-file",
            "--use-tabs=true",
            "--print-width=100",
            "--trailing-comma=all",
          },
        },
      },
    },
  },
}
