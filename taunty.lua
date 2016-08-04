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
  local unitid = unit.unitid
	local name = unit.name
	if (unitid)
	  if unit.isTank
	    addon:sendMsg(L["Tank %s has died!"]:format(name));
    elseif unit.isHeal
      addon:sendMsg(L["Heal %s has died!"]:format(name));
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
  
  -- Check if target is player
  local is_playerdst = bit.band(dstflags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  
  -- Taunt Stuff
  if (subevent == "SPELL_CAST_SUCCESS") and (tauntSpellNames[spellname])
    print("Player taunted: " .. dstname .. (" with ") .. (spellname or "nil"));
  elseif (subevent == "SPELL_AURA_APPLIED") and (aoetauntSpellNames[spellname])
    print("Player AOE-taunted: " .. dstname .. (" with ") .. (spellname or "nil"));
  elseif (subevent == "SPELL_MISSED") and (tauntSpellNames[spellname] or aoetauntSpellNames[spellname]) 
    local missType = extraspellID
    print(" Player taunt with " .. spellname .. " failed on: " .. dstname .. " - " .. missType); 
  end
  
  -- Death Stuff
  if (subevent == "UNIT_DIED" and is_playerdst)
    addon:SomebodyDied(unit);
end
