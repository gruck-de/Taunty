local addon = Taunty;
local tauntSpellNames = getSpells("355", "62124", "116189"); -- tbd (Warr, Pala, Monk)
-- local aeotauntSpellNames = getSpells("12345"); -- AoE Taunt Spells 
local raid = raid;

function addon:onInit()
  print("Taunty watching over you...");
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end
addon:onInit();

function getSpells(spellIDs)
  local result = {};
  for i, v in ipairs(spellIDs) do
    local spellName = GetSpellInfo(v); -- Hier könnte ein Fehler auftreten wenn es die ID nicht gibt
    result[spellName] = true;
  end
end

function addon:sendMsg(msg)
  msg = "Taunty: " .. msg;
  addon:print(msg);
end

function addon:SomebodyDied(unit)
  local unitid = unit.unitid;
  local name = unit.name;
  if (unitid) then
  	if unit.isTank then
  	   addon:sendMsg(L["Tank %s has died!"]:format(name));
  	   PlaySoundFile("Sound\\interface\\igQuestFailed.ogg", "Master");
        elseif unit.isHeal then
           addon:sendMsg(L["Heal %s has died!"]:format(name));
           PlaySoundFile("Sound\\Event Sounds\\Wisp\\WispPissed1.ogg", "Master");
        end
   end
end

function addon:COMBAT_LOG_EVENT_UNFILTERED(timestamp, subevent, hideCaster, ...)
  local spellID, spellname, spellschool, 
     extraspellID
  srcGUID, srcname, srcflags, srcRaidFlags,
  dstGUID, dstname, dstflags, dstRaidFlags,
  spellID, spellname, spellschool, 
  extraspellID = ...
  
  if not subevent then
		return
	end
  
  -- Check if target is player
  local is_playerdst = bit.band(dstflags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0;
  
  -- Taunt Stuff
  if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname]) then
    addon:sendMsg(L["%s taunted %s with %s"]:format(srcname, dstname, spellname));
    PlaySoundFile("Sound\\interface\\PickUp\\PickUpMetalSmall.ogg", "Master");
  elseif (subevent == "SPELL_AURA_APPLIED") and (aoetauntSpellNames[spellname]) then
    addon:sendMsg(L["%s AoE-taunted %s with %s"]:format(srcname, dstname, spellname));
  elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aoetauntSpellNames[spellname]) then
    local missType = extraspellID;
    addon:sendMsg(L["%s taunt failed on %s with %s. Reason: %s"]:format(srcname, dstname, spellname, missType));
  end
  
  -- Death Stuff
  if (subevent == "UNIT_DIED" and is_playerdst) then
    addon:SomebodyDied(unit);
  end
end
