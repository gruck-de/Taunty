local Taunty = ...;
local L = Taunty.L;
Taunty = {};
Taunty.L = {};

local f = CreateFrame("Frame",nil,UIParent);

local playerid = UnitGUID("player");
local playername = UnitName("player");


function Taunty:OnInitialize()
  print("Taunty watching over you...");
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end
Taunty:OnInitialize();

function Taunty:convertIDstoNames(spellIDs)
  local result = {};
  for i, v in ipairs(spellIDs) do
    local spellName = GetSpellInfo(v); -- Hier könnte ein Fehler auftreten wenn es die ID nicht gibt
	-- print(spellName .. " wurde eingetragen");
    result[spellName] = true;
  end
  return result
end
-- local tauntSpellIDs = {355, 62124, 116189}; -- tbd (Warr, Pala, Monk)
local tauntSpellIDs = {
  355,   -- Taunt (Warrior)
  62124, -- Hand of Reckoning (Paladin)
  6795,  -- Growl (Druid)
  56222, -- Dark Command (Death Knight)
  49576, -- Death Grip (Death Knight)  
  20736, -- Distracting Shot (Hunter)  
  116189, -- Provoke (Monk)
  17735, -- Suffering (Warlock Voidwalker)
  171014, -- Seethe (Warlock Abyssal)
  2649  -- Growl (Hunter Pet)
}
local tauntSpellNames = Taunty:convertIDstoNames(tauntSpellIDs); 

local aeotauntSpellIDs = {204079}; -- AoE Taunt Spells 
local aeotauntSpellNames = Taunty:convertIDstoNames(aeotauntSpellIDs); 

function Taunty:sendMsg(msg)
  msg = "Taunty: " .. msg;
  print(msg);
end

function Taunty:eventHandler(event, ...)  
  if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
    Taunty:COMBAT_LOG_EVENT_UNFILTERED(...);
  end
end
f:SetScript("OnEvent", Taunty.eventHandler);


function Taunty:COMBAT_LOG_EVENT_UNFILTERED(...) 
  local _,subevent,_,srcGUID,srcname,srcflags,srcRaidFlags,dstGUID,dstname,dstflags,dstRaidFlags,spellID,spellname,spellschool,misstype,_,_,_,_,_ = ...
  
  if not subevent then
		return
	end
 
  -- Taunt Stuff 
  if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname]) then
	if (srcGUID == playerid) then -- selber gespottet
      Taunty:sendMsg(("%s %s taunted %s with %s"):format(GetSpecializationRoleByID(GetInspectSpecialization(srcname)), srcname, dstname, GetSpellLink(spellID)));
	  PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");	  
	else
	  if (UnitGUID("targettarget") == playerid) then -- hat mich im Ziel
		Taunty:sendMsg(("%s %s ninja-taunted %s with %s"):format(GetSpecializationRoleByID(GetInspectSpecialization(srcname)), srcname, dstname, GetSpellLink(spellID)));
	    PlaySoundFile("Sound\\Doodad\\G_NecropolisWound.ogg", "Master");
	  else 
	    Taunty:sendMsg(("%s %s taunted %s with %s"):format(GetSpecializationRoleByID(GetInspectSpecialization(srcname)), srcname, dstname, GetSpellLink(spellID)));
	    PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
	  end
	end
  elseif (subevent == "SPELL_AURA_APPLIED") and (aeotauntSpellNames[spellname]) then
    Taunty:sendMsg(("%s AoE-taunted %s with %s"):format(srcname, dstname, GetSpellLink(spellID)));
	PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
  elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aoetauntSpellNames[spellname]) then   
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

