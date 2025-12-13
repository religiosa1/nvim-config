return {
  { "nvim-neotest/neotest-plenary" },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-jest",
      -- "Nelfimov/neotest-node-test-runner",
      "marilari88/neotest-vitest",
    },
    opts = {
      discovery = {
        enabled = true,
      },
      adapters = {
        "neotest-plenary",
        -- ["neotest-node-test-runner"] = {},
        ["neotest-vitest"] = {},
        -- wip setup for work-related jest crap
        -- other available options: https://github.com/nvim-neotest/neotest-jest
        ["neotest-jest"] = {
          jestCommand = "yarn test --",
          jest_test_discovery = true,
          isTestFile = function(file_path)
            if not file_path then
              return false
            end
            return vim.fn.fnamemodify(file_path, ":e:e"):match("test%.[jt]sx?$") ~= nil
          end,
          discovery = {
            enabled = false,
          },
        },
      },
    },
  },
}
