        










local rhox_settlement_candidate_table={}

local choice_string ={
    "FIRST",
    "SECOND",
    "THIRD",
    "FOURTH"
}


local function rhox_nagash_find_closest_settlements_and_trigger_dilemma(character)
    rhox_settlement_candidate_table={} --initialize it
    
    
	
	local pos_x = character:logical_position_x()
	local pos_y = character:logical_position_y()
	
    local region_list = cm:model():world():region_manager():region_list()
    for i=0,region_list:num_items()-1 do
        local region= region_list:item_at(i)
        local settlement= region:settlement()
        local reg_pos_x = settlement:logical_position_x()
        local reg_pos_y = settlement:logical_position_y()
        local distance = distance_squared(pos_x, pos_y, reg_pos_x, reg_pos_y);
        if distance < 900 then 
            local x ={
                name= region:name(),
                distance= distance
            }
            table.insert(rhox_settlement_candidate_table, x)
        end
	end
    table.sort(rhox_settlement_candidate_table, function(a,b) return a.distance < b.distance end)

    if #rhox_settlement_candidate_table >0 then
        local dilemma_builder = cm:create_dilemma_builder("rhox_nagash_bp_fly");
        local payload_builder = cm:create_payload();
        local count =3 
        if #rhox_settlement_candidate_table < 3 then
            count = #rhox_settlement_candidate_table
        end

        for i=1,count do
            dilemma_builder:add_choice_payload(choice_string[i], payload_builder);
        end
        dilemma_builder:add_choice_payload(choice_string[4], payload_builder);
        cm:launch_custom_dilemma_from_builder(dilemma_builder, cm:get_faction("mixer_nag_nagash"));
    end
end











core:add_listener(
    "rhox_nagash_fly_dilemma_issued",
    "DilemmaIssuedEvent",
    function(context)
        return context:dilemma() == "rhox_nagash_bp_fly"
    end,
    function(context)
        
        core:add_listener(
        "rhox_nagash_dilemma_panel_listener",
        "PanelOpenedCampaign",
        function(context)
            return (context.string == "events")
        end,
        function(context)

            cm:callback(function()
                local dilemma_choice_count=3
                if #rhox_settlement_candidate_table < 3 then
                    dilemma_choice_count= #rhox_settlement_candidate_table
                end
            
                for i=1,dilemma_choice_count do 
                    --out("Rhox Nagash: Target region: "..rhox_settlement_candidate_table[i].name)
                    local region_string = (common.get_localised_string("regions_onscreen_"..rhox_settlement_candidate_table[i].name))
                    out("Rhox Nagash: region string: "..region_string)
                    local dilemma_location = find_uicomponent(core:get_ui_root(),"events", "event_layouts", "dilemma_active", "dilemma", "background","dilemma_list", "CcoCdirEventsDilemmaChoiceDetailRecordrhox_nagash_bp_fly"..choice_string[i], "choice_button", "button_txt")
                    if dilemma_location then
                        dilemma_location:SetText(region_string)
                    end
                end

            end,
            0.3
            )

        end,
        false --see you next time
    )
    end,
    true
)



core:add_listener(
    "rhox_nagash_fly_dilemma_choice_made",
    "DilemmaChoiceMadeEvent",
    function(context)
        local dilemma = context:dilemma();
        local choice = context:choice();
        return dilemma == "rhox_nagash_bp_fly" and choice ~=3 and choice < #rhox_settlement_candidate_table; --choice starts from 0 --second is to prevent giving the trait in the case of Chaos wastes
    end,
    function(context)
        local choice = context:choice();
        
        --local target_region = cm:get_region(rhox_settlement_candidate_table[i+1].name)
        local x,y = cm:find_valid_spawn_location_for_character_from_settlement("mixer_nag_nagash", rhox_settlement_candidate_table[choice+1].name, false, true, 10)
        if x ~= -1 and y ~= -1 then
            local nagash = cm:get_faction("mixer_nag_nagash"):faction_leader()
            cm:teleport_to(cm:char_lookup_str(nagash), x, y)
        end
    end,
    true
);




cm:add_first_tick_callback(
    function()
        core:add_listener(
            "bp_button_leftclick",
            "ComponentLClickUp",
            function (context)
                return context.string == "icon_effect" and cm:get_faction("mixer_nag_nagash"):has_effect_bundle("rhox_nagash_woke") and cm:get_faction("mixer_nag_nagash"):faction_leader():has_military_force()
            end,
            function ()
                rhox_nagash_find_closest_settlements_and_trigger_dilemma(cm:get_faction("mixer_nag_nagash"):faction_leader())
            end,
            true
        )
        
    end
);