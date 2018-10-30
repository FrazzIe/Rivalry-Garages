function Garages:GetPlayer()
	return Garages.Data.ServerId or GetPlayerFromServerId(PlayerId())
end

function Garages:IsVehicleOwned(Vehicle) -- Change this to get a decorator
	local Player = Garages.GetPlayer()
	local IsOwned = false

	if Garages.Data.Vehicles[Player] then
		for Index = 1, #Garages.Data.Vehicles[Player] do
			if Plate == Garages.Data.Vehicles[Player][Index].Plate then
				IsOwned = true
				break
			end
		end
	end

	return IsOwned
end

function Garages:IsGarageOwned(Type, GarageId)
	local Player = Garages.GetPlayer()
	local IsOwned = false

	if Garages.Data.Garages[Player] then
		for Index = 1, #Garages.Data.Garages[Player] do
			if GarageId == Garages.Data.Garages[Player][Index].GarageId and Type == Garages.Data.Garages[Player][Index].Type then
				IsOwned = true
				break
			end
		end
	end

	return IsOwned
end

function Garages:GetVehicleIndex(Vehicle) -- Change this to get a decorator
	local Player = Garages.GetPlayer()

	if Garages.Data.Vehicles[Player] then
		for Index = 1, #Garages.Data.Vehicles[Player] do
			if Plate == Garages.Data.Vehicles[Player][Index].Plate then
				return Index
			end
		end
	end

	return nil
end

function Garages:GetGarageIndex(Type, GarageId)
	local Player = Garages.GetPlayer()

	if Garages.Data.Garages[Player] then
		for Index = 1, #Garages.Data.Garages[Player] do
			if GarageId == Garages.Data.Garages[Player][Index].GarageId and Type == Garages.Data.Garages[Player][Index].Type then
				return Index
			end
		end
	end

	return nil
end

function Garages:GetGarageCount(Type, GarageId)
	local Player = Garages.GetPlayer()
	local Count = 0

	if Garages.Data.Vehicles[Player] then
		for Index = 1, #Garages.Data.Vehicles[Player] do
			if GarageId == Garages.Data.Vehicles[Player][Index].GarageId and Type == Garages.Data.Vehicles[Player][Index].Type then
				Count = Count + 1
			end
		end
	end

	return Count
end

function Garages:GetOwnedGaragesOfType(Type)
	local Player = Garages.GetPlayer()
	local GaragesFound = {}

	if Garages.Data.Garages[Player] then
		for Index = 1, #Garages.Data.Garages[Player] do
			if Type == Garages.Data.Garages[Player][Index].Type then
				table.insert(GaragesFound, Garages.Data.Garages[Player][Index])
			end
		end
	end

	return GaragesFound
end

function Garages:GetAvailableGarageId(Type)
	local PossibleGarages = GetOwnedGaragesOfType(Type)
	local AvailableGarages = {}

	for Index = 1, #PossibleGarages do
		if Garages.GetGarageCount(Type, PossibleGarages[Index].GarageId) < PossibleGarages[Index].Slots then
			table.insert(AvailableGarages, PossibleGarages[Index])
		end
	end

	return AvailableGarages
end

function Garages:SpawnVehicle(Vehicle)
	if type(Vehicle) ~= "table" then return Log.Error("Vehicle must be a table value") end

	local Model = GetHashKey(Vehicle.Model)

	RequestModel(Model)

	while not HasModelLoaded(Model) do
		Citizen.Wait(0)
	end

	Vehicle.Handle = CreateVehicle(Model, Garages.Config.Locations[Vehicle.Type][Vehicle.GarageId].Coordinates.x, Garages.Config.Locations[Vehicle.Type][Vehicle.GarageId].Coordinates.y, Garages.Config.Locations[Vehicle.Type][Vehicle.GarageId].Coordinates.z, Garages.Config.Locations[Vehicle.Type][Vehicle.GarageId].Coordinates.h, true, false)

	while not DoesEntityExist(Vehicle.Handle) do
		Citizen.Wait(0)
	end

	SetVehicleHasBeenOwnedByPlayer(Vehicle.Handle, true)
	SetVehicleNumberPlateText(Vehicle.Handle, Vehicle.Plate)

	NetworkRegisterEntityAsNetworked(Vehicle.Handle)

	Vehicle.NetworkHandle = NetworkGetNetworkIdFromEntity(Vehicle.Handle)

	SetNetworkIdCanMigrate(Vehicle.NetworkHandle, true)
	SetNetworkIdExistsOnAllMachines(Vehicle.NetworkHandle, true)

	SetVehicleOnGroundProperly(Vehicle.Handle)

	SetVehicleModKit(Vehicle.Handle, 0)

	for Index = 0, 48 do
		if Vehicle.Mods[tostring(Index)] then
			SetVehicleMod(Vehicle.Handle, Index, Vehicle.Mods[tostring(Index)])
		end
	end

	ToggleVehicleMod(Vehicle.Handle, 18, Vehicle.Turbo)
	ToggleVehicleMod(Vehicle.Handle, 20, Vehicle.TyreSmoke)
	ToggleVehicleMod(Vehicle.Handle, 22, Vehicle.XenonLights)

	SetVehicleWheelType(Vehicle.Handle, tonumber(Vehicle.Wheels.Type))

	SetVehicleMod(Vehicle.Handle, 23, tonumber(Vehicle.Wheels.Front.Handle), Vehicle.Wheels.Front.Custom)

	if IsThisModelABike(Model) then
		SetVehicleMod(Vehicle.Handle, 24, tonumber(Vehicle.Wheels.Rear.Handle), Vehicle.Wheels.Rear.Custom)
	end

	for i = 0, 3 do
		SetVehicleNeonLightEnabled(Vehicle.Handle, i, Vehicle.Neon[i+1])
	end

	SetVehicleTyresCanBurst(Vehicle.Handle, Vehicle.Wheels.Bulletproof)

	SetVehicleWindowTint(Vehicle.Handle, tonumber(Vehicle.Colour.Tint))
	SetVehicleColours(Vehicle.Handle, Vehicle.Colour.Primary, Vehicle.Colour.Secondary)
	SetVehicleDashboardColour(Vehicle.Handle, Vehicle.Colour.Dashboard)
	SetVehicleInteriorColour(Vehicle.Handle, Vehicle.Colour.Interior)
	SetVehicleExtraColours(Vehicle.Handle, Vehicle.Colour.Pearlescent, Vehicle.Colour.Wheel)
	SetVehicleNeonLightsColour(Vehicle.Handle, Vehicle.Colour.Neon.Red, Vehicle.Colour.Neon.Green, Vehicle.Colour.Neon.Blue)
	SetVehicleTyreSmokeColor(Vehicle.Handle, Vehicle.Colour.Smoke.Red, Vehicle.Colour.Smoke.Green, Vehicle.Colour.Smoke.Blue)
	SetVehicleNumberPlateTextIndex(Vehicle.Handle, Vehicle.Colour.Plate)

	SetModelAsNoLongerNeeded(Model)

	TaskWarpPedIntoVehicle(Player.Ped, Vehicle.Handle, -1)

	Vehicle.State = "Missing"
	TriggerServerEvent("Garages.Out", Vehicle)
end

function Garages:StoreVehicle(Vehicle, Type, GarageId)
	if DoesEntityExist(Vehicle) then
		local Plate = GetVehicleNumberPlateText(Vehicle)
		if IsVehicleOwned(Plate) then
			local Index = GetVehicleIndex(Plate)
			local Player = Garages.GetPlayer()

			if Type == Garages.Data.Vehicles[Player][Index].Type then
				if GetGarageCount(Type, GarageId) < Garages.Config.Locations[Type][GarageId].Slots or (GetGarageCount(Type, GarageId) >= Garages.Config.Locations[Type][GarageId].Slots and Garages.Config.Locations[Index].GarageId == GarageId) then
					Garages.Data.Vehicles[Player][Index].Colour.Primary, Garages.Data.Vehicles[Player][Index].Colour.Secondary = GetVehicleColours(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Pearlescent, Garages.Data.Vehicles[Player][Index].Colour.Wheel = GetVehicleExtraColours(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Dashboard = GetVehicleDashboardColour(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Interior = GetVehicleInteriorColour(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Smoke.Red, Garages.Data.Vehicles[Player][Index].Colour.Smoke.Green, Garages.Data.Vehicles[Player][Index].Colour.Smoke.Blue = GetVehicleTyreSmokeColor(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Neon.Red, Garages.Data.Vehicles[Player][Index].Colour.Neon.Green, Garages.Data.Vehicles[Player][Index].Colour.Neon.Blue = GetVehicleNeonLightsColour(Vehicle)
					Garages.Data.Vehicles[Player][Index].Colour.Plate = GetVehicleNumberPlateTextIndex(Vehicle) 
					Garages.Data.Vehicles[Player][Index].Colour.Tint = GetVehicleWindowTint(Vehicle)
					Garages.Data.Vehicles[Player][Index].Wheels.Type = GetVehicleWheelType(Vehicle)
					Garages.Data.Vehicles[Player][Index].Wheels.Front.Custom = tobool(GetVehicleModVariation(Vehicle, 23))
					Garages.Data.Vehicles[Player][Index].Wheels.Rear.Custom = tobool(GetVehicleModVariation(Vehicle, 24))
					Garages.Data.Vehicles[Player][Index].Wheels.Front.Handle = GetVehicleMod(Vehicle, 23)
					Garages.Data.Vehicles[Player][Index].Wheels.Rear.Handle = GetVehicleMod(Vehicle, 24)
					Garages.Data.Vehicles[Player][Index].Bulletproof = tobool(not GetVehicleTyresCanBurst(Vehicle))
					Garages.Data.Vehicles[Player][Index].Turbo = tobool(IsToggleModOn(Vehicle, 18)) 
					Garages.Data.Vehicles[Player][Index].TyreSmoke = tobool(IsToggleModOn(Vehicle, 20))
					Garages.Data.Vehicles[Player][Index].XenonLights = tobool(IsToggleModOn(Vehicle, 22))
					Garages.Data.Vehicles[Player][Index].Handle = nil
					Garages.Data.Vehicles[Player][Index].State = "Available" 
					Garages.Data.Vehicles[Player][Index].Type = Type
					Garages.Data.Vehicles[Player][Index].GarageId = GarageId

					for i = 0, 3, 1 do
						Garages.Data.Vehicles[Player][Index].Neon[i+1] = tobool(IsVehicleNeonLightEnabled(Vehicle, i))
					end

					for i = 0, 48, 1 do
						if Garages.Data.Vehicles[Player][Index].Mods[tostring(i)] then
							Garages.Data.Vehicles[Player][Index].Mods[tostring(i)] = GetVehicleMod(Vehicle, i)
						end
					end

					Utilities.DestroyVehicle(Vehicle)

					TriggerServerEvent("Garages.Store", Garages.Data.Vehicles[Player][Index])
				end
			end
		else
			PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
		end
	else
		PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
	end
end

function Garages:GenerateSlots(Amount)
	local Slots = {}

	for Index = 1, Amount do
		table.insert(Slots, Index)
	end

	return Slots
end

Citizen.CreateThread(function()
	local GarageMenu = NativeUI.CreateMenu("Garage", "Options", 1300, 300)
	local GarageMenuItems = {
		Purchase = {
			Label = "Purchase",
			Description = "Purchase this garage!",
			RightLabel = "$",
			LeftBadge = nil,
			RightBadge = nil,
			Enabled = true,
		},
		Slots = {
			Label = "Slots",
			Description = "Amount of vehicles you can store in your garage!",
			Items = {},
			Index = 1,
			Enabled = true,
		},
	}
	while true do
		Citizen.Wait(0)

		local PlayerPed = PlayerPedId()
		local PlayerPosition = GetEntityCoords(PlayerPed, false)

		for Type, Garages in pairs(Garages.Config.Locations) do
			for Index = 1, #Garages do
				local Distance = #(Garages[Index].Coordinates - PlayerPosition)

				if Distance < 20 then
					Utilities.RenderMarker(25, Garages[Index].Coordinates.x, Garages[Index].Coordinates.y, Garages[Index].Coordinates.z, 3.0, 3.0, 3.5, 255, 255, 0, 255)

					if Distance < 3 then
						Utilities.DisplayHelpText("Press ~INPUT_CONTEXT~ to open the garage!")
						
						local GarageOpen = NativeUI.Visible(GarageMenu)

						if IsControlJustPressed(1, 51) then
							GarageOpen = not GarageOpen
							NativeUI.Visible(GarageMenu, GarageOpen)

							if GarageOpen then
								GarageMenuItems.Slots.Items = Garages:GenerateSlots(Garages[Index].Slots)
								GarageMenuItems.Slots.Index = 1
							end
						end

						if GarageOpen then
							ShowCursorThisFrame()
							NativeUI.Title()
							NativeUI.Subtitle()

							if IsGarageOwned(Type, Index) then
								
							else
								NativeUI.Button(GarageMenuItems.Purchase.Label, GarageMenuItems.Purchase.Description, GarageMenuItems.Purchase.RightLabel..(Garages[Index].Cost + (Garages.Data.Price.Slot * GarageMenuItems.Slots.Index)), GarageMenuItems.Purchase.LeftBadge, GarageMenuItems.Purchase.RightBadge, GarageMenuItems.Purchase.Enabled, function(Hovered, Active, Selected)
									if Active then
										if Enabled then
											GarageMenuItems.Purchase.Enabled = false

											TriggerServerEvent("Garages.Buy", Type, Index, 1)
										end
									end
								end)

								NativeUI.List(GarageMenuItems.Slots.Label, GarageMenuItems.Slots.Items, GarageMenuItems.Slots.Index, GarageMenuItems.Slots.Description, GarageMenuItems.Slots.Enabled, function(Hovered, Active, Selected, Index)
									GarageMenuItems.Slots.Index = Index
								end)
							end

							NativeUI.Background()
							NativeUI.Navigation()
							NativeUI.Description()
							NativeUI.Render()
						end

					elseif Distance > 3 then
						if NativeUI.Visible(GarageMenu) then
							NativeUI.Visible(GarageMenu, false)
						end
					end
				end
			end
		end
	end
end)