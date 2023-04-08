

--out("Rhox Nagash: check")
--Script by prop joe, modified by Belisarian

local last_kill = nil
local spawn_blyramid = 0;
local blyramid_anchor_coords = nil;

--load_script_libraries(); --added by rhox
bm = battle_manager:new(empire_battle:new());
-- local gc = generated_cutscene:new(true);
gb = generated_battle:new(
	false,                                      		-- screen starts black
	false,                                     		-- prevent deployment for player
	false,                                      	-- prevent deployment for ai
	nil, -- intro cutscene function
	false                                      		-- debug mode
);

-- check for various types of units, and takes action if finds fitting ones, enemy army and ally army are relative
local function scan_units_for_targets(alliance_armies, enemy_armies)
	local summoned = nil
	local pos
	local b
	local w
    --out("Rhox Nagash: Inside the scan units for targets function")
	for j=1, alliance_armies:count() do
		local army = alliance_armies:item(j)
		local player_units = army:units();

		for i = 1, player_units:count() do
			local current_unit = player_units:item(i);
			if current_unit then
				local type_key = current_unit:type();
				--out("Rhox Nagash: Before doing script_unit thing")
				--out("Rhox Nagash: Currently looking unit key: "..tostring(type_key))
				--local su = script_unit:new(army, i)
				local su = script_unit:new(current_unit, "rhox_nagash_"..tostring(i))
				
				
				
				-- spawns blyramid and remembers coordinates
				if (type_key == "nag_nagash_boss") and spawn_blyramid < 1 and gb:has_battle_started() then
                    out("Rhox Nagash: I'm spawning the black Pyramid!")
					-- current_unit:position();
					blyramid_anchor_coords = current_unit:position();
					
					-- testing ping
					-- gb:add_ping_icon_on_message("test", blyramid_anchor_coords, 4, 1000, 8000);
					-- gb.sm:trigger_message("test");
					army:use_special_ability("nag_blyramid_itself", blyramid_anchor_coords, d_to_r(0))
					--army:use_special_ability("nag_blyramid_itself", blyramid_anchor_coords)
					out("Rhox Nagash: Summoned black pyramid x, y, z is: "..blyramid_anchor_coords:get_x().."/"..blyramid_anchor_coords:get_y().."/"..blyramid_anchor_coords:get_z())
					spawn_blyramid = 1
				end
                
				-- sends units summoned diretly at the enemy and takes control away from player
				if (type_key == "nag_inf_skeleton_warriors_endless_tomb_summoned") and gb:has_battle_started() then
					
					-- out("script nag_inf_skeleton_warriors_endless_tomb_summoned")
					-- script_unit:new(current_army, unit_index_in_army);
					-- local uc = army:create_unit_controller();
					-- uc:add_units(current_unit);
					-- unitgroup.sunits:item(i);
					if current_unit:is_idle() then			
						-- out("script nag_inf_skeleton_warriors_endless_tomb_summoned not mowing")			
						endless_tomb_warrior_pos = current_unit:position();	
						closest_unit = get_closest_standing_unit(enemy_armies, endless_tomb_warrior_pos)
						closest_unit_pos = closest_unit:position();
						current_unit_uc = su.uc

						current_unit_uc:take_control();
						current_unit_uc:attack_unit(closest_unit, nil, true);
						-- current_unit_uc:attack_line(endless_tomb_warrior_pos, closest_unit_pos, true)

						-- testing ping
						-- gb:add_ping_icon_on_message("test", endless_tomb_warrior_pos, 4, 1000, 8000);
						-- gb.sm:trigger_message("test");
						
					end					
				end
                
				-- for blyramid bombardment, deletes targeting unit and deploys 5 bombardments in that location
				if type_key == "nag_bombardment_targeting" then
                    out("Rhox Nagash: Black Pyramid Fire!")
					summoned = su
					summoned:cache_location()
					pos = summoned:get_cached_position()
					b = summoned:get_cached_bearing()
					w = summoned:get_cached_width()
					summoned:set_enabled(false)
					summoned:kill(true)
					last_kill = os.clock()
                    out("Rhox Nagash: spawn_blyramid is: "..spawn_blyramid)
					if spawn_blyramid == 1 then
						-- blyramid_anchor_coords
						-- pos
						-- math.atan2(targetY-gunY, targetX-gunX)
						-- calculate angle between target and blyramid
						out("Rhox Nagash: black pyramid anchor coords x, y, z is: "..blyramid_anchor_coords:get_x().."/"..blyramid_anchor_coords:get_y().."/"..blyramid_anchor_coords:get_z())
						out("Rhox Nagash: Summoned target's position's x, y, z is: "..pos:get_x().."/"..pos:get_y().."/"..pos:get_z())
						--y = pos:get_z()-(blyramid_anchor_coords:get_z() + 1400)
						y = pos:get_y()-(blyramid_anchor_coords:get_y() + 1400)
						x = pos:get_x()-(blyramid_anchor_coords:get_x() + 1400)
						original_x = pos:get_x()
						original_y = pos:get_y()
						original_z = pos:get_z()						
						angle_radians = math.atan2(y, x)
						out("Rhox Nagash: angle_radians: "..angle_radians)
						angle_degrees = math.deg(angle_radians)
                        out("Rhox Nagash: angle_degrees: "..angle_degrees)
                        
                        y_generated = bm:get_terrain_height(original_x, original_z)
                        --y_generated = original_y
                        --out("Rhox Nagash: Y generated: "..y_generated)
                        --out("Rhox Nagash: black pyramid fire: x, y, z is: "..original_x.."/"..y_generated.."/"..original_z)
						
						army:use_special_ability("nag_army_abilities_blyramid_bombardment_00", v(original_x, y_generated, original_z), angle_radians)
						--army:use_special_ability("nag_army_abilities_blyramid_bombardment_00", v(original_x, y_generated, original_z))
						
						y_generated = bm:get_terrain_height(original_x + 10, original_z - 10)
						army:use_special_ability("nag_army_abilities_blyramid_bombardment_01", v(original_x + 10, y_generated, original_z - 10), angle_radians)
						
						y_generated = bm:get_terrain_height(original_x - 10, original_z + 10)
						army:use_special_ability("nag_army_abilities_blyramid_bombardment_02", v(original_x - 10, y_generated, original_z + 10), angle_radians)
						
						y_generated = bm:get_terrain_height(original_x + 10, original_z + 10)
						army:use_special_ability("nag_army_abilities_blyramid_bombardment_03", v(original_x + 10, y_generated, original_z + 10), angle_radians)
						
						y_generated = bm:get_terrain_height(original_x - 10, original_z - 10)
						army:use_special_ability("nag_army_abilities_blyramid_bombardment_04", v(original_x - 10, y_generated, original_z - 10), angle_radians)
					end		
				end
				--]]
			end
		end
	end
end


-- main loop, cleans up UI of whatever got killed last cycle (used for blyramid bombard) and runs unit scan function from both sides
local function update()
    
	
	
	--[[
	local ui_root = core:get_ui_root()
	local event_icon = find_uicomponent(ui_root, "hud_battle", "radar_holder", "radar_group", "adc_frame", "event_icon")
	if event_icon then
		local label = find_uicomponent(event_icon, "label")
		if label then
			if string.find(label:GetStateText(), "wiped out") then
				UIComponent(label:Parent()):SetVisible(false)
			end
		end
	end

	if last_kill and os.clock() - last_kill < 5 then
		local adc_ping = find_uicomponent(ui_root, "hud_battle", "ping_parent", "adc_ping")
		if adc_ping then
			local adc_icon = find_uicomponent(adc_ping, "adc_icon")
			local arrow = find_uicomponent(adc_ping, "arrow")
			if adc_icon and arrow then
				if string.find(adc_icon:GetTooltipText(), "wiped out") then
					UIComponent(adc_icon:Parent()):SetVisible(false)
					adc_icon:SetVisible(false)
					adc_ping:SetVisible(false)
					arrow:SetVisible(false)
				end
			end
		end
	end
	--]] --let's not do this. People need to see wiped out event


	local alliance_armies = bm:alliances():item(bm:get_player_alliance_num()):armies()
	local enemy_armies = bm:alliances():item(bm:get_non_player_alliance_num()):armies()
    --out("Rhox Nagash: Player Alliance number "..bm:get_player_alliance_num())
    --out("Rhox Nagash: non-Player Alliance number "..bm:get_non_player_alliance_num())

	local ok, err = pcall(function()
        scan_units_for_targets(alliance_armies, enemy_armies)
		scan_units_for_targets(enemy_armies, alliance_armies)
    end)
    
    local abilities_need_hiding={
        "button_holder_nag_army_abilities_endless_tomb_hidden_dummy",
        "button_holder_nag_army_abilities_blyramid_bombardment_00",
        "button_holder_nag_army_abilities_blyramid_bombardment_01",
        "button_holder_nag_army_abilities_blyramid_bombardment_02",
        "button_holder_nag_army_abilities_blyramid_bombardment_03",
        "button_holder_nag_army_abilities_blyramid_bombardment_04",
        "button_holder_nag_blyramid_itself"
    }
    
	
	local army_ability_parent = find_uicomponent(core:get_ui_root(), "hud_battle", "army_ability_container", "army_ability_parent")
	if not army_ability_parent then
        return
    end
    for i=1,#abilities_need_hiding do
        local ability = find_uicomponent(army_ability_parent, abilities_need_hiding[i])
        if not ability then
            return
        end
        ability:SetVisible(false)
    end
    
end



-- killing and reviving listener
core:remove_listener("belisarian_nagash_blyramid_scan_listener_cb")
core:add_listener(
	"belisarian_nagash_blyramid_scan_listener_cb",
	"RealTimeTrigger",
	function(context)
		return context.string == "belisarian_nagash_blyramid_scan_listener"
	end,
	function(context)
		update()
		real_timer.register_singleshot("belisarian_nagash_blyramid_scan_listener", 50)
	end,
	true
)
-- repeat every 50 ms cycle
bm:remove_process("belisarian_nagash_blyramid_scan_cycle")
bm:callback(function()
	update()
	real_timer.register_singleshot("belisarian_nagash_blyramid_scan_listener", 50)
end, 1000, "belisarian_nagash_blyramid_scan_cycle")