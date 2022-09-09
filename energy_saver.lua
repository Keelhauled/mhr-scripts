local ____IL2CPP = require("energy_saver.IL2CPP.IL2CPP")
local snow = ____IL2CPP.snow
local via = ____IL2CPP.via
local modMenuModule = "ModOptionsMenu.ModMenuApi"
local config_path = "energy_saver.json"
local fps_option_list = { 30, 60, 90, 120, 144, 165, 240, 600 }
local config = { townFps = 60 }
local game_status = 1
local training = false

function get_fps_option()
    local index = snow.StmOptionManager.Instance._StmOptionDataContainer:getFrameRateOption()
    return fps_option_list[index+1]
end

function set_max_fps()
    local fps_option = get_fps_option()
    if fps_option > config.townFps and not training and game_status == 1 then
        via.Application:set_MaxFps(config.townFps+.0)
    else
        via.Application:set_MaxFps(fps_option+.0)
        -- find value for unlimited fps
    end
end

function is_module_available(name)
	if package.loaded[name] then
		return true;
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name);

			if type(loader) == 'function' then
				package.preload[name] = loader;
				return true;
			end
		end

		return false;
	end
end

function blank_pre_func(args) end
function blank_post_func(retval) return retval end

local config_file = json.load_file(config_path)
if config_file ~= nil then
    config = config_file
else
    json.dump_file(config_path, config)
end

-- set fps when game switching between hunts and chill
sdk.hook(snow.QuestManager.onChangedGameStatus,
    function(args)
        game_status = sdk.to_int64(args[3])
        set_max_fps()
    end,
    blank_post_func
)

-- set fps when a setting is changed
sdk.hook(snow.StmOptionManager.applyOptionValue,
    blank_pre_func,
    function(retval)
        set_max_fps()
        return retval
    end
)

-- cutscenes reset fps cap
sdk.hook(snow.eventcut.UniqueEventManager.playEventCommon,
    blank_pre_func,
    function(retval)
        set_max_fps()
        return retval
    end
)

-- track training state
sdk.hook(snow.VillageAreaManager.jump,
    function(args)
        local area_index = sdk.to_int64(args[3])
        training = area_index == 5
        set_max_fps()
    end,
    blank_post_func
)

-- track training state
sdk.hook(snow.VillageState.onExitTrainingArea,
    function(args)
        training = false
    end,
    blank_post_func
)

if is_module_available(modMenuModule) then
    modUI = require(modMenuModule);
    local changed = false
    modUI.OnMenu("Energy Saver", "Options to limit the power usage of the game.", function()
        changed, config.townFps = modUI.Slider("Town Framerate", config.townFps, 10, get_fps_option(), "Set framerate for town.")
        if changed then
            set_max_fps()
        end
    end)
end

re.on_config_save(function()
	json.dump_file(config_path, config);
end)
