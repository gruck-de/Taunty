local taunty = taunty;

function taunty:onInit()
  print("Taunty watching over you...");
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end
