function Div(el)
  if el.classes:includes("value-box") then

    -- Existing attributes
    local icon      = el.attributes["icon"] or ""
    local icon_type = el.attributes["icon-type"] or "bi" -- supports "fa" | "bi" | "svg" | "png"
    local color     = el.attributes["color"] or "bg-blue"
    local value     = el.attributes["value"] or ""
    local width     = el.attributes["width"] or "100%"
    local align     = el.attributes["align"] or "left"
    local href      = el.attributes["href"] or ""

    local icon_size_raw = el.attributes["icon-size"]

    -- em units for font-based icons (BI/FA), px for image-based (SVG/PNG)
    local icon_size_font
    local icon_size_img
    if icon_size_raw then
      -- If the user explicitly set icon-size, use it for both — they know what they're doing
      icon_size_font = icon_size_raw
      icon_size_img  = icon_size_raw
    else
      icon_size_font = "8em"   -- default for BI / FA
      icon_size_img  = "256px"    -- default for SVG / PNG
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

    -- Build the outer wrapper
    local html_open
    if href ~= "" then
      html_open = string.format(
        '<a href="%s" class="value-box %s%s" style="width:%s; text-align:%s; display:block; text-decoration:none; cursor:pointer;"%s>',
        href, color, fragment_class, width, align, index_data
      )
    else
      html_open = string.format(
        '<div class="value-box %s%s" style="width:%s; text-align:%s;"%s>',
        color, fragment_class, width, align, index_data
      )
    end

    -- ADD ICON — all three types use icon_size
    if icon ~= "" then
      if icon_type == "fa" then
        -- Inject FontAwesome CDN into document header
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">')
        html_open = html_open .. string.format(
          '<i class="icon %s" style="font-size:%s;"></i>',
          icon, icon_size_font
        )

      elseif icon_type == "svg" then
        local svg_file = io.open(icon, "r")
        if svg_file then
          local svg_content = svg_file:read("*all")
          svg_file:close()

          svg_content = svg_content:gsub('<svg', string.format(
            '<svg style="width:%s; height:%s;"', icon_size_img, icon_size_img
          ))

          html_open = html_open .. string.format(
            '<span class="icon" style="width:%s; height:%s; display:inline-flex; align-items:center; justify-content:center; font-size:inherit;">%s</span>',
            icon_size_img, icon_size_img, svg_content
          )
        else
          io.stderr:write(string.format("value-box warning: SVG file not found: %s\n", icon))
        end

      elseif icon_type == "png" then
        html_open = html_open .. string.format(
          '<img class="icon" src="%s" style="width:%s; height:%s; object-fit:contain;" alt="">',
          icon, icon_size_img, icon_size_img
        )

      else
        -- Bootstrap Icons
        -- Inject Bootstrap Icons CDN into document header
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">')
        -- Add icon
        html_open = html_open .. string.format(
          '<i class="icon bi %s" style="font-size:%s;"></i>',
          icon, icon_size_font
        )
      end
    end

    -- ADD VALUE (if it exists)
    if value ~= "" then
      html_open = html_open .. string.format('<div class="value">%s</div>', value)
    end

    -- Open the details wrapper
    html_open = html_open .. '<div class="details">'

    local html_close = href ~= "" and '</div></a>' or '</div></div>'

    local result = pandoc.List({pandoc.RawBlock("html", html_open)})
    result:extend(el.content)
    result:insert(pandoc.RawBlock("html", html_close))

    -- Inject the stylesheet automatically (Quarto will safely deduplicate this)
    quarto.doc.add_html_dependency({
      name = "value-box-styles",
      version = "1.0.0",
      stylesheets = {"value-box.css"}
    })

    return result
  end


end
