local function capitalize(str)
    return (string.gsub(str, '^%l', string.upper))
end

local function camelize(str)
    return (string.gsub(str, '%W+(%w+)', capitalize))
end

function friendlyName(str)
    return (camelize(str):gsub("%W", ""))
end

function getFilename(url)
    return url:match("^.+/(.+)%..+$")
end
