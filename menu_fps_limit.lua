local metatable = (function()
    -- Metatable magic by Stracker

    local create_namespace
    local namespace_functions = {}

    ---@param self Namespace
    function namespace_functions.T(self)
        return function(ns) return ns._typedef end
    end

    ---@param self Namespace
    function namespace_functions.Instance(self)
        return sdk.get_managed_singleton(self._name)
    end

    local namespace_builder_metatable = {
        ---@param name string
        __index = function(self, name)
            -- Fallback for fields that can't be taken as symbols
            if namespace_functions[name] then
                return namespace_functions[name](self)
            end
            local typedef = rawget(self, "_typedef")
            if typedef then
                local field = typedef:get_field(name)
                if field then
                    if field:is_static() then
                        return field:get_data()
                    end
                    return field
                end

                local method = typedef:get_method(name)
                if method then
                    return method
                end
            end
            local force = false
            if name:sub(1, 2) == "__" then
                name  = name:sub(3)
                force = true
            end
            return create_namespace(rawget(self, "_name") .. "." .. name, force)
        end
    }

    create_namespace = function(basename, force_namespace)
        force_namespace = force_namespace or false

        ---@class Namespace
        local table = { _name = basename }
        if sdk.find_type_definition(basename) and not force_namespace then
            table = { _typedef = sdk.find_type_definition(basename), _name = basename }
        else
            table = { _name = basename }
        end
        return setmetatable(table, namespace_builder_metatable)
    end

    return setmetatable({}, { __index = function(self, name)
        return create_namespace(name)
    end })
end)()

local snow = metatable.snow
local app = metatable.via.Application

local modMenuModule = "ModOptionsMenu.ModMenuApi"
local config_path = "menu_fps_limit.json"
local config = { limit = 40 }
local fps_option_list = { 30.0, 60.0, 90.0, 120.0, 144.0, 165.0, 240.0, 600.0 }

local config_file = json.load_file(config_path)
if config_file ~= nil then
    config = config_file
else
    json.dump_file(config_path, config)
end

local function limit_max_fps(args)
    app:set_MaxFps(config.limit+.0)
end

local function limit_max_fps_if_in_base(args)
    if snow.QuestManager.Instance._QuestStatus == 0 then
        app:set_MaxFps(config.limit+.0)
    end
end

local function reset_max_fps(args)
    local index = snow.StmOptionManager.Instance._StmOptionDataContainer:getFrameRateOption()
    app:set_MaxFps(fps_option_list[index+1])
end

local function empty_post_func(retval)
    return retval
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

sdk.hook(
    snow.NpcCamera.requestMediumCloseUpCamera,
    limit_max_fps_if_in_base,
    empty_post_func
)

sdk.hook(
    snow.NpcCamera.requestReleaseCamera,
    reset_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.fsm.itembox.GuiItemBoxMenu.doOpen,
    limit_max_fps_if_in_base,
    empty_post_func
)

sdk.hook(
    snow.gui.fsm.itembox.GuiItemBoxMenu.doClose,
    reset_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.GuiPauseWindow.doOpen,
    limit_max_fps,
    empty_post_func
)

sdk.hook(
    snow.gui.GuiPauseWindow.doClose,
    reset_max_fps,
    empty_post_func
)

if is_module_available(modMenuModule) then
    modUI = require(modMenuModule);
    local text = "Set framerate limit for item box and smithy menus."
    modUI.OnMenu("Limit Menu Framerate", text, function()
        _, config.limit = modUI.Slider("Limit", config.limit, 30, 90, text)
    end)
end

re.on_config_save(function()
	json.dump_file(config_path, config);
end)
