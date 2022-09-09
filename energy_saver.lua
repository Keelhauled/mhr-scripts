local app = sdk.get_native_singleton("via.Application")
local via_app_type_definition = sdk.find_type_definition("via.Application")
local set_MaxFps = via_app_type_definition:get_method("set_MaxFps")

local ____IL2CPP = require("MonsterJournalPage.IL2CPP.IL2CPP")
local snow = ____IL2CPP.snow
local via = ____IL2CPP.via
local modMenuModule = "ModOptionsMenu.ModMenuApi"
local config_path = "energy_saver.json"

local fps_option_list = { 30, 60, 90, 120, 144, 165, 240, 600 }
local config = { townFps = 60 }
local game_status

function get_fps_option()
    --local index = sdk.get_managed_singleton("snow.StmOptionManager"):get_field("_StmOptionDataContainer"):call("getFrameRateOption")
    local index = snow.StmOptionManager.Instance._StmOptionDataContainer.getFrameRateOption()
    return fps_option_list[index+1]
end

function status_changed(new_status)
    log.debug("Game status: " .. tostring(new_status))
    game_status = new_status
    
    local selected_fps_option = get_fps_option()
    if selected_fps_option > config.townFps then
        if new_status == 1 then
            set_MaxFps:call(app, config.townFps+.0)
            --via.Application.Instance.set_MaxFps(config.townFps+.0)
        else
            set_MaxFps:call(app, selected_fps_option+.0)
            --via.Application.Instance.set_MaxFps(selected_fps_option+.0)
        end
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
    function(args) status_changed(sdk.to_int64(args[3])); end,
    function(retval) return retval; end);

if is_module_available(modMenuModule) then
    modUI = require(modMenuModule);

    local changed = false
    local name = "Energy Saver";
    local description = "Options to limit the power usage of the game.";
    local modObj = modUI.OnMenu(name, description, function()
        changed, config.townFps = modUI.Slider("Town Framerate", config.townFps, 10, get_fps_option(), "Set framerate for town.")

        if changed then
            if game_status == 1 then
                set_MaxFps:call(app, config.townFps+.0)
                --via.Application.Instance.set_MaxFps(config.townFps+.0)
            end
        end
    end)
end

re.on_config_save(function()
	json.dump_file(config_path, config);
end)
