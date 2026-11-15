-- Physical connector status also includes outputs disabled by Hyprland.
local M = {}

local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return "" end
    local value = file:read("*a") or ""
    file:close()
    return value
end

local function edid_text(edid, tag)
    for offset = 55, 109, 18 do
        local descriptor = edid:sub(offset, offset + 17)
        if descriptor:sub(1, 3) == "\0\0\0" and descriptor:byte(4) == tag then
            return descriptor:sub(6, 18):gsub("[%z\r\n]", ""):match("^%s*(.-)%s*$")
        end
    end
    return ""
end

function M.read_topology()
    local outputs = {}
    -- Only enumerate filenames in the shell; read status and EDID directly.
    local paths = io.popen("printf '%s\\n' /sys/class/drm/card*-*/status", "r")
    if not paths then return outputs end
    for path in paths:lines() do
        local name = path:match("/card%d+%-(.-)/status$")
        if name and read_file(path):match("^connected%s*$") then
            local edid = read_file(path:gsub("/status$", "/edid"))
            outputs[#outputs + 1] = {
                name = name,
                model = edid_text(edid, 0xfc),
                serial = edid_text(edid, 0xff),
            }
        end
    end
    paths:close()
    table.sort(outputs, function(a, b) return a.name < b.name end)
    return outputs
end

function M.plan(outputs)
    local roles = {}
    local internal = "eDP-1"
    local signature = {}
    local expected = {
        ["25332F001855"] = { role = "main", model = "MO27Q28G" },
        ["UK02346057703"] = { role = "left", model = "PHL27E1N5600H" },
        ["UK02214010768"] = { role = "up", model = "PHL24E1N5300" },
    }
    for _, output in ipairs(outputs) do
        signature[#signature + 1] = output.name .. ":" .. output.model .. ":" .. output.serial
        if output.name:match("^eDP%-") then internal = output.name end
        local device = expected[output.serial]
        if device and output.model == device.model then roles[device.role] = output.name end
    end
    table.sort(signature)
    local desktop = roles.main ~= nil and roles.left ~= nil and roles.up ~= nil
    return {
        desktop = desktop,
        internal = internal,
        main = desktop and roles.main or internal,
        left = roles.left,
        up = roles.up,
        cursor = desktop and { 960, 540 } or { 1280, 720 },
        signature = table.concat(signature, "|"),
    }
end

return M
