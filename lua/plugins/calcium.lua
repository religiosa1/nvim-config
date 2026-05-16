-- Calcium plugin for performing math calculations on the v-selected text
-- Don't also forget about the builtin expression register aka "calculator":
-- in insert mode: ctrl+R, =
return {
  "necrom4/calcium.nvim",
  cmd = { "Calcium" },
  opts = {
    default_mode = "replace",
  },
  init = function()
    require("which-key").add({
      { "<leader>=", icon = { icon = "", color = "yellow" } },
    })
  end,
  keys = {
    {
      "<leader>=",
      "<cmd>Calcium replace<CR>",
      desc = "Calculate",
      mode = { "n", "x" },
    },
    {
      "<leader>+",
      function()
        local title = "stats"
        local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
        local input = table.concat(region, "\n")
        local numbers = {}
        for token in input:gmatch("[^%sa-zA-Z,\"'`%[%]{}()=:;]+") do
          local num = tonumber(token)
          if num ~= nil then
            table.insert(numbers, num)
          end
        end
        if #numbers == 0 then
          vim.notify("no numbers found", vim.log.levels.WARN, { title = title })
          return
        end
        table.sort(numbers)
        local min = numbers[1]
        local max = numbers[#numbers]

        local mid = math.floor(#numbers / 2)
        local median
        if #numbers % 2 == 0 then
          median = (numbers[mid] + numbers[mid + 1]) / 2
        else
          median = numbers[mid + 1]
        end

        -- The Welford online algorithm for mean/average accumulation and variance
        -- https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm
        local mean, m2 = 0, 0
        for n, x in ipairs(numbers) do
          local delta = x - mean
          mean = mean + delta / n
          m2 = m2 + delta * (x - mean)
        end
        local variance = m2 / #numbers
        local stddev = math.sqrt(variance)
        local fmt = function(x)
          return string.format("%.10g", x)
        end
        local msg = table.concat({
          "min = " .. fmt(min),
          "max = " .. fmt(max),
          "avg = " .. fmt(mean),
          "med = " .. fmt(median),
          "std = " .. fmt(stddev),
        }, "\n")
        vim.notify(msg, vim.log.levels.INFO, { title = title })
      end,
      desc = "avg/min/max",
      mode = { "x" },
    },
  },
}
