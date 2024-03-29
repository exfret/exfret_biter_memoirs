require("names")
require("scripts/show_biter_stats")
require("scripts/initialize_unit")
require("scripts/initialize_nest")
require("scripts/memoir")
require("scripts/nametags")

local function ensure_globals()
    if global.last_memoir_tick == nil then
        global.last_memoir_tick = 0
    end

    if global.unit_info == nil then
        global.unit_info = {}
    end

    if global.nest_info == nil then
        global.nest_info = {}
    end
end

function validate_unit(entity, unit_number)
    if not entity.valid then
        if unit_number ~= nil then
            global.unit_info[entity.unit_number] = nil
        end
        return
    elseif entity.type ~= "unit" then
        return
    end

    if global.unit_info[entity.unit_number] == nil then
        initialize_unit({entity = entity, keep_hidden = true})
    end

    local table_info = global.unit_info[entity.unit_number]

    if table_info.name == nil then
        table_info.name = global.biter_names[math.random(1, #global.biter_names)]
    end
    if table_info.entity == nil then
        table_info.entity = entity
    end
    if table_info.birth == nil then
        table_info.birth = game.tick
    end
end

function validate_spawner(entity, position)
    if not entity.valid then
        if position ~= nil then
            global.nest_info[position.x][position.y] = nil
        end
        return
    elseif entity.type ~= "unit-spawner" then
        return
    end

    local table_info = global.nest_info[entity.unit_number]

    if table_info.name == nil then
        table_info.name = global.nest_names[math.random(1, #global.nest_names)]
    end
end

script.on_init(function ()
    add_names()

    ensure_globals()
end)

script.on_configuration_changed(function()
    game.print("Biter Memoirs: Mod configuration changed, loading names list.")
    add_names()

    ensure_globals()
end)

script.on_event(defines.events.on_entity_spawned, function(event)
    initialize_unit(event)
end)

script.on_event(defines.events.on_entity_died, function(event)
    validate_unit(event.entity)

    if event.entity.type == "unit" then
        if global.unit_info[event.entity.unit_number] ~= nil and global.unit_info[event.entity.unit_number].show_name then
            -- I just want to make very sure the pikachu memoir shows up, so it's hardcoded for now
            if global.unit_info[event.entity.unit_number] ~= nil and (global.unit_info[event.entity.unit_number].name == "Pikachu" or global.unit_info[event.entity.unit_number].name == "Pikachu2") then
                show_memoir(event)
            elseif game.tick - global.last_memoir_tick >= settings.global["exfret-biter-memoirs-min-message-delay"].value and math.random() < settings.global["exfret-biter-memoirs-message-chance"].value then
                show_memoir(event)
            end

            global.unit_info[event.entity.unit_number] = nil
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)
    update_nametags()
end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "initialize_spawner_nest" then
        initialize_nest(event)
    end
end)

script.on_event("show-biter-info", function(event)
    if not game.players[event.player_index].gui.screen.biter_stats_panel then
        if event.selected_prototype ~= nil and event.selected_prototype.derived_type == "unit" then
            local search_distance = 10
            local possible_selections = game.players[event.player_index].surface.find_entities_filtered({position = event.cursor_position, radius = search_distance, type = "unit"})
            local closest_unit
            local closest_unit_distance_squared = search_distance * search_distance
            for _, possible_selection in pairs(possible_selections) do
                local x_diff = possible_selection.position.x - event.cursor_position.x
                local y_diff = possible_selection.position.y - event.cursor_position.y
                if x_diff * x_diff + y_diff * y_diff < closest_unit_distance_squared then
                    closest_unit_distance_squared = x_diff * x_diff + y_diff * y_diff
                    closest_unit = possible_selection
                end
            end

            if closest_unit ~= nil then
                validate_unit(closest_unit)
                show_biter_gui(game.players[event.player_index], closest_unit)
            end
        end
    else
        game.players[event.player_index].gui.screen.biter_stats_panel.destroy()
    end
end)