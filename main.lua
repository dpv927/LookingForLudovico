local LFL = RegisterMod('Looking for Ludovico', 1)


--- Returns true if the current level can have a treasure room.
--- In Hard mode, there are treasure rooms in all levels up to 
--- the level with Mom's fight.
---@param level Level
local function IsTreasureRoomInLevel(level)
	return level:GetStage() <= LevelStage.STAGE3_2
end


--- Hides a room and its adjacent rooms in the map.
--- @param room RoomDescriptor
--- @param level Level
local function HideRoomAndAdjacents(room, level)

	local wrd = level:GetRoomByIdx(room.SafeGridIndex)
	wrd.DisplayFlags = 0
	wrd.VisitedCount = 0

	for offset in ipairs({13, -1, 1, -13}) do
		wrd = level:GetRoomByIdx(room.SafeGridIndex + offset)

		if wrd then
			wrd.DisplayFlags = 0
		end
	end
end


LFL:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	local game = Game()
	local level = game:GetLevel()

	if game:IsGreedMode() or (not IsTreasureRoomInLevel(level)) then
		-- Greed mode not supported and we can skip levels after
		-- Mom's fight (Womb, Utero, etc).
		return
	end

	local levelRoomsList = level:GetRooms()
	local iPosition = Isaac.GetPlayer(0).Position
	local iRoomIdx  = level:GetCurrentRoomIndex()

	LFL.found_item = false

	for  i=0, #levelRoomsList - 1 do
		local room = levelRoomsList:Get(i)

		if room.Data.Type == RoomType.ROOM_TREASURE then

			-- Change room to force item load/generation
			Isaac.GetPlayer(0).Position = Vector(350,0)
			game:ChangeRoom(room.GridIndex)

			local pickups = Isaac.FindByType(
				EntityType.ENTITY_PICKUP, 
				PickupVariant.PICKUP_COLLECTIBLE,
				-1, false, false
			)

			for _, pickup in ipairs(pickups) do
				if pickup then
					-- Ensure that the collectible is not nil and its the item we are looking for.
					local collectible = Isaac.GetItemConfig():GetCollectible(pickup.SubType)

					if collectible and collectible.ID == CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE then
						game:GetPlayer(0):AnimateHappy()
						LFL.found_item = true
						break
					end
				end
			end

			-- Come back to the initial room
			HideRoomAndAdjacents(room, level)
			game:GetRoom():Update()

			Isaac.GetPlayer(0).Position = iPosition
			game:ChangeRoom(iRoomIdx)
			LFL.initial_room = game:GetRoom()

			if LFL.found_item then
				break
			end
		end
	end
end)


LFL:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if LFL.found_item then
		local position = Isaac.GetPlayer(0).Position

		position.X = position.X - 150
		position.Y = position.Y - 80
		local renderpos = Isaac.WorldToScreen(position)
		Isaac.RenderText("I can feel Ludovico's", renderpos.X, renderpos.Y, 1,1,1,1)

		position.X = position.X + 30
		position.Y = position.Y + 20
		renderpos = Isaac.WorldToScreen(position)
		Isaac.RenderText("presence...", renderpos.X, renderpos.Y, 1,1,1,1)
	end
end)


LFL:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	if LFL.initial_room and LFL.initial_room ~= Game():GetRoom() then 
		LFL.initial_room = nil
		LFL.found_item = false
	end
end)