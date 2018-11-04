Garages = {}

Garages.Data = {
	Vehicles = {},
	Garages = {},
	Price = {
		Slot = 250,
		Impound = 5000,
	},
}

Garages.Config = {
	Blips = {
		["Vehicle"] = {
			Name = "Garage",
			Sprite = 1,
			Colour = 1,
		},
		["Watercraft"] = {
			Name = "Marina",
			Sprite = 1,
			Colour = 1,
		},
		["Aircraft"] = {
			Name = "Hangar",
			Sprite = 1,
			Colour = 1,
		},
	}
}

Garages.Config.Locations = {
	["Vehicle"] = {},
	["Watercraft"] = {},
	["Aircraft"] = {},
}

Garages.Config.Insurance = {
	
}

if not IsDuplicityVersion() then
	AddEventHandler("onClientMapStart", function()
		Garages.Data.ServerId = GetPlayerServerId(PlayerId())
	end)
end