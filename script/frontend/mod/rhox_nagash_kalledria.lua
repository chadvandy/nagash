core:add_ui_created_callback(
    function(context)
        if vfs.exists("script/frontend/mod/mixer_frontend.lua")then
    
            mixer_enable_custom_faction("1568726704")
            mixer_add_starting_unit_list_for_faction("mixer_vmp_wailing_conclave", {"nag_vmp_kalledria_syreen","wh_main_vmp_inf_crypt_ghouls","wh_main_vmp_cav_hexwraiths", "wh_main_vmp_inf_cairn_wraiths"})
            
            mixer_change_lord_name("1568726704", "nag_vmp_kalledria")
            
            mixer_add_faction_to_major_faction_list("mixer_vmp_wailing_conclave")
        end        
    end
)