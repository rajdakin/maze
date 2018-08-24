function add_contrib_nontest_levels(level_manager)
	--[[ Template:
	level_manager:addLevel([LEVEL_NAME], {
		["level_array_version"] = 2,
		["starting_room"] = [INIT_ROOM],
		["column_count"] = [COL_COUNT],
		["rooms_datas"] = {[ROOMS_DATAS_ARRAY]},
		["map_reveal"] = [MAP_REVEAL],
		["win_level"] = [WIN_LEVEL],
		["alternative_lore"] = [ALTERNATIVE_LORE]
	})
	--]]
end

function add_contrib_test_levels(level_manager)
	--[[ Template:
	level_manager:addTestLevel([LEVEL_NAME], {
		["level_array_version"] = 1,
		["starting_room"] = [INIT_ROOM],
		["column_count"] = [COL_COUNT],
		["rooms_datas"] = {[ROOMS_DATAS_ARRAY]},
		["map_reveal"] = [MAP_REVEAL],
		["win_level"] = [WIN_LEVEL],
		["alternative_lore"] = [ALTERNATIVE_LORE]
	})
	--]]
end
