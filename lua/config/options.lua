-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "-->",
  trail = "·",
}
vim.opt.cc = "80,120,140"
vim.opt.expandtab = false
vim.opt.smartindent = false -- relying on the treesitter indent instead

-- setting terminal tab title
vim.opt.title = true
-- the most important part to avoid confusion -- when launching in just
-- directory (without a filename provided -- aka Scratch buffer), we're
-- displaying cwd folder name, which is most likely the project name
if vim.fn.argc() == 0 then
  vim.opt.titlestring = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. " - Nvim"
end
-- Langmap for russian keybindings
vim.opt.langmap = "ЙQ,йq,ЦW,цw,УE,уe,КR,кr,ЕT,еt,НY,нy,ГU,гu,ШI,шi,ЩO,щo,ЗP,зp,Х{,х[,Ъ},ъ],"
  .. "ФA,фa,ЫS,ыs,ВD,вd,АF,аf,ПG,пg,РH,рh,ОJ,оj,ЛK,лk,ДL,дl,Ж:,ж\\;,Э\",э'"
  .. "ЯZ,яz,ЧX,чx,СC,сc,МV,мv,ИB,иb,ТN,тn,ЬM,ьm,Б<,б\\,,Ю>,ю."

vim.cmd("cnoreabbrev й q")
vim.cmd("cnoreabbrev ц w")
vim.cmd("cnoreabbrev у e")
vim.cmd("cnoreabbrev k r")
