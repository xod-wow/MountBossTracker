--[[----------------------------------------------------------------------------

  MountBossTracker

  Simple databroker tooltip to see which bosses that drop mounts you've
  already killed this week.

  Copyright 2017-2020 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local MBT = CreateFrame("Frame", "MBT", UIParent)

MBT.CurrentTooltipLines = { }

MBT.BossTable = {
    {   header = "Burning Crusade", },

    {
        name = "Anzu",
        instance = "Auchindoun: Sethekk Halls",
        encounter = 3,
        mountids = { 185, },
    },
    {
        name = "Attumen the Huntsman",
        instance = "Karazhan",
        encounter = 1,
        mountids = { 168, },
    },

    {   header = "Wrath of the Lich King", },

    {
        name = "Archavon",
        instance = "Vault of Archavon",
        encounter = 1,
        mountids = { 287, },
    },
    {
        name = "Yogg-Saron",
        instance = "Ulduar",
        encounter = 16,
        mountids = { 304, },
    },
    {
        name = "The Lich King",
        instance = "Icecrown Citadel",
        encounter = 12,
        mountids = { 363, },
    },
    {
        name = "Onyxia",
        instance = "Onyxia's Lair",
        encounter = 1,
        mountids = { 349, },
    },

    {   header = "Cataclysm", },

    {
        name = "Alysrazor",
        instance = "Firelands",
        encounter = 4,
        mountids = { 425, },
    },
    {
        name = "Ragnaros",
        instance = "Firelands",
        encounter = 7,
        mountids = { 415, },
    },
    {
        name = "Ultraxion",
        instance = "Dragon Soul",
        encounter = 5,
        mountids = { 445, },
    },
    {
        name = "Deathwing",
        instance = "Dragon Soul",
        encounter = 8,
        mountids = { 442, 444, },
    },
    {
        name = "Al'Akir",
        instance = "Throne of the Four Winds",
        encounter = 2,
        mountids = { 396, },
    },
    {
        name = "Bloodlord Mandokir",
        instance = "Zul'Gurub",
        encounter = 2,
        mountids = { 410, },
    },
    {
        name = "High Priestess Kilnara",
        instance = "Zul'Gurub",
        encounter = 4,
        mountids = { 411, },
    },

    {   header = "Mists of Pandaria", },

    {
        name = "Elegon",
        instance = "Mogu'shan Vaults",
        encounter = 5,
        mountids = { 478, },
    },
    {
        name = "Horridon",
        instance = "Throne of Thunder",
        encounter = 2,
        mountids = { 531, },
    },
    {
        name = "Ji-Kun",
        instance = "Throne of Thunder",
        encounter = 6,
        mountids = { 543, },
    },
    {
        name = "Sha of Anger",
        mountids = { 473, },
    },
    {
        name = "Galleon",
        mountids = { 515, },
    },
    {
        name = "Nalak",
        mountids = { 542, },
    },
    {
        name = "Oondasta",
        mountids = { 533, },
    },
    {
        name = "Garrosh Hellscream",
        instance = "Siege of Orgrimmar",
        encounter = 14,
        mountids = { 559, },
    },

    {   header = "Warlords of Draenor", },

    {
        name = "Garrison Invasion - Gold",
        mountids = { 616, 626, 642, 649, },
    },
    {
        name = "Blackhand",
        instance = "Blackrock Foundry",
        encounter = 10,
        mountids = { 613, },
    },
    {
        name = "Archimonde",
        instance = "Hellfire Citadel",
        encounter = 13,
        mountids = { 751, },
    },
    {
        name = "Rukhmar",
        mountids = { 634, },
    },

    {   header = "Legion", },

    {
        name = "Attumen the Huntsman",
        instance = "Return to Karazhan",
        encounter = 5,
        mountids = { 875 },
    },
    {
        name = "Gul'dan",
        instance = "The Nighthold",
        encounter = 10,
        mountids = { 633, 791, },
    },
    {
        name = "Argus the Unmaker",
        instance = "Antorus, the Burning Throne",
        encounter = 11,
        mountids = { 954, },
    },

    {   header = "Battle for Azeroth", },

    {
        name = "Harlan Sweete",
        instance = "Freehold",
        encounter = 4,
        mountids = { 995, },
    },
    {
        name = "Unbound Abomination",
        instance = "The Underrot",
        encounter = 4,
        mountids = { 1053, },
    },
    {
        name = "HK-8 Aerial Oppression Unit",
        instance = "Operation: Mechagon",
        encounter = 4,
        mountids = { 1252, },
    },
    {
        name = "Dazar, The First King",
        instance = "Kings' Rest",
        encounter = 4,
        mountids = { 1040, },
    },
    {
        name = "N'Zoth the Corruptor",
        instance = "Ny'alotha, the Waking City",
        encounter = 12,
        mountids = { 1293, },
    },
}

-- Missing at least one of the argument mountIDs
function MBT:MissingMounts(...)
    local id
    for i = 1, select('#', ...) do
        id = select(i, ...)
        if false == select(11, C_MountJournal.GetMountInfoByID(id)) then
            return true
        end
    end
    return false
end

function MBT:OnEvent(e, arg1, arg2)
    if e == "UPDATE_INSTANCE_INFO" then
        self:Update()
    else
        RequestRaidInfo()
    end
end

-- Terribly inefficient but who cares
function MBT:IsBossDead(b)
    if b.instance then
        for i = 1, GetNumSavedInstances() do
            local name, id, reset, diff, locked = GetSavedInstanceInfo(i)
            if locked and name == b.instance then
                -- print(GetSavedInstanceInfo(i))
                -- print(GetSavedInstanceEncounterInfo(i, b.encounter))
                return select(3, GetSavedInstanceEncounterInfo(i, b.encounter))
            end
        end
    else
        for i = 1, GetNumSavedWorldBosses() do
            if GetSavedWorldBossInfo(i) == b.name then
                return true
            end
        end
    end
    return false
end

function MBT:Update()
    wipe(MBT.CurrentTooltipLines)

    for _,b in ipairs(MBT.BossTable) do
        if b.header then
            if #MBT.CurrentTooltipLines > 0 then
                tinsert(MBT.CurrentTooltipLines, '')
            end
            tinsert(MBT.CurrentTooltipLines, b.header)
        elseif b.mountids and MBT:MissingMounts(unpack(b.mountids)) == false then
            -- skip
        elseif MBT:IsBossDead(b) then
            tinsert(MBT.CurrentTooltipLines, format("  |cffff0000%s|r", b.name))
        else
            tinsert(MBT.CurrentTooltipLines, format("  |cff00ff00%s|r", b.name))
        end
    end
end

function MBT:SetupTooltip(toolTip)
    for _,line in ipairs(MBT.CurrentTooltipLines) do
        toolTip:AddLine(line)
    end
end

function MBT:FindEncounter(pattern)
    local name, description, id, _, link
    local i = 1
    local fails = 0
    while true do
        local name, description, id, _, link = EJ_GetEncounterInfo(i)
        i = i + 1
        if not name then
            fails = fails + 1
            if fails >= 1000 then break end
        else
            fails = 0
            if string.find(name:lower(), pattern:lower()) then
                print(format("Encounter %d = %s (%s)", id, name, link))
            end
        end
    end
end

function MBT:FindInstance(pattern)
    local name, description, mapID, link
    local i  = 1
    local fails = 0
    local j, bossID
    while true do
        local name, description, _, _, _, _, _, link = EJ_GetInstanceInfo(i)
        if not name then
            fails = fails + 1
            if fails >= 1000 then break end
        else
            fails = 0
            if string.find(name:lower(), pattern:lower()) then
                print(format("Instance %d = %s (%s)", i, name, link))
                j = 1
                while true do
                    name, _, bossID = EJ_GetEncounterInfoByIndex(j, i)
                    if not name then break end
                    print(format("  %d = %s (%s)", j, name, bossID))
                    j = j + 1
                end
            end
        end
        i = i + 1
    end
end

function MBT:FindTier(pattern)
    local name, link
    for i = 1, EJ_GetCurrentTier() do
        name, link = EJ_GetTierInfo(i)
        if string.find(name:lower(), pattern:lower()) then
            print(format("Tier %d = %s (%s)", i, name, link))
        end
    end
end

function MBT:FindMount(pattern)
    local name
    for _,id in ipairs(C_MountJournal.GetMountIDs()) do
        name = C_MountJournal.GetMountInfoByID(id)
        if string.find(name:lower(), pattern:lower()) then
            print(format("Mount %d = %s", id, name))
        end
    end
end

local LDB = LibStub("LibDataBroker-1.1", true)

MBT.broker = LDB:NewDataObject("MountBossTracker", {
                type = "data source",
                text = "MBT",
                label = "MBT",
                tocname = "MountBossTracker",
                        --"launcher",
                icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8.png",
                OnTooltipShow = function(ttFrame)
                    MBT:SetupTooltip(ttFrame)
                end,
        })

MBT:RegisterEvent("UPDATE_INSTANCE_INFO")
MBT:RegisterEvent("PLAYER_REGEN_ENABLED")
MBT:SetScript("OnEvent", function (self, ...) self:OnEvent(...) end)

SLASH_MBT1 = "/mbt"
SlashCmdList["MBT"] = function (val)
    LoadAddOn("Blizzard_EncounterJournal")
    MBT:FindInstance(val)
    MBT:FindEncounter(val)
    MBT:FindMount(val)
end
