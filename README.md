# 💤 My LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

Contains my lazyvim configuration.

lazyvim.json is placed in the gitignore for now, as I'm still experimenting
with the plugin list on different machines.

List of "extras" that's definitely going to be shared across:

```
"lazyvim.plugins.extras.lang.markdown",
```

A lot of omarchy customization plugins are also placed in the gitignore:

- lazyvim.json
- lua/plugins/all-themes.lua
- lua/plugins/disable-news-alert.lua
- lua/plugins/omarchy-theme-hotreload.lua
- lua/plugins/snacks-animated-scrolling-off.lua
- lua/plugins/theme.lua
- plugin/after/transparency.lua

## TODOs:

- [ ] Disable annoying snippets in markdown specifically, but across the board.
      They bring too much clutter. Leave only my own personal stuff, or things I reviewed.
- [ ] Add "copy file" and "archive and copy" file mini.files commands.
