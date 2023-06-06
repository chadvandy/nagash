rhox_nagash_guinevere_info={ --global so others can approach this too
    traits=nil, --trait, it will transfer to the next faction also
    rank=1, --rank, it will transfer to the next faction also
    previous_faction=nil, --she never visits two factions in a row
    current_faction=nil, --to check whether this faction has been annihilated or not
    remaining_turn=-1,
    trespass_immune_character_cqi =-1,
    bonus_turns =0,
    num_uses=0
}  


local guin_base_turn = 20

local guin_culture={
    wh3_main_ksl_kislev = true,
    wh_main_brt_bretonnia = true,
    wh_main_emp_empire = true,
    wh_main_vmp_vampire_counts = true
}

local function get_character_by_subtype(subtype, faction)
    local character_list = faction:character_list()
    
    for i = 0, character_list:num_items() - 1 do
        local character = character_list:item_at(i)
        
        if character:character_subtype(subtype) then
            return character
        end
    end
    return false
end

core:add_listener(
    "rhox_nagash_guin_giving_turn_start",
    "WorldStartRound",
    function(context)
        if cm:model():turn_number() < 5 then --don't trigger it until the turn 5
            return false
        end
    
        return rhox_nagash_guinevere_info.remaining_turn == -1 --character turn start would reduce this value
    end,
    function(context)
        out("Rhox Nagash Guin: Sending Guin to somewhere")
        local all_factions = cm:model():world():faction_list();
        local visit_candidate ={}
        for i = 0, all_factions:num_items()-1 do
            local faction = all_factions:item_at(i);
            if guin_culture[faction:culture()] and faction:is_dead() == false and faction:has_faction_leader() and faction:faction_leader():has_military_force() then --we're going to summon her to where the faction leader is, so faction leader must have military force
                table.insert(visit_candidate, faction:name());
            end
        end;
        
        visit_candidate = cm:random_sort(visit_candidate);
        local target_faction = nil
        for i=1,#visit_candidate do
            if visit_candidate[i] ~= previous_faction then
                target_faction = visit_candidate[i]
                break
            end
        end
        
        if cm:model():turn_number() ==5 then
            target_faction = "wh3_main_vmp_lahmian_sisterhood"
        end
        
        if not target_faction then
            out("Rhox Nagash Guin: No available target faction found, ")
            return
        end
        local guin_faction = cm:get_faction(target_faction)
        
        
        out("Rhox Nagash Guin: Guin going to ".. target_faction)
        local x, y = cm:find_valid_spawn_location_for_character_from_character(target_faction, cm:char_lookup_str(guin_faction:faction_leader()), true, 10)
        cm:spawn_agent_at_position(guin_faction, x, y, "dignitary", "nag_guinevere")
        local new_character = cm:get_most_recently_created_character_of_type(target_faction, "dignitary", "nag_guinevere")
        if new_character then
            local forename = common:get_localised_string("names_name_1937224343")
            cm:change_character_custom_name(new_character, forename, "","","")
            ---aplying the previous bonuses
            local new_char_lookup = cm:char_lookup_str(new_character)
            local traits_to_copy = rhox_nagash_guinevere_info.traits
            if traits_to_copy then
                for i =1, #traits_to_copy do
                    local trait_to_copy = traits_to_copy[i]
                    cm:force_add_trait(new_char_lookup, trait_to_copy)
                end
            end
            cm:add_agent_experience(new_char_lookup,rhox_nagash_guinevere_info.rank, true)
        end
        rhox_nagash_guinevere_info.remaining_turn = guin_base_turn
        cm:apply_effect_bundle("rhox_nagash_guinevere_remaining_turn_dummy", target_faction, rhox_nagash_guinevere_info.remaining_turn)
        rhox_nagash_guinevere_info.current_faction = target_faction
        if guin_faction:is_human() then --trigger incident
            cm:trigger_incident_with_targets(guin_faction:command_queue_index(), "rhox_nagash_guin_arrive", 0, 0, new_character:command_queue_index(), 0, 0, 0)
        end
        
    end,
    true
)

local function rhox_nagash_guinevere_check_depart(character, faction)
    rhox_nagash_guinevere_info.remaining_turn = rhox_nagash_guinevere_info.remaining_turn -1
    out("Rhox Nagash Guin: Checking depart: Remaining turn ".. rhox_nagash_guinevere_info.remaining_turn)
    if rhox_nagash_guinevere_info.remaining_turn <= 0 then
        rhox_nagash_guinevere_info.previous_faction = faction:name()
        rhox_nagash_guinevere_info.remaining_turn = -1;
        
        local value = 500+ 1000*rhox_nagash_guinevere_info.num_uses
        
        if faction:is_human() then
            local incident_builder = cm:create_incident_builder("rhox_nagash_guin_leave")
            incident_builder:add_target("default", character)
            local payload_builder = cm:create_payload()
            payload_builder:treasury_adjustment(value)
            payload_builder:text_display("rhox_nagash_guinevere_departs")
            payload_builder:text_display("rhox_nagash_guinevere_presents")
            incident_builder:set_payload(payload_builder)
            cm:launch_custom_incident_from_builder(incident_builder, faction)
            --cm:trigger_incident_with_targets(faction:command_queue_index(), "rhox_nagash_guin_leave", 0, 0, character:command_queue_index(), 0, 0, 0)
        else
            cm:treasury_mod(faction:name(), value)--just add gold for the ai
        end
        --out("Rhox Nagash Guin: Triggered incident")
        
        rhox_nagash_guinevere_info.traits=character:all_traits()
        rhox_nagash_guinevere_info.rank=character:rank()
        
        --out("Rhox Nagash Guin: Stored information")
        
        cm:disable_event_feed_events(true, "wh_event_category_character", "", "")
        --cm:set_character_immortality(cm:char_lookup_str(character), false)
        cm:suppress_immortality(character:family_member():command_queue_index(), true) 
		cm:kill_character(cm:char_lookup_str(character), false)

        
        --out("Rhox Nagash Guin: Killed her")
        
        
        cm:callback(function() cm:disable_event_feed_events(false, "wh_event_category_character", "", "") end, 0.2)
        rhox_nagash_guinevere_info.current_faction = nil
        rhox_nagash_guinevere_info.bonus_turns =0
        rhox_nagash_guinevere_info.num_uses =0
    end
end

local function rhox_nagash_guinevere_remove_trespass_immune()
    if rhox_nagash_guinevere_info.trespass_immune_character_cqi ~= -1 then
        local character = cm:get_character_by_cqi(rhox_nagash_guinevere_info.trespass_immune_character_cqi)
        cm:set_character_excluded_from_trespassing(character, false)
        rhox_nagash_guinevere_info.trespass_immune_character_cqi = -1
        out("Rhox Nagash Guin: Removing tresspass immune from guy with cqi: ".. rhox_nagash_guinevere_info.trespass_immune_character_cqi)
    end
end

local function rhox_nagash_guinevere_apply_trespass_immune(character)
    if character:has_skill("nag_skill_node_guinevere_diplo_01") == false then
        return --need skill
    end
    if character:is_embedded_in_military_force() then
        local mf = character:embedded_in_military_force()
        local general = mf:general_character()
        if not general then
            return
        end
        rhox_nagash_guinevere_info.trespass_immune_character_cqi = general:cqi()
        out("Rhox Nagash Guin: Applying tresspass immune to guy with cqi: ".. general:cqi())
        cm:set_character_excluded_from_trespassing(general, true)
    end
end

local function rhox_nagash_guinevere_apply_prostitute(character, faction)
    if character:bonus_values():scripted_value("rhox_nagash_guine_prostitute", "value") == 0 or not character:region() then
        return --don't do it
    end
    local region = character:region()
    local owning_faction = region:owning_faction()
    if not owning_faction then
        return
    end
    
    if owning_faction:has_effect_bundle("rhox_nagash_guinevere_relation_increased_hidden") then
        return --don't apply bonus again
    end
    
    if guin_culture[owning_faction:culture()] then
        cm:apply_effect_bundle("rhox_nagash_guinevere_relation_increased_hidden", owning_faction:name(), 5)
        local value = math.floor((character:bonus_values():scripted_value("rhox_nagash_guine_prostitute", "value")/5)  +0.2)  --doing this just in case
        out("Rhox Nagash Guin: Applying Prostitute bonus ".. value .. " to faction ".. owning_faction:name())
        cm:apply_dilemma_diplomatic_bonus(faction:name(), owning_faction:name(), value)
    end
    
end

local function rhox_nagash_guinevere_apply_high_vamp_corruption_bonus(character, faction)
    if character:has_skill("nag_skill_node_guinevere_diplo_05") == false then
        return--don't do it if she don't have skill
    end
    if cm:get_corruption_value_in_region(character:region(), "wh3_main_corruption_vampiric") > 80 and character:is_embedded_in_military_force() then
        local mf = character:embedded_in_military_force()
        out("Rhox Nagash Guin: Applying high vamp corruption bonus to military force cqi: ".. mf:command_queue_index())
        cm:apply_effect_bundle_to_force("rhox_nagash_guinevere_high_corruption_bonus", mf:command_queue_index(), 2) --turn is 2 so players could see it
    end
end

local function rhox_nagash_guinevere_apply_bonus_duration(character, faction)
    local value = character:bonus_values():scripted_value("rhox_nagash_guine_longer_stay", "value")
    
    if value == rhox_nagash_guinevere_info.bonus_turns then --nothing to do
        return
    end
    
    local bonus_value = value - rhox_nagash_guinevere_info.bonus_turns
    
    out("Rhox Nagash Guin: Applying bonus remaining turn: ".. bonus_value)
    
    rhox_nagash_guinevere_info.bonus_turns= value
    rhox_nagash_guinevere_info.remaining_turn = rhox_nagash_guinevere_info.remaining_turn+ bonus_value
    cm:apply_effect_bundle("rhox_nagash_guinevere_remaining_turn_dummy", faction:name(), bonus_value)
    
    
end

core:add_listener(
    "rhox_nagash_guin_remaining_turn_check",
    "CharacterTurnStart",
    function(context)
        local character = context:character()
        return character:character_subtype_key() == "nag_guinevere"
    end,
    function(context)
        local character = context:character()
        local faction = character:faction()
        
        rhox_nagash_guinevere_remove_trespass_immune()
        rhox_nagash_guinevere_apply_trespass_immune(character)
        
        rhox_nagash_guinevere_apply_prostitute(character, faction)
        
        rhox_nagash_guinevere_apply_high_vamp_corruption_bonus(character, faction)
        
        rhox_nagash_guinevere_apply_bonus_duration(character, faction)
        cm:callback(function()
            rhox_nagash_guinevere_check_depart(character, faction)--do it last
            end,
        5)
    end,
    true
)



core:add_listener(
    "rhox_nagash_guin_embed_listener",
    "CharacterCharacterTargetAction",
    function(context)
        return context:agent_action_key() == "wh2_main_agent_action_dignitary_assist_army_replenish_troops" and context:character():character_subtype_key() == "nag_guinevere" and context:character():has_skill("nag_skill_node_guinevere_diplo_01") and rhox_nagash_guinevere_info.trespass_immune_character_cqi == -1 --last is to not apply to the two different mfs
    end,
    function(context)
        local character = context:character()
        rhox_nagash_guinevere_apply_trespass_immune(character)
    end,
    true
)

core:add_listener(
    "rhox_nagash_guin_settlement_listener",
    "CharacterGarrisonTargetAction",
    function(context)
        return context:character():character_subtype_key() == "nag_guinevere" and context:character():bonus_values():scripted_value("rhox_nagash_guine_settlement", "value") ~= 0 and (context:mission_result_critial_success() or context:mission_result_success())
    end,
    function(context)
        out("Rhox Nagash Guin: Garrison action Success!")
        local character = context:character()
        local faction = character:faction()
        local region = context:garrison_residence():region();
        local owning_faction = region:owning_faction()
        if not owning_faction then
            return--it's garrison target so they're likely to have it, but just in case
        end
        
        if owning_faction:has_effect_bundle("rhox_nagash_guinevere_relation_increased_hidden") then
            return --don't apply bonus again
        end
        
        if guin_culture[owning_faction:culture()] then
            cm:apply_effect_bundle("rhox_nagash_guinevere_relation_increased_hidden", owning_faction:name(), 5)
            local value = math.floor((character:bonus_values():scripted_value("rhox_nagash_guine_settlement", "value")/5)  +0.2)  --doing this just in case
            out("Rhox Nagash Guin: Applying settlement action diplo bonus ".. value .. " to faction ".. owning_faction:name())
            cm:apply_dilemma_diplomatic_bonus(faction:name(), owning_faction:name(), value)
        end
    end,
    true
)


---------------------------guin increase number of uses

core:add_listener(
    "rhox_nagash_guin_increase_num_character_action",
    "CharacterCharacterTargetAction",
    function(context)
        return context:character():character_subtype_key() == "nag_guinevere" and (context:mission_result_critial_success() or context:mission_result_success())
    end,
    function(context)
        rhox_nagash_guinevere_info.num_uses = rhox_nagash_guinevere_info.num_uses+1
    end,
    true
)

core:add_listener(
    "rhox_nagash_guin_increase_num_settlement_action",
    "CharacterGarrisonTargetAction",
    function(context)
        return context:character():character_subtype_key() == "nag_guinevere" and (context:mission_result_critial_success() or context:mission_result_success())
    end,
    function(context)
        rhox_nagash_guinevere_info.num_uses = rhox_nagash_guinevere_info.num_uses+1
    end,
    true
)
core:add_listener(
    "rhox_nagash_guin_increase_num_battle",
    "CharacterCompletedBattle",
    function(context)
        local character = context:character()
        local faction = character:faction()
        local guin = get_character_by_subtype("nag_guinevere", faction)
        
        local pb = context:pending_battle();

        return pb:has_been_fought() and character:won_battle() and character:has_military_force() and guin and guin:is_embedded_in_military_force() and guin:embedded_in_military_force():command_queue_index() == character:military_force():command_queue_index()
    end,
    function(context)
        rhox_nagash_guinevere_info.num_uses = rhox_nagash_guinevere_info.num_uses+1        
        out("Rhox Nagash Guin: Guin embedded army wins the battle, increasing the num to ".. rhox_nagash_guinevere_info.num_uses)
    
    
        
    end,
    true
)





--------------------------------------------------------------
----------------------- SAVING / LOADING ---------------------
--------------------------------------------------------------
cm:add_saving_game_callback(
	function(context)
		cm:save_named_value("rhox_nagash_guinevere_info", rhox_nagash_guinevere_info, context)
	end
)
cm:add_loading_game_callback(
	function(context)
		if cm:is_new_game() == false then
			rhox_nagash_guinevere_info = cm:load_named_value("rhox_nagash_guinevere_info", rhox_nagash_guinevere_info, context)
		end
	end
)
