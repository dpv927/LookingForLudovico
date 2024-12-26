local LFL = RegisterMod('Looking for Ludovico', 1)

LFL:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	local game = Game()
	local level = game:GetLevel()
	local rooms = level:GetRooms()

	local initialRoom = level:GetCurrentRoomIndex()
	local position = Isaac.GetPlayer(0).Position
	LFL.found_item = false

	for i=0, #rooms - 1 do
		local room = rooms:Get(i)

		if room.Data.Type == RoomType.ROOM_TREASURE then
			
			-- The purpose of entering the treasure room is to force the load 
			-- of the items at the room (rooms contents are not loaded until
			-- you enter for the first time).
			
			game:ChangeRoom(room.GridIndex)
			local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)

			for _, pickup in ipairs(pickups) do
				if pickup then
					if Isaac.GetItemConfig():GetCollectible(pickup.SubType).ID == CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE then
						print("Ludovico's Technique was found!")
						game:GetPlayer(0):AnimateHappy()
						LFL.found_item = true
						goto endCallback
					end
				end
			end
		end
	end

	-- Restore player room and position only if the item was not 
	-- found at any treasure room.
	print("Ludovico's Technique was not found :(")
	::endCallback::
	Isaac.GetPlayer(0).Position = position
	game:ChangeRoom(initialRoom)
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