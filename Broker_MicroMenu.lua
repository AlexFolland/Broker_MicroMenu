-- Broker_MicroMenu by yess
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local LibQTip = LibStub('LibQTip-1.0')
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_MicroMenu")

local _G, floor, string, GetNetStats, GetFramerate  = _G, floor, string, GetNetStats, GetFramerate
local delay, counter = 1,0
local dataobj, tooltip, db
local color = true
local _
local addonName = Broker_MicroMenuEmbeddedName or "Broker_MicroMenu"
local path = Broker_MicroMenuEmbeddedPath or "Interface\\AddOns\\Broker_MicroMenu\\media\\"

local function Debug(...)
	--@debug@
	local s = addonName.." Debug:"
	for i=1,_G.select("#", ...) do
		local x = _G.select(i, ...)
		s = _G.strjoin(" ",s,_G.tostring(x))
	end
	_G.DEFAULT_CHAT_FRAME:AddMessage(s)
	--@end-debug@
end

local function RGBToHex(r, g, b)
	return ("%02x%02x%02x"):format(r*255, g*255, b*255)
end

local mb = _G.MainMenuMicroButton and _G.MainMenuMicroButton:GetScript("OnMouseUp")
local function mainmenu(self, ...) self.down = 1; mb(self, ...) end

dataobj = ldb:NewDataObject(addonName, {
	type = "data source",
	icon = path.."green.tga",
	label = "MicroMenu",
	text  = "",
	OnClick = function(self, button, ...)
		if button == "RightButton" then
			if _G.IsModifierKeyDown() then
				mainmenu(self, button, ...)
			else
				dataobj:OpenOptions()
			end
		else
			_G.ToggleCharacter("PaperDollFrame")
		end
		LibQTip:Release(tooltip)
		tooltip = nil
	end
})

-------------------------
-- custom libqtip cell
-------------------------
local myProvider, cellPrototype = LibQTip:CreateCellProvider()

function cellPrototype:InitializeCell()
	self.texture = self:CreateTexture()
	self.texture:SetAllPoints(self)
end

function cellPrototype:SetupCell(tooltip, value, justification, font, iconCoords, unitID,guild,atlas)
	local tex = self.texture
	tex:SetWidth(16)
	tex:SetHeight(16)

	if guild then
		_G.SetSmallGuildTabardTextures("player", tex,tex);
	elseif unitID then
		_G.SetPortraitTexture(tex, unitID)
	else
		if atlas then
			tex:SetAtlas(value)
		else
			tex:SetTexture(value)
		end
	end
	if iconCoords then
		tex:SetTexCoord(_G.unpack(iconCoords))
	end
	return tex:GetWidth(), tex:GetHeight()
end

function cellPrototype:ReleaseCell()

end

-------------------------

function dataobj:UpdateText()
	local fps = floor(GetFramerate())
	local _, _, latencyHome, latencyWorld = GetNetStats()

    local colorGood = "|cff00ff00"
	local fpsColor, colorHome, colorWorld = "", "", ""
	if db.enableColoring then
		if fps > 30 then
			fpsColor = colorGood
		elseif fps > 20 then
			fpsColor = "|cffffd200"
		else
			fpsColor = "|cffdd3a00"
		end
		if latencyHome < 300 then
			colorHome = colorGood
		elseif latencyHome < 500 then
			colorHome = "|cffffd200"
		else
			colorHome = "|cffdd3a00"
		end
		if latencyWorld < 300 then
			colorWorld = colorGood
			dataobj.icon = path.."green.tga"
		elseif latencyWorld < 500 then
			colorWorld = "|cffffd200"
			dataobj.icon = path.."yellow.tga"
		else
			colorWorld = "|cffdd3a00"
			dataobj.icon = path.."red.tga"
		end
	end

	if db.customTextSetting then
		local lw_string = colorWorld..latencyWorld.."|r"
		local lh_string = colorHome..latencyHome.."|r"
		local fps_string = fpsColor..fps.."|r"
		local text = string.gsub(string.gsub(string.gsub(db.textOutput, "{fps}", (fps_string or "fps")), "{lw}", (lw_string or "lw")), "{lh}", (lh_string or "lh"))
		dataobj.text = text
	else
		local text = ""
		if db.showWorldLatency then
			text = string.format("%s%i|r %s ", colorWorld, latencyWorld, _G.MILLISECONDS_ABBR)
		end
		if db.showHomeLatency then
			text = string.format("%s%s%i|r %s ", text, colorHome, latencyHome, _G.MILLISECONDS_ABBR)
		end
		if db.showFPS then
			if db.fpsFirst then
				dataobj.text = string.format("%s%i|r %s %s", fpsColor, fps , L["fps"], text)
			else
				dataobj.text = string.format("%s%s%i|r fps", text, fpsColor, fps )
			end
		else
			dataobj.text = text
		end
	end
end

local function MouseHandler(event, func, button, ...)
	local name = func

	if _G.type(func) == "function" then
		func(event, func,button, ...)
	else
		func:GetScript("OnClick")(func,button, ...)
	end

	LibQTip:Release(tooltip)
	tooltip = nil
end

function dataobj:OnEnter()
	if tooltip then
		LibQTip:Release(tooltip)
	end

	tooltip = LibQTip:Acquire(addonName.."Tooltip", 2, "LEFT", "LEFT")
	tooltip:Clear()
	self.tooltip = tooltip

	local y, x = tooltip:AddLine()
	tooltip:SetCell(y, 1, "", myProvider, {0.2, 0.8, 0.2, 0.8},"player")
	local ckey = _G.GetBindingKey("TOGGLECHARACTER0")
	if ckey then
		tooltip:SetCell(y, 2, _G.CHARACTER_BUTTON.."|cffffd200 ("..ckey..")")
	else
		tooltip:SetCell(y, 2, _G.CHARACTER_BUTTON)
	end
	tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, function() _G.ToggleCharacter("PaperDollFrame") end)

	if _G.ProfessionMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, "UI-HUD-MicroMenu-".._G.ProfessionMicroButton.textureName.."-Up", myProvider,nil,nil,nil,true)
		tooltip:SetCell(y, 2, _G.ProfessionMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.ProfessionMicroButton)
	end

	local y, x = tooltip:AddLine()
	if _G.PlayerSpellsMicroButton then
		tooltip:SetCell(y, 1, path.."talents.tga", myProvider)
		tooltip:SetCell(y, 2, _G.PlayerSpellsMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.PlayerSpellsMicroButton)
	else
		tooltip:SetCell(y, 1, path.."spells.tga", myProvider)
		local key = _G.GetBindingKey("TOGGLESPELLBOOK")
		if key then
			tooltip:SetCell(y, 2, _G.SPELLBOOK_ABILITIES_BUTTON.."|cffffd200 ("..key..")")
		else
			tooltip:SetCell(y, 2, _G.SPELLBOOK_ABILITIES_BUTTON)
		end
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, function(self, func, button, ...)

			if _G.InCombatLockdown() then
				if key then
					_G.DEFAULT_CHAT_FRAME:AddMessage("Can't open the Spellbook during combat. Use your hot key: "..key)
				else
					_G.DEFAULT_CHAT_FRAME:AddMessage("Can't open the Spellbook during combat. Set and use a hot key.")
				end
			else
				_G.ToggleSpellBook(_G.BOOKTYPE_SPELL)
			end
		end)
	end

	if _G.TalentMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."talents.tga", myProvider)
		tooltip:SetCell(y, 2, _G.TalentMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, function(self, func, button, ...)
			if _G.InCombatLockdown() then
				key = _G.GetBindingKey("TOGGLETALENTS")
				if key then
					_G.DEFAULT_CHAT_FRAME:AddMessage("Can't open the Talents during combat. Use your hot key: "..key)
				else
					_G.DEFAULT_CHAT_FRAME:AddMessage("Can't open the Talents during combat. Set and use a hot key.")
				end
			else
				_G.LoadAddOn("Blizzard_TalentUI")
				if  _G.PlayerTalentFrame:IsShown() then
					_G.PlayerTalentFrame:Hide()
				else
					_G.tinsert(_G.UISpecialFrames,_G.PlayerTalentFrame:GetName());
					_G.PlayerTalentFrame:Show()
				end
			end
		end)
	end

	if _G.AchievementMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."achivements.tga", myProvider)
		tooltip:SetCell(y, 2, _G.AchievementMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.AchievementMicroButton)
	end

	if _G.QuestLogMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."quest.tga", myProvider)
		tooltip:SetCell(y, 2, _G.QuestLogMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.QuestLogMicroButton)
	end

	if _G.GuildMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, "", myProvider, nil,"player",true)
		tooltip:SetCell(y, 2, _G.GuildMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.GuildMicroButton)
	end

	if _G.LFDMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."lfg.tga", myProvider)
		tooltip:SetCell(y, 2, _G.LFDMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.LFDMicroButton)
	end

	if _G.CollectionsMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."mounts.tga", myProvider)
		local clkey = _G.GetBindingKey("TOGGLECOLLECTIONS")
		if clkey then
			tooltip:SetCell(y, 2, _G.COLLECTIONS.."|cffffd200 ("..clkey..")")
		else
			tooltip:SetCell(y, 2, _G.COLLECTIONS)
		end
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.CollectionsMicroButton)
	end

	if _G.EJMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."journal.tga", myProvider)
		tooltip:SetCell(y, 2, _G.EJMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.EJMicroButton)
	end
	if _G.RaidMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."raid.tga", myProvider)
		tooltip:SetCell(y, 2, _G.RaidMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.RaidMicroButton)
	end

	if _G.StoreMicroButton then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."store.tga", myProvider)
		tooltip:SetCell(y, 2, _G.StoreMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.StoreMicroButton)
	end

	if _G.MainMenuMicroButton and _G.ToggleGameMenu then
		local y, x = tooltip:AddLine()
		tooltip:SetCell(y, 1, path.."green.tga", myProvider)
		tooltip:SetCell(y, 2, _G.MainMenuMicroButton.tooltipText)
		tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, _G.ToggleGameMenu)
	end

	if _G.GameMenuButtonSettings then
		tooltip:AddSeparator(10,0,0,0,0)

		-- Adding Buttons of Main Game Menu
		local GameMenuButtons = {
			_G.GameMenuButtonSettings,
			_G.GameMenuButtonEditMode,
			_G.GameMenuButtonMacros,
			_G.GameMenuButtonAddons,
		}

		for _, MenuButton in pairs(GameMenuButtons) do
			if MenuButton then
				local y, x = tooltip:AddLine()
				tooltip:SetCell(y, 2, MenuButton:GetText())
				tooltip:SetLineScript(y, "OnMouseUp", MouseHandler, function() MenuButton:Click() end)
			end
		end
	end

	tooltip:SetAutoHideDelay(0.01, self)
	tooltip:SmartAnchorTo(self)
	tooltip:Show()
end

function dataobj:SetDB(database)
	db = database
end

local function OnUpdate(self, elapsed)
	counter = counter + elapsed
	if counter >= delay then
		dataobj:UpdateText()
		counter = 0
	end
end

local function OnDragStart(self, elapsed)
	if tooltip then
		LibQTip:Release(tooltip)
	end
end

local frame = CreateFrame("Frame")
local function OnEnterWorld(self)
	dataobj:RegisterOptions()
	frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end


frame:SetScript("OnUpdate", OnUpdate)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnEnterWorld)

