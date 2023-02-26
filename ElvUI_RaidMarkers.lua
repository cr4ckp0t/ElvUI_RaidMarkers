-------------------------------------------------------------------------------
-- ElvUI Raid Markers Bar By Crackpotx
-- Contains modifications graciously provided by Dridzt!
-------------------------------------------------------------------------------
local E, _, V, P, G = unpack(ElvUI) --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local RM = E:NewModule("RaidMarkersBar")
local L = E.Libs.ACL:GetLocale("ElvUI_RaidMarkers", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local RegisterStateDriver = _G.RegisterStateDriver
local SetRaidTargetIcon = _G.SetRaidTargetIcon
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnregisterStateDriver = _G.UnregisterStateDriver
local unpack = _G.unpack

local BUTTON_HEIGHT = 18
local BUTTON_WIDTH = 18
local BUTTON_DISTANCE = 5
local MODIFIER_DEFAULT = "shift-"

-- thanks to Mahdiin for the new world marker ids
local buttonMap = {
	[1] = {RT = 1, WM = 5}, -- yellow/star
	[2] = {RT = 2, WM = 6}, -- orange/circle
	[3] = {RT = 3, WM = 3}, -- purple/diamond
	[4] = {RT = 4, WM = 2}, -- green/triangle
	[5] = {RT = 5, WM = 7}, -- white/moon
	[6] = {RT = 6, WM = 1}, -- blue/square
	[7] = {RT = 7, WM = 4}, -- red/cross
	[8] = {RT = 8, WM = 8}, -- white/skull
	[9] = {RT = 0, WM = 0} -- clear target/flare
}

local function Capitalize(str)
	return str:gsub("^%l", string.upper)
end

function RM:ToggleBar()
	if self.db.show then
		self.frame:Show()
	elseif not self.db.show then
		self.frame:Hide()
	end
end

function RM:UpdateMover()
	local scale = self.frame:GetScale()
	self.frame.mover:Size(self.frame:GetWidth() * scale, self.frame:GetHeight() * scale)
end

function RM:UpdateBar(first)
	local height, width

	-- adjust height/width for orientation
	if self.db.orient == "vertical" then
		width = BUTTON_WIDTH + 3
		height = (BUTTON_HEIGHT * 9) + (BUTTON_DISTANCE * 9)
	else
		width = (BUTTON_WIDTH * 9) + (BUTTON_DISTANCE * 9)
		height = BUTTON_HEIGHT + 3
	end

	if first then
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER")
	end

	self.frame:SetScale(self.db.scale or 1.0)
	self.frame:SetWidth(width)
	self.frame:SetHeight(height)

	for i = 9, 1, -1 do
		local button = self.frame.buttons[i]
		local prev = self.frame.buttons[i + 1]
		button:ClearAllPoints()

		-- align the buttons with orientation
		if self.db.orient == "vertical" then
			if i == 9 then
				button:SetPoint("TOP", 0, -3)
			else
				button:SetPoint("TOP", prev, "BOTTOM", 0, -BUTTON_DISTANCE)
			end
		else
			if i == 9 then
				button:SetPoint("LEFT", 3, 0)
			else
				button:SetPoint("LEFT", prev, "RIGHT", BUTTON_DISTANCE, 0)
			end
		end
	end

	if self.db.visible == "hide" then
		UnregisterStateDriver(self.frame, "visibility")
		if self.frame:IsShown() then
			self.frame:Hide()
		end
	elseif self.db.visible == "show" then
		UnregisterStateDriver(self.frame, "visibility")
		if not self.frame:IsShown() then
			self.frame:Show()
		end
	else
		RegisterStateDriver(self.frame, "visibility", self.db.visible == "auto" and "[noexists, nogroup] hide; show" or "[group] show; hide")
	end
end

function RM:ButtonFactory()
	-- create the buttons
	for i, buttonData in ipairs(buttonMap) do
		local button = CreateFrame("Button", ("ElvUI_RaidMarkersBarButton%d"):format(i), _G["ElvUI_RaidMarkersBar"], "SecureActionButtonTemplate, BackdropTemplate")
		button:SetHeight(BUTTON_HEIGHT)
		button:SetWidth(BUTTON_WIDTH)

		local image = button:CreateTexture(nil, "BACKGROUND")
		image:SetAllPoints()
		image:SetTexture(i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(i))

		local target, flare = buttonData.RT, buttonData.WM
		-- target icons
		if target then
			button:SetAttribute("type1", "macro")
			button:SetAttribute("macrotext1", ('/run SetRaidTargetIcon("target", %d)'):format(i < 9 and i or 0))

			-- for the tooltip
			button:SetScript("OnEnter", function(slf)
				slf:SetBackdropBorderColor(.7, .7, 0)
				GameTooltip:SetOwner(slf, "ANCHOR_BOTTOM")
				GameTooltip:SetText(L["ElvUI Raid Markers"])
				GameTooltip:AddLine(i == 9 and L["Click to clear the mark."] or L["Click to mark the target."], 1, 1, 1)
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		-- world markers (flares)
		if flare then
			-- add flares to the macro texts
			local modifier = RM.db.modifier or MODIFIER_DEFAULT
			button:SetAttribute(("%stype1"):format(modifier), "macro")
			button.modifier = modifier
			button:SetAttribute(("%smacrotext1"):format(modifier), flare == 0 and "/cwm 0" or ("/cwm %d\n/wm %d"):format(flare, flare))

			-- more tooltip
			button:SetScript("OnEnter", function(slf)
				slf:SetBackdropBorderColor(.7, .7, 0)
				GameTooltip:SetOwner(slf, "ANCHOR_BOTTOM")
				GameTooltip:SetText(L["ElvUI Raid Markers"])
				GameTooltip:AddLine(i == 9 and (L["Click to clear the mark.\n%sClick to remove all flares."]):format(Capitalize(button.modifier)) or (L["Click to mark the target.\n%sClick to place a flare."]):format(Capitalize(button.modifier)), 1, 1, 1)
				GameTooltip:Show()
			end)

			button:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		button:RegisterForClicks("AnyDown", "AnyUp")
		self.frame.buttons[i] = button
	end
end

function RM:InitBar()
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER")

	local height, width
	-- adjust height/width for orientation
	if self.db.orient == "vertical" then
		width = BUTTON_WIDTH + 3
		height = (BUTTON_HEIGHT * 9) + (BUTTON_DISTANCE * 9)
	else
		width = (BUTTON_WIDTH * 9) + (BUTTON_DISTANCE * 9)
		height = BUTTON_HEIGHT + 3
	end

	self.frame:SetWidth(width)
	self.frame:SetHeight(height)
end

function RM:Initialize()
	self.db = E.db.actionbar.raidmarkersbar

	self.frame = CreateFrame("Frame", "ElvUI_RaidMarkersBar", E.UIParent, "SecureHandlerStateTemplate, BackdropTemplate")
	self.frame:SetResizable(false)
	self.frame:SetClampedToScreen(true)
	self.frame:SetTemplate("Default", true)

	self.frame.buttons = {}
	self:ButtonFactory()

	self:UpdateBar(true)

	-- since we use scale we must auto update the mover
	E:CreateMover(self.frame, "ElvUI_RMBarMover", L["Raid Markers Bar"])
	self:UpdateMover()
end

E:RegisterModule(RM:GetName())

P["actionbar"]["raidmarkersbar"] = {
	["visible"] = "group",
	["modifier"] = "shift-",
	["orient"] = "horizontal",
	["scale"] = 1.0
}

local function InjectOptions()
	if not E.Options.args.Crackpotx then
		E.Options.args.Crackpotx = ACH:Group(L["Plugins by |cff0070deCrackpotx|r"])
	end
	if not E.Options.args.Crackpotx.args.thanks then
		E.Options.args.Crackpotx.args.thanks = ACH:Description(L["Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."], 1)
	end

	E.Options.args.Crackpotx.args.raidmarkersbar = ACH:Group(L["Raid Markers"], nil, nil, nil, function(info) return RM.db[info[#info]] end, function(info, value) RM.db[info[#info]] = value; RM:UpdateBar(); RM:UpdateMover(); end)
	E.Options.args.Crackpotx.args.raidmarkersbar.args.visible = ACH:Select(L["Bar Visibility"], L["Select how the raid markers bar will be displayed."], 1, { ["hide"] = L["Hide"], ["show"] = L["Show"], ["auto"] = L["Auto"], ["group"] = L["Group"] })
	E.Options.args.Crackpotx.args.raidmarkersbar.args.modifier = ACH:Select(L["World Markers Modifier"], L["Choose the button modifier to use the world markers (flares)."], 2, { ["alt-"] = L["Alt"], ["ctrl-"] = L["Control"], ["shift-"] = L["Shift"] })
	E.Options.args.Crackpotx.args.raidmarkersbar.args.orient = ACH:Select(L["Orientation"], L["Choose the orientation of the raid markers bar."], 3, { ["horizontal"] = L["Horizontal"], ["vertical"] = L["Vertical"] })
	E.Options.args.Crackpotx.args.raidmarkersbar.args.scale = ACH:Range(L["Scale"], L["Set the frame scale."], 4, { min = 0.5, max = 5.0, step = 0.1 })
end

EP:RegisterPlugin(..., InjectOptions)
