local Taunty = ...;
local L = Taunty.L;
Taunty = {};
Taunty.L = {};


-- local aeotauntSpellNames = convertIDstoNames("12345"); -- AoE Taunt Spells 
-- local raid = raid;
local f = CreateFrame("Frame",nil,UIParent);


function Taunty:OnInitialize()
  print("Taunty watching over you...");
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end
Taunty:OnInitialize();

function Taunty:convertIDstoNames(spellIDs)
  local result = {};
  for i, v in ipairs(spellIDs) do
    local spellName = GetSpellInfo(v); -- Hier könnte ein Fehler auftreten wenn es die ID nicht gibt
	print(spellName .. " wurde eingetragen");
    result[spellName] = true;
  end
  return result
end
local tauntSpellIDs = {355, 62124, 116189}; -- tbd (Warr, Pala, Monk)
local tauntSpellNames = Taunty:convertIDstoNames(tauntSpellIDs); 

function Taunty:sendMsg(msg)
  msg = "Taunty: " .. msg;
  print(msg);
end

function Taunty:SomebodyDied(unit)
  local unitid = unit.unitid;
  local name = unit.name;
  if (unitid) then
  	if unit.isTank then
  	   Taunty:sendMsg(L["Tank %s has died!"]:format(name));
  	   PlaySoundFile("Sound\\interface\\igQuestFailed.ogg", "Master");
        elseif unit.isHeal then
           Taunty:sendMsg(L["Heal %s has died!"]:format(name));
           PlaySoundFile("Sound\\Event Sounds\\Wisp\\WispPissed1.ogg", "Master");
        end
   end
end

function Taunty:eventHandler(event, ...)
  --print("event:" .. event);
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
  
  --print("Subevent: " .. subevent);
  --Check if target is player
  --local is_playerdst = band(dstflags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0;
  --print("player: " .. is_playerdst);
  --print("SpellID: " .. spellID);
  --print("Spellname: " .. spellname);
  
 
  -- Taunt Stuff
  if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname]) then
	print("ICH WAR HIER");
    Taunty:sendMsg(("%s taunted %s with %s"):format(srcname, dstname, spellname));
    PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
--  elseif (subevent == "SPELL_AURA_APPLIED") and (aoetauntSpellNames[spellname]) then
--    Taunty:sendMsg(L["%s AoE-taunted %s with %s"]:format(srcname, dstname, spellname));
  elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aoetauntSpellNames[spellname]) then   
    Taunty:sendMsg(L["%s taunt failed on %s with %s. Reason: %s"]:format(srcname, dstname, spellname, misstype));
  end
  
  -- Death Stuff
  if (subevent == "UNIT_DIED" and is_playerdst) then
    Taunty:SomebodyDied(unit);
  end
end
print("end of file");
