local langmap = require("util.langmap")

local RU_LANGMAP = "Ё~,ё`,ЙQ,йq,ЦW,цw,УE,уe,КR,кr,ЕT,еt,НY,нy,ГU,гu,ШI,шi,ЩO,щo,ЗP,зp,Х{,х[,Ъ},ъ],"
  .. "ФA,фa,ЫS,ыs,ВD,вd,АF,аf,ПG,пg,РH,рh,ОJ,оj,ЛK,лk,ДL,дl,Ж:,ж\\;,Э\",э'"
  .. "ЯZ,яz,ЧX,чx,СC,сc,МV,мv,ИB,иb,ТN,тn,ЬM,ьm,Б<,б\\,,Ю>,ю."

describe("langmap", function()
  local original_langmap

  before_each(function()
    original_langmap = vim.o.langmap
    vim.o.langmap = RU_LANGMAP
  end)

  after_each(function()
    vim.o.langmap = original_langmap
  end)

  describe("get", function()
    it("remaps plain chars", function()
      assert.are.equal("пр", langmap.get("gh"))
      assert.are.equal("пД", langmap.get("gL"))
      assert.are.equal("Ё", langmap.get("~"))
      assert.are.equal("йЖ", langmap.get("q:"))
    end)

    it("remaps escaped chars from langmap", function()
      assert.are.equal("ж", langmap.get(";"))
      assert.are.equal("б", langmap.get(","))
    end)

    it("keeps chars missing from langmap", function()
      assert.are.equal("й/", langmap.get("q/"))
      assert.are.equal("1", langmap.get("1"))
    end)

    it("remaps char inside modifier notation", function()
      assert.are.equal("<C-ц>", langmap.get("<C-w>"))
      assert.are.equal("<C-в>", langmap.get("<C-d>"))
      assert.are.equal("п<C-м>", langmap.get("g<C-v>"))
    end)

    it("adds shift modifier for uppercase non-ascii with modifiers", function()
      assert.are.equal("<A-S-Р>", langmap.get("<A-H>"))
      assert.are.equal("<A-S-Д>", langmap.get("<A-L>"))
      assert.are.equal("<C-S-В>", langmap.get("<C-D>"))
    end)

    it("doesn't duplicate existing shift modifier", function()
      assert.are.equal("<A-S-Р>", langmap.get("<A-S-H>"))
      assert.are.equal("<s-a-Р>", langmap.get("<s-a-H>"))
    end)

    it("keeps named keys", function()
      assert.are.equal("<leader>Щ", langmap.get("<leader>O"))
      assert.are.equal("<Leader><C-я>", langmap.get("<Leader><C-z>"))
      assert.are.equal("<Esc><Esc>", langmap.get("<Esc><Esc>"))
      assert.are.equal("<S-Tab>", langmap.get("<S-Tab>"))
      assert.are.equal("<lt>ф", langmap.get("<lt>a"))
      assert.are.equal("<C-->", langmap.get("<C-->"))
    end)

    it("treats invalid key notation as regular chars", function()
      assert.are.equal("Бащщ", langmap.get("<foo"))
      assert.are.equal("БащщЮ", langmap.get("<foo>"))
    end)

    it("supports pairs without commas between them", function()
      vim.o.langmap = "ФAфa"
      assert.are.equal("Фф", langmap.get("Aa"))
    end)

    it("picks up langmap option changes", function()
      vim.o.langmap = "ФA"
      assert.are.equal("Ф", langmap.get("A"))
      vim.o.langmap = "ЯA"
      assert.are.equal("Я", langmap.get("A"))
    end)

    it("errors on unsupported 'abc;xyz' form", function()
      vim.o.langmap = "фыв;asd"
      assert.has_error(function()
        langmap.get("a")
      end)
    end)
  end)

  describe("set_keymap", function()
    local buf

    before_each(function()
      buf = vim.api.nvim_create_buf(false, true)
    end)

    after_each(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("sets both latin and langmapped keymaps", function()
      langmap.set_keymap("n", "gh", "^", { buffer = buf, desc = "Line start" })
      for _, lhs in ipairs { "gh", "пр" } do
        local map = vim.api.nvim_buf_call(buf, function()
          return vim.fn.maparg(lhs, "n", false, true)
        end)
        assert.are.equal("^", map.rhs)
        assert.are.equal("Line start", map.desc)
      end
    end)

    it("triggers the shifted non-ascii keymap on <M-S-Р> input", function()
      local hits = 0
      langmap.set_keymap("n", "<A-H>", function()
        hits = hits + 1
      end, { buffer = buf })
      vim.api.nvim_buf_call(buf, function()
        vim.api.nvim_feedkeys(vim.keycode("<M-S-Р>"), "xt", false)
      end)
      assert.are.equal(1, hits)
    end)

    it("drops desc on leader duplicate", function()
      langmap.set_keymap("n", "<leader>O", "<cmd>Oil<cr>", { buffer = buf, desc = "Oil" })
      local latin = vim.api.nvim_buf_call(buf, function()
        return vim.fn.maparg("<leader>O", "n", false, true)
      end)
      local langmapped = vim.api.nvim_buf_call(buf, function()
        return vim.fn.maparg("<leader>Щ", "n", false, true)
      end)
      assert.are.equal("Oil", latin.desc)
      assert.are.equal("<cmd>Oil<cr>", langmapped.rhs)
      assert.is_nil(langmapped.desc)
    end)
  end)

  describe("extend_lazy_keys", function()
    it("puts duplicates right after originals", function()
      local fn = function() end
      local keys = langmap.extend_lazy_keys {
        { "gh", fn, mode = { "n", "x" }, desc = "Line start" },
        "<Esc>",
        "q",
      }
      assert.are.same({
        { "gh", fn, mode = { "n", "x" }, desc = "Line start" },
        { "пр", fn, mode = { "n", "x" }, desc = "Line start" },
        "<Esc>",
        "q",
        "й",
      }, keys)
    end)

    it("drops desc on leader duplicates", function()
      local keys = langmap.extend_lazy_keys { { "<leader>O", "<cmd>Oil<cr>", desc = "Oil" } }
      assert.are.same({
        { "<leader>O", "<cmd>Oil<cr>", desc = "Oil" },
        { "<leader>Щ", "<cmd>Oil<cr>" },
      }, keys)
    end)

    it("duplicates disabled keys", function()
      assert.are.same({ { "s", false }, { "ы", false } }, langmap.extend_lazy_keys { { "s", false } })
    end)

    it("prefers explicit langmapped entries", function()
      local keys = langmap.extend_lazy_keys {
        { "s", false },
        { "s", "latin" },
        { "ы", "cyrillic" },
      }
      assert.are.same({ { "s", false }, { "s", "latin" }, { "ы", "cyrillic" } }, keys)
    end)

    it("doesn't mutate the original specs", function()
      local spec = { "<leader>O", "<cmd>Oil<cr>", desc = "Oil" }
      langmap.extend_lazy_keys { spec }
      assert.are.same({ "<leader>O", "<cmd>Oil<cr>", desc = "Oil" }, spec)
    end)
  end)

  describe("extend_keymaps", function()
    it("adds langmapped duplicates", function()
      local keymaps = langmap.extend_keymaps {
        H = { "actions.parent", mode = "n", desc = "Parent" },
        ["<C-s>"] = false,
        ["<Esc><Esc>"] = "actions.close",
      }
      assert.are.same({
        H = { "actions.parent", mode = "n", desc = "Parent" },
        ["Р"] = { "actions.parent", mode = "n", desc = "Parent" },
        ["<C-s>"] = false,
        ["<C-ы>"] = false,
        ["<Esc><Esc>"] = "actions.close",
      }, keymaps)
    end)

    it("drops desc on leader duplicates", function()
      local keymaps = langmap.extend_keymaps { ["<leader>yy"] = { "actions.yank", desc = "Yank" } }
      assert.are.same({ "actions.yank" }, keymaps["<leader>нн"])
      assert.are.equal("Yank", keymaps["<leader>yy"].desc)
    end)

    it("prefers explicit langmapped entries", function()
      local keymaps = langmap.extend_keymaps { L = "actions.select", ["Д"] = "actions.other" }
      assert.are.equal("actions.other", keymaps["Д"])
    end)
  end)
end)
