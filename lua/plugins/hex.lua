-- hex
-- https://github.com/RaafatTurki/hex.nvim
-- return { 'RaafatTurki/hex.nvim' }
return {
  'RaafatTurki/hex.nvim',
  ft = { 'hex', 'efi' },
  cmd = { 'HexDump', 'HexAssemble', 'HexToggle' },
  opts = {
    dump_cmd = 'xxd -g 1 -u',
    assemble_cmd = 'xxd -r',
    -- any other custom settings go here
  },
}
