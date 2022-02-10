-- the scripted mechanics revolving around the raising of the BP and what not

-- TODO "unlock ritual" when the BP is occupied by Nagash (or upgraded to a certain level? some other criterion?)
-- TODO spawn intervention armies (use the welf system) when the ritual begins
-- TODO set the ritual in some cute UI, something floating on the BP region?

--- TODO the end game ritual

--- TODO all of the rituals

---@class bdsm
local bdsm = get_bdsm()

local rite_status = {
    nag_winds = false, -- TODO
    nag_death = false,
    nag_divinity = false,
    nag_man = false,
    nag_nagash = false,
}

local function add_scroll_bar()
    core:add_listener(
        "AddScrollBar",
        "PanelOpenedCampaign",
        function(context)
            return context.string == "rituals_panel" and cm:get_local_faction_name(true) == bdsm:get_faction_key()
        end,
        function(context)
            local uic = UIComponent(context.component)
            local rituals_list = find_uicomponent(uic, "panel_frame", "rituals_list")
            local dummy = core:get_or_create_component("rituals_dummy", "ui/campaign ui/script_dummy")
            local killer_dummy = core:get_or_create_component("killer_dummy", "ui/campaign ui/script_dummy")

            -- force all rituals onto a new invisible parent while I create the horizontal list view
            local addresses = {}
            for i = 0, rituals_list:ChildCount() -1 do
                local child_uic = UIComponent(rituals_list:Find(i))
                addresses[#addresses+1] = child_uic:Address()
            end

            for i = 1, #addresses do
                rituals_list:Divorce(addresses[i])
                dummy:Adopt(addresses[i])
            end

            -- create and grab the horizontal list view
            local killed = core:get_or_create_component("new_killed", "ui/campaign ui/building_browser", core:get_ui_root())
            local listview = find_uicomponent(killed, "listview")

            -- add horlistview onto the rituals list
            rituals_list:Adopt(listview:Address())

            -- kill the building browser created
            killer_dummy:Adopt(killed:Address())

            local lview = find_uicomponent(rituals_list, "listview")

            -- destroy unneeded details
            local killed2 = find_uicomponent(lview, "list_clip", "list_box", "building_tree")
            killer_dummy:Adopt(killed2:Address())
            killer_dummy:DestroyChildren()

            -- set lview size to the rituals_list
            local x, y = rituals_list:Position()
            local w, h = rituals_list:Bounds()

            lview:SetCanResizeWidth(true) lview:SetCanResizeHeight(true)
            lview:Resize(w -75, h -50)
            lview:SetCanResizeWidth(false) lview:SetCanResizeHeight(false)

            -- minor buffer between the corner
            lview:MoveTo(x + 20, y + 20)

            local lbox = find_uicomponent(lview, "list_clip", "list_box")

            -- readd the rituals to the lview
            for j = 1, #addresses do
                local child_uic = UIComponent(addresses[j])

                dummy:Divorce(addresses[j])
                lbox:Adopt(addresses[j])
            end

            -- kill the dummies
            dummy:Adopt(killer_dummy:Address())
            dummy:DestoryChildren()
        end,
        true
    )
end

--- unlock rite + show event message
local function unlock_rite(rite_key)
    if rite_status[rite_key] == nil then
        return bdsm:logf("Trying to unlock rite %s but it's not a valid Nagash rite!", tostring(rite_key))
    end

    if rite_status[rite_key] == true then 
        return bdsm:logf("Trying to unlock rite %s but it's already available!", rite_key)
    end

    local faction_key = bdsm:get_faction_key()
    local faction = bdsm:get_faction()

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

local vlib = get_vandy_lib()

---@type vlib_camp_counselor
local cc = vlib:get_module("camp_counselor")

--- Repeated callback that adds the floating button on the BP settlement banner
function bdsm:add_bp_button()  
    vlib:repeat_callback(
        function()
            --- TODO handle states if the ritual is already underway
            local label = find_uicomponent("3d_ui_parent", "label_settlement:"..bdsm._bp_key)
            if label and label:Visible() then 
                local icon_holder = find_uicomponent(label, "list_parent", "icon_holder")
                if find_uicomponent(icon_holder, "bp_button") then 
                    return
                end

                local extant = find_uicomponent(icon_holder, "icon_port")

                local w,h = extant:Dimensions()

                local bp_button = core:get_or_create_component("bp_button", "ui/templates/round_small_button", icon_holder)

                bp_button:SetCanResizeWidth(true)
                bp_button:SetCanResizeHeight(true)

                bp_button:Resize(w, h)
                
                --- TODO icon
                local t = effect.get_localised_string("bp_button_text")
                -- local icon = 
                bp_button:SetTooltipText(t, true)

                icon_holder:Layout()
            end
        end,
        100, -- 100ms
        "add_bp_button"
    )

    core:add_listener(
        "bp_button_pressed",
        "ComponentLClickUp",
        function(context)
            return context.string == "bp_button"
        end,
        function(context)
            -- start the ritual
            cm:perform_ritual(bdsm:get_faction_key(), "", "nag_bp_raise")

            --- TODO trigger mission for "survive"

            --- TODO wound Nagash Husk for 999 turns
            --- TODO set a composite scene on the settlement
            --- TODO start up some interactive markers
            --- TODO set a value for "bp ritual underway"
        end,
        true
    )
end

--- TODO add in Black Pyramid raising rite 
function bdsm:is_bp_rite_available()
    --- TODO owns BP but hasn't performed the Ascendancy
    local f = self:get_faction()
    local v = cm:get_saved_value("nag_bp_raise")
    local owns = false

    local r_list = f:region_list()

    if v and v == true then
        return false
    end

    for i = 0, r_list:num_items() -1 do
        local region = r_list:item_at(i)

        if region:name() == self._bp_key then
            owns = true
        end
    end

    return owns
end

function bdsm:unlock_rites_listeners()
    if not cm:get_saved_value("nag_rites_lock") then 
        rite_status.nag_death = false
        rite_status.nag_winds = false
        rite_status.nag_divinity = false
        rite_status.nag_man = false
        rite_status.nag_nagash = false

        local f = self:get_faction()

        for key,_ in pairs(rite_status) do 
            cm:lock_ritual(f, key)
        end
    end

    if not rite_status.nag_winds then
        --- TODO this never triggers right?
        -- build the BP Obelisk
        core:add_listener(
            "NagWinds",
            "MilitaryForceBuildingCompleteEvent",
            function(context)
                self:logf("MilitaryForceBuildingCompleteEvent!")
                return context:building():name() == "nag_bpyramid_main_obelisk_4"
            end,
            function(context)
                unlock_rite("nag_winds")
            end,
            false
        )
    end

    if not rite_status.nag_death then
        --- Win 5 battles with Nagash
        core:add_listener(
            "NagDeath",
            "CharacterCompletedBattle",
            function(context)
                --- TODO "and nagash won"
                local character = context:character()
                return (character:character_subtype_key() == "nag_nagash_husk" or character:character_subtype_key() == "nag_nagash_boss") and character:won_battle()
            end,
            function(context)
                local total = cm:get_saved_value("nag_death") or 0
                total = total + 1

                if total == 5 then
                    unlock_rite("nag_death")
                else
                    --- TODO display in the ritual panel?
                    cm:set_saved_value("nag_death")
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
                return character:faction():name() == bdsm:get_faction_key() and (character:character_subtype_key() == "nag_nagash_husk" or character:character_subtype_key() == "nag_nagash_boss") and character:rank() >= 12
            end,
            function(context)
                unlock_rite("nag_divinity")
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
                return not faction:is_null_interface() and faction:name() == bdsm:get_faction_key() and faction:region_list():num_items() >= 10
            end,
            function(context)
                unlock_rite("nag_man")
            end,
            false
        )
    end

    if not rite_status.nag_nagash then
        core:add_listener(
            "NagNagash",
            "BlackPyramidRaised",
            true,
            function(context)
                unlock_rite("nag_nagash")
            end,
            false
        )
        
        core:add_listener(
            "NagNagash",
            "FactionTurnStart",
            function(context)
                return context:faction():name() == bdsm:get_faction_key() and cm:turn_number() >= 50
            end,
            function(context)
                unlock_rite("nag_nagash")
            end,
            false
        )
    end
end

--- TODO scripted effects
function bdsm:trigger_rites_listeners()
    --- TODO on rite completed, select a Nemesis faction to target. can do this programmatically with a dilemma, yay
    --- nag_man
    core:add_listener(
        "nag_man",
        "RitualCompletedEvent",
        function(context)
            return context:ritual():ritual_key() == "nag_man"
        end,
        function(context)
            --- TODO some way to select a Nemesis faction to target, decide
        end,
        true
    )

    --- Breaks ATM
    -- -- nag_death
    -- bdsm:load_db("nag_death")

    local function get_random_mortarch()
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

    core:add_listener(
        "NagDeath",
        "RitualCompletedEvent",
        function(context)
            return context:ritual():ritual_key() == "nag_death"
        end,
        function(context)
            --- spawn a death army at Nagash, at BP, or at a random Mortarch, or at a random settlement, in that order.
            local nag = bdsm:get_faction_leader()
            local key = bdsm:get_faction_key()
            local x,y,region
            if nag:has_military_force() and nag:region():is_null_interface() == false then
                x,y = cm:find_valid_spawn_location_for_character_from_character(key, "character_cqi:"..nag:command_queue_index(), true, 5)
                region = nag:region():name()
            else
                -- check BP
                local bp = cm:get_region(bdsm._bp_key)
                if bp and bp:owning_faction():is_null_interface() == false and bp:owning_faction():name() == key then 
                    x,y = cm:find_valid_spawn_location_for_character_from_settlement(key, bdsm._bp_key, false, true, 5)
                    region = bp
                else
                    -- check for a random mortarch
                    local random_mort = get_random_mortarch()
                    if random_mort then
                        x,y = cm:find_valid_spawn_location_for_character_from_character(key, "character_cqi:"..random_mort:command_queue_index(), true, 5)
                        region = random_mort:region():name()
                    else
                        -- check for a random settlement
                        local settlement_list = bdsm:get_faction():region_list()
                        local random_settlement = settlement_list:item_at(cm:random_number(settlement_list:num_items()-1, 0))

                        x,y = cm:find_valid_spawn_location_for_character_from_settlement(key, random_settlement:name(), false, true, 5)
                        region = random_settlement:name()
                    end
                end
            end

            --- spawn the army
            cm:create_force(
                key,
                random_army_manager:generate_force("nag_death", cm:random_number(15, 12), false),
                region,
                x,
                y,
                true,
                function(char_cqi, mf_cqi)
                    --- TODO apply EB for the duration of the ritual
                    local eb_key = "nag_death_shambling_horde"
                    cm:apply_effect_bundle_to_force(eb_key, mf_cqi, 5) 
                end,
                false
            )

            --- TODO add an event
        end,
        true
    )
end


function bdsm:setup_rites()
    
    --- TODO causes CTD on load game (:
    cc:add_pr_uic("nag_warpstone", "ui/skins/default/icon_warpstone.png", bdsm:get_faction_key())

    add_scroll_bar()

    self:unlock_rites_listeners()
    self:trigger_rites_listeners()

    --- TODO refresh if settlement capture!
    if self:is_bp_rite_available() then
        self:add_bp_button()
    end
end

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("nag_rites", rite_status, context)
    end
)

cm:add_loading_game_callback(
    function(context)
        rite_status = cm:load_named_value("nag_rites", rite_status, context)
    end
)