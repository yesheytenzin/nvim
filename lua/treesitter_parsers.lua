-- Single source of truth for the Treesitter parsers this config needs.
-- Required by lua/plugins/cpp.lua at startup (missing-only install, no
-- network when everything is cached) and by scripts/bootstrap.lua for
-- headless prefetch on fresh machines.
--
-- Tracks: C/C++ (c, cpp, cmake, make), Ruby/Rails (ruby, embedded_template
-- for eruby, yaml, json), Rust (rust, toml), Zig (zig), Lua (lua),
-- Bash (bash), Python (python).
-- "comment" is a query dependency (injection target for comment nodes).
return {
  "c", "cpp", "cmake", "make",
  "ruby", "embedded_template", "yaml", "json",
  "rust", "comment", "toml",
  "zig",
  "lua",
  "bash",
  "python",
}
