local ScrollConfig = nil
local function GetScrollConfig(id)
	ScrollConfig = ScrollConfig or LoadDatabaseWithKey("scroll", "scroll") or {}

	return ScrollConfig[id]
end

local SuitConfig = nil
local function GetSuitConfig(id)
	if SuitConfig == nil then
		SuitConfig = {}
		DATABASE.ForEach("suit", function(row)
			SuitConfig[row.suit_id] = SuitConfig[row.suit_id] or {}
			SuitConfig[row.suit_id][row.count] = SuitConfig[row.suit_id][row.count] or {}
			SuitConfig[row.suit_id][row.count][row.quality] = SuitConfig[row.suit_id][row.count][row.quality] or {}
			SuitConfig[row.suit_id][row.count][row.quality] = row
		end)
	end
	return SuitConfig[id]
end
return {
	GetSuitConfig = GetSuitConfig,
	GetScrollConfig = GetScrollConfig
}