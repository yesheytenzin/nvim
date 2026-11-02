-- Compatibility shim: some guides / old commands use require("config.theme").
-- Real implementation lives in custom.omarchy_theme (Omarchy dynamic theme).
-- This just forwards so :lua require("config.theme").reload() works.
local real = require("custom.omarchy_theme")
return real
