# Lovit
> love2d and luvit on same runtime

These two lua runtime are both for different purpose, one for games, and the other for servers.

I tried to add luvit to love, and nailed it (still it may have some bugs, or game performances drops)

This was just a fun thing to do, but if some a y'all find a good reason to make a stable version of lovit (since love already include luasocket natively, a relatively good fs api...), then share your idea with me! (my discord : `little#8291`)

## How to use

### Coding your game with lovit
When creating your game and testing, you just nee to put the `src` folder, renamed as `lovit` into your game's root folder

You can see an example in the `example` folder ( you will need to copy lovit along side with the example games, and run it with a console open)

before using luvit's modules, you will need to add the following line 
```lua
require("lovit/init")()
```
It can take parameters : 
```lua
require("lovit/init")({
    custom_luvi = string,           -- provide your own path to luvi library.
                                    -- be aware this cannot be inside of the .love archive !

    load_dns = boolean,             -- load the dns resolver. default: true
    overwrite_require = boolean,    -- if it overwrite require with lovit.require. default: true
    auto_seed = boolean,            -- weither to seed math.random. default: true
    seed = number,                  -- seed to use fot math.random. default: os.time()
    throw = boolean                 -- allow the init script to throw an error default: false
                                    -- init always return state, error.
})
```

Then you need to allow luv to do his work : 
```lua
local lovit = require"lovit"

function love.update()
    -- your game's update
    lovit.update()
end

function love.quit()
    lovit.quit()
end
```
With this, luv share your game ressource and this allow you to skip luv update when your game's update is slowed. 

### Release your game with lovit
>**Don't** do that unless you're sure of this to work. I'm not responsible if your game crash at some points.

If you need to provide your game in a .love format or in appimage (which I higtly advice against since it not stable and no testing was done ! ) you will need :

> to read [this](https://love2d.org/wiki/Game_Distribution)

- For any .love format or love executable concatenated with the .love archive:

    Put the correspondible `luvi-*.so` or `luvi-*.dll` file alongside the executable (or in a lua/love search path).
    For Windows, the .dll files in `distribution/windows/` must be included too (on linux they would be provided by the package manager)

- For an appimage

    Use whatever way to create a valid love appdir that suit you more, and add you game's executable wherever you want, and dont forget to put the corresponding `luvi-**.so` for the targeted platform in the lua search path (e.g. `share/luajit-*/luvi-*.so` )


When distributing your game you can get rid of `lovit/distrubution/` and `lovit/luvi-*` since they are provided here for testing you game, and take alot of place

if you want to compile your own luvi library, you can find my luvi fork [here](https://github.com/lil-evil/luvi) (just follow the regular build tutorial, i automaticaly compile a shared library)