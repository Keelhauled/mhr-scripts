local ____IL2CPP = require("energy_saver.IL2CPP.IL2CPP")
local snow = ____IL2CPP.snow
local via = ____IL2CPP.via
local modMenuModule = "ModOptionsMenu.ModMenuApi"
local config_path = "energy_saver.json"
local fps_option_list = { 30, 60, 90, 120, 144, 165, 240, 600 }
local config = { townFps = 60, unfocusedFps = 30 }
local game_status = 1

function get_fps_option()
    local index = snow.StmOptionManager.Instance._StmOptionDataContainer:getFrameRateOption()
    return fps_option_list[index+1]
end

function set_max_fps()
    if game_status == 1 then
        via.Application:set_MaxFps(config.townFps+.0)
    else
        via.Application:set_MaxFps(selected_fps_option+.0)
        -- find value for unlimited fps
    end
end

function game_status_changed(game_status_new)
    game_status = game_status_new
    local selected_fps_option = get_fps_option()
    if selected_fps_option > config.townFps then
        set_max_fps()
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

local config_file = json.load_file(config_path)
if config_file ~= nil then
    config = config_file
else
    json.dump_file(config_path, config)
end

sdk.hook(snow.QuestManager.onChangedGameStatus,
    function(args) game_status_changed(sdk.to_int64(args[3])); end,
    function(retval) return retval; end)

if is_module_available(modMenuModule) then
    modUI = require(modMenuModule);

    local changed = false
    modUI.OnMenu("Energy Saver", "Options to limit the power usage of the game.", function()
        changed, config.townFps = modUI.Slider("Town Framerate", config.townFps, 10, get_fps_option(), "Set framerate for town.")
        if changed then set_max_fps() end
    end)
end

re.on_config_save(function()
	json.dump_file(config_path, config);
end)
