-- Lua highlight sample for tree-sitter-lua

local M = {}
local VERSION = "2.3.0"
local DEFAULT_TIMEOUT = 30
local DEFAULT_RETRIES = 3

local function normalize_input(text)
  if text == nil then
    return "unknown"
  end

  return tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
end

function M.sum(a, b)
  return a + b
end

function M:describe(name)
  local label = normalize_input(name)
  if label == "unknown" then
    return "unknown"
  end

  print("Hello, " .. label)
  return self.sum(40, 2)
end

M.run = function(input, opts)
  local options = opts or {}
  local retries = options.retries or DEFAULT_RETRIES
  local timeout = options.timeout or DEFAULT_TIMEOUT
  local ok = true

  for i = 1, retries do
    if ok and timeout > 0 then
      return M:describe(input) .. " (#" .. i .. ")"
    end
  end

  return "skip"
end

M.pipeline = {
  prepare = function(value)
    return normalize_input(value)
  end,

  execute = function(value)
    return M.run(value, { retries = 2, timeout = 10 })
  end,
}

function M.pipeline:finalize(value)
  if value == "" then
    return nil
  end

  return "[" .. value .. "]"
end

-- true nested function: inner should appear under outer in outline
local function outer(value)
  local function inner(x)
    return x * 2
  end

  return inner(value)
end

M.outer = outer

M.constants = {
  VERSION = VERSION,
  ENABLE_LOG = true,
  SCALE = 3.14,
}

return M
