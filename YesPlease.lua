local addonName, addon = ...

local defaults = {
    autoConfirm = true,
    delay = 0.1,
    minimap = { hide = false },
    autoList = {
        -- Enchant / temporary / poison overwrite
        REPLACE_ENCHANT = true,
        BIND_ENCHANT = true,
        TRADE_REPLACE_ENCHANT = true,
        TRADE_POTENTIAL_BIND_ENCHANT = true,
        ACTION_WILL_BIND_ITEM = true,

        -- Auction House
        BUYOUT_AUCTION = true,
        BUYOUT_AUCTION_EXPENSIVE = false,
        BID_AUCTION = false,
        CANCEL_AUCTION = false,
        PURCHASE_AUCTION_UNIQUE = true,

        -- Group / summon / loot
        PARTY_INVITE = true,
        CONFIRM_SUMMON = true,
        CONFIRM_SUMMON_SCENARIO = true,
        CONFIRM_SUMMON_STARTING_AREA = true,
        CONFIRM_LOOT_DISTRIBUTION = true,
        CONFIRM_LOOT_ROLL = true,

        -- Bind / equip
        AUTOEQUIP_BIND = true,
        EQUIP_BIND = true,
        USE_BIND = true,
        LOOT_BIND = true,
        CONFIRM_BINDER = false,

        -- Other common
        CONFIRM_OVERWRITE_EQUIPMENT_SET = true,
        CONFIRM_DELETE_EQUIPMENT_SET = false,
        CONFIRM_BUY_BANK_SLOT = true,
        CONFIRM_BUY_REAGENTBANK_TAB = true,
        CONFIRM_HIGH_COST_ITEM = false,
        CONFIRM_PURCHASE_TOKEN_ITEM = false,
        CONFIRM_MAIL_ITEM_UNREFUNDABLE = false,
        END_REFUND = false,
        END_BOUND_TRADEABLE = false,
    },
}

local db

local function ClickFirstPopup()
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() then
            local button = _G["StaticPopup" .. i .. "Button1"]
            if button and button:IsEnabled() and button:IsVisible() then
                button:Click()
                return true
            end
        end
    end
    return false
end

local function OnStaticPopupShow(which, text_arg1, text_arg2, data)
    if not db.autoConfirm then return end
    if not which or not db.autoList[which] then return end

    C_Timer.After(db.delay, function()
        local popup = StaticPopup1
        if popup and popup:IsShown() and popup.which == which then
            local button = StaticPopup1Button1
            if button and button:IsEnabled() then
                button:Click()
            end
        end
    end)
end

-- Options frame
local optionsFrame
local function CreateOptionsFrame()
    if optionsFrame then return optionsFrame end

    local f = CreateFrame("Frame", "YesPleaseOptions", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(420, 520)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -5)
    f.title:SetText("YesPlease")

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 1)
    scroll:SetScrollChild(content)

    local y = -8

    -- Master toggle
    local master = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    master:SetPoint("TOPLEFT", 8, y)
    master.text:SetText("Enable auto-confirm")
    master:SetScript("OnClick", function(self)
        db.autoConfirm = self:GetChecked()
    end)
    master:SetChecked(db.autoConfirm)
    y = y - 28

    -- Sorted checkbox list
    local keys = {}
    for k in pairs(db.autoList) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 8, y)
        cb.text:SetText(key)
        cb:SetChecked(db.autoList[key])
        cb:SetScript("OnClick", function(self)
            db.autoList[key] = self:GetChecked()
        end)
        y = y - 24
    end

    content:SetHeight(math.abs(y) + 16)
    optionsFrame = f
    return f
end

local function ToggleOptions()
    local f = CreateOptionsFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

-- Minimap button
local minimapButton
local function CreateMinimapButton()
    if minimapButton then return end

    local btn = CreateFrame("Button", "YesPleaseMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self) self:StartMoving() end)
    btn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Addons\\YesPlease\\icon")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ToggleOptions()
        end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("YesPlease")
        GameTooltip:AddLine("Left-click: Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    minimapButton = btn
end

local function Initialize()
    YesPleaseDB = YesPleaseDB or {}
    db = YesPleaseDB

    for k, v in pairs(defaults) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = CopyTable(v)
            else
                db[k] = v
            end
        end
    end

    -- Merge any new keys from defaults into existing autoList
    for k, v in pairs(defaults.autoList) do
        if db.autoList[k] == nil then
            db.autoList[k] = v
        end
    end

    CreateMinimapButton()
    if db.minimap and db.minimap.hide then
        minimapButton:Hide()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Initialize()
        hooksecurefunc("StaticPopup_Show", OnStaticPopupShow)
        print("|cff00ff00YesPlease|r loaded. Type |cffffff00/yp|r or click the minimap button for settings.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash commands
SLASH_YESPLEASE1 = "/yp"
SLASH_YESPLEASE2 = "/yesplease"
SLASH_YESPLEASE3 = "/yes"

SlashCmdList["YESPLEASE"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "auto" or msg == "auto on" then
        db.autoConfirm = true
        print("|cff00ff00YesPlease|r: Auto-confirm enabled.")
    elseif msg == "auto off" or msg == "noauto" then
        db.autoConfirm = false
        print("|cff00ff00YesPlease|r: Auto-confirm disabled.")
    elseif msg == "list" then
        print("|cff00ff00YesPlease|r auto list:")
        for which, enabled in pairs(db.autoList) do
            print("  " .. which .. ": " .. (enabled and "|cff00ff00on|r" or "|cffff0000off|r"))
        end
    elseif msg == "config" or msg == "options" or msg == "settings" or msg == "" then
        ToggleOptions()
    else
        if ClickFirstPopup() then
            -- silent success on bare /yes or /yp when a popup exists
        else
            print("|cff00ff00YesPlease|r commands:")
            print("  /yp           - Open settings")
            print("  /yp auto      - Enable auto-confirm")
            print("  /yp auto off  - Disable auto-confirm")
            print("  /yp list      - Print current list")
            print("  /yes          - Click the first confirmation button")
        end
    end
end
