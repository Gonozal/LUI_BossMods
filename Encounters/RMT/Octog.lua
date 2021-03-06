require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Octog"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Star-Eater the Voracious",
    	["unit.shard"] = "Astral Shard",
		["unit.shard_circle"] = "Astral Shard Circle",
        ["unit.squirgling"] = "Squirgling",
        ["unit.chaos_orb"] = "Chaos Orb",
        ["unit.noxious_ink_pool"] = "Noxious Ink Pool",
        -- Casts
        ["cast.hookshot"] = "Hookshot",
        ["cast.summon_squirglings"] = "Summon Squirglings",
        ["cast.flamethrower"] = "Flamethrower",
        ["cast.supernova"] = "Supernova",
        -- Alerts
        ["alert.hookshot"] = "HOOKSHOT!",
        ["alert.flamethrower"] = "FLAMETHROWER!",
        ["alert.chaos_tether"] = "STAY INSIDE CHAOS ORB!!!",
        -- Labels
        ["label.next_hookshot"] = "Next Hookshot",
        ["label.next_flamethrower"] = "Next Flamethrower",
        ["label.next_orbs"] = "Next Orbs",
        ["label.chaos_tether"] = "Chaos Tether",
		["label.shard_circle"] = "Astral Shard Circle",
		["label.noxious_ink_pool"] = "Squirgling Pools",
    },
    ["deDE"] = {
        ["unit.boss"] = "Star-Eater the Voracious",
    },
    ["frFR"] = {
        ["unit.boss"] = "Star-Eater the Voracious",
    },
}

local DEBUFF_CHAOS_TETHER = 85583
local BUFF_CHAOS_AMPLIFIER = 86876

local ROCKET_HEIGHT = 20
local ROOM_FLOOR_Y = 378

local POOL_CHECK_INTERVALL = 0.25


function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Octog"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 0,
                mapId = 548,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss = {
                enable = true,
                label = "unit.boss",
                position = 1,
            },
        },
        timers = {
            hookshot = {
                enable = true,
                position = 1,
                color = "c8ffd700",
                label = "label.next_hookshot",
            },
            flamethrower = {
                enable = true,
                position = 2,
                color = "c8ff4500",
                label = "label.next_flamethrower",
            },
            orbs = {
                enable = true,
                position = 3,
                color = "c89932cc",
                label = "label.next_orbs",
            },
            supernova = {
                enable = true,
                position = 4,
                color = "c800ffff",
                label = "cast.supernova",
            },
        },
        alerts = {
            hookshot = {
                enable = true,
                position = 1,
                label = "cast.hookshot",
            },
            flamethrower = {
                enable = true,
                position = 2,
                label = "cast.flamethrower",
            },
            chaos_tether = {
                enable = true,
                position = 3,
                label = "label.chaos_tether",
            },
        },
        sounds = {
            hookshot = {
                enable = true,
                position = 1,
                file = "burn",
                label = "cast.hookshot",
            },
            flamethrower = {
                enable = true,
                position = 2,
                file = "inferno",
                label = "cast.flamethrower",
            },
            chaos_tether = {
                enable = true,
                position = 3,
                file = "beware",
                label = "label.chaos_tether",
            },
        },
        auras = {
            chaos_tether = {
                enable = true,
                sprite = "LUIBM_position",
                color = "ff9932cc",
                label = "label.chaos_tether",
            },
        },
        lines = {
            hookshot = {
                enable = true,
                position = 1,
                thickness = 6,
                color = "ffff0000",
                label = "cast.hookshot",
            },
			pools = {
                enable = true,
                position = 5,
                thickness = 5,
                sColor = "ff0000ff",
				color = "ff0000ff",
                label = "label.noxious_ink_pool",
            },
			shard_circles = {
                enable = true,
                position = 4,
                thickness = 5,
                sColor = "ff00ffff",
                label = "label.shard_circle",
            },	
            shards = {
                enable = true,
                position = 2,
                thickness = 6,
                color = "ff00ffff",
                label = "unit.shard",
             },
            squirgling = {
                enable = true,
                position = 3,
                thickness = 6,
                color = "ff00ffff",
                label = "unit.squirgling",
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

    if sName == self.L["unit.boss"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
        self.core:DrawPolygon("HOOSHOT1", tUnit, self.config.lines.hookshot, 10.5, 0, 20, nil, Vector3.New(3,0,9.25))
        self.core:DrawPolygon("HOOSHOT2", tUnit, self.config.lines.hookshot, 10.5, 0, 20, nil, Vector3.New(-3,0,9.25))
    elseif sName == self.L["unit.squirgling"] then
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.squirgling)
    elseif sName == self.L["unit.shard"] and self.config.lines.shards.enable then
        if not self.tShardTimer then
            self.tShardTimer = ApolloTimer.Create(.1, true, "CheckShardsTimer", self)
        end
		local shardPos = tUnit:GetPosition()
		if shardPos.y - ROOM_FLOOR_Y < 20 then
			local size = 2 - ((shardPos.y - ROOM_FLOOR_Y) / 40)
			shardPos.y = ROOM_FLOOR_Y
			--self.core:DrawPolygon(nId, shardPos, size, 0, 3, "red", 20)
			self.core:DrawPolygon("shardcircle".. tostring(nId), Vector3.New(shardPos), self.config.lines.shard_circles, 2, 0, 20)
		end
        self.tShardIds[nId] = false;
	elseif sName == self.L["unit.noxious_ink_pool"] then
		self.core:DrawPolygon("pool".. tostring(nId), tUnit, self.config.lines.pools, 5.2, 0, 20)
		table.insert(self.tpools, {id = nId, timer = 0})
    end
end

function Mod:ExpandCircles()
	for i, v in ipairs(self.tpools) do
		self.tpools[i].timer = self.tpools[i].timer + POOL_CHECK_INTERVALL
		local tUnit = GameLib.GetUnitById(self.tpools[i].id) 
		if tUnit then
			if self.tpools[i].timer % 8 == 0 then
				self.core:DrawPolygon("pool".. tostring(self.tpools[i].id), tUnit, self.config.lines.pools, 5.2 + 2 * (self.tpools[i].timer / 8), 0, 20)
			end
		end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.shard"] then
        self.tShardIds[nId] = nil
        self.core:RemoveLineBetween(nId)
		self.core:RemovePolygon("shardcircle".. tostring(nId))
    end
end

function Mod:CheckShardsTimer()
    local playerPosition = Vector3.New(self.unitPlayer:GetPosition())

    for nId, hasLine in pairs(self.tShardIds) do
        local unit = GameLib.GetUnitById(nId)
        if unit then
            local shardPosition = Vector3.New(unit:GetPosition())
            local horizontalDistance = self:HorizontalDistance(playerPosition, shardPosition)
            local isClose = horizontalDistance < 20
            if shardPosition.y + 5 < playerPosition.y then
                -- Don't draw lines to shards far below than player
                self.core:RemoveLineBetween(nId)
                self.tShardIds[nId] = false
            elseif isClose and shardPosition.y < (playerPosition.y + ROCKET_HEIGHT + 2) then
                -- Draw lines to shards player can reach with rocket boost
                if not hasLine then
                    if shardPosition.y <= ROOM_FLOOR_Y + 40 then
                        local belowShardPos = Vector3.New(shardPosition)
                        belowShardPos.y = belowShardPos.y - 42
                        self.core:DrawLineBetween(nId, shardPosition, belowShardPos, self.config.lines.shards)
                    else
                        self.core:DrawLineBetween(nId, shardPosition, nil, self.config.lines.shards)
                    end
                    self.tShardIds[nId] = true
                end
            else
                -- Don't draw lines to shards the player can't reach
                self.core:RemoveLineBetween(nId)
                self.tShardIds[nId] = false
            end
        else
            self.tShardIds[nId] = nil
        end
    end
end

function Mod:HorizontalDistance(pos1, pos2)
    return (Vector2.New(pos1.x, pos1.z) - Vector2.New(pos2.x, pos2.z)):Length()
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if BUFF_CHAOS_AMPLIFIER == nSpellId then
        self.core:AddTimer("ORBS", self.L["label.next_orbs"], 80, self.config.timers.orbs)
        self.nNextOrbs = GameLib.GetGameTime() + 80
    elseif DEBUFF_CHAOS_TETHER == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_Tether", self.config.auras.chaos_tether, nDuration, self.L["alert.chaos_tether"])
            self.core:ShowAlert("Alert_Tether", self.L["alert.chaos_tether"], self.config.alerts.chaos_tether)
            self.core:PlaySound(self.config.sounds.chaos_tether)
        end
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if BUFF_CHAOS_AMPLIFIER == nSpellId then
        self.core:AddTimer("ORBS", self.L["label.next_orbs"], 85, self.config.timers.orbs)
        self.nNextOrbs = GameLib.GetGameTime() + 85
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName then
        if self.L["cast.hookshot"] == sCastName then
            local nCurrentTime = GameLib.GetGameTime()
            self.nLastHookshot = nCurrentTime
            self.core:AddTimer("HOOKSHOT", self.L["label.next_hookshot"], 30, self.config.timers.hookshot)
            self.core:ShowAlert("Alert_Hookshot", self.L["alert.hookshot"], self.config.alerts.hookshot)
            self.core:PlaySound(self.config.sounds.hookshot)
        elseif self.L["cast.supernova"] == sCastName then
            self.core:RemoveTimer("HOOKSHOT")
            self.core:RemoveTimer("FLAMETHROWER")
            self.core:RemoveTimer("ORBS")
            self.core:AddTimer("SUPERNOVA", self.L["cast.supernova"], tCast.nDuration, self.config.timers.supernova)
        elseif self.L["cast.flamethrower"] == sCastName then
            self.core:AddTimer("FLAMETHROWER", self.L["label.next_flamethrower"], 45, self.config.timers.flamethrower)
            self.core:ShowAlert("Alert_Flamethrower", self.L["alert.flamethrower"], self.config.alerts.flamethrower)
            self.core:PlaySound(self.config.sounds.flamethrower)
            local nCurrentTime = GameLib.GetGameTime()
            self.nLastFlamethrower = nCurrentTime
        end
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName then
        if self.L["cast.supernova"] == sCastName then
            self.core:RemoveTimer("SUPERNOVA")

            self.tShardIds = {}
            if self.tShardTimer then
                self.tShardTimer:Stop()
                self.tShardTimer = nil
            end

            local timeToNextOrbs = self.nNextOrbs - GameLib.GetGameTime()
            if timeToNextOrbs < 10 then
                self.core:AddTimer("ORBS", self.L["label.next_orbs"], 10, self.config.timers.orbs)
            else
                self.core:AddTimer("ORBS", self.L["label.next_orbs"], timeToNextOrbs, self.config.timers.orbs)
            end
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
    self.tShardIds = {}
	self.tpools = {}
    self.unitPlayer = GameLib.GetPlayerUnit()
    self.nNextOrbs = GameLib.GetGameTime() + 48
    self.nLastFlamethrower = GameLib.GetGameTime()
    self.nLastHookshot = GameLib.GetGameTime()

	self.tShardTimer = ApolloTimer.Create(POOL_CHECK_INTERVALL, true, "ExpandCircles", self)


    self.core:AddTimer("HOOKSHOT", self.L["label.next_hookshot"], 10, self.config.timers.hookshot)
    self.core:AddTimer("FLAMETHROWER", self.L["label.next_flamethrower"], 34, self.config.timers.flamethrower)
    self.core:AddTimer("ORBS", self.L["label.next_orbs"], 48, self.config.timers.orbs)
end

function Mod:OnDisable()
    self.run = false
    if self.tPoolTimer then
		self.tPoolTimer:Stop()
		self.tPoolTimer = nil
	end
    if self.tShardTimer then
        self.tShardTimer:Stop()
        self.tShardTimer = nil
    end
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
