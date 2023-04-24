local lovit = {
    version = "1.0.0"
}

--- Initializes luvit runtime without checking if it's already loaded. Usefull when spawning new threads.
---@param options table
---@return boolean state
---@return string error
function lovit.init(options)
    local loadfile = loadfile
    local bundle_src = ""
    if love then
        loadfile = love.filesystem.load
        bundle_src = love.filesystem.getSource()
        love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";lovit/luvit/?.lua;lovit/luvit/?/init.lua")
        love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lovit/?")
    end
    options = options or {}

    --custom loading
    package.path = package.path .. ";lovit/luvit/?.lua;lovit/luvit/?/init.lua"

    local lib_ext = ""
    local target_arch, target_os = require("ffi").arch, require("ffi").os

    if type(options.custom_luvi) ~= "string" then
        if target_arch == "x86" or target_arch == "arm" or target_arch == "ppc" or target_arch == "ppc64" then
            local err = target_arch .. " is not a supported architecture"
            if options.throw == true then
                error("Could not load luvi: " .. err)
            end
            return false, err
        end
        if target_os == "OSX" then
            local err = target_os .. " is not a supported platform"
            if options.throw == true then
                error("Could not load luvi: " .. err)
            end
            return false, err
        end
        lib_ext = target_arch .. "."
        if target_os == "Windows" then
            lib_ext = lib_ext .. "dll"
        else
            lib_ext = lib_ext .. "so"
        end
    else
        lib_ext = options.custom_luvi
    end

    local luvi_runtime, lrerr = package.loadlib("lovit/luvi-"..lib_ext, "luaopen_luviruntime")
    -- if bundled, love don't allow loading library inside th zipped game
    if lrerr then luvi_runtime, lrerr = package.loadlib("luvi-"..lib_ext, "luaopen_luviruntime") end

    if luvi_runtime then
        luvi_runtime()
    else
        if options.throw == true then
            error("Could not load luvi: "..lrerr)
        end
        return false, lrerr
    end

    local luvipath = loadfile("lovit/luvi/luvipath.lua", "t", _G)()
    package.preload["luvipath"] = function() return luvipath end

    local luvibundle = loadfile("lovit/luvi/luvibundle.lua", "t", _G)()
    package.preload["luvibundle"] = function() return luvibundle end

    -- load bundle
    bundle_src = bundle_src or require("uv").cwd()
    require("luvi").bundle = luvibundle.makeBundle({bundle_src})

    local uv = require('uv')

    -- load luvit's require
    local req, module = require("require")(uv.cwd())
    _G.module = module
    lovit.require = req

    if options.overwrite_require ~= false then
        _G.require = lovit.require
    end

    _G.process = lovit.require('process').globalProcess()

    -- Seed Lua's RNG
    if options.auto_seed ~= false then
        local math = require('math')
        local os = require('os')
        if type(options.seed) == "number" then
            math.randomseed(options.seed)
        else
            math.randomseed(os.time())
        end
    end

    -- Load Resolver
    if options.load_dns ~= false then
        local dns = lovit.require('dns')
        dns.loadResolver()
    end

    -- EPIPE ignore
    do
        if jit.os ~= 'Windows' then
            local sig = uv.new_signal()
            uv.signal_start(sig, 'sigpipe')
            uv.unref(sig)
        end
    end
end

--- start uv loop and allow it to handle requests
function lovit.update()
    -- run the event loop and alow love to continue
    -- if no event is present
    require("uv").run("nowait")
end

--- stops uv loop and cleanup his handle
function lovit.quit()
    local uv = require("uv")

    -- quit luv's event loop
    uv.stop()

    -- this will be avoided since it cause seg faults.
    -- further research needs to be done with love2d cleanup
    --[[
        local function isFileHandle(handle, name, fd)
            return _G.process[name].handle == handle and uv.guess_handle(fd) == 'file'
        end
        local function isStdioFileHandle(handle)
            return isFileHandle(handle, 'stdin', 0) or isFileHandle(handle, 'stdout', 1) or isFileHandle(handle, 'stderr', 2)
        end
        -- When the loop exits, close all unclosed uv handles (flushing any streams found).
        uv.walk(function (handle)
            if handle then

                -- avoid SIGSEGV error. thoses may be handled be love2d
                local handle_type = uv.handle_get_type(handle)
                if handle_type == "tcp" or handle_type == "signal" or handle_type == "tty" or handle_type == "check" or handle_type == "idle" then return end
                print(handle_type, isStdioFileHandle(handle))
                local function close()
                if not handle:is_closing() then handle:close() end
                end
                -- The isStdioFileHandle check is a hacky way to avoid an abort when a stdio handle is a pipe to a file
                -- TODO: Fix this in a better way, see https://github.com/luvit/luvit/issues/1094
                if handle.shutdown and not isStdioFileHandle(handle) then
                    handle:shutdown(close)
                else
                    close()
                end
            end
        end)
        uv.run()
    ]]
end

--- Initializes luvit runtime
---@param options table
---@return boolean state
---@return string error
local function lovit_main(options)
    -- check if runtime is already loaded
    if ({ pcall(require, "luvi") })[1] then
        return false, "already loaded"
    else -- load it
        return lovit.init(options)
    end
end

lovit = setmetatable(lovit, {
    __call = lovit_main
})

package.preload["lovit"] = function()
    return lovit
end

return lovit