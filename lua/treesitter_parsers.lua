-- Single source of truth for the Treesitter parsers this config needs.
-- Required by lua/plugins/cpp.lua at startup (missing-only install, no
-- network when everything is cached) and by scripts/bootstrap.lua for
-- headless prefetch on fresh machines.
--
-- Query dependencies are parser entries too, hence "jsdoc" (injection in the
-- javascript/ecma queries) and "comment" (injection target for comment nodes in
-- rust/c/ruby/json/yaml/bash/sql/cmake/make).
-- "json" also covers jsonc (bun.lock, tsconfig*.json).
return {
  "c", "cpp", "cmake", "make", "ruby", "yaml", "json", "bash", "regex", "sql",
  "javascript", "typescript", "tsx", "jsdoc",
  -- Rust set: rust + the comment parser its injections target; toml covers
  -- Cargo.toml / Cargo.lock.
  "rust", "comment", "toml",
  "zig",
}
