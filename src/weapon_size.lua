local modMenuModule = "ModOptionsMenu.ModMenuApi"
local config_path = "weapon_size.json"
local config = { scale = 1.0 }

local typedef = sdk.find_type_definition("snow.player.PlayerWeaponCtrl")
local start_method = typedef:get_method("start")

sdk.hook(start_method, function(args)
    local weapctrl = sdk.to_managed_object(args[2])
    weapctrl:set_field("_bodyConstScale", config.scale)
end, function(retval) end)

if is_module_available(modMenuModule) then
    modUI = require(modMenuModule);
    modUI.OnMenu("Weapon Size", "Change weapon size", function()
        _, config.scale = modUI.FloatSlider("Scale", config.scale, 0.0, 2.0, "Change global weapon size on back")
    end)
end

re.on_config_save(function()
	json.dump_file(config_path, config);
end)
