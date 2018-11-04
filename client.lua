function Garages:GetPlayer()
	return Garages.Data.ServerId or GetPlayerFromServerId(PlayerId())
end

function Garages:SetupVehicle(data)
	local NeonColour, SmokeColour = json.decode(data.neon_colour), json.decode(data.smoke_colour)
	local Vehicle = {
		Id = data.id,
		Plate = data.plate,
		CharacterId = data.character_id,
		Model = data.model,
		Name = data.name,
		Cost = data.cost,
		State = data.state,
		Type = data.type,
		GarageId = data.garage_id,
		Insured = number_to_bool(data.insurance),
		Mods = {},
		Wheels = {
			Type = data.wheeltype,
			Bulletproof = number_to_bool(data.bulletproof_wheels),
			Front = {
				Handle = data.mod23,
				Custom = number_to_bool(data.custom_wheels),
			},
			Rear = {
				Handle = data.mod24,
				Custom = number_to_bool(data.custom_wheels2),
			},
		},
		Neon = {
			number_to_bool(data.neon0),
			number_to_bool(data.neon1),
			number_to_bool(data.neon2),
			number_to_bool(data.neon3),
		},
		Turbo = number_to_bool(data.turbo),
		TyreSmoke = number_to_bool(data.tyre_smoke),
		XenonLights = number_to_bool(data.xenon_lights),
		Colour = {
			Primary = data.primary_colour,
			Secondary = data.secondary_colour,
			Pearlescent = data.pearlescent_colour,
			Wheel = data.wheel_colour,
			Dashboard = data.dashboard_colour,
			Interior = data.interior_colour,
			Neon = {Red = NeonColour[1], Green = NeonColour[2], Blue = NeonColour[3]},
			Smoke = {Red = SmokeColour[1], Green = SmokeColour[2], Blue = SmokeColour[3]},
			Tint = data.tint_colour,
			Plate = data.plate_colour,
		},
		Health = {
			Engine = data.engine_health,
			Petrol = data.petrol_health,
			Vehicle = data.vehicle_health,
			Body = data.body_health,
		},
	}

	for Index = 0, 48 do
		if data["mod"..Index] and Index ~= 23 and Index ~= 24 then
			Vehicle.Mods[tostring(Index)] = tonumber(data["mod"..Index])
		end
	end

	return Vehicle
end

function Garages:SetupGarage(data)
	local Garage = {
		Id = data.id,
		CharacterId = data.character_id,
		Type = data.type,
		Cost = data.cost,
		GarageId = data.garage_id,
		Slots = data.slots,
	}
	return Garage
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
		if IsVehicleOwned(Vehicle) then
			local Index = GetVehicleIndex(Vehicle)
			local Player = Garages.GetPlayer()

			if Type == Garages.Data.Vehicles[Player][Index].Type then
				local SlotsUsed = GetGarageCount(Type, GarageId)

				if SlotsUsed < Garages.Config.Locations[Type][GarageId].Slots or (SlotsUsed >= Garages.Config.Locations[Type][GarageId].Slots and Garages.Config.Locations[Index].GarageId == GarageId) then
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

					for Neon = 0, 3 do
						Garages.Data.Vehicles[Player][Index].Neon[Neon + 1] = tobool(IsVehicleNeonLightEnabled(Vehicle, Neon))
					end

					for Mod = 0, 48 do
						if Garages.Data.Vehicles[Player][Index].Mods[tostring(Mod)] then
							Garages.Data.Vehicles[Player][Index].Mods[tostring(Mod)] = GetVehicleMod(Vehicle, Mod)
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
		Store = {
			Label = "Store",
			Description = "Store a vehicle in the garage!",
			Enabled = true
		},
		Vehicle = {
			Description = {
				["Available"] = "Take this vehicle out?",
				["Missing"] = "This vehicle is missing!",
				["Impounded"] = "This vehicle was impounded, it will cost you $"..Garages.Data.Price.Impound.." to get access to it!"
			},
			RightLabel = {
				["Available"] = "~g~",
				["Missing"] = "~r~",
				["Impounded"] = "~b~"
			},
			Enabled = true,
		}
		Empty = {
			Label = "Empty slot", 
			Description = "An empty slot?",
			Enabled = true,
		},
		Upgrade = {
			Label = "Purchase slot",
			Description = "A slot in the garage that you can purchase?",
			RightLabel = "$",
			Enabled = true,
		},
		Sell = {
			Label = "Sell",
			Description = "Sell your garage!",
			RightLabel = "$",
			Enabled = true,
		},
	}
	local InsuranceMenu = NativeUI.CreateMenu("Insurance", "Vehicles", 1300, 300)
	local InsuranceMenuItems = {
		Claim = {
			Description = "Once you claim a vehicle it will go back into your garage!",
			RightLabel = "~b~Claim",
			Enabled = true,
		},
		Purchase = {
			Description = "You can insure this vehicle for $",
			RightLabel = "~r~Uninsured",
			Enabled = true,
		},
		Insured = {
			Description = "This vehicle is already insured and stored in the garage!",
			RightLabel = "~g~Insured",
			Enabled = true,
		},
	}

	function DisableGarageItems(Bool)
		if type(Bool) == "boolean" then
			for Item, Attributes in pairs(GarageMenuItems) do
				Attributes.Enabled = not Bool
			end
		end
	end

	function DisableInsuranceItems(Bool)
		if type(Bool) == "boolean" then
			for Item, Attributes in pairs(InsuranceMenuItems) do
				Attributes.Enabled = not Bool
			end
		end
	end

	RegisterNetEvent("Garages.Reset")
	AddEventHandler("Garages.Reset", function()
		DisableGarageItems(false)
		DisableInsuranceItems(false)
	end)

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
								local PersonalGarage = Garages.Data.Garages[Garages:GetPlayer()][Garages:GetGarageIndex(Type, Index)]

								if PersonalGarage then
									local SlotsUsed = GetGarageCount(Type, GarageId)
									local AvaliableSlots = PersonalGarage.Slots - SlotsUsed
									local PurchasableSlots = Garages[Index].Slots - PersonalGarage.Slots

									NativeUI.Button(GarageMenuItems.Store.Label, GarageMenuItems.Store.Description, nil, nil, nil, GarageMenuItems.Store.Enabled, function(Hovered, Active, Selected)
										if Active then
											local Vehicle, Position = GetNearestVehicleAtCoords(PlayerPosition.x, PlayerPosition.y, PlayerPosition.z, 10)

											Garages:StoreVehicle(Vehicle, Type, Index)
										end
									end)

									for Vehicle = 1, #Garages.Data.Vehicles do
										if Garages.Data.Vehicles[Vehicle].GarageId == Index then
											NativeUI.Button(Garages.Data.Vehicles[Vehicle].Name, GarageMenuItems.Vehicle.Description[Garages.Data.Vehicles[Vehicle].State], GarageMenuItems.Vehicle.RightLabel[Garages.Data.Vehicles[Vehicle].State]..Garages.Data.Vehicles[Vehicle].State, nil, nil, GarageMenuItems.Vehicle.Enabled, function(Hovered, Active, Selected)
												if Active then
													if GarageMenuItems.Vehicle.Enabled then
														if Garages.Data.Vehicles[Vehicle].State == "Available" then
															NativeUI.Visible(GarageMenu, false)
															Garages:StoreVehicle(Garages.Data.Vehicles[Vehicle], Type, Index)

														elseif Garages.Data.Vehicles[Vehicle].State == "Impounded" then
															DisableGarageItems(true)

															TriggerServerEvent("Garages.Impound", Garages.Data.Vehicles[Vehicle].Id)
														end
													end
												end
											end)
										end
									end

									if AvailableSlots > 0 then
										for EmptySlot = 1, AvailableSlots do
											NativeUI.Button(GarageMenuItems.Empty.Label, GarageMenuItems.Empty.Description, nil, nil, nil, GarageMenuItems.Empty.Enabled, function(Hovered, Active, Selected)
												if Active then
													PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
												end
											end)
										end
									end

									if PurchasableSlots > 0 then
										for AvailableSlot = 1, PurchasableSlots do
											NativeUI.Button(GarageMenuItems.Upgrade.Label, GarageMenuItems.Upgrade.Description, GarageMenuItems.Upgrade.RightLabel..Garages.Data.Price.Slot, nil, nil, GarageMenuItems.Upgrade.Enabled, function(Hovered, Active, Selected)
												if Active then
													if GarageMenuItems.Upgrade.Enabled then
														DisableGarageItems(true)

														TriggerServerEvent("Garages.Upgrade", Type, Index)
													end
												end
											end)
										end
									end

									if SlotsUsed == 0 then
										NativeUI.Button(GarageMenuItems.Sell.Label, GarageMenuItems.Sell.Description, GarageMenuItems.Sell.RightLabel..PersonalGarage.Cost, nil, nil, GarageMenuItems.Upgrade.Enabled, function(Hovered, Active, Selected)
											if Active then
												if GarageMenuItems.Sell.Enabled then
													DisableGarageItems(true)

													TriggerServerEvent("Garages.Sell", Type, Index)
												end
											end
										end)
									end
								end
							else
								NativeUI.Button(GarageMenuItems.Purchase.Label, GarageMenuItems.Purchase.Description, GarageMenuItems.Purchase.RightLabel..(Garages[Index].Cost + (Garages.Data.Price.Slot * GarageMenuItems.Slots.Index)), GarageMenuItems.Purchase.LeftBadge, GarageMenuItems.Purchase.RightBadge, GarageMenuItems.Purchase.Enabled, function(Hovered, Active, Selected)
									if Active then
										if GarageMenuItems.Purchase.Enabled then
											DisableGarageItems(true)

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

		for Index = 1, #Config.Garages.Insurance do
			local Distance = #(Config.Garages.Insurance[Index] - PlayerPosition)

			if Distance < 20 then
				Utilities.RenderMarker(25, Config.Garages.Insurance[Index].x, Config.Garages.Insurance[Index].y, Config.Garages.Insurance[Index].z, 3.0, 3.0, 3.5, 255, 255, 0, 255)

				if Distance < 3 then
					Utilities.DisplayHelpText("Press ~INPUT_CONTEXT~ to open the insurance centre!")
						
					local InsuranceOpen = NativeUI.Visible(InsuranceMenu)

					if IsControlJustPressed(1, 51) then
						InsuranceOpen = not InsuranceOpen
						NativeUI.Visible(InsuranceMenu, InsuranceOpen)
					end
					
					if InsuranceOpen then
						local Vehicles = Garages.Data.Vehicles[Garages:GetPlayer()]

						if Vehicles then
							ShowCursorThisFrame()
							NativeUI.Title()
							NativeUI.Subtitle()

							for Vehicle = 1, #Vehicles do
								if Vehicles[Vehicle].Insured then
									if Vehicles[Vehicle].State == "Missing" then
										NativeUI.Button(Vehicles[Vehicle].Name, InsuranceMenuItems.Claim.Description, InsuranceMenuItems.Claim.RightLabel, nil, nil, InsuranceMenuItems.Claim.Enabled, function(Hovered, Active, Selected)
											if Active then
												if InsuranceMenuItems.Claim.Enabled then
													DisableInsuranceItems(true)

													TriggerServerEvent("Garages.Claim", Vehicles[Vehicle].Id)
												end
											end
										end)
									else
										NativeUI.Button(Vehicles[Vehicle].Name, InsuranceMenuItems.Insured.Description, InsuranceMenuItems.Insured.RightLabel, nil, nil, InsuranceMenuItems.Insured.Enabled, function(Hovered, Active, Selected)
										end)
									end
								else
									NativeUI.Button(Vehicles[Vehicle].Name, InsuranceMenuItems.Purchase.Description..math.round(Vehicles[Vehicle].Cost/10), InsuranceMenuItems.Purchase.RightLabel, nil, nil, InsuranceMenuItems.Purchase.Enabled, function(Hovered, Active, Selected)
										if Active then
											if InsuranceMenuItems.Purchase.Enabled then
												DisableInsuranceItems(true)

												TriggerServerEvent("Garages.Insurance", Vehicles[Vehicle].Id)
											end
										end
									end)
								end
							end

							NativeUI.Background()
							NativeUI.Navigation()
							NativeUI.Description()
							NativeUI.Render()
						end
					end
				elseif Distance > 3 then
					if NativeUI.Visible(InsuranceMenu) then
						NativeUI.Visible(InsuranceMenu, false)
					end
				end
			end
		end
	end
end)

RegisterNetEvent("Garages.Sync")
AddEventHandler("Garages.Sync", function(Vehicles, Garages)
	Garages.Data.Vehicles = Vehicle
	Garages.Data.Garages = Garages
end)

RegisterNetEvent("Garages.Setup.Garages")
AddEventHandler("Garages.Setup.Garages", function(Garages)
	for Index = 1, #Garages do
		Garages[Index] = Garages:SetupGarage(Garages[Index])
	end

	TriggerServerEvent("Garages.Setup.Garages", Garages)
end)

RegisterNetEvent("Garages.Setup.Vehicles")
AddEventHandler("Garages.Setup.Vehicles", function(Vehicles)
	for Index = 1, #Vehicles do
		Vehicles[Index] = Garages:SetupVehicle(Vehicles[Index])
	end

	TriggerServerEvent("Garages.Setup.Vehicles", Vehicles)
end)