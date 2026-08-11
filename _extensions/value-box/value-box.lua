function detect_icon_type(icon)
  if icon:match("%.svg$") then
    return "svg"
  elseif icon:match("%.png$") or icon:match("%.jpe?g$") or icon:match("%.webp$") then
    return "png"
  elseif icon:match("^fa[srbldt]?%-.+") then
    return "fa"
  elseif icon:match("^ti%-.+") then
    return "tabler"
  elseif icon:match("^ph%-?%a*%s+ph%-.+") then
    return "phosphor"
  else
    return "bi"  -- fallback: assume Bootstrap Icons
  end
end

-- Material Symbols variants: never auto-detected (icon names are plain words
-- like "home", indistinguishable from a bare Bootstrap Icons fallback), so
-- these are only reachable via an explicit icon-type attribute.
local material_variants = {
  ["material"]          = { class = "material-symbols-outlined", family = "Material+Symbols+Outlined" },
  ["material-outlined"] = { class = "material-symbols-outlined", family = "Material+Symbols+Outlined" },
  ["material-rounded"]  = { class = "material-symbols-rounded",  family = "Material+Symbols+Rounded" },
  ["material-sharp"]    = { class = "material-symbols-sharp",    family = "Material+Symbols+Sharp" },
}

-- Phosphor Icons ships one stylesheet per weight rather than a single bundle,
-- so the leading weight class in the icon value (e.g. "ph-bold ph-heart")
-- picks which CDN file gets linked.
local phosphor_weight_dirs = {
  ["ph"]         = "regular",
  ["ph-thin"]    = "thin",
  ["ph-light"]   = "light",
  ["ph-bold"]    = "bold",
  ["ph-fill"]    = "fill",
  ["ph-duotone"] = "duotone",
}


function Div(el)
  if el.classes:includes("value-box") then

    -- Existing attributes
    local icon      = el.attributes["icon"] or ""
    local icon_type -- supports "fa" | "bi" | "svg" | "png" | "material" | "material-outlined" | "material-rounded" | "material-sharp" | "tabler" | "phosphor"
    if el.attributes["icon-type"] then
      icon_type = el.attributes["icon-type"]
    elseif icon ~= "" then
      icon_type = detect_icon_type(icon)
    else
      icon_type = "bi"
    end
    local color     = el.attributes["color"] or "bg-blue"
    local value     = el.attributes["value"] or ""
    local width     = el.attributes["width"] or "80%"
    local height    = el.attributes["height"] or ""
    local min_height = el.attributes["min-height"] or "100px"
    local padding     = el.attributes["padding"] or "1.5rem"
    local align     = el.attributes["align"] or "left"
    local valign = el.attributes["valign"] or "middle"
    local href      = el.attributes["href"] or ""
    local icon_pos  = el.attributes["icon-position"] or "top" -- "top" | "bottom" | "left" | "right"
    local value_pos = el.attributes["value-position"] or "top" -- "top" | "bottom" | "left" | "right"
    local font_size = el.attributes["font-size"] or ""
    local value_font_size = el.attributes["value-font-size"] or "2.2rem"

    local font_color = el.attributes["font-color"] or "white"
    local value_color = el.attributes["value-color"] or font_color
    local icon_color = el.attributes["icon-color"] or "white"

    local icon_size_raw = el.attributes["icon-size"]

    -- em units for font-based icons (BI/FA), px for image-based (SVG/PNG)
    local icon_size_font
    local icon_size_img
    if icon_size_raw then
      icon_size_font = icon_size_raw
      icon_size_img  = icon_size_raw
    else
      icon_size_font = "3em"
      icon_size_img  = "128px"
    end

    -- Fragment logic
    local fragment_attr = el.attributes["fragment"]
    local fragment_class = ""
    if fragment_attr then
      fragment_class = " fragment " .. (fragment_attr == "true" and "fade-in-then-semi-out" or fragment_attr)
    end

    -- Fragment Index logic
    local index_attr = el.attributes["index"]
    local index_data = ""
    if index_attr then
      index_data = string.format(' data-fragment-index="%s"', index_attr)
    end

    -- Flex layout styles for left/right icon and value positioning
    local outer_extra_style   = el.attributes["outer-extra-style"] or ""
    local icon_extra_style    = el.attributes["icon-extra-style"] or ""
    local content_extra_style = el.attributes["content-extra-style"] or ""
    local details_extra_style = el.attributes["details-extra-style"] or ""
    local value_extra_style   = el.attributes["value-extra-style"] or ""

    -- icon-position controls the outer wrapper: icon vs. everything else
    if icon_pos == "left" then
      outer_extra_style   = outer_extra_style .. " display:flex; flex-direction:row; align-items:center; gap:1em;"
      icon_extra_style    = icon_extra_style .. " flex-shrink:0;"
      content_extra_style = content_extra_style .. " flex:1;"
    elseif icon_pos == "right" then
      outer_extra_style   = outer_extra_style .. " display:flex; flex-direction:row-reverse; align-items:center; gap:1em;"
      icon_extra_style    = icon_extra_style .. " flex-shrink:0;"
      content_extra_style = content_extra_style .. " flex:1;"
    end

    -- value-position controls the inner content wrapper: value vs. details, independent of icon-position
    if value_pos == "left" then
      content_extra_style = content_extra_style .. " display:flex; flex-direction:row; align-items:center; gap:0.75em;"
      value_extra_style   = value_extra_style .. " flex-shrink:0;"
      details_extra_style = details_extra_style .. " flex:1;"
    elseif value_pos == "right" then
      content_extra_style = content_extra_style .. " display:flex; flex-direction:row-reverse; align-items:center; gap:0.75em;"
      value_extra_style   = value_extra_style .. " flex-shrink:0;"
      details_extra_style = details_extra_style .. " flex:1;"
    end

    -- Compensate for icon-font glyphs' built-in optical bearing so a stacked
    -- icon visually lines up with the left/right edge of the value/details text.
    if (icon_pos == "top" or icon_pos == "bottom") and (icon_type == "fa" or icon_type == "bi" or icon_type == "tabler" or icon_type == "phosphor" or material_variants[icon_type]) then
      local bearing = "0.12em"
      if align == "left" then
        icon_extra_style = icon_extra_style .. string.format(" margin-left:-%s;", bearing)
      elseif align == "right" then
        icon_extra_style = icon_extra_style .. string.format(" margin-right:-%s;", bearing)
      end
    end

    -- Vertical alignment — requires flex on the outer wrapper
    if valign ~= "" then
      local valign_map = { top = "flex-start", middle = "center", bottom = "flex-end" }
      local align_value = valign_map[valign] or valign  -- fall back to raw value if not a shorthand
      if outer_extra_style:find("display:flex") then
        -- Already flex (left/right icon position) — just override align-items
        outer_extra_style = outer_extra_style:gsub("align%-items:[^;]+;", string.format("align-items:%s;", align_value))
      else
        -- Add flex column layout so justify-content controls vertical alignment
        outer_extra_style = outer_extra_style .. string.format(" display:flex; flex-direction:column; justify-content:%s;", align_value)
      end
    end

    -- Build the outer wrapper
    local html_open
    if href ~= "" then
      html_open = string.format(
        '<a href="%s" class="value-box %s%s" style="width:%s; height:%s; min-height:%s; padding:%s; text-align:%s; display:block; text-decoration:none; cursor:pointer;%s"%s>',
        href, color, fragment_class, width, height, min_height, padding, align,  outer_extra_style, index_data
      )
    else
      html_open = string.format(
        '<div class="value-box %s%s" style="width:%s; height:%s; min-height:%s; padding:%s; text-align:%s; %s"%s>',
        color, fragment_class, width, height, min_height, padding, align, outer_extra_style, index_data
      )
    end

    -- Build icon HTML (empty string if no icon)
    local icon_html = ""
    if icon ~= "" then
      if icon_type == "fa" then
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">')
        icon_html = string.format(
          '<i class="icon %s" style="font-size:%s;color:%s;%s"></i>',
          icon, icon_size_font, icon_color, icon_extra_style
        )

      elseif icon_type == "svg" then
        local svg_file = io.open(icon, "r")
        if svg_file then
          local svg_content = svg_file:read("*all")
          svg_file:close()
          svg_content = svg_content:gsub('<svg', string.format(
            '<svg style="width:%s; height:%s;"', icon_size_img, icon_size_img
          ))
          icon_html = string.format(
            '<span class="icon" style="width:%s; height:%s; display:inline-flex; align-items:center; justify-content:center; font-size:inherit;%s">%s</span>',
            icon_size_img, icon_size_img, icon_extra_style, svg_content
          )
        else
          io.stderr:write(string.format("value-box warning: SVG file not found: %s\n", icon))
        end

      elseif icon_type == "png" then
        local png_file = io.open(icon, "r")
        if png_file then
          png_file:close()
          icon_html = string.format(
            '<img class="icon" src="%s" style="width:%s; height:%s; object-fit:contain; display:block; margin:0 auto;%s" alt="">',
            icon, icon_size_img, icon_size_img, icon_extra_style
          )
        else
          io.stderr:write(string.format("value-box warning: PNG file not found '%s', falling back to Bootstrap Icons\n", icon))
          quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">')
          icon_html = string.format(
            '<i class="icon bi %s" style="font-size:%s; color:%s;%s"></i>',
            icon, icon_size_font, icon_color, icon_extra_style
          )
        end

      elseif material_variants[icon_type] then
        local variant = material_variants[icon_type]
        quarto.doc.include_text("in-header", string.format(
          '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=%s:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=block">',
          variant.family
        ))
        icon_html = string.format(
          '<span class="icon %s" style="font-size:%s;color:%s;%s">%s</span>',
          variant.class, icon_size_font, icon_color, icon_extra_style, icon
        )

      elseif icon_type == "tabler" then
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.46.0/tabler-icons.min.css">')
        icon_html = string.format(
          '<i class="icon ti %s" style="font-size:%s;color:%s;%s"></i>',
          icon, icon_size_font, icon_color, icon_extra_style
        )

      elseif icon_type == "phosphor" then
        local weight_token = icon:match("^(%S+)")
        local weight_dir = phosphor_weight_dirs[weight_token] or "regular"
        quarto.doc.include_text("in-header", string.format(
          '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@phosphor-icons/web@2.1.2/src/%s/style.css">',
          weight_dir
        ))
        icon_html = string.format(
          '<i class="icon %s" style="font-size:%s;color:%s;%s"></i>',
          icon, icon_size_font, icon_color, icon_extra_style
        )

      else
        -- Bootstrap Icons (default)
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">')
        icon_html = string.format(
          '<i class="icon bi %s" style="font-size:%s; color:%s;%s"></i>',
          icon, icon_size_font, icon_color, icon_extra_style
        )
      end
    end

    -- Build value HTML (empty string if no value)
    local value_html = ""
    if value ~= "" then
      value_html = string.format(
        '<div class="value" style="font-size: %s; color:%s;%s">%s</div>',
        value_font_size, value_color, value_extra_style, value
      )
    end

    -- For bottom placement, defer icon injection; otherwise inject it now
    if icon_pos ~= "bottom" then
      html_open = html_open .. icon_html
    end

    -- Open the content wrapper (holds value + details, positioned independently of the icon)
    html_open = html_open .. string.format('<div class="vb-content" style="%s">', content_extra_style)

    -- For bottom placement, defer value injection; otherwise inject it now
    if value_pos ~= "bottom" then
      html_open = html_open .. value_html
    end

    -- Open the details wrapper
    html_open = html_open .. string.format('<div class="details" style="font-size: %s;color:%s;%s">',
      font_size, font_color, details_extra_style)

    -- Close details, optionally append value below, close content wrapper, optionally append icon below, then close outer
    local html_close = '</div>' -- close .details
    if value_pos == "bottom" then
      html_close = html_close .. value_html
    end
    html_close = html_close .. '</div>' -- close .vb-content
    if icon_pos == "bottom" then
      html_close = html_close .. icon_html
    end
    html_close = html_close .. (href ~= "" and '</a>' or '</div>')

    local result = pandoc.List({pandoc.RawBlock("html", html_open)})
    result:extend(el.content)
    result:insert(pandoc.RawBlock("html", html_close))

    quarto.doc.add_html_dependency({
      name = "value-box-styles",
      version = "1.0.0",
      stylesheets = {"value-box.css"}
    })

    return result
  end

end
