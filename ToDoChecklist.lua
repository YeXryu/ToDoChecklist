-- Inicjalizacja zmiennych zapisanych
Todo_Settings = Todo_Settings or {}
Todo_CharacterData = Todo_CharacterData or {}
Todo_CompletedTasks = Todo_CompletedTasks or {}

-- Zmienna do przechowywania odniesienia do okna z danymi postaci
local characterDataFrame = nil

-- Inicjalizacja głównej ramki
local frame = CreateFrame("Frame", "MainFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(220, 250)  -- Rozmiar ramki
frame:SetPoint("CENTER")

-- Tytuł ramki
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 5, 0)
frame.title:SetText("Rudy's Checklist")

-- Wyświetlanie nicku aktualnej postaci
frame.player = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.player:SetPoint("TOP", 0, -27)
frame.player:SetText("Character: " .. UnitName("player"))

-- Dodanie komunikatu dla niskiego poziomu
frame.levelMessage = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.levelMessage:SetPoint("CENTER", frame, "CENTER", 0, 0)
frame.levelMessage:SetText("You're not 80 yet!")
frame.levelMessage:Hide()  -- Początkowo ukryty

-- Ustawienie, by ramka była możliwa do przesunięcia
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Zapisanie pozycji okna
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    Todo_Settings.framePosition = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
end)

-- Dźwięk otwarcia/zamknięcia
frame:SetScript("OnShow", function()
    PlaySound(808)
end)
frame:SetScript("OnHide", function()
    PlaySound(808)
end)

-- Lista zadań
local tasks = {
    { name = "World Boss", maximum = 1, quests = { { questId = 71136 } }},
    { name = "Weekly Dungeon Quest", maximum = 1, quests = { { questId = 83443 }, { questId = 83457 }}},
    { name = "Weekly WQ Cache", maximum = 2, quests = { { questId = 83280 }, { questId = 83281 }, { questId = 82582 }}},
    { name = "Worldsoul Quest", maximum = 1, quests = { { questId = 82452 } }},
    { name = "Weekly PvP Quest", maximum = 1, quests = { { questId = 80186 },{ questId = 80187 }}},-- { questId = 80672 }}},
    { name = "Weekly Azj-Kahet", maximum = 1, quests = { { questId = 80670 }, { questId = 80671 }, { questId = 80672 }}},
    { name = "Weekly Hallowfall", maximum = 1, quests = { { questId = 76586 } }},
    { name = "Weekly Ringing Deeps", maximum = 1, quests = { { questId = 83333 } }},
    { name = "Weekly Isle of Dorn", maximum = 1, quests = { { questId = 83240 } }},
}

-- Funkcja do sprawdzania ilości waluty o ID 3028
local function GetCurrencyAmount()
    local currencyID = 3028
    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if currencyInfo then
        return currencyInfo.quantity
    else
        return 0
    end

end

-- Funkcja do sprawdzania itemlevela
local function GetItemLevel()
    local itemlevel = math.floor(select(2, GetAverageItemLevel()))
    print("Retrieved item level: ", itemlevel)  -- Dodane do debugowania
    return itemlevel
end

local playerLevel
-- Funkcja aktualizująca dane o zadaniach
local function UpdateTaskData()
    print("UpdateTaskData started")
    playerLevel = UnitLevel("player")
    if playerLevel < 80 then
        -- Ukryj listę zadań
        for _, taskText in ipairs(frame.taskTexts) do
            taskText:Hide()
        end
        -- Pokaż komunikat
        frame.levelMessage:Show()
        return
    else
        -- Pokaż listę zadań
        for _, taskText in ipairs(frame.taskTexts) do
            taskText:Show()
        end
        -- Ukryj komunikat
        frame.levelMessage:Hide()
    end

    local completedTasksCount = 0
    for i, task in ipairs(tasks) do
        local completed = 0  -- Resetowanie licznika ukończonych zadań dla każdego zadania

        -- Zliczanie ukończonych zadań
        for _, idk in pairs(task.quests) do
            if C_QuestLog.IsQuestFlaggedCompleted(idk.questId) then
                completed = completed + 1
            end
        end

        -- Aktualizacja tekstu
        local taskText = frame.taskTexts[i]
        if taskText then
            local color = ""
            if completed >= task.maximum then
                color = "FF00ff96"
                completedTasksCount = completedTasksCount + 1
            else
                color = "ffff7801"
            end
            taskText:SetText(task.name .. " " .. WrapTextInColorCode(completed .. " / " .. task.maximum, color))
        end

        -- Zapisanie danych do globalnej zmiennej
        local playerName = UnitName("player")
        Todo_CharacterData[playerName] = Todo_CharacterData[playerName] or {}
        Todo_CharacterData[playerName][task.name] = completed
    end

    -- Zapisanie liczby ukończonych zadań
    Todo_CompletedTasks[UnitName("player")] = completedTasksCount
end

local function IsWeeklyReset()
    -- Sprawdzenie aktualnego czasu serwera
    local serverTime = GetServerTime()
    
    -- Znajdź następny reset
    local resetTime = C_DateAndTime.GetSecondsUntilWeeklyReset()
    
    -- Dodaj odpowiednią liczbę sekund do czasu serwera, aby uzyskać czas ostatniego resetu
    local lastReset = serverTime - resetTime
    
    -- Sprawdź, czy czas ostatniego logowania dla tej postaci jest przed ostatnim resetem
    local playerName = UnitName("player")
    local lastLogin = Todo_CharacterData[playerName] and Todo_CharacterData[playerName].lastLogin or 0
    if lastLogin < lastReset then
    --if lastLogin < serverTime then -- debugging
        print("Weekly reset detected")
        return true
    else
        print("No weekly reset")
        return false
    end
end

local function ShowResetMessage()
    local msg = "Weekly quests have been reset!\n\n Data for ALTs might be outdated!"
    message(msg)
    PlaySound(12867, "Master")  -- Dźwięk powiadomienia
end

-- Aktualizacja currency 
local function CurrencyCheck()
    local name = UnitName("player")
    Todo_CharacterData[name].currency3028 = GetCurrencyAmount()
    print("Currency check")
end

--Aktualizacja ilvla
local function ilvlCheck()
    local name = UnitName("player")
    Todo_CharacterData[name].equippedIlvl = GetItemLevel()
    print("Aktualizacja ilvl: ", GetItemLevel())
end

-- Sprawdzanie poziomu postaci przed wyświetlaniem tekstu waluty i poziomu przedmiotów
local function ShowKeysAndIlvl()
    local level = UnitLevel("player")
    local equippedIlvl = GetItemLevel()
    local currency3028 = GetCurrencyAmount()
    if level == 80 then
        -- Wyświetlanie informacji o walucie i poziomie przedmiotów
        frame.currencyText:SetText("Equipped ilvl: " .. equippedIlvl .."\nRestored Coffer Keys: " .. currency3028)
        frame.currencyText:Show()  -- Pokaż tekst waluty i poziomu przedmiotów
        print("Postac powyzej 80, wyswietlam ilvl i keye")
    else
        frame.currencyText:Hide()  -- Ukryj tekst waluty i poziomu przedmiotów
        print("Postac ponizej 80, chowam ilvl i keye")
    end
end

-- Funkcja aktualizująca dane o bieżącej postaci i walucie
local function UpdateCharacterData()
    local name = UnitName("player")
    local level = UnitLevel("player")
    local class = UnitClass("player")

    -- Zapisanie informacji o bieżącej postaci do zmiennej globalnej
    Todo_CharacterData[name] = Todo_CharacterData[name] or {}
    Todo_CharacterData[name].level = level
    Todo_CharacterData[name].class = class
    print("Zapisałem ".. name .." | " .. level .." | " .. class)
end

-- Funkcja informująca o czasie ostatniego wylogowania
local function UpdateLogoutTime()
    local name = UnitName("player")
    Todo_CharacterData[name].lastLogin = GetServerTime()  -- Aktualizacja lastLogin
end

local function InitializeCharacterData()
    if IsWeeklyReset() then
        ShowResetMessage()
        -- Zresetowanie zadań dla postaci
        Todo_CompletedTasks[UnitName("player")] = 0
    end
    UpdateCharacterData()
    UpdateTaskData()
    ShowKeysAndIlvl()
end

-- Funkcja wywoływana przy starcie gry
local function OnEvent(self, event, ...)

    if event == "ADDON_LOADED" and ... == "ToDoChecklist" then
        local pos = Todo_Settings.framePosition
        if pos then
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(5, InitializeCharacterData)

    elseif event == "PLAYER_LOGIN" or event == "PLAYER_LEVEL_UP" then
        UpdateCharacterData()

    elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
        CurrencyCheck()

    elseif event == "QUEST_TURNED_IN" then
        UpdateTaskData()

    elseif event == "PLAYER_AVG_ITEM_LEVEL_UPDATE" then
        ilvlCheck()

    elseif event == "PLAYER_LOGOUT" then
        UpdateLogoutTime()
    end
end

-- Rejestracja zdarzeń
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", OnEvent)

-- Tworzenie tekstu dla każdego zadania
frame.taskTexts = {}  -- Tablica do przechowywania odniesień do tekstów
local previousTaskText
for i, task in ipairs(tasks) do
    local taskText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if i == 1 then
        -- Pierwszy element, ustaw jego pozycję bezpośrednio
        taskText:SetPoint("TOPLEFT", 10, -40)
    else
        -- Kolejne elementy, pozycjonuj w odniesieniu do poprzedniego
        taskText:SetPoint("TOPLEFT", previousTaskText, "BOTTOMLEFT", 0, -2)
    end

    -- Dodanie tekstu do tablicy
    frame.taskTexts[i] = taskText

    previousTaskText = taskText
end

-- Dodanie tekstu dla waluty 3028
frame.currencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.currencyText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 40)  -- Ustawienie pozycji tekstu
frame.currencyText:SetJustifyH("LEFT")
frame.currencyText:SetText("Restored Coffer Keys: " .. GetCurrencyAmount())

-- Dodanie przycisku do wyświetlania danych postaci
local showButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
showButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
showButton:SetSize(120, 25)
showButton:SetText("Show ALTs")

local function ShowCharacterDataFrame()
    -- Dźwięk
    PlaySound(89826)

    -- Sprawdzenie czy okno już istnieje
    if characterDataFrame and characterDataFrame:IsShown() then
        characterDataFrame:Hide()
    else
        -- Jeżeli nie istnieje, utwórz je na nowo
        if not characterDataFrame then
            characterDataFrame = CreateFrame("Frame", "CharacterDataFrame", UIParent, "BasicFrameTemplateWithInset")
            characterDataFrame:SetSize(230, 270)
            characterDataFrame:SetPoint("CENTER")
            characterDataFrame:EnableMouse(true)
            characterDataFrame:SetMovable(true)
            characterDataFrame:RegisterForDrag("LeftButton")
            characterDataFrame:SetScript("OnDragStart", characterDataFrame.StartMoving)
            characterDataFrame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                -- Zapisanie pozycji okna
                local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
                Todo_Settings.cDataFramePosition = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
            end)

            -- Przywrócenie pozycji z zapisanych zmiennych
            local pos = Todo_Settings.cDataFramePosition
            if pos then
                characterDataFrame:ClearAllPoints() -- Dodane aby uniknąć konfliktu
                characterDataFrame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
            end

            -- Tytuł ramki
            characterDataFrame.title = characterDataFrame:CreateFontString(nil, "OVERLAY")
            characterDataFrame.title:SetFontObject("GameFontHighlight")
            characterDataFrame.title:SetPoint("CENTER", characterDataFrame.TitleBg, "CENTER", 5, 0)
            characterDataFrame.title:SetText("Weeklies done on alts")

            -- Dodanie przewijanej ramki
            local scrollFrame = CreateFrame("ScrollFrame", nil, characterDataFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 10, -20)
            scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

            local content = CreateFrame("Frame", nil, scrollFrame)
            content:SetSize(200, 250)
            scrollFrame:SetScrollChild(content)

            local previousCharacterText = nil

            -- Zbierz dane do sortowania
            local characters = {}
            for characterName, characterData in pairs(Todo_CharacterData) do
                if characterName ~= UnitName("player") and characterData.level == 80 then
                    table.insert(characters, { name = characterName, data = characterData })
                end
            end

            -- Sortowanie alfabetyczne z główną postacią na początku
            table.sort(characters, function(a, b)
                if a.name == Todo_Settings.MainCharacter then
                    return true
                elseif b.name == Todo_Settings.MainCharacter then
                    return false
                else
                    return a.name < b.name
                end
            end)

            -- Sprawdzenie czy są dane o postaciach
            if #characters > 0 then
                for _, charInfo in ipairs(characters) do
                    local characterName = charInfo.name
                    local characterData = charInfo.data

                    local characterText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    if previousCharacterText then
                        characterText:SetPoint("TOPLEFT", previousCharacterText, "BOTTOMLEFT", 0, -10)
                    else
                        characterText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
                    end

                    -- Kolorowanie nagłówka postaci
                    local completedTasks = Todo_CompletedTasks[characterName] or 0
                    local headerColor = nil
                    local characterHeader = nil
                    if completedTasks >= 4 then
                        headerColor ="FF00ff96"
                        characterHeader = WrapTextInColorCode(characterName .. " (" .. characterData.class .. ")", headerColor)
                    else 
                        headerColor= "ffff7801"
                        characterHeader = WrapTextInColorCode(characterName .. " (" .. characterData.class .. ")", headerColor)
                    end

                    local characterDisplayText = "--------------------------------------\n".. characterHeader .. "\n" .. "---------------------------------------\n"
                    -- Dodawanie danych o zadaniach
                    for _, task in ipairs(tasks) do
                        local taskName = task.name
                        local completed = characterData[taskName] or 0
                        local taskColor = (completed >= task.maximum) and "FF00ff96" or "ffff7801"
                        characterDisplayText = characterDisplayText .. WrapTextInColorCode(taskName .. ": " .. completed .. " / " .. task.maximum, taskColor) .. "\n"
                    end
                    characterDisplayText = characterDisplayText .. "Restored Coffer Keys: " .. (characterData.currency3028 or 0) .. "\n" .. "Equipped ilvl: " .. (characterData.equippedIlvl) .. "\n"
                    characterText:SetJustifyH("LEFT")
                    characterText:SetText(characterDisplayText)
                    previousCharacterText = characterText
                end    
            else
                local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                noDataText:SetPoint("TOP", content, "TOP", 0, -20)
                noDataText:SetText("NO DATA TO DISPLAY\n\nYou need to log in\nas a different character\nto show data for ALTs")
            end
        end
        characterDataFrame:Show()
    end
end


showButton:SetScript("OnClick", ShowCharacterDataFrame)

SLASH_RESETALERT1 = "/resetalert"
SlashCmdList["RESETALERT"] = function()
    ShowResetMessage()
end
-- Rejestracja komendy
SLASH_TODO1 = "/todo"
SlashCmdList["TODO"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end