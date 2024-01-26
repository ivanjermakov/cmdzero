local M = {}

function M.protect(fn, msg)
	return function(...)
		local args = { ... }

		return xpcall(function()
			return fn(unpack(args))
		end, function(err)
			local lines = {}
			if msg then
				table.insert(lines, msg)
			end
			table.insert(lines, err)
			table.insert(lines, debug.traceback("", 3))

			M.error(table.concat(lines, "\n"))
			return err
		end)
	end
end

function M.try(fn, msg, ...)
	return M.protect(fn, msg)(...)
end

function M.notify(msg, level)
	vim.notify(msg, level, {
		title = "cmdzero.nvim",
		on_open = function(win)
			vim.api.nvim_win_set_option(win, "conceallevel", 3)
			local buf = vim.api.nvim_win_get_buf(win)
			vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
			vim.api.nvim_win_set_option(win, "spell", false)
		end,
	})
end

function M.warn(msg)
	M.notify(msg, vim.log.levels.WARN)
end

function M.error(msg)
	M.notify(msg, vim.log.levels.ERROR)
end

function M.info(msg)
	M.notify(msg, vim.log.levels.INFO)
end

return M
