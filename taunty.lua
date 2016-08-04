local taunty = taunty;
local tauntSpellNames = fillTaunts("355", "62124", "116189"); -- tbd (Warr, Pala, Monk)

function taunty:onInit()
  print("Taunty watching over you...");
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function fillTaunts(spellIDs)
  local result = {};
  for i, v in ipairs(spellIDs) do
    local spellName = GetSpellInfo(v); -- Hier könnte ein Fehler auftreten wenn es die ID nicht gibt
    result[spellName] = true;
  end
end

function addon:COMBAT_LOG_EVENT_UNFILTERED(timestamp, subevent, hideCaster, ...)
  local spellID, spellname, spellschool, 
     extraspellID
  srcGUID, srcname, srcflags, srcRaidFlags,
  dstGUID, dstname, dstflags, dstRaidFlags,
  spellID, spellname, spellschool, 
  extraspellID = ...
  
  if (subevent == "SPELL_CAST_SUCCESS")
    if (tauntSpellNames[spellname])
        print("Player taunted: " .. dstname .. (" with ") .. (spellname or "nil"));
    elseif
      print("Player casted: " .. (spellname or "nil"));
    end
  end
end
