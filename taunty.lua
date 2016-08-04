local taunty = taunty;

function taunty:onInit()
  print("Taunty watching over you...");
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end


function addon:COMBAT_LOG_EVENT_UNFILTERED(timestamp, subevent, hideCaster, ...)
  local spellID, spellname, spellschool, 
     extraspellID
  srcGUID, srcname, srcflags, srcRaidFlags,
  dstGUID, dstname, dstflags, dstRaidFlags,
  spellID, spellname, spellschool, 
  extraspellID = ...
  
  if (subevent == "SPELL_CAST_SUCCESS")
    print("Player casted: " .. (spellname or "nil"));
  end
end
