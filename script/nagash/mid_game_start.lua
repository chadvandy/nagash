-- mid game start file
-- used for dev testing (during our internal beta) and potentially for an optional start campaign mode for release that begins with Nagash at relatively full strength

---@class bdsm
local bdsm = get_bdsm()

--- DEV OPTION
-- Give Nagash the entire world except for BP.
function bdsm:world_domination_start()
    local region_list = cm:model():world():region_manager():region_list()
    local faction_key = self:get_faction_key()

    for i = 0, region_list:num_items() -1 do
        local region = region_list:item_at(i)
        local region_name = region:name()
        if region_name ~= "wh2_main_great_mortis_delta_black_pyramid_of_nagash" then
            cm:transfer_region_to_faction(region_name, faction_key)
        end
    end
end

--- TODO
--- Lock every event tech behind a "TO BE COMPLETED" thing
local function lock_all_techs()
    local mortarchs = bdsm._mortarchs
    ---@type vlib_camp_counselor
    local cc = get_vlib():get_module("camp_counselor")

    local filter = {faction=bdsm:get_faction_key()}

    ---@param mortarch mortarch
    for i, mortarch in ipairs(mortarchs) do
        local key = mortarch.subtype
        if key == "nag_mortarch_arkhan" then
            --- Unlock tech immediately, lock events
            local unlock_tech = key .. "_unlock"
            cc:set_techs_lock_state(unlock_tech, "unlocked", "", filter)
            for j = 1,3 do 
                local event_tech = key .. "_event_"..j

                cc:set_techs_lock_state(event_tech, "locked", "TO BE COMPLETED", filter)
            end
        else
            --- Lock by default for the mission, lock events
            -- mortarch:
            for j = 1,3 do 
                local event_tech = key .. "_event_"..j

                cc:set_techs_lock_state(event_tech, "locked", "TO BE COMPLETED", filter)
            end
        end
    end
end

-- set Black Pyramid to ruined, give Nagash the BP horde, spawn Nagash and Arkhan to the faction
function bdsm:mid_game_start()
    local sentinels_key = "wh2_dlc09_tmb_the_sentinels"
    local bp_key = "wh2_main_great_mortis_delta_black_pyramid_of_nagash"

    cm:set_saved_value("nagash_intro_completed", true)

    -- kill the Sentinels completely
    local sentinels = cm:get_faction(sentinels_key)
    do
        local char_list = sentinels:character_list()
        for i = 0, char_list:num_items() -1  do
            local char = char_list:item_at(i)
            local cqi = char:command_queue_index()

            cm:kill_character_and_commanded_unit("character_cqi:"..cqi, true, false)
        end
    end

    -- ruin the BP and set it as untargetable -- TODO figure out if that fucks any other mods or functionalities
    cm:set_region_abandoned(bp_key)
    cm:cai_disable_targeting_against_settlement("settlement:"..bp_key)

    cm:force_religion_factors(bp_key, "wh_main_religion_undeath", 1)

    local faction_key = bdsm:get_faction_key()
    local faction_obj = cm:get_faction(faction_key)
    local faction_leader = faction_obj:faction_leader()
    local cqi = faction_leader:command_queue_index()

    -- spawn the bone daddy
    local x,y = cm:find_valid_spawn_location_for_character_from_settlement(
        faction_key,
        bp_key,
        false,
        true,
        5
    )

    local ax,ay = cm:find_valid_spawn_location_for_character_from_position(
        faction_key,
        x,
        y,
        true,
        5
    )

    bdsm:log("getting coords:")
    bdsm:log(x)
    bdsm:log(y)

    local units = {
        "nag_vanilla_vmp_inf_skeleton_warriors_0",
        "nag_vanilla_vmp_inf_skeleton_warriors_0",
        "nag_vanilla_tmb_cav_nehekhara_horsemen_0",
        "nag_carrion_riders",
        "nag_nagashi_guard",
        "nag_nagashi_guard_halb",
    }

    cm:create_force_with_general(
        faction_key,
        table.concat(units, ","),
        bp_key,
        x,
        y,
        "general",
        "nag_nagash_boss",
        "names_name_1937224328",
        "",
        "names_name_1777692413",
        "",
        true,
        nil
    )

    cm:create_agent(
        faction_key,
        "spy",
        "nag_morghasts_archai",
        ax,
        ay,
        false,
        function(cqi)

        end
    )

    cm:callback(function()
    -- kill the Mixer-spawned lord
        cm:kill_character_and_commanded_unit("character_cqi:"..cqi, true, false)

        -- local nagash = faction_obj:faction_leader()
        -- local cqi = nagash:command_queue_index()
        -- bdsm:log("Nagash cqi is: "..nagash:command_queue_index())

        -- local mf = nagash:military_force()

        -- bdsm:log("converting")
        -- cm:convert_force_to_type(mf, "black_pyramid")
        -- bdsm:log("converted")
    end, 0.5)

    -- spawn in Arkhan
    local ark = self:get_mortarch_with_key("nag_mortarch_arkhan")
    ark:spawn_to_pool()

    lock_all_techs()

    --- kill Arkhan's faction
    kill_faction("wh2_dlc09_tmb_followers_of_nagash")

    cm:callback(function()
        CampaignUI.ClearSelection()

        -- trigger the How To Play event
        cm:show_message_event(
            faction_key,
            "event_feed_strings_text_wh2_scripted_event_how_they_play_title",
            "factions_screen_name_"..faction_key,
            "event_feed_strings_text_nag_scripted_event_how_they_play_nagasha",
            true,
            594,
            nil,
            nil
        )
    end, 0.1)
end