-- Inicjalizacja zmiennych zapisanych
Todo_Settings = Todo_Settings or {}
Todo_Settings.MainCharacter = Todo_Settings.MainCharacter or nil
Todo_Settings.AutoShow = Todo_Settings.AutoShow or true
Todo_Settings.ShowAltsList = Todo_Settings.ShowAltsList or {}

-- Funkcja zapisująca ustawienia
local function SaveSettings()
    Todo_Settings.MainCharacter = Todo_Settings.MainCharacter
    Todo_Settings.AutoShow = Todo_Settings.AutoShow
    Todo_Settings.ShowAltsList = Todo_Settings.ShowAltsList
end

-- Tworzenie głównej ramki ustawień
local settingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(300, 400)
settingsFrame:SetPoint("CENTER")
settingsFrame:Hide() -- Domyślnie ukryte

-- Tytuł ramki ustawień
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
settingsFrame.title:SetFontObject("GameFontHighlight")
settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 5, 0)
settingsFrame.title:SetText("ToDo Checklist Settings")

-- Opcja wyboru głównej postaci
local mainCharacterDropdown = CreateFrame("Frame", "MainCharacterDropdown", settingsFrame, "UIDropDownMenuTemplate")
mainCharacterDropdown:SetPoint("TOPLEFT", 20, -40)
UIDropDownMenu_SetWidth(mainCharacterDropdown, 180)

local function InitializeMainCharacterDropdown()
    local info = UIDropDownMenu_CreateInfo()
    for characterName in pairs(Todo_CharacterData) do
        info.text = characterName
        info.func = function()
            UIDropDownMenu_SetSelectedName(mainCharacterDropdown, characterName)
            Todo_Settings.MainCharacter = characterName
            SaveSettings()
        end
        UIDropDownMenu_AddButton(info)
    end

    -- Ustaw aktualnie wybraną główną postać
    if Todo_Settings.MainCharacter then
        UIDropDownMenu_SetSelectedName(mainCharacterDropdown, Todo_Settings.MainCharacter)
    else
        UIDropDownMenu_SetText(mainCharacterDropdown, "Select Main Character")
    end
end

UIDropDownMenu_Initialize(mainCharacterDropdown, InitializeMainCharacterDropdown)

-- Przycisk do zapisania głównej postaci
local saveMainButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
saveMainButton:SetPoint("TOPLEFT", mainCharacterDropdown, "BOTTOMLEFT", 0, -10)
saveMainButton:SetSize(180, 25)
saveMainButton:SetText("Save Main Character")
saveMainButton:SetScript("OnClick", function()
    local selectedCharacter = UIDropDownMenu_GetSelectedName(mainCharacterDropdown)
    if selectedCharacter and Todo_CharacterData[selectedCharacter] then
        Todo_Settings.MainCharacter = selectedCharacter
        print("Main character set to: " .. selectedCharacter)
        SaveSettings()
    else
        print("Please select a valid main character.")
    end
end)

local checkbox_settings = {
    {
        settingText = "Show Checklist on login",
        settingKey = "enableChecklist",
        settingTooltip = "While enabled, your To-Do Checklist will auto-show on login",
    },
    {
        settingText = "Track World Boss",
        settingKey = "enableWorldBoss",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've killed World Boss",
    },
    {
        settingText = "Track Weekly Spark Quest",
        settingKey = "enableSparkQuest",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've done Weekly Spark Quest",
    },
    {
        settingText = "Track Special Assignments",
        settingKey = "enableSpecialAssignments",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've done Special Assignments World Quests",
    },
    {
        settingText = "Track Weekly Zones Quests",
        settingKey = "enableZonesQuests",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've done Weekly Quests in all of Khaz Algar zones",
    },
    {
        settingText = "Track Weekly Reputation Quests",
        settingKey = "enableRepQuests",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've done Weekly Reputation Quests",
    },
    {
        settingText = "Track Weekly Crafting Quests",
        settingKey = "enableCraftQuests",
        settingTooltip = "While enabled, your To-Do Checklist will be tracking if you've done Weekly Crafting Quests",
    },
}

local checkboxes = 0

local function CreateCheckbox(checkboxText, key, checkboxTooltip)
    local checkbox = CreateFrame("CheckButton", "ShowOrHideOption" .. checkboxes, settingsFrame, "UICheckButtonTemplate")
    checkbox.Text:SetText(checkboxText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -120 + (checkboxes * -30))

    if Todo_Settings.settingsKeys[key] == nil then
        Todo_Settings.settingsKeys[key] = true
    end

    checkbox:SetChecked(Todo_Settings.settingsKeys[key])

    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(checkboxTooltip, nil, nil, nil, nil, true)
    end)

    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    checkbox:SetScript("OnClick", function(self)
        Todo_Settings.settingsKeys[key] = self:GetChecked()
    end)

    checkboxes = checkboxes + 1

    return checkbox
end

-- Invisible frame to scan events
local eventListenerFrame = CreateFrame("Frame", "ToDoSettingsEventListenerFrame", UIParent)

eventListenerFrame:RegisterEvent("PLAYER_LOGIN")

eventListenerFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    if not Todo_Settings.settingsKeys then
        Todo_Settings.settingsKeys = {}
    end
    
    for _, setting in pairs(checkbox_settings) do
        CreateCheckbox(setting.settingText, setting.settingKey, setting.settingTooltip)
    end
  end
end)

-- Funkcja pokazująca ramkę ustawień
local function ShowSettingsFrame()
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end

-- Rejestracja slash command
SLASH_SHOWSETTINGS1 = "/todoset"
SlashCmdList["SHOWSETTINGS"] = function()
    ShowSettingsFrame()
end

-- Rejestracja zdarzeń
local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Sprawdzanie czy okno ma być automatycznie pokazane
        if Todo_Settings.AutoShow then
        settingsFrame:Show()
        end
    end
end

-- Rejestracja zdarzeń
settingsFrame:RegisterEvent("PLAYER_LOGIN")
settingsFrame:SetScript("OnEvent", OnEvent)
