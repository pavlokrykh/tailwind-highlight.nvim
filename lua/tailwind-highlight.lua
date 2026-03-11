local M = {}

local tw_class_cache = {}
local ns_id = vim.api.nvim_create_namespace("tailwind_class_highlight")
local HL_GROUP = "TailwindClass"

local tw_patterns = {
  -- Layout
  "^block$", "^inline$", "^inline%-block$", "^flex$", "^inline%-flex$",
  "^grid$", "^inline%-grid$", "^hidden$", "^contents$", "^flow%-root$",
  "^table$", "^table%-row$", "^table%-cell$",

  -- Flex/Grid
  "^flex%-", "^grid%-", "^col%-", "^row%-", "^gap%-", "^order%-",
  "^flex%-1$", "^flex%-auto$", "^flex%-initial$", "^flex%-none$",
  "^grow$", "^grow%-", "^shrink$", "^shrink%-",
  "^basis%-",
  "^justify%-", "^items%-", "^self%-", "^place%-", "^content%-",

  -- Spacing
  "^[mp][xylrtbse]?%-", "^space%-",

  -- Sizing
  "^[wh]%-", "^min%-[wh]%-", "^max%-[wh]%-", "^size%-",

  -- Typography
  "^text%-", "^font%-", "^tracking%-", "^leading%-",
  "^uppercase$", "^lowercase$", "^capitalize$", "^normal%-case$",
  "^truncate$", "^line%-clamp%-", "^decoration%-", "^underline$",
  "^overline$", "^line%-through$", "^no%-underline$",
  "^italic$", "^not%-italic$", "^antialiased$", "^subpixel%-antialiased$",
  "^whitespace%-", "^break%-", "^hyphens%-",
  "^indent%-", "^align%-", "^list%-",

  -- Backgrounds
  "^bg%-",

  -- Borders
  "^border$", "^border%-[0248]$", "^border%-x", "^border%-y",
  "^border%-[trblse]", "^border%-", "^rounded",
  "^divide%-", "^ring%-", "^outline%-", "^outline$",

  -- Effects
  "^shadow", "^opacity%-", "^mix%-blend%-", "^bg%-blend%-",

  -- Filters
  "^blur", "^brightness%-", "^contrast%-", "^drop%-shadow",
  "^grayscale", "^hue%-rotate%-", "^invert", "^saturate%-", "^sepia",
  "^backdrop%-",

  -- Tables
  "^border%-collapse$", "^border%-separate$", "^table%-",
  "^caption%-",

  -- Transitions & Animation
  "^transition", "^duration%-", "^ease%-", "^delay%-",
  "^animate%-",

  -- Transforms
  "^scale%-", "^rotate%-", "^translate%-", "^skew%-",
  "^origin%-", "^transform$", "^transform%-",

  -- Interactivity
  "^cursor%-", "^select%-", "^resize", "^scroll%-",
  "^snap%-", "^touch%-", "^caret%-", "^accent%-",
  "^appearance%-", "^pointer%-events%-", "^will%-change%-",

  -- Position
  "^static$", "^fixed$", "^absolute$", "^relative$", "^sticky$",
  "^inset%-", "^top%-", "^right%-", "^bottom%-", "^left%-",
  "^start%-", "^end%-",
  "^z%-",

  -- Visibility
  "^visible$", "^invisible$", "^collapse$",

  -- Display
  "^overflow%-", "^overscroll%-",
  "^float%-", "^clear%-",
  "^isolat", "^object%-",

  -- SVG
  "^fill%-", "^stroke%-",

  -- Accessibility
  "^sr%-only$", "^not%-sr%-only$",
  "^forced%-color%-adjust%-",

  -- Container
  "^container$",

  -- Columns
  "^columns%-", "^break%-",

  -- Aspect
  "^aspect%-",
}

local tw_prefixes = {
  "sm", "md", "lg", "xl", "2xl",
  "hover", "focus", "active", "disabled", "visited",
  "first", "last", "odd", "even", "focus%-within",
  "focus%-visible", "checked", "required", "invalid",
  "placeholder", "file", "marker", "selection",
  "before", "after", "first%-line", "first%-letter",
  "dark", "motion%-safe", "motion%-reduce",
  "contrast%-more", "contrast%-less",
  "portrait", "landscape", "print",
  "aria%-", "data%-", "supports%-", "group%-", "peer%-",
  "has%-", "not%-", "is%-",
  "ltr", "rtl", "open",
}

local tw_standalone = {
  ["flex"] = true, ["block"] = true, ["inline"] = true, ["grid"] = true,
  ["hidden"] = true, ["static"] = true, ["fixed"] = true, ["absolute"] = true,
  ["relative"] = true, ["sticky"] = true, ["visible"] = true, ["invisible"] = true,
  ["container"] = true, ["truncate"] = true, ["antialiased"] = true,
  ["italic"] = true, ["underline"] = true, ["overline"] = true, ["uppercase"] = true,
  ["lowercase"] = true, ["capitalize"] = true, ["ordinal"] = true,
  ["outline"] = true, ["border"] = true, ["grow"] = true, ["shrink"] = true,
  ["transition"] = true, ["transform"] = true, ["filter"] = true, ["resize"] = true,
  ["snap"] = true, ["contents"] = true, ["collapse"] = true,
}

local arbitrary_pattern = "%[.+%]"

---@param class string
---@return string
local function strip_prefixes(class)
  local base = class
  local changed = true
  while changed do
    changed = false
    local prefix, rest = base:match("^([%w%-]+):(.+)$")
    if prefix and rest then
      for _, p in ipairs(tw_prefixes) do
        if prefix:match("^" .. p) then
          base = rest
          changed = true
          break
        end
      end
      if not changed and rest then
        base = rest
        changed = true
      end
    end
  end
  base = base:gsub("^!", "")
  base = base:gsub("^%-", "")
  return base
end

---@param class string
---@return boolean
local function is_tailwind_class(class)
  if tw_class_cache[class] ~= nil then
    return tw_class_cache[class]
  end

  local base = strip_prefixes(class)

  if tw_standalone[base] then
    tw_class_cache[class] = true
    return true
  end

  if base:match(arbitrary_pattern) then
    local util_prefix = base:match("^(.-)%[")
    if util_prefix and #util_prefix > 0 then
      util_prefix = util_prefix:gsub("%-$", "")
      for _, pattern in ipairs(tw_patterns) do
        if (util_prefix .. "-x"):match(pattern) then
          tw_class_cache[class] = true
          return true
        end
      end
    end
    tw_class_cache[class] = true
    return true
  end

  for _, pattern in ipairs(tw_patterns) do
    if base:match(pattern) then
      tw_class_cache[class] = true
      return true
    end
  end

  tw_class_cache[class] = false
  return false
end

--- Extract classes from a raw string of space-separated class names
--- and record their positions relative to a given offset in the line
---@param classes_str string
---@param offset number  -- 0-indexed column of the first char of classes_str in the line
---@return table[]
local function extract_classes(classes_str, offset)
  local results = {}
  if not classes_str or #classes_str == 0 then return results end
  local pos = 1
  for class in classes_str:gmatch("%S+") do
    local s, e = classes_str:find(class, pos, true)
    if s then
      table.insert(results, {
        class = class,
        col_start = offset + s - 1,
        col_end = offset + e,
      })
      pos = e + 1
    end
  end
  return results
end

--- Parse all class-like attributes in a line
---@param line string
---@return table[]
local function find_classes_in_line(line)
  local results = {}

  -- Helper: merge extracted classes into results
  local function collect(classes_str, offset)
    local extracted = extract_classes(classes_str, offset)
    for _, v in ipairs(extracted) do
      table.insert(results, v)
    end
  end

  -- ============================================================
  -- 1. Standard HTML: class="..." and class='...'
  -- ============================================================
  for attr_start, classes_str in line:gmatch('()class%s*=%s*"([^"]*)"') do
    local quote_pos = line:find('"', tonumber(attr_start) or 1)
    if quote_pos then
      collect(classes_str, quote_pos)
    end
  end

  for attr_start, classes_str in line:gmatch("()class%s*=%s*'([^']*)'") do
    local quote_pos = line:find("'", tonumber(attr_start) or 1)
    if quote_pos then
      collect(classes_str, quote_pos)
    end
  end

  -- ============================================================
  -- 2. Angular: [class]="'...'"
  --    The value is a TS expression; classes live inside inner quotes
  -- ============================================================
  for attr_start in line:gmatch("()%[class%]%s*=%s*\"") do
    local outer_quote = line:find('"', tonumber(attr_start) or 1)
    if outer_quote then
      local outer_end = line:find('"', outer_quote + 1)
      if outer_end then
        local expr = line:sub(outer_quote + 1, outer_end - 1)
        -- Find inner single-quoted strings: 'flex items-center ...'
        for inner_start, inner_str in expr:gmatch("()'([^']*)'") do
          local abs_offset = outer_quote + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
        -- Also find inner backtick strings: `flex items-center ...`
        for inner_start, inner_str in expr:gmatch("()`([^`]*)`") do
          local abs_offset = outer_quote + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
      end
    end
  end

  -- ============================================================
  -- 3. Angular: [ngClass]="'...'" and [ngClass]="{ 'class': expr }"
  -- ============================================================
  for attr_start in line:gmatch("()%[ngClass%]%s*=%s*\"") do
    local outer_quote = line:find('"', tonumber(attr_start) or 1)
    if outer_quote then
      local outer_end = line:find('"', outer_quote + 1)
      if outer_end then
        local expr = line:sub(outer_quote + 1, outer_end - 1)
        -- Inner single-quoted strings (both simple and object-key forms)
        for inner_start, inner_str in expr:gmatch("()'([^']*)'") do
          local abs_offset = outer_quote + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
      end
    end
  end

  -- ============================================================
  -- 4. Angular: [class.some-tw-class]="expression"
  --    The class name is between "class." and "]"
  -- ============================================================
  for full_start, class_name in line:gmatch("()%[class%.([%w%-]+)%]") do
    local bracket_pos = line:find("%[class%.", tonumber(full_start) or 1)
    if bracket_pos then
      -- +7 accounts for "[class." length
      local class_col_start = bracket_pos + 6
      local class_col_end = class_col_start + #class_name
      table.insert(results, {
        class = class_name,
        col_start = class_col_start,
        col_end = class_col_end,
      })
    end
  end

  -- ============================================================
  -- 5. React JSX: className="..." and className='...'
  -- ============================================================
  for attr_start, classes_str in line:gmatch('()className%s*=%s*"([^"]*)"') do
    local quote_pos = line:find('"', tonumber(attr_start) or 1)
    if quote_pos then
      collect(classes_str, quote_pos)
    end
  end

  for attr_start, classes_str in line:gmatch("()className%s*=%s*'([^']*)'") do
    local quote_pos = line:find("'", tonumber(attr_start) or 1)
    if quote_pos then
      collect(classes_str, quote_pos)
    end
  end

  -- ============================================================
  -- 6. React JSX: className={`...`} (template literals)
  --    and className={"..."} / className={'...'}
  -- ============================================================
  for attr_start in line:gmatch("()className%s*=%s*{") do
    local brace_pos = line:find("{", tonumber(attr_start) or 1)
    if brace_pos then
      local brace_end = line:find("}", brace_pos + 1)
      if brace_end then
        local expr = line:sub(brace_pos + 1, brace_end - 1)
        -- Backtick template literals
        for inner_start, inner_str in expr:gmatch("()`([^`]*)`") do
          local abs_offset = brace_pos + (tonumber(inner_start) or 1)
          -- For template literals, strip ${...} expressions and treat remaining as classes
          local cleaned = inner_str:gsub("%$%b{}", " ")
          collect(cleaned, abs_offset)
        end
        -- Double-quoted strings inside braces
        for inner_start, inner_str in expr:gmatch('()"([^"]*)"') do
          local abs_offset = brace_pos + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
        -- Single-quoted strings inside braces
        for inner_start, inner_str in expr:gmatch("()'([^']*)'") do
          local abs_offset = brace_pos + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
      end
    end
  end

  -- ============================================================
  -- 7. React clsx/classnames/cn/cva/twMerge function calls
  --    Matches: clsx("...", '...'), cn("..."), classNames("..."), twMerge("..."), cva("...")
  -- ============================================================
  for func_name_start in line:gmatch("()[cC][lLnNvVtT][sSwSaA]?[xXmMeE]?[rRsS]?[gG]?[eE]?%s*%(") do
    local paren_pos = line:find("%(", tonumber(func_name_start) or 1)
    if paren_pos then
      -- Simple: find matching closing paren (doesn't handle nested parens)
      local paren_end = line:find("%)", paren_pos + 1)
      if paren_end then
        local expr = line:sub(paren_pos + 1, paren_end - 1)
        -- Double-quoted
        for inner_start, inner_str in expr:gmatch('()"([^"]*)"') do
          local abs_offset = paren_pos + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
        -- Single-quoted
        for inner_start, inner_str in expr:gmatch("()'([^']*)'") do
          local abs_offset = paren_pos + (tonumber(inner_start) or 1)
          collect(inner_str, abs_offset)
        end
        -- Backtick
        for inner_start, inner_str in expr:gmatch("()`([^`]*)`") do
          local abs_offset = paren_pos + (tonumber(inner_start) or 1)
          local cleaned = inner_str:gsub("%$%b{}", " ")
          collect(cleaned, abs_offset)
        end
      end
    end
  end

  return results
end

---@param bufnr number|nil
function M.highlight_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for line_nr, line in ipairs(lines) do
    local classes = find_classes_in_line(line)
    for _, cls in ipairs(classes) do
      if is_tailwind_class(cls.class) then
        vim.api.nvim_buf_add_highlight(
          bufnr, ns_id, HL_GROUP,
          line_nr - 1,
          cls.col_start,
          cls.col_end
        )
      end
    end
  end
end

---@param opts table|nil
function M.setup(opts)
  opts = opts or {}

  local hl_color = opts.color or "#6db3ab"
  local hl_style = opts.style or "bold"

  vim.api.nvim_set_hl(0, HL_GROUP, {
    fg = hl_color,
    bold = hl_style:find("bold") ~= nil,
    italic = hl_style:find("italic") ~= nil,
    underline = hl_style:find("underline") ~= nil,
  })

  local filetypes = opts.filetypes or {
    "html", "htmlangular", "typescript", "typescriptreact",
    "javascript", "javascriptreact", "vue", "svelte", "astro",
    "jsx", "tsx",
  }

  local group = vim.api.nvim_create_augroup("TailwindClassHighlight", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "*",
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      local matched = false
      for _, f in ipairs(filetypes) do
        if ft == f then
          matched = true
          break
        end
      end
      if not matched then return end

      if args.event == "TextChanged" or args.event == "TextChangedI" then
        if not _G._tw_hl_timers then _G._tw_hl_timers = {} end
        if _G._tw_hl_timers[args.buf] then
          _G._tw_hl_timers[args.buf]:stop()
        end
        local timer = vim.loop.new_timer()
        if not timer then return end
        _G._tw_hl_timers[args.buf] = timer
        timer:start(300, 0, vim.schedule_wrap(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            M.highlight_buffer(args.buf)
          end
        end))
      else
        M.highlight_buffer(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      vim.api.nvim_set_hl(0, HL_GROUP, {
        fg = hl_color,
        bold = hl_style:find("bold") ~= nil,
        italic = hl_style:find("italic") ~= nil,
        underline = hl_style:find("underline") ~= nil,
      })
    end,
  })
end

function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.clear_cache()
  tw_class_cache = {}
end

return M
