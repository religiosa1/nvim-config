return {
  "nvim-mini/mini.surround",
  opts = function(_, opts)
    opts.custom_surroundings = opts.custom_surroundings or {}
    -- "j" for generic: identifier (word/./:: chars) followed by balanced <>
    -- e.g. Array<string>, Map<K, V>, Vec::<i32>
    opts.custom_surroundings.j = {
      input = { "%f[%w_%.:][%w_%.:]+%b<>", "^.-<().*()>$" },
      output = function()
        local name = MiniSurround.user_input("Generic name")
        if name == nil then return nil end
        return { left = name .. "<", right = ">" }
      end,
    }
  end,
}
