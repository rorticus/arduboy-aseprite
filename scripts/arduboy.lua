Format1BitHorizontal = "1 bit (horizontal)"
Format1BitVertical = "1 bit (vertical)"
Format8Bit = "8 bit (indexed)"
Format32Bit = "32 bit (RGBA)"

LayersSeparate = "Individually"
LayersFlat = "Flattened Together"

dofile('./helpers.lua')
dofile('./bits.lua')

function hexFromImage(img, format)
    local width = img.width
    local height = img.height

    local bitArray

    if format == Format1BitHorizontal then
        bitArray = HorizontalBitArray:create(width, height)
    elseif format == Format1BitVertical then
        bitArray = VerticalBitArray:create(width, height)
    elseif format == Format8Bit then
        bitArray = HorizontalByteArray:create(width, height)
    elseif format == Format32Bit then
        bitArray = RGBAByteArray:create(width, height)
    end

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local c = Color(img:getPixel(x, y))
            bitArray:set(x, y, c)
        end
    end

    local hexArray = bitArray:toHexArray()

    return hexArray
end

function hexArrayToCString(hexArray, opts)
    local str = ""
    local chars = 0

    local template = opts.template
    local name = opts.name
    local width = opts.width
    local height = opts.height
    local sized = opts.sized

    str = string.format("%s = {\n    ", string.gsub(template, 'NAME', name))

    if sized then
        if not name:find("Mask") then
            str = str .. string.format("%d, %d,\n    ", width, height)
        end
    end

    for i = 0, #hexArray - 1 do
        str = str .. string.format("0x%s", hexArray[i])
        if i < #hexArray - 1 then
            str = str .. ", "
        end

        chars = chars + 1

        if chars >= 16 then
            str = str .. "\n    "
            chars = 0
        end
    end

    str = str .. "\n};\n";

    return str
end

function convertImageToCString(img, opts)
    local format = opts.format
    local name = opts.name or 'unnamed'

    local hexArray = hexFromImage(img, format)

    return hexArrayToCString(hexArray, {
        template= opts.template,
        sized= opts.sized,
        width= img.width,
        height= img.height,
        name= friendlyName(name)
    })
end

function convertAllLayersOfSprite(sprite, frame, opts)
    local format = opts.format
    local str = ""

    for l = 1, #sprite.layers do

        local layer = sprite.layers[l]

        for c = 1, #layer.cels do
            local img = Image(sprite.spec)
            img:clear()

            local celImg = layer.cels[c].image
            img:drawImage(celImg, layer.cels[c].position)

            str = str .. convertImageToCString(img, {
                template= opts.template,
                format= format,
                sized= opts.sized,
                width= img.width,
                height= img.height,
                name= friendlyName(layer.name)
            }) .. "\n"
        end
    end

    return str
end

function convertSprite(sprite, frame, opts)
    local format = opts.format

    local img = Image(sprite.spec)
    img:clear()
    img:drawSprite(sprite)

    return convertImageToCString(img, {
        template= opts.template,
        format= format,
        sized= opts.sized,
        width= img.width,
        height= img.height,
        name= friendlyName(getFilename(sprite.filename or "unnamed"))
    })
end

function generateCString(opts)
    local sprite = opts.sprite
    local frame = opts.frame
    local layers = opts.layers

    if layers == LayersSeparate then
        return convertAllLayersOfSprite(sprite, frame, opts)
    elseif layers == LayersFlat then
        return convertSprite(sprite, frame, opts)
    end

    return ""
end

function doExport(opts)
    local spr = app.activeSprite
    if not spr then return app.alert "There is no active sprite" end

    local dlg = Dialog{ title = "Export for Arduboy" }

    local formats = {
        Format1BitHorizontal,
        Format1BitVertical
    }

    if spr.spec.colorMode == ColorMode.GRAY or spr.spec.colorMode == ColorMode.INDEXED then
        formats[#formats + 1] = Format8Bit
    end

    formats[#formats + 1] = Format32Bit
    
    dlg:combobox{
        id="format",
        label="Format:",
        option=opts.format,
        options=formats
    }
    dlg:combobox{
        id="layers",
        label="Export Layers:",
        option=opts.layers,
        options={
            LayersSeparate,
            LayersFlat
        }
    }
    dlg:entry{ id="template", label="Template:", text=opts.template }
    dlg:check{ id="sized", label="Include Dimensions:", selected=opts.includeSize }
    dlg:button{ id="confirm", text="Generate", onclick=function () 
        dlg:close()

        local data = dlg.data

        opts.template = dlg.data.template
        opts.includeSize = dlg.data.sized
        opts.format = dlg.data.format
        opts.layers = dlg.data.layers

        print(generateCString {
            sprite=app.activeSprite,
            frame=app.activeFrame,
            template=dlg.data.template,
            sized=dlg.data.sized,
            format=dlg.data.format,
            layers=dlg.data.layers
        })
    end }

    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()    
end

function init(plugin)
    print("Aseprite is initializing my plugin")

    if plugin.preferences.template == nil then
        plugin.preferences.template = "const uint8_t PROGMEM"
    end

    if plugin.preferences.includeSize == nil then
        plugin.preferences.includeSize = true
    end

    if plugin.preferences.format == nil then
        plugin.preferences.format = Format1BitVertical
    end

    if plugin.preferences.layers == nil then
        plugin.preferences.layers = LayersSeparate
    end

    plugin:newCommand{
        id="ExportForArduboy",
        title="Export as C Array...",
        group="file_export",
        onclick=function()
            doExport(plugin.preferences)
        end
    }
end
