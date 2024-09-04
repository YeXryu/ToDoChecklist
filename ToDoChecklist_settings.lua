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

-- Opcja włączania/wyłączania automatycznego pokazywania okna dodatku
local autoShowCheckbox = CreateFrame("CheckButton", "AutoShowCheckbox", settingsFrame, "ChatConfigCheckButtonTemplate")
autoShowCheckbox:SetPoint("TOPLEFT", saveMainButton, "BOTTOMLEFT", -2, -10)
AutoShowCheckboxText:SetText("Auto-show addon on login")
autoShowCheckbox:SetChecked(Todo_Settings.AutoShow)
autoShowCheckbox:SetScript("OnClick", function(self)
    Todo_Settings.AutoShow = self:GetChecked()
    SaveSettings()
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
