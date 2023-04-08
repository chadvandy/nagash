local nagash_faction = "mixer_nag_nagash"

local rite_status = {
    nag_winds = false,
    nag_death = false,
    nag_divinity = false,
    nag_man = false
}



--- unlock rite + show event message
local function unlock_rite(rite_key)
    if rite_status[rite_key] == nil then
        return out("Trying to unlock rite %s but it's not a valid Nagash rite!", tostring(rite_key))
    end

    if rite_status[rite_key] == true then 
        return out("Trying to unlock rite %s but it's already available!", rite_key)
    end

    local faction_key = nagash_faction
    local faction = cm:get_faction(nagash_faction)

    cm:unlock_ritual(faction, rite_key, 0)
    rite_status[rite_key] = true

    cm:callback(
		function()
			cm:show_message_event(
				faction_key,
				"event_feed_strings_text_wh2_event_feed_string_scripted_event_rite_unlocked_primary_detail",
				"rituals_display_name_" .. rite_key,
				"rituals_description_" .. rite_key,
				true,
				902,
				nil,
				nil,
				true
			);
		end,
		0.2
	);
end


local function play_rite()
    out("Rhox Nagash: Inside the rite visibility function")
	local orig_rite_performed = find_uicomponent(core:get_ui_root(), "rite_performed")
	if not orig_rite_performed then 
        out("Rhox Nagash: I don't see any rite")
        --return --not summoned so let's do this
    end

	local rite = core:get_or_create_component("rhox_nagash_rite", "ui/campaign ui/rite_performed", core:get_ui_root())
	if not rite then
        out("Rhox Nagash: Could not create it? Why?")
	end
	for i = 0, rite:ChildCount() - 1 do
		local uic_child = UIComponent(rite:Find(i));
		uic_child:SetVisible(false)
	end;
	
	local tokmbking_animation = find_uicomponent(rite, "wh2_dlc09_tmb_tomb_kings")
	tokmbking_animation:SetVisible(true)

end




function unlock_rites_listeners()
    out("Rhox Nagash Rite listener")
    
    
    core:add_listener(
        "rhox_nagash_rite_animation",
        "RitualStartedEvent",
        function(context)
            return context:performing_faction() == cm:get_local_faction(true) and cm:get_local_faction_name(true) == nagash_faction
        end,
        function()
            cm:callback(function()
                play_rite()
            end, 0)
        end,
        true
    )
    
    if not rite_status.nag_winds then
        -- build the BP Obelisk
        core:add_listener(
            "NagWinds",
            "MilitaryForceBuildingCompleteEvent",
            function(context)
                return context:building() == "nag_bpyramid_main_obelisk_4";
            end,
            function(context)
                --out("Rhox Nagash Nagwinds")
                if not rite_status.nag_winds then
                    out("MilitaryForceBuildingCompleteEvent!")
                    unlock_rite("nag_winds")
                    rite_status.nag_winds = true
                end
            end,
            false
	    )

    end

    if not rite_status.nag_death then
        core:add_listener(
            "NagDeathTurns",
            "FactionTurnStart",
            function(context)
                return context:faction():name() == nagash_faction and cm:turn_number() >= 35
            end,
            function(context)
                out("Rhox Nagash Death")
                if not rite_status.nag_death then
                    unlock_rite("nag_death")
                    rite_status.nag_death = true
                end
            end,
            false
        )
    end

    if not rite_status.nag_divinity then
        --- Nag level
        core:add_listener(
            "NagDivinity",
            "CharacterRankUp",
            function(context)
                local character = context:character()
                return character:faction():name() == nagash_faction and (character:character_subtype_key() == "nag_nagash_husk" or character:character_subtype_key() == "nag_nagash_boss") and character:rank() >= 8
            end,
            function(context)
                out("Rhox Nagash Nagdivinity")
                if not rite_status.nag_divinity then
                    unlock_rite("nag_divinity")
                    rite_status.nag_divinity = true
                end
            end,
            false
        )
    end

    if not rite_status.nag_man then
        core:add_listener(
            "NagMan",
            "RegionFactionChangeEvent",
            function(context)
                local faction = context:region():owning_faction()
                return not faction:is_null_interface() and faction:name() == nagash_faction and faction:region_list():num_items() >= 10
            end,
            function(context)
                out("Rhox Nagash Nagman")
                if not rite_status.nag_man then
                    unlock_rite("nag_man")
                    rite_status.nag_man = true
                end
            end,
            false
        )
    end
    
    local function get_random_mortarch(faction)
        local morts = {}
        local char_list = self:get_faction():character_list()
        for i = 0, char_list:num_items() -1 do
            local char = char_list:item_at(i)
            if char:has_military_force() and char:region():is_null_interface() == false and char:character_subtype_key():find("_mortarch_") then 
                morts[#morts+1] = char
            end
        end

        if #morts == 0 then return nil end

        return morts[cm:random_number(#morts)]
    end

    random_army_manager:new_force("nag_death")

    --- Will always be 1 Nagashi Guard
    random_army_manager:add_mandatory_unit("nag_death", "nag_nagashi_guard", 1)

    --- Numbers here are "weights", which are pooled to determine chance.
    random_army_manager:add_unit("nag_death", "nag_spirit_hosts", 2)
    random_army_manager:add_unit("nag_death", "nag_vanilla_tmb_cav_skeleton_horsemen_0", 2)
    random_army_manager:add_unit("nag_death", "nag_vanilla_tmb_inf_skeleton_archers_0", 2)
    random_army_manager:add_unit("nag_death", "nag_vanilla_tmb_inf_skeleton_spearmen_0", 6)
    random_army_manager:add_unit("nag_death", "nag_vanilla_vmp_inf_zombie", 6)
    
    core:add_listener(
        "NagDeath",
        "RitualCompletedEvent",
        function(context)
            return context:ritual():ritual_key() == "nag_death"
        end,
        function(context)
            
            --- spawn a death army at Nagash, at BP, or at a random Mortarch, or at a random settlement, in that order.
            local faction = cm:get_faction(nagash_faction)
            local nag = cm:get_faction(nagash_faction):faction_leader()
            local key = nagash_faction
            local x,y,region
            if nag:has_military_force() and nag:region():is_null_interface() == false then
                x,y = cm:find_valid_spawn_location_for_character_from_character(key, "character_cqi:"..nag:command_queue_index(), true, 5)
                region = nag:region():name()
            else
                -- check BP
                local bp = cm:get_region("wh3_main_combi_region_black_pyramid_of_nagash")
                if bp and bp:owning_faction():is_null_interface() == false and bp:owning_faction():name() == key then 
                    x,y = cm:find_valid_spawn_location_for_character_from_settlement(key, "wh3_main_combi_region_black_pyramid_of_nagash", false, true, 5)
                    region = bp
                else
                    -- check for a random mortarch
                    local random_mort = get_random_mortarch(faction)
                    if random_mort then
                        x,y = cm:find_valid_spawn_location_for_character_from_character(key, "character_cqi:"..random_mort:command_queue_index(), true, 5)
                        region = random_mort:region():name()
                    else
                        -- check for a random settlement
                        local settlement_list = faction:region_list()
                        local random_settlement = settlement_list:item_at(cm:random_number(settlement_list:num_items()-1, 0))

                        x,y = cm:find_valid_spawn_location_for_character_from_settlement(key, random_settlement:name(), false, true, 5)
                        region = random_settlement:name()
                    end
                end
            end

            --- spawn the army
            cm:create_force(
                key,
                random_army_manager:generate_force("nag_death", 19, false),
                region,
                x,
                y,
                true,
                function(char_cqi, mf_cqi)
                    local mf = cm:get_military_force_by_cqi(mf_cqi)
                    --- TODO apply EB for the duration of the ritual
                    local eb_key = "nag_death_shambling_horde"
                    cm:apply_effect_bundle_to_force(eb_key, mf_cqi, 5)

                    -- cm:convert_force_to_type(mf, "nag_shambling_horde")
                end,
                false
            )

            --- TODO add an event message
        end,
        true
    )
end




--------------------------------------------------------------
----------------------- SAVING / LOADING ---------------------
--------------------------------------------------------------
cm:add_saving_game_callback(
	function(context)
		cm:save_named_value("rhox_nagash_rite_status", rite_status, context)
	end
)
cm:add_loading_game_callback(
	function(context)
		if cm:is_new_game() == false then
			rite_status = cm:load_named_value("rhox_nagash_rite_status", rite_status, context)
		end
	end
)