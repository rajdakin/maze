function add_contrib_levels()
	--[[ Template:
	levels[getArrayLength(levels) - 2] = Level({
		["level_array_version"] = 1,
		["starting_room"] = [INIT_ROOM],
		["column_count"] = [COL_COUNT],
		["rooms_datas"] = {[ROOMS_DATAS_ARRAY]},
		["lores"] = {[LORE_BEGIN], {[LORE_GOODEND], [LORE_DEATHEND]}}
	})
	--]]
end
