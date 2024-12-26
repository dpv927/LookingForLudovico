local LFL = RegisterMod('Looking for Ludovico', 1)


LFL:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	local game = Game()
	local level = game:GetLevel()

	-- We dont need to check levels where there are no treasure rooms.
	-- For greed mode, we can ignore the last level and for hard or 
	-- normal mode, we can ignore all levels after Depths II.

	if (game:IsGreedMode() and level:GetStage() == LevelStage.STAGE7_GREED)
		or (level:GetStage() > LevelStage.STAGE3_2) then
		return
	end

	local rooms =  level:GetRooms()
	LFL.found_item = false

	local initialRoom = {
		position = Isaac.GetPlayer(0).Position,
		idx = level:GetCurrentRoomIndex(),
	}

	for  i=0, #rooms - 1 do
		local room = rooms:Get(i)

		if room.Data.Type == RoomType.ROOM_TREASURE then

			-- Here we just make the player to be in the top left corner, so we avoid piking up the
			-- pedestal item accidentally when entering the treasure room.
			Isaac.GetPlayer(0).Position = game:GetRoom():GetTopLeftPos()

			-- The purpose of entering the treasure room is to force the load of the items at the room
			-- (rooms contents are not loaded until you enter for the first time).
			game:ChangeRoom(room.GridIndex)
			local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)

			for _, pickup in ipairs(pickups) do
				if pickup then
					-- Ensure that the collectible is not nil and its the item we are looking for.
					local collectible = Isaac.GetItemConfig():GetCollectible(pickup.SubType)

					if collectible and collectible.ID == CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE then
						game:GetPlayer(0):AnimateHappy()
						LFL.found_item = true
						goto endCallback
					end
				end
			end
		end
	end

	::endCallback::

	-- Go back to the initial room and restore the player
	-- position inside it.
	Isaac.GetPlayer(0).Position = initialRoom.position
	game:ChangeRoom(initialRoom.idx)
	LFL.initial_room = game:GetRoom()
	
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