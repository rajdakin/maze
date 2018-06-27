function add_contrib_nontest_levels(level_manager)
	--[[ Template:
	level_manager:addLevel({
		["level_array_version"] = 1,
		["starting_room"] = [INIT_ROOM],
		["column_count"] = [COL_COUNT],
		["rooms_datas"] = {[ROOMS_DATAS_ARRAY]},
		["lores"] = {[LORE_BEGIN], {[LORE_GOODEND], [LORE_DEATHEND]}}
	})
	--]]
end

function add_contrib_test_levels(level_manager)
	--[[ Template:
	level_manager:addTestLevel({
		["level_array_version"] = 1,
		["starting_room"] = [INIT_ROOM],
		["column_count"] = [COL_COUNT],
		["rooms_datas"] = {[ROOMS_DATAS_ARRAY]},
		["lores"] = {[LORE_BEGIN], {[LORE_GOODEND], [LORE_DEATHEND]}}
	})
	--]]
end
