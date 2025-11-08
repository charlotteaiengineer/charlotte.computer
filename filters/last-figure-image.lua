-- Quarto Lua filter: Set document-level `image` metadata to the LAST figure
-- Behavior:
-- - Prefer images inside figure blocks (Divs with class "quarto-figure" or "figure")
-- - Fallback to any image if no figure blocks exist
-- - Always override existing `image` so listings reflect the last plot

local function has_class(attr, class_name)
  if not attr or not attr.classes then return false end
  for _, c in ipairs(attr.classes) do
    if c == class_name then return true end
  end
  return false
end

local function collect_last_images(blocks)
  local last_any_src = nil
  local last_figure_src = nil

  local function set_last_any(img)
    if img.src and img.src ~= "" then
      last_any_src = img.src
    end
    return nil
  end

  local function set_last_figure(img)
    if img.src and img.src ~= "" then
      last_figure_src = img.src
    end
    return nil
  end

  for i = 1, #blocks do
    local b = blocks[i]
    -- Track all images
    pandoc.walk_block(b, { Image = set_last_any })
    -- Prefer images inside figure-like containers
    if b.t == "Div" and (has_class(b.attr, "quarto-figure") or has_class(b.attr, "figure")) then
      pandoc.walk_block(b, { Image = set_last_figure })
    end
  end

  return last_figure_src or last_any_src
end

function Pandoc(doc)
  local last_src = collect_last_images(doc.blocks or {})
  if last_src ~= nil then
    doc.meta.image = pandoc.MetaString(last_src)
  end
  return doc
end
