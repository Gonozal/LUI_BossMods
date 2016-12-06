require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Starmap"

local Locales = {
    ["enUS"] = {
        ["unit.world_ender"] = "World Ender",
        ["unit.asteroid"] = "Rogue Asteroid",
        ["unit.debris"] = "Cosmic Debris",
        -- Messages
        ["message.next_world_ender"] = "Next World Ender",
        -- Alerts
        ["alert.solar_wind"] = "Reset your stacks!",
        -- Labels
        ["label.solar_wind"] = "Solar Wind Stacks",
		["label.directions"] = "Cardinal Directions",
		["label.asteroid_player"] = "Lines to Asteroids",
		["label.debris_player"] = "Lines to Debris",

    },
    ["deDE"] = {
        ["unit.boss"] = "Starmap",
    },
    ["frFR"] = {
        ["unit.boss"] = "Starmap",
    },
}

local DEBUFF_SOLAR_WIND = 87536

local STARMAP_FLOOR_Y = -96

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Starmap"
    self.tTrigger = {
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 556,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            world_ender = {
                enable = true,
                label = "unit.world_ender",
            }
        },
        timers = {
            world_ender = {
                enable = true,
                label = "message.next_world_ender",
            },
        },
        alerts = {
            solar_wind = {
                enable = true,
                label = "label.solar_wind",
            },
        },
        auras = {
            solar_wind = {
                enable = true,
                sprite = "LUIBM_heat",
                color = "ffffa500",
                label = "label.solar_wind",
            },
        },
        lines = {
            world_ender = {
                enable = true,
                thickness = 16,
                color = "ff00ffff",
                label = "unit.world_ender",
            },
            asteroid = {
                enable = true,
                thickness = 8,
                color = "ffff0000",
                label = "unit.asteroid",
            },
			asteroid_player = {
                enable = true,
                thickness = 4,
                color = "ffff0000",
                label = "label.asteroid_player",
            },
            debris = {
                enable = true,
                thickness = 8,
                color = "ffff0000",
                label = "unit.debris",
            },
			debris_player = {
                enable = true,
                thickness = 4,
                color = "fff4d742",
                label = "unit.debris",
            },
        },
		texts = {
			cardinal_directions = {
				enable = true,
                font = "Subtitle",
                color = false,
                label = "label.directions",
			},
		},
        sounds = {
            solar_wind = {
                enable = true,
                file = "beware",
                label = "label.solar_wind",
            },
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.world_ender"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.world_ender, 30)
        self.core:AddUnit(nId,sName,tUnit,self.config.units.world_ender)
        self.core:AddTimer("Timer_WorldEnder", self.L["message.next_world_ender"], 66, self.config.timers.world_ender)
    elseif sName == self.L["unit.asteroid"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.asteroid, 15)
		self.core:DrawLineBetween("to" .. tostring(nId), tUnit, GameLib.GetPlayerUnit(), self.config.lines.asteroid_player)
    elseif sName == self.L["unit.debris"] then
        self.core:DrawPolygon(nId, tUnit, self.config.lines.debris, 3, 0, 6)
		self.core:DrawLineBetween("to" .. tostring(nId), tUnit, GameLib.GetPlayerUnit(), self.config.lines.debris_player)

    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_SOLAR_WIND == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if nStack >= 6 then
                self.core:ShowAura("STACKS", self.config.auras.solar_wind, nDuration, self.L["alert.solar_wind"])

                if not self.warned then
                    self.core:PlaySound(self.config.sounds.solar_wind)
                    self.core:ShowAlert("STACKS", self.L["alert.solar_wind"], self.config.alerts.solar_wind)
                    self.warned = true
                end
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_SOLAR_WIND == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("STACKS")
            self.warned = nil
        end
    end
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
    self.core:AddTimer("Timer_WorldEnder", self.L["message.next_world_ender"], 52, self.config.timers.world_ender)
	
	local south_pos = Vector3.New({x = -77, y= STARMAP_FLOOR_Y, z = 410})
	local north_pos = Vector3.New({x = -77,  y = STARMAP_FLOOR_Y,  z = 310})
	local west_pos =  Vector3.New({x = -127, y = STARMAP_FLOOR_Y, z = 360})
	local east_pos =  Vector3.New({x = -27,  y = STARMAP_FLOOR_Y,  z = 360})
	
	self.core:DrawText("southLabel", south_pos, self.config.texts.cardinal_directions, "South", false, 50)
	self.core:DrawText("northLabel", north_pos, self.config.texts.cardinal_directions, "North", false, 50)
	self.core:DrawText("westLabel", west_pos, self.config.texts.cardinal_directions, "West", false, 50)
	self.core:DrawText("eastLabel", east_pos, self.config.texts.cardinal_directions, "East", false, 50)



end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
