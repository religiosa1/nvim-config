return {
  { "nvim-neotest/neotest-plenary" },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-jest" },
    opts = {
      discovery = {
        enabled = false,
      },
      adapters = {
        "neotest-plenary",
        -- wip setup for work-related jest crap
        -- other available options: https://github.com/nvim-neotest/neotest-jest
        ["neotest-jest"] = {
          jestCommand = "yarn test --",
          jest_test_discovery = false,
          isTestFile = function(file_path)
            if not file_path then
              return false
            end
            return vim.fn.fnamemodify(file_path, ":e:e"):match("test%.[jt]sx?$") ~= nil
          end,
        },
      },
    },
  },
}
