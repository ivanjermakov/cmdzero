local config = require("cmdzero.config")
local log = require("cmdzero.log")
local nui_line = require("nui.line")

local M = {}

---@alias RenderFunc fun(renderer: Renderer, clear?: boolean)

---@class Renderer
---@field _render RenderFunc
---@field lines NuiLine[]
---@field opts? table
---@field dirty boolean
---@field _clear boolean
local Renderer = {}
Renderer.__index = Renderer

---@param render string
---@param opts? table
function M.new(render, opts)
    return setmetatable({
        _render = M[render],
        opts = opts or {},
        dirty = false,
        lines = {},
    }, Renderer)
end

function Renderer:render()
    if self.dirty then
        log.debug("render", self)
        local ok, err = pcall(self._render, self)
        if not ok then
            vim.notify(err, "error", { title = "Messages" })
        end
        self.dirty = false
    end
end

function Renderer:clear()
    self._clear = true
end

function Renderer:render_buf(buf, opts)
    opts = opts or {}
    for l, line in ipairs(self.lines) do
        line:render(buf, config.ns, l + (opts.offset or 0))
    end
end

function Renderer:get_text()
    return table.concat(
        vim.tbl_map(
            function(l) return l:content() end,
            self.lines
        ),
        "\n"
    )
end

function Renderer:add(chunks)
    if self._clear then
        self.lines = {}
        self._clear = false
    end
    self.dirty = true
    for _, chunk in ipairs(chunks) do
        local attr_id, text = unpack(chunk)

        local function append(l)
            if #self.lines == 0 then
                table.insert(self.lines, nui_line())
            end
            local line = self.lines[#self.lines]
            line:append(l)
        end

        while text ~= "" do
            local nl = text:find("\n")
            if nl then
                local str = text:sub(1, nl - 1)
                append(str)
                table.insert(self.lines, nui_line())
                text = text:sub(nl + 1)
            else
                append(text)
                text = ""
            end
        end
    end
end

setmetatable(M, {
    __index = function(_, key)
        return require("cmdzero.render." .. key)
    end,
})

return M
