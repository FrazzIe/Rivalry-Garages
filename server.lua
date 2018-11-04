function number_to_bool(value)
	return value == 1
end

function bool_to_number(value)
	return value and 1 or 0
end

function Garages:GetVehicleIndex(Source, Id)
	for Index = 1, #Garages.Data.Vehicles[Source] do
		if Id == Garages.Data.Vehicles[Source][Index].Id then
			return Index
		end
	end

	return nil
end

function Garages:GetGarageIndex(Source, Type, GarageId)
	for Index = 1, #Garages.Data.Garages[Source] do
		if GarageId == Garages.Data.Garages[Source][Index].GarageId and Type == Garages.Data.Garages[Source][Index].Type then
			return Index
		end
	end

	return nil
end

function Garages:AddVehicle(Source, Vehicle)
	table.insert(Garages.Data.Vehicles[Source], Vehicle)

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
end

function Garages:PurchaseGarage(Source, Type, GarageId, Slots, Cost, CharacterId)
	exports["GHMattiMySQL"]:Insert("garages", {
		{
			["character_id"] = CharacterId,
			["garage_id"] = GarageId,
			["type"] = Type,
			["cost"] = Cost,
			["slots"] = Slots,
		}
	}, function(id)
		table.insert(Garages.Data.Garages[Source], {Id = id, CharacterId = CharacterId, Type = Type, Cost = Cost, GarageId = GarageId, Slots = Slots})

		TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)

		--Notify("Garage purchased!", 3000, Source)
	end, true)
end

function Garages:RemoveImpound(Source, Plate, Index)
	Garages.Data.Vehicles[Source][Index].State = "Available"

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
end

function Garages:PurchaseInsurance(Source, Index)
	Garages.Data.Vehicles[Source][Index].Insurance = true

	exports["GHMattiMySQL"]:QueryAsync("UPDATE vehicles SET insurance=1 WHERE id=@id", {["@id"] = Garages.Data.Vehicles[Source][Index].Id})

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)

	--Notify("Insurance purchased", 3000, Source)
end

function Garages:UpgradeGarage(Source, GarageId, Index)
	Garages.Data.Garages[Source][Index].Cost = Garages.Data.Garages[Source][Index].Cost + Garages.Data.Price.Slot
	Garages.Data.Garages[Source][Index].Slots = Garages.Data.Garages[Source][Index].Slots + 1

	exports["GHMattiMySQL"]:QueryAsync("UPDATE garages SET cost=@cost, slots=@slots WHERE garage_id=@garage_id", {["@garage_id"] = GarageId, ["cost"] = Garages.Data.Garages[Source][Index].Cost, ["slots"] = Garages.Data.Garages[Source][Index].Slots})

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)

	--Notify("Garage upgraded!", 3000, Source)
end

RegisterServerEvent("Garages.Initialise")
AddEventHandler("Garages.Initialise", function(Source, Identifier, CharacterId)
	Garages.Data.Garages[Source] = {}
	Garages.Data.Vehicles[Source] = {}

	exports["GHMattiMySQL"]:QueryResultAsync("SELECT * FROM garages WHERE character_id=@character_id", {["@character_id"] = CharacterId}, function(Garages)
		TriggerClientEvent("Garages.Setup.Garages", Source, Garages)
	end)

	exports["GHMattiMySQL"]:QueryResultAsync("SELECT * FROM vehicles WHERE character_id=@character_id", {["@character_id"] = CharacterId}, function(Vehicles)
		TriggerClientEvent("Garages.Setup.Vehicles", Source, Vehicles)
	end)

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
end)

RegisterServerEvent("Garages.Setup.Garages")
AddEventHandler("Garages.Setup.Garages", function(Garages)
	local Source = source

	Garages.Data.Garages[Source] = Garages

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
end)

RegisterServerEvent("Garages.Setup.Vehicles")
AddEventHandler("Garages.Setup.Vehicles", function(Vehicles)
	local Source = source
	
	Garages.Data.Vehicles[Source] = Vehicles

	TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
end)

RegisterServerEvent("Garages.Buy")
AddEventHandler("Garages.Buy", function(Type, GarageId, Slots)
	local Source = source
	local Cost = math.round(Config.Garages[Type][GarageId].Cost + (Garages.Data.Price.Slot * Slots))

	TriggerEvent("core:getuser", Source, function(user)
		if user.get("wallet") >= Cost then
			user.removeWallet(Cost)

			PurchaseGarage(Source, Type, GarageId, Slots, Cost, user.get("characterID"))
		elseif user.get("bank") >= Cost then
			user.removeBank(Cost)

			PurchaseGarage(Source, Type, GarageId, Slots, Cost, user.get("characterID"))
		else
			--Notify("Insufficient funds", 3000, Source)

			TriggerClientEvent("Garages.Reset", Source)
		end
	end)
end)

RegisterServerEvent("Garages.Sell")
AddEventHandler("Garages.Sell", function(Type, GarageId)
	local Source = source
	local Index = GetGarageIndex(Source, Type, GarageId)

	if Index then
		TriggerEvent("core:getuser", Source, function(user)
			user.addBank(math.round(Garages.Data.Garages[Source][Index].Cost/2))

			table.remove(Garages.Data.Garages[Source], Index)

			exports["GHMattiMySQL"]:QueryAsync("DELETE FROM garages WHERE garage_id=@garage_id", {["@garage_id"] = GarageId})

			TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)

			--Notify("Garage sold!", 3000, Source)
		end)
	else
		TriggerClientEvent("Garages.Reset", Source)
	end
end)

RegisterServerEvent("Garages.Sell.Vehicle")
AddEventHandler("Garages.Sell.Vehicle", function(Handle, Id)
	local Source = source
	local Index = GetVehicleIndex(Source, Id)

	if Index then
		TriggerEvent("core:getuser", Source, function(user)
			user.addBank(math.round(Garages.Data.Vehicles[Source][Index].Cost/2))

			table.remove(Garages.Data.Vehicles, Index)

			exports["GHMattiMySQL"]:QueryAsync("DELETE FROM vehicles WHERE id=@id", {["@id"] = Id})

			TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)

			--Notify("Vehicle sold!", 3000, Source)
		end)
	else
		--Notify("This vehicle does not belong to you!", 3000, Source)
	end
end)

RegisterServerEvent("Garages.Impound")
AddEventHandler("Garages.Impound", function(Id)
	local Source = source
	local Index = GetVehicleIndex(Source, Id)

	if Index then
		TriggerEvent("core:getuser", Source, function(user)
			if user.get("wallet") >= Garages.Data.Price.Impound then
				user.removeWallet(Garages.Data.Price.Impound)

				RemoveImpound(Source, Id)
			elseif user.get("bank") >= Garages.Data.Price.Impound then
				user.removeBank(Garages.Data.Price.Impound)

				RemoveImpound(Source, Id)
			else
				--Notify("Insufficient funds", 3000, Source)

				TriggerClientEvent("Garages.Reset", Source)
			end
		end)
	else
		TriggerClientEvent("Garages.Reset", Source)
	end
end)

RegisterServerEvent("Garages.Store")
AddEventHandler("Garages.Store", function(Vehicle)
	local Source = source
	local Index = GetVehicleIndex(Source, Vehicle.Id)

	if Index then
		Garages.Data.Vehicles[Source][Index].Mods = Vehicle.Mods
		Garages.Data.Vehicles[Source][Index].Colour = Vehicle.Colour
		Garages.Data.Vehicles[Source][Index].Wheels = Vehicle.Wheels
		Garages.Data.Vehicles[Source][Index].Neon = Vehicle.Neon
		Garages.Data.Vehicles[Source][Index].State = Vehicle.State
		Garages.Data.Vehicles[Source][Index].Turbo = Vehicle.Turbo
		Garages.Data.Vehicles[Source][Index].TyreSmoke = Vehicle.TyreSmoke
		Garages.Data.Vehicles[Source][Index].XenonLights = Vehicle.XenonLights
		Garages.Data.Vehicles[Source][Index].GarageId = Vehicle.GarageId

		exports["GHMattiMySQL"]:QueryAsync("UPDATE vehicles SET garage_id=@garage_id, primary_colour=@primary_colour, secondary_colour=@secondary_colour, pearlescent_colour=@pearlescent_colour, wheel_colour=@wheel_colour, dashboard_colour=@dashboard_colour, interior_colour=@interior_colour, smoke_colour=@smoke_colour, plate_colour=@plate_colour, neon_colour=@neon_colour, tint_colour=@tint_colour, mod0=@mod0, mod1=@mod1, mod2=@mod2, mod3=@mod3, mod4=@mod4, mod5=@mod5, mod6=@mod6, mod7=@mod7, mod8=@mod8, mod10=@mod10, mod11=@mod11, mod12=@mod12, mod13=@mod13, mod14=@mod14, mod15=@mod15, mod16=@mod16, mod23=@mod23, mod24=@mod24, mod25=@mod25, mod26=@mod26, mod27=@mod27, mod28=@mod28, mod29=@mod29, mod30=@mod30, mod31=@mod31, mod32=@mod32, mod33=@mod33, mod34=@mod34, mod35=@mod35, mod36=@mod36, mod37=@mod37, mod38=@mod38, mod39=@mod39, mod40=@mod40, mod41=@mod41, mod42=@mod42, mod43=@mod43, mod44=@mod44, mod45=@mod45, mod46=@mod46, mod48=@mod48, tyre_smoke=@tyre_smoke, xenon_lights=@xenon_lights, turbo=@turbo, custom_wheels=@custom_wheels, custom_wheels2=@custom_wheels2, bulletproof_wheels=@bulletproof_wheels, wheeltype=@wheeltype, neon0=@neon0, neon1=@neon1, neon2=@neon2, neon3=@neon3, engine_health=@engine_health, petrol_health=@petrol_health, vehicle_health=@vehicle_health WHERE id=@id", { 
			["@id"] = Garages.Data.Vehicles[Source][Index].Id,
			["@character_id"] = Garages.Data.Vehicles[Source][Index].CharacterId,
			["@garage_id"] = Garages.Data.Vehicles[Source][Index].GarageId,
			["@primary_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Primary,
			["@secondary_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Secondary,
			["@pearlescent_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Pearlescent,
			["@wheel_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Wheel,
			["@dashboard_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Dashboard,
			["@interior_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Interior,
			["@smoke_colour"] = json.encode({Garages.Data.Vehicles[Source][Index].Colour.Smoke.Red, Garages.Data.Vehicles[Source][Index].Colour.Smoke.Green, Garages.Data.Vehicles[Source][Index].Colour.Smoke.Blue}),
			["@plate_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Plate,
			["@neon_colour"] = json.encode({Garages.Data.Vehicles[Source][Index].Colour.Neon.Red, Garages.Data.Vehicles[Source][Index].Colour.Neon.Green, Garages.Data.Vehicles[Source][Index].Colour.Neon.Blue}),
			["@tint_colour"] = Garages.Data.Vehicles[Source][Index].Colour.Tint,
			["@mod0"] = Garages.Data.Vehicles[Source][Index].Mods["0"],
			["@mod1"] = Garages.Data.Vehicles[Source][Index].Mods["1"],
			["@mod2"] = Garages.Data.Vehicles[Source][Index].Mods["2"],
			["@mod3"] = Garages.Data.Vehicles[Source][Index].Mods["3"],
			["@mod4"] = Garages.Data.Vehicles[Source][Index].Mods["4"],
			["@mod5"] = Garages.Data.Vehicles[Source][Index].Mods["5"],
			["@mod6"] = Garages.Data.Vehicles[Source][Index].Mods["6"],
			["@mod7"] = Garages.Data.Vehicles[Source][Index].Mods["7"],
			["@mod8"] = Garages.Data.Vehicles[Source][Index].Mods["8"],
			["@mod10"] = Garages.Data.Vehicles[Source][Index].Mods["10"],
			["@mod11"] = Garages.Data.Vehicles[Source][Index].Mods["11"],
			["@mod12"] = Garages.Data.Vehicles[Source][Index].Mods["12"],
			["@mod13"] = Garages.Data.Vehicles[Source][Index].Mods["13"],
			["@mod14"] = Garages.Data.Vehicles[Source][Index].Mods["14"],
			["@mod15"] = Garages.Data.Vehicles[Source][Index].Mods["15"],
			["@mod16"] = Garages.Data.Vehicles[Source][Index].Mods["16"],
			["@mod23"] = Garages.Data.Vehicles[Source][Index].Wheels.Front.Handle,
			["@mod24"] = Garages.Data.Vehicles[Source][Index].Wheels.Rear.Handle,
			["@mod25"] = Garages.Data.Vehicles[Source][Index].Mods["25"],
			["@mod26"] = Garages.Data.Vehicles[Source][Index].Mods["26"],
			["@mod27"] = Garages.Data.Vehicles[Source][Index].Mods["27"],
			["@mod28"] = Garages.Data.Vehicles[Source][Index].Mods["28"],
			["@mod29"] = Garages.Data.Vehicles[Source][Index].Mods["29"],
			["@mod30"] = Garages.Data.Vehicles[Source][Index].Mods["30"],
			["@mod31"] = Garages.Data.Vehicles[Source][Index].Mods["31"],
			["@mod32"] = Garages.Data.Vehicles[Source][Index].Mods["32"],
			["@mod33"] = Garages.Data.Vehicles[Source][Index].Mods["33"],
			["@mod34"] = Garages.Data.Vehicles[Source][Index].Mods["34"],
			["@mod35"] = Garages.Data.Vehicles[Source][Index].Mods["35"],
			["@mod36"] = Garages.Data.Vehicles[Source][Index].Mods["36"],
			["@mod37"] = Garages.Data.Vehicles[Source][Index].Mods["37"],
			["@mod38"] = Garages.Data.Vehicles[Source][Index].Mods["38"],
			["@mod39"] = Garages.Data.Vehicles[Source][Index].Mods["39"],
			["@mod40"] = Garages.Data.Vehicles[Source][Index].Mods["40"],
			["@mod41"] = Garages.Data.Vehicles[Source][Index].Mods["41"],
			["@mod42"] = Garages.Data.Vehicles[Source][Index].Mods["42"],
			["@mod43"] = Garages.Data.Vehicles[Source][Index].Mods["43"],
			["@mod44"] = Garages.Data.Vehicles[Source][Index].Mods["44"],
			["@mod45"] = Garages.Data.Vehicles[Source][Index].Mods["45"],
			["@mod46"] = Garages.Data.Vehicles[Source][Index].Mods["46"],
			["@mod48"] = Garages.Data.Vehicles[Source][Index].Mods["48"],
			["@tyre_smoke"] = Garages.Data.Vehicles[Source][Index].TyreSmoke,
			["@xenon_lights"] = Garages.Data.Vehicles[Source][Index].XenonLights,
			["@turbo"] = Garages.Data.Vehicles[Source][Index].Turbo,
			["@custom_wheels"] = Garages.Data.Vehicles[Source][Index].Wheels.Front.Custom,
			["@custom_wheels2"] = Garages.Data.Vehicles[Source][Index].Wheels.Rear.Custom,
			["@bulletproof_wheels"] = Garages.Data.Vehicles[Source][Index].Wheels.Bulletproof,
			["@wheeltype"] = Garages.Data.Vehicles[Source][Index].Wheels.Type,
			["@neon0"] = Garages.Data.Vehicles[Source][Index].Neon[1],
			["@neon1"] = Garages.Data.Vehicles[Source][Index].Neon[2],
			["@neon2"] = Garages.Data.Vehicles[Source][Index].Neon[3],
			["@neon3"] = Garages.Data.Vehicles[Source][Index].Neon[4],
			["@engine_health"] = Garages.Data.Vehicles[Source][Index].Health.Engine,
			["@petrol_health"] = Garages.Data.Vehicles[Source][Index].Health.Petrol,
			["@vehicle_health"] = Garages.Data.Vehicles[Source][Index].Health.Vehicle,
			["@body_health"] = Garages.Data.Vehicles[Source][Index].Health.Body,
		})

		TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
	end
end)

RegisterServerEvent("Garages.Out")
AddEventHandler("Garages.Out", function(Vehicle)
	local Source = source
	local Index = GetVehicleIndex(Source, Vehicle.Id)

	if Index then
		Garages.Data.Vehicles[Source][Index].State = Vehicle.State
		Garages.Data.Vehicles[Source][Index].Handle = Vehicle.Handle
				
		TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
	end
end)

RegisterServerEvent("Garages.Insurance")
AddEventHandler("Garages.Insurance", function(Id)
	local Source = source
	local Index = GetVehicleIndex(Source, Id)

	if Index then
		local Cost = math.round(Garages.Data.Vehicles[Source][Index].Cost/10)

		TriggerEvent("core:getuser", Source, function(user)
			if user.get("wallet") >= Cost then
				user.removeWallet(Cost)

				PurchaseInsurance(Source, Index)
			elseif user.get("bank") >= Cost then
				user.removeBank(Cost)
				PurchaseInsurance(Source, Index)
			else
				Notify("Insufficient funds", 3000, Source)
				TriggerClientEvent("Garages.Reset", Source)
			end
		end)
	else
		TriggerClientEvent("Garages.Reset", Source)
	end
end)

RegisterServerEvent("Garages.Claim")
AddEventHandler("Garages.Claim", function(Id)
	local Source = source
	local Index = GetVehicleIndex(Source, Id)

	if Index then
		Garages.Data.Vehicles[Source][Index].State = "Available"

		TriggerClientEvent("Garages.Sync", -1, Garages.Data.Vehicles, Garages.Data.Garages)
	else
		TriggerClientEvent("Garages.Reset", Source)
	end
end)

RegisterServerEvent("Garages.Upgrade")
AddEventHandler("Garages.Upgrade", function(Type, GarageId)
	local Source = source
	local Index = GetGarageIndex(Source, Type, GarageId)

	if Index then
		TriggerEvent("core:getuser", Source, function(user)
			if user.get("wallet") >= Garages.Data.Price.Slot then
				user.removeWallet(Garages.Data.Price.Slot)

				UpgradeGarage(Source, GarageId, Index)
			elseif user.get("bank") >= Garages.Data.Price.Slot then
				user.removeBank(Garages.Data.Price.Slot)

				UpgradeGarage(Source, GarageId, Index)
			else
				--Notify("Insufficient funds", 3000, Source)

				TriggerClientEvent("Garages.Reset", Source)
			end
		end)
	else
		TriggerClientEvent("Garages.Reset", Source)
	end
end)