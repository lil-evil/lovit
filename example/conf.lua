-- initialization of lovit
require("lovit/init")()



function love.conf(t)
    t.console = true

    t.window.title = "lovit"
    t.window.vsync = 0
end