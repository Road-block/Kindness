local addonName, addon = ...
KindnessDB = KindnessDB or {emote="EMOTE0_TOKEN"}
local EMOTE_FONT_COLOR = CreateColor(1.0,0.5,0.25)
addon.shortlabel = EMOTE_FONT_COLOR:WrapTextInColorCode("Kind")
local f = CreateFrame("Frame")
f.OnEvent = function(self,event,...)
  return addon[event] and addon[event](addon,...)
end
f:SetScript("OnEvent",f.OnEvent)
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("ADDON_LOADED")
local CombatLog_Object_IsA = _G.CombatLog_Object_IsA
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local GetTime = _G.GetTime
local DoEmote = _G.DoEmote
local fastrandom = _G.fastrandom
local COMBATLOG_FILTER_OUTSIDE_FRIEND = bit.bor(
  COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
  COMBATLOG_OBJECT_REACTION_FRIENDLY,
  COMBATLOG_OBJECT_CONTROL_PLAYER,
  COMBATLOG_OBJECT_TYPE_PLAYER
)
local COMBATLOG_FILTER_FRIEND = bit.bor(
  COMBATLOG_OBJECT_REACTION_FRIENDLY,
  COMBATLOG_OBJECT_CONTROL_PLAYER,
  COMBATLOG_OBJECT_TYPE_PLAYER
)
local COMBATLOG_FILTER_ME = _G.COMBATLOG_FILTER_ME
local THANKS_CD = 30
local subEvents = {
  ["SPELL_HEAL"] = true,
  ["SPELL_PERIODIC_HEAL"] = true,
  ["SPELL_ENERGIZE"] = true,
  ["SPELL_AURA_APPLIED"] = true,
  ["SPELL_AURA_APPLIED_DOSE"] = true,
  ["SPELL_DISPEL"] = true,
  ["SPELL_RESURRECT"] = true,
}
local RAISE_ALLY, RAISE_ALLY_BUFF = 61999, 46619
local spells = {
  [RAISE_ALLY] = true, -- "Raise Ally"
  [RAISE_ALLY_BUFF] = true, -- "Raise Ally" self-buff gives control of Risen Ally
}
local rngEMOTES = {
  EMOTE2_TOKEN, --"AMAZE"
  EMOTE5_TOKEN, --"APPLAUD"
  EMOTE12_TOKEN, --"BLUSH"
  EMOTE17_TOKEN, --"BOW"
  EMOTE21_TOKEN, --"CHEER"
  EMOTE24_TOKEN, --"CLAP"
  EMOTE34_TOKEN, --"CURTSEY"
  EMOTE54_TOKEN, --"HAIL"
  EMOTE55_TOKEN, --"HAPPY"
  EMOTE57_TOKEN, --"HUG"
  EMOTE79_TOKEN, --"SALUTE"
  EMOTE98_TOKEN, --"THANK"
  EMOTE123_TOKEN, --"PRAISE"
  EMOTE126_TOKEN, --"RAISE"
  EMOTE145_TOKEN, --"SMILE"
  EMOTE380_TOKEN, --"HIGHFIVE"
  EMOTE413_TOKEN, --"PROUD"
}
local rngEMOTES2 = {
  EMOTE9_TOKEN, -- "BITE"
  EMOTE13_TOKEN, -- "BONK"
  EMOTE30_TOKEN, -- "CRACK"
  EMOTE37_TOKEN, -- "DROOL"
  EMOTE47_TOKEN, -- "GLARE"
  EMOTE58_TOKEN, -- "HUNGRY"
  EMOTE65_TOKEN, -- "MOON"
  EMOTE99_TOKEN, -- "THREATEN"
  EMOTE131_TOKEN, -- "SLAP"
  EMOTE146_TOKEN, -- "RASP"
  EMOTE147_TOKEN, -- "GROWL"
  EMOTE161_TOKEN, -- "ATTACKMYTARGET"
  EMOTE368_TOKEN, -- "BLAME"
  EMOTE398_TOKEN, -- "HISS"
  EMOTE428_TOKEN, -- "SHAKEFIST"
  EMOTE434_TOKEN, -- "SMACK"
}
local numEmotes = #rngEMOTES
local numEmote2 = #rngEMOTES2
local emote_cache = {}
local throttle = {}
do
  for i=1, 522 do
    local emoteToken = format("EMOTE%d_TOKEN",i)
    local emote = _G[emoteToken]
    if emote then
      emote_cache[emote:lower()] = emoteToken
    end
  end
end
function addon:Print(msg)
  local chatFrame = (SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME)
  chatFrame:AddMessage(format("%s: %s",self.shortlabel,msg))
end
function addon:DoEmote(destName, set)
  local emote = KindnessDB.emote
  if emote == "EMOTE0_TOKEN" then
    if set and set == 2 then
      emote = rngEMOTES2[fastrandom(numEmote2)]
    else
      emote = rngEMOTES[fastrandom(numEmotes)]
    end
  end
  DoEmote(emote,destName)
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(...)
  local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24  = CombatLogGetCurrentEventInfo()
  if not (subEvents[subevent]) then return end
  if not sourceFlags and destFlags then return end
  local is_me = CombatLog_Object_IsA(destFlags,COMBATLOG_FILTER_ME)
  if not is_me then return end
  local outside_friend = CombatLog_Object_IsA(sourceFlags,COMBATLOG_FILTER_OUTSIDE_FRIEND)
  if (subevent ~= "SPELL_RESURRECT" and not outside_friend) then return end
  local now = GetTime()
  local set
  if not throttle[sourceName] or (now - throttle[sourceName]) >= THANKS_CD then
    local shouldThank = nil
    if subevent == "SPELL_RESURRECT" then
      self._resOfferer = sourceName
      f:RegisterEvent("PLAYER_ALIVE")
      f:RegisterEvent("PLAYER_UNGHOST")
      return
    elseif (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_APPLIED_DOSE") then
      local auraType = arg15
      if auraType == "BUFF" then
        shouldThank = sourceName
      elseif auraType == "DEBUFF" then
        shouldThank = sourceName
        set = 2
      end
    elseif subevent == "SPELL_DISPEL" then
      local auraType = arg18
      if auraType == "DEBUFF" then
        shouldThank = sourceName
      elseif auraType == "BUFF" then
        shouldThank = sourceName
        set = 2
      end
    else
      shouldThank = sourceName
    end
    if shouldThank then
      addon:DoEmote(shouldThank,set)
      throttle[shouldThank] = now
    end
  end
end
function addon:PLAYER_ALIVE(...)
  f:UnregisterEvent("PLAYER_ALIVE")
  f:UnregisterEvent("PLAYER_UNGHOST")
  if addon._resOfferer then
    local shouldThank = addon._resOfferer
    addon:DoEmote(shouldThank)
    throttle[shouldThank] = GetTime()
  end
  addon._resOfferer = nil
end
addon.PLAYER_UNGHOST = addon.PLAYER_ALIVE
function addon:ADDON_LOADED(...)
  if ... == addonName then

  end
end
local addon_upper, addon_lower = addonName:upper(), addonName:lower()
SlashCmdList[addon_upper] = function(msg)
  local option = {}
  msg = (msg or ""):trim()
  msg = msg:lower()
  for token in msg:gmatch("(%S+)") do
    tinsert(option,token)
  end
  if not msg or msg == "" or msg == "?" then
    addon:Print("/kind <emote||random>")
    addon:Print("    set the reaction emote")
    addon:Print("    eg. /kind thank or /kind random")
    addon:Print("current: "..(KindnessDB.emote == "EMOTE0_TOKEN" and "random" or KindnessDB.emote))
    return
  end
  local cmd = option[1]
  if cmd=="random" or cmd=="rng" then
    KindnessDB.emote = "EMOTE0_TOKEN"
    addon:Print("Will now react with a random emote")
    return
  end
  local emote_token = emote_cache[cmd]
  if emote_token then
    KindnessDB.emote = _G[emote_token]
    addon:Print(format("Will now react with %q",_G[emote_token]))
  else
    addon:Print(format("%q is not a recognized Emote",cmd))
  end
end
_G["SLASH_"..addon_upper.."1"] = "/"..addon_lower
_G["SLASH_"..addon_upper.."2"] = "/kind"
--_G[addonName] = addon
