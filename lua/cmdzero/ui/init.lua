local config = require("cmdzero.config")
local log = require("cmdzero.log")

local M = {}

M.attached = false

function M.attach()
    M.attached = true
    vim.ui_attach(config.ns, { ext_messages = true }, function(event, ...)
        M.handle(event, ...)
    end)
end

function M.detach()
    if M.attached then
        vim.ui_detach(config.ns)
        M.attached = false
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("cmdzero", {})

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = group,
        callback = function()
            M.detach()
            vim.cmd([[redraw]])
        end,
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            M.attach()
        end,
    })

    M.attach()
end

function M.handle(event, ...)
    local event_group, event_type = event:match("([a-z]+)_(.*)")
    local on = "on_" .. event_type

    local ok, handler = pcall(require, "cmdzero.ui." .. event_group)
    if ok and type(handler[on]) == "function" then
        log.debug("handler", event, ...)
        handler[on](event, ...)
    else
        log.debug("no handler for", event_group, event_type, event, ...)
    end
end

return M
