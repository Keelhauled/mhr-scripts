local ____IL2CPP = require("energy_saver.IL2CPP.IL2CPP")
local snow = ____IL2CPP.snow
local via = ____IL2CPP.via

local max_fps = via.Application:get_MaxFps()

function limit_max_fps(args)
    via.Application:set_MaxFps(40.0)
end

function reset_max_fps(args)
    via.Application:set_MaxFps(max_fps)
end

function empty_post_func(retval)
    return retval
end

sdk.hook(
    snow.gui.fsm.smithy.GuiSmithy.doOpen,
    limit_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.fsm.smithy.GuiSmithy.doClose,
    reset_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.fsm.itembox.GuiItemBoxMenu.doOpen,
    limit_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.fsm.itembox.GuiItemBoxMenu.doClose,
    reset_max_fps,
    empty_post_func
)
