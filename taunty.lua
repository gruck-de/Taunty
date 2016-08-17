local Taunty = ...;
local L = Taunty.L;
Taunty = {};
Taunty.L = {};

local f = CreateFrame("Frame", nil, UIParent);

local taunty_varsLoaded = false;
local playerid = UnitGUID("player");
local playername = UnitName("player");
local isParty = UnitInParty(playerid);
local isRaid = UnitInRaid(playerid);


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
    
    local targetid = UnitGUID("target")
    local mytarget = true
    --if dstGUID ~= targetid then
    --if band(dstflags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then
    --return  -- the destination is not a creature
    --end
    --mytarget = false
    --end
    -- Taunt Stuff
    if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname]) then
        if (srcGUID == playerid) then -- player taunt
            Taunty:sendMsg(("%s %s taunted %s with %s"):format(GetSpecializationRoleByID(GetInspectSpecialization(srcname)), srcname, dstname, GetSpellLink(spellID)));
            PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
        else
            local whatRole = GetSpecializationRoleByID(GetInspectSpecialization(srcname));
            -- in case we don't know the role
            if whatRole == nil then
                whatRole = "";
            end
            
            -- prevent error due to Earth Elemental taunt
            if dstname == nil then
                dstname = "UNKNOWN";
            end
            playerid = UnitGUID("player");
            
            if (UnitGUID("targettarget") == playerid) then -- player is the target
                Taunty:sendMsg(("%s %s ninja-taunted %s with %s"):format(whatRole, srcname, dstname, GetSpellLink(spellID)));
                PlaySoundFile("Sound\\Doodad\\G_NecropolisWound.ogg", "Master");
            else
                Taunty:sendMsg(("%s %s taunted %s with %s"):format(whatRole, srcname, dstname, GetSpellLink(spellID)));
                PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
            end
        end
    elseif (subevent == "SPELL_AURA_APPLIED") and (aeotauntSpellNames[spellname]) then
        Taunty:sendMsg(("%s AoE-taunted %s with %s"):format(srcname, dstname, GetSpellLink(spellID)));
        PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
    elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aeotauntSpellNames[spellname]) then
        Taunty:sendMsg(("%s taunt failed on %s with %s. Reason: %s"):format(srcname, dstname, GetSpellLink(spellID), misstype));
        PlaySoundFile("Sound\\Spells\\SimonGame_Visual_GameFailedSmall.ogg", "Master")
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
