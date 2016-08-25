local Taunty = ...;
local L = Taunty.L;
Taunty = {};
Taunty.L = {};

-- static config params for now
local debug = false;
local raidonly = false;
local grouponly = false;

local f = CreateFrame("Frame", nil, UIParent);

local taunty_varsLoaded = false;
local playerid = UnitGUID("player");
local playername = UnitName("player");
local isParty = UnitInParty(playerid);
local isRaid = UnitInRaid(playerid);
local UnitInBattleground = UnitInBattleground;
local GetZonePVPInfo = GetZonePVPInfo;


function Taunty:OnInitialize()
    print("Taunty watching over you...");
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    f:RegisterEvent("GROUP_ROSTER_UPDATE");
end
Taunty:OnInitialize();

function Taunty:convertIDstoNames(spellIDs)
    local result = {};
    for i, v in ipairs(spellIDs) do
        local spellName = GetSpellInfo(v); -- Could cause error if unknown
        result[spellName] = true;
    end
    return result
end

local tauntSpellIDs = {
    355, -- Taunt (Warrior)
    62124, -- Hand of Reckoning (Paladin)
    6795, -- Growl (Druid)
    56222, -- Dark Command (Death Knight)
    49576, -- Death Grip (Death Knight)
    20736, -- Distracting Shot (Hunter)
    116189, -- Provoke (Monk)
    17735, -- Suffering (Warlock Voidwalker)
    171014, -- Seethe (Warlock Abyssal)
    2649, -- Growl (Hunter Pet)
    36213, -- Angered Earth, AoE effect but not buff
    185245 -- Torment
};
local tauntSpellNames = Taunty:convertIDstoNames(tauntSpellIDs);

local aeotauntSpellIDs = {
    204079 -- Paladin new AoE
};
local aeotauntSpellNames = Taunty:convertIDstoNames(aeotauntSpellIDs);

-- Table for looking up raid icon id from destFlags
local raidIconLookup = {
    [COMBATLOG_OBJECT_RAIDTARGET1] = 1,
    [COMBATLOG_OBJECT_RAIDTARGET2] = 2,
    [COMBATLOG_OBJECT_RAIDTARGET3] = 3,
    [COMBATLOG_OBJECT_RAIDTARGET4] = 4,
    [COMBATLOG_OBJECT_RAIDTARGET5] = 5,
    [COMBATLOG_OBJECT_RAIDTARGET6] = 6,
    [COMBATLOG_OBJECT_RAIDTARGET7] = 7,
    [COMBATLOG_OBJECT_RAIDTARGET8] = 8,
}

local scanTool = CreateFrame("GameTooltip", "ScanTooltip", nil, "GameTooltipTemplate")
scanTool:SetOwner(WorldFrame, "ANCHOR_NONE")
local scanText = _G["ScanTooltipTextLeft2"]-- This is the line with <[Player]'s Pet>

function getPetOwner(petName)
    scanTool:ClearLines()
    scanTool:SetUnit(petName)
    local ownerText = scanText:GetText()
    if not ownerText then return nil end
    local owner, _ = string.split("'", ownerText)
    
    return owner -- This is the pet's owner
end


function Taunty:sendMsg(msg)
    msg = "|cFFFF0000Taunty:|r " .. msg;
    print(msg);
end

function Taunty:eventHandler(event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        Taunty:COMBAT_LOG_EVENT_UNFILTERED(...);
    elseif (event == "GROUP_ROSTER_UPDATE") then
        Taunty:GROUP_ROSTER_UPDATE(...);
    end
end
f:SetScript("OnEvent", Taunty.eventHandler);


function Taunty:GROUP_ROSTER_UPDATE(...)
    -- not used so far..
    isParty = UnitInParty("player");
    isRaid = UnitInRaid("player");
    playerid = UnitGUID("player");
    playername = UnitName("player");
end

function Taunty:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, subevent, _, srcGUID, srcname, srcflags, srcRaidFlags, dstGUID, dstname, dstflags, dstRaidFlags, spellID, spellname, spellschool, misstype, _, _, _, _, _ = ...
    
    if not subevent then
        return
    end
    
    -- Get id of raid icon on target, or nil if none
    local raidIcon = raidIconLookup[bit.band(dstRaidFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)]
    
    local targetid = UnitGUID("target")
    local mytarget = true
    -- Taunt Stuff
    if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname]) then
        
        -- check if pvp and return if true
        if UnitInBattleground('player') or GetZonePVPInfo() == 'arena' then return end
        
        
        if debug then
            Taunty:sendMsg(srcGUID);
            Taunty:sendMsg(srcname);
            Taunty:sendMsg(getPetOwner(srcname));
            Taunty:sendMsg(srcflags);
        end
        
        
        if (srcGUID == playerid) then -- player taunt
            Taunty:sendMsg(("%s %s taunted %s with %s"):format(GetSpecializationRoleByID(GetInspectSpecialization(srcname)), srcname, dstname, GetSpellLink(spellID)));
            PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
        else
            local inScope = false;
            
            -- check if in my raid
            if bit.band(srcflags, COMBATLOG_OBJECT_AFFILIATION_RAID) > 0 then
                inScope = true;
            end
            
            -- check if in my group
            if bit.band(srcflags, COMBATLOG_OBJECT_AFFILIATION_PARTY) > 0 then
                inScope = true;
            end
            
            -- check if is mine
            if bit.band(srcflags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
                inScope = true;
            end
            
            -- not in scope, so we don't want to know
            if not inScope then return end
            
            -- check if it was a pet
            if bit.band(srcflags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then
                local owner = getPetOwner(srcname);
                if owner then
                    srcname = srcname .. " <" .. owner .. ">";
                end
            else
                -- since it's not a pet, it could have a role
                local whatRole = GetSpecializationRoleByID(GetInspectSpecialization(srcname));
                if whatRole then
                    srcname = whatRole .. srcname;
                end
            end
            
            -- prevent error due to Earth Elemental taunt
            if dstname == nil then
                dstname = "UNKNOWN";
            end

            playerid = UnitGUID("player");
            
            if (UnitGUID("targettarget") == playerid) then -- player is the target
                Taunty:sendMsg(("%s ninja-taunted %s with %s"):format(srcname, dstname, GetSpellLink(spellID)));
                PlaySoundFile("Sound\\Doodad\\G_NecropolisWound.ogg", "Master");
            else
                Taunty:sendMsg(("%s taunted %s with %s"):format(srcname, dstname, GetSpellLink(spellID)));
                PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
            end
        --end
        end
    elseif (subevent == "SPELL_AURA_APPLIED") and (aeotauntSpellNames[spellname]) then
        -- check if pvp and return if true
        if UnitInBattleground('player') or GetZonePVPInfo() == 'arena' then return end
        
        Taunty:sendMsg(("%s AoE-taunted %s with %s"):format(srcname, dstname, GetSpellLink(spellID)));
        PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
    elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aeotauntSpellNames[spellname]) then
        -- check if pvp and return if true
        if UnitInBattleground('player') or GetZonePVPInfo() == 'arena' then return end
        
        Taunty:sendMsg(("%s taunt failed on %s with %s. Reason: %s"):format(srcname, dstname, GetSpellLink(spellID), misstype));
        PlaySoundFile("Sound\\Spells\\SimonGame_Visual_GameFailedSmall.ogg", "Master");
    end
    
    -- Death Stuff
    if (subevent == "UNIT_DIED" and UnitIsPlayer(dstname)) then
        local role = GetSpecializationRoleByID(GetInspectSpecialization(dstname));
        if (role == "TANK") then
            Taunty:sendMsg(("Tank %s has died!"):format(dstname));
            PlaySoundFile("Sound\\interface\\igQuestFailed.ogg", "Master");
        elseif (role == "HEALER") then
            Taunty:sendMsg(("Healer %s has died!"):format(dstname));
            PlaySoundFile("Sound\\Event Sounds\\Wisp\\WispPissed1.ogg", "Master")
        end
    end
end
