--[[
    ✨ Supply Teleporter Pro Turbo ✨
    Script otimizado para teleporte rápido e fluido para partes Unpressed e movimentação de suprimentos no Roblox.
    Criado para [Seu Canal no YouTube]
    Versão: 2.1
    Data: Outubro 2025
--]]

-- Serviços
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Jogador local
local LocalPlayer = Players.LocalPlayer

-- Configurações
local CONFIG = {
    AURA_DISTANCE = 999,        -- Alcance máximo para detecção de suprimentos (studs)
    SUPPLY_LIMIT = 30,          -- Limite máximo de suprimentos
    MAX_AURA = 2000,            -- Máximo alcance da aura
    MAX_SUPPLIES = 100,         -- Máximo limite de suprimentos
    TWEEN_DURATION = 0.01,      -- Duração do tween (muito rápido)
    BUTTON_TELEPORT_DELAY = 0.5, -- Aumentado para evitar travamentos
    SUPPLY_MOVE_DELAY = 0.1,    -- Aumentado para reduzir sobrecarga
    TARGET_CFRAME = CFrame.new(52.2001572, 3.72930002, 9.49186707, 
                               0.713073432, -0.0566850826, 0.698794067, 
                               0, 0.996726096, 0.0808528587, 
                               -0.701089382, 0, 0) -- CFrame alvo para suprimentos (usado no Turbo Unpressed)
}

-- Variáveis de estado
local isTeleportActive = false
local isFlingActive = false
local isButtonTeleportActive = false
local remote = nil
local originalCFrame = nil
local currentTween = nil -- Controle do tween atual

-- Funções Utilitárias
local function findRemote()
    local registry = (getreg or debug.getregistry)()
    for _, item in ipairs(registry) do
        if type(item) == "table" and rawget(item, "FireServer") and rawget(item, "BindEvents") then
            remote = item
            print("✅ Remote encontrado:", remote)
            return true
        end
    end
    warn("❌ Remote não encontrado! Algumas funcionalidades podem não funcionar.")
    return false
end

local function moveObject(object, targetCFrame)
    if not remote or not object or not object.Parent then
        warn("❌ Erro: Remote ou objeto inválido para:", object)
        return false
    end
    local success, err = pcall(function()
        remote:FireServer("UpdateProperty", object, "CFrame", targetCFrame)
    end)
    if not success then
        warn("❌ Falha ao mover:", object and object.Name or "nil", "Erro:", err)
        return false
    end
    print("🚚 Movido:", object.Name, "para:", targetCFrame)
    return true
end

local function createTween(object, targetCFrame, duration)
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, {CFrame = targetCFrame})
    currentTween = tween
    tween:Play()
    return tween
end

local function countSupplies(supplyFolder)
    local count = 0
    for _, obj in pairs(supplyFolder:GetChildren()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("supply") or obj.Name:lower():find("box")) then
            count = count + 1
        end
    end
    return count
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function getRandomFlingOffset()
    local directions = {
        CFrame.new(0, 50, 0),
        CFrame.new(0, -50, 0),
        CFrame.new(50, 0, 0),
        CFrame.new(-50, 0, 0),
        CFrame.new(0, 0, 50),
        CFrame.new(0, 0, -50)
    }
    return directions[math.random(1, #directions)]
end

local function getButtonCFrame(button)
    if button:IsA("BasePart") then
        return button.CFrame * CFrame.new(0, 2, 0)
    elseif button:IsA("Model") then
        local unpressedPart = button:FindFirstChild("Unpressed")
        if unpressedPart and unpressedPart:IsA("BasePart") then
            return unpressedPart.CFrame * CFrame.new(0, 2, 0)
        elseif button.PrimaryPart then
            return button.PrimaryPart.CFrame * CFrame.new(0, 2, 0)
        end
    end
    warn("❌ Botão", button and button.Name or "nil", "não possui uma BasePart válida ou Unpressed!")
    return nil
end

-- Funções Principais
local function teleportSuppliesAndPlayer()
    while isTeleportActive do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("⏳ Aguardando personagem ou HumanoidRootPart...")
            wait(0.1)
            continue
        end

        local playerPosition = character.HumanoidRootPart.Position
        local supplyFolder = Workspace:FindFirstChild("AllSupplyBoxes")

        if not supplyFolder then
            warn("❌ Pasta AllSupplyBoxes não encontrada no Workspace!")
            wait(1)
            continue
        end

        local supplyCount = countSupplies(supplyFolder)
        print("📦 Contagem inicial de suprimentos:", supplyCount)

        local targetSupply = nil
        for _, supply in pairs(supplyFolder:GetChildren()) do
            if supply and supply.Parent and supply:IsA("BasePart") then
                targetSupply = supply
                break
            end
        end

        if not targetSupply then
            warn("❌ Nenhum suprimento válido encontrado em AllSupplyBoxes!")
            wait(1)
            continue
        end

        local supplyCFrame = targetSupply.CFrame * CFrame.new(0, 2, 0)
        print("🎯 Teleportando jogador para:", supplyCFrame)
        local tween = createTween(character.HumanoidRootPart, supplyCFrame, CONFIG.TWEEN_DURATION)
        tween.Completed:Wait()

        if originalCFrame then
            local suppliesToMove = {}
            for _, supply in pairs(supplyFolder:GetChildren()) do
                if supply:IsA("BasePart") and (supply.Name:lower():find("supply") or supply.Name:lower():find("box")) then
                    local distance = getDistance(playerPosition, supply.Position)
                    if distance <= CONFIG.AURA_DISTANCE then
                        table.insert(suppliesToMove, supply)
                    end
                end
            end

            if #suppliesToMove > 0 then
                print("🚚 Movendo", #suppliesToMove, "suprimentos para a posição original:", originalCFrame)
                spawn(function()
                    for i, supply in ipairs(suppliesToMove) do
                        if i <= CONFIG.SUPPLY_LIMIT then
                            moveObject(supply, originalCFrame * CFrame.new(0, 2, 0))
                            wait(CONFIG.SUPPLY_MOVE_DELAY)
                        end
                    end
                end)
            else
                print("ℹ️ Nenhum suprimento dentro do alcance da aura para teleportar.")
            end
        else
            warn("❌ originalCFrame não está definido! Não é possível mover suprimentos.")
        end

        wait(0.05)
    end
end

local function flingSupplies()
    while isFlingActive do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("⏳ Aguardando personagem ou HumanoidRootPart...")
            wait(0.1)
            continue
        end

        local playerPosition = character.HumanoidRootPart.Position
        local supplyFolder = Workspace:FindFirstChild("AllSupplyBoxes")
        if not supplyFolder then
            warn("❌ Pasta AllSupplyBoxes não encontrada no Workspace!")
            isFlingActive = false
            FlingButton.Text = "Fling"
            FlingButton.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
            print("🛑 Fling de suprimentos desativado!")
            break
        end

        local suppliesToFling = {}
        for _, supply in pairs(supplyFolder:GetChildren()) do
            if supply:IsA("BasePart") and (supply.Name:lower():find("supply") or supply.Name:lower():find("box")) then
                local distance = getDistance(playerPosition, supply.Position)
                if distance <= CONFIG.AURA_DISTANCE then
                    table.insert(suppliesToFling, supply)
                end
            end
        end

        if #suppliesToFling > 0 then
            for _, supply in ipairs(suppliesToFling) do
                local flingOffset = getRandomFlingOffset()
                local newCFrame = supply.CFrame * flingOffset
                if moveObject(supply, newCFrame) then
                    print("💨 Fling aplicado a:", supply.Name)
                end
                wait(CONFIG.SUPPLY_MOVE_DELAY)
            end
        else
            warn("ℹ️ Nenhum suprimento encontrado dentro do alcance para fling!")
        end
        wait(0.1)
    end
end

local function teleportToButtons()
    while isButtonTeleportActive do
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("⏳ Aguardando personagem ou HumanoidRootPart...")
            wait(0.1)
            continue
        end

        local supplyButtons = Workspace:FindFirstChild("SupplyButtons")
        if not supplyButtons then
            warn("❌ Pasta SupplyButtons não encontrada no Workspace! Verifique o nome no Explorer.")
            isButtonTeleportActive = false
            ButtonTeleportButton.Text = "Turbo Unpressed"
            ButtonTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
            print("🛑 Teleporte para partes Unpressed desativado!")
            break
        end

        local buttons = supplyButtons:GetChildren()
        if #buttons == 0 then
            warn("❌ Nenhum botão encontrado em SupplyButtons!")
            wait(1)
            continue
        end

        print("📋 Botões encontrados:", #buttons)
        for i, button in ipairs(buttons) do
            print("Botão", i, ":", button.Name, button:FindFirstChild("Unpressed") and "tem Unpressed" or "sem Unpressed")
        end

        local buttonSequence = {
            {index = 5, name = "Unpressed"},
            {index = 4, name = "Unpressed"},
            {index = 6, name = "Unpressed"},
            {index = 3, name = "Unpressed"},
            {name = "Button.Unpressed"},
            {index = 7, name = "Unpressed"}
        }

        for _, action in ipairs(buttonSequence) do
            if not isButtonTeleportActive then break end
            local button, partName
            if action.index then
                button = buttons[action.index]
                partName = action.name
            else
                button = supplyButtons:FindFirstChild("Button")
                partName = "Unpressed"
            end

            if not button or not button.Parent then
                warn("❌ Botão no índice ou nome", action.index or "Button", "não encontrado ou foi destruído!")
                continue
            end

            local unpressedPart = button:IsA("BasePart") and button.Name == "Unpressed" and button or button:FindFirstChild("Unpressed")
            if not unpressedPart or not unpressedPart:IsA("BasePart") then
                warn("❌ Parte Unpressed não encontrada ou não é BasePart no botão:", button.Name)
                continue
            end

            local buttonCFrame = unpressedPart.CFrame * CFrame.new(0, 2, 0)
            print("🎯 Teleportando para parte Unpressed no botão:", button.Name)
            local success, err = pcall(function()
                local tween = createTween(character.HumanoidRootPart, buttonCFrame, CONFIG.TWEEN_DURATION)
                tween.Completed:Wait()
            end)
            if not success then
                warn("❌ Falha no tween para botão:", button.Name, "Erro:", err)
                character.HumanoidRootPart.CFrame = buttonCFrame
                print("🔄 Fallback: Teleporte direto para:", buttonCFrame)
            end

            local clickDetector = unpressedPart:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                local success, err = pcall(function()
                    fireclickdetector(clickDetector)
                end)
                if success then
                    print("✅ ClickDetector ativado na parte Unpressed:", unpressedPart.Name)
                else
                    warn("❌ Erro ao ativar ClickDetector na parte:", unpressedPart.Name, "Erro:", err)
                end
                wait(0.1) -- Pequeno delay após clicar
            else
                print("ℹ️ Sem ClickDetector, continuando...")
            end

            local supplyFolder = Workspace:FindFirstChild("AllSupplyBoxes")
            if supplyFolder then
                local suppliesToMove = {}
                for _, supply in pairs(supplyFolder:GetChildren()) do
                    if supply:IsA("BasePart") and (supply.Name:lower():find("supply") or supply.Name:lower():find("box")) then
                        table.insert(suppliesToMove, supply)
                    end
                end
                if #suppliesToMove > 0 then
                    print("🚚 Movendo", math.min(#suppliesToMove, CONFIG.SUPPLY_LIMIT), "suprimentos para coordenada fixa:", CONFIG.TARGET_CFRAME)
                    spawn(function()
                        for i, supply in ipairs(suppliesToMove) do
                            if i <= CONFIG.SUPPLY_LIMIT then
                                moveObject(supply, CONFIG.TARGET_CFRAME)
                                wait(CONFIG.SUPPLY_MOVE_DELAY)
                            end
                        end
                    end)
                else
                    print("ℹ️ Nenhum suprimento encontrado para teleportar.")
                end
            else
                warn("❌ Pasta AllSupplyBoxes não encontrada!")
            end
            wait(CONFIG.BUTTON_TELEPORT_DELAY)
        end
    end
end

-- Criação da GUI
local function createGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SupplyTeleporterGui"
    ScreenGui.Parent = game:GetService("CoreGui")
    print("🖼️ ScreenGui criado!")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ZIndex = 2000
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(0, 150, 255)
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 2001
    TopBar.Parent = MainFrame
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 20)
    topCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.Text = "✨ Supply Teleporter Pro Turbo"
    Title.TextColor3 = Color3.fromRGB(255, 215, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextStrokeTransparency = 0.4
    Title.ZIndex = 2002
    Title.Parent = TopBar
    local titleTween = TweenService:Create(Title, TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {TextTransparency = 0})
    titleTween:Play()

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0.85, 0, 0, 50)
    ToggleButton.Position = UDim2.new(0.075, 0, 0.12, 0)
    ToggleButton.Text = "Teleportar"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 16
    ToggleButton.ZIndex = 2002
    ToggleButton.Parent = MainFrame
    local btnCorner1 = Instance.new("UICorner")
    btnCorner1.CornerRadius = UDim.new(0, 10)
    btnCorner1.Parent = ToggleButton
    local btnStroke1 = Instance.new("UIStroke")
    btnStroke1.Thickness = 1.5
    btnStroke1.Color = Color3.fromRGB(0, 180, 255)
    btnStroke1.Parent = ToggleButton

    local FlingButton = Instance.new("TextButton")
    FlingButton.Size = UDim2.new(0.85, 0, 0, 50)
    FlingButton.Position = UDim2.new(0.075, 0, 0.27, 0)
    FlingButton.Text = "Fling"
    FlingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlingButton.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
    FlingButton.Font = Enum.Font.GothamBold
    FlingButton.TextSize = 16
    FlingButton.ZIndex = 2002
    FlingButton.Parent = MainFrame
    local btnCorner2 = Instance.new("UICorner")
    btnCorner2.CornerRadius = UDim.new(0, 10)
    btnCorner2.Parent = FlingButton
    local btnStroke2 = Instance.new("UIStroke")
    btnStroke2.Thickness = 1.5
    btnStroke2.Color = Color3.fromRGB(255, 120, 0)
    btnStroke2.Parent = FlingButton

    local ButtonTeleportButton = Instance.new("TextButton")
    ButtonTeleportButton.Size = UDim2.new(0.85, 0, 0, 50)
    ButtonTeleportButton.Position = UDim2.new(0.075, 0, 0.42, 0)
    ButtonTeleportButton.Text = "Turbo Unpressed"
    ButtonTeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ButtonTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
    ButtonTeleportButton.Font = Enum.Font.GothamBold
    ButtonTeleportButton.TextSize = 16
    ButtonTeleportButton.ZIndex = 2002
    ButtonTeleportButton.Parent = MainFrame
    local btnCorner3 = Instance.new("UICorner")
    btnCorner3.CornerRadius = UDim.new(0, 10)
    btnCorner3.Parent = ButtonTeleportButton
    local btnStroke3 = Instance.new("UIStroke")
    btnStroke3.Thickness = 1.5
    btnStroke3.Color = Color3.fromRGB(0, 255, 180)
    btnStroke3.Parent = ButtonTeleportButton

    local AuraLabel = Instance.new("TextLabel")
    AuraLabel.Size = UDim2.new(0.85, 0, 0, 30)
    AuraLabel.Position = UDim2.new(0.075, 0, 0.54, 0)
    AuraLabel.Text = "Alcance da Aura (máx 2000):"
    AuraLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
    AuraLabel.BackgroundTransparency = 1
    AuraLabel.Font = Enum.Font.GothamSemibold
    AuraLabel.TextSize = 14
    AuraLabel.ZIndex = 2002
    AuraLabel.Parent = MainFrame

    local AuraTextBox = Instance.new("TextBox")
    AuraTextBox.Size = UDim2.new(0.4, 0, 0, 40)
    AuraTextBox.Position = UDim2.new(0.075, 0, 0.62, 0)
    AuraTextBox.Text = tostring(CONFIG.AURA_DISTANCE)
    AuraTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    AuraTextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    AuraTextBox.Font = Enum.Font.Gotham
    AuraTextBox.TextSize = 16
    AuraTextBox.ZIndex = 2002
    AuraTextBox.Parent = MainFrame
    local txtCorner1 = Instance.new("UICorner")
    txtCorner1.CornerRadius = UDim.new(0, 8)
    txtCorner1.Parent = AuraTextBox
    local txtStroke1 = Instance.new("UIStroke")
    txtStroke1.Thickness = 1
    txtStroke1.Color = Color3.fromRGB(0, 150, 255)
    txtStroke1.Parent = AuraTextBox

    local SupplyLimitLabel = Instance.new("TextLabel")
    SupplyLimitLabel.Size = UDim2.new(0.85, 0, 0, 30)
    SupplyLimitLabel.Position = UDim2.new(0.075, 0, 0.71, 0)
    SupplyLimitLabel.Text = "Limite de Suprimentos (máx 100):"
    SupplyLimitLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
    SupplyLimitLabel.BackgroundTransparency = 1
    SupplyLimitLabel.Font = Enum.Font.GothamSemibold
    SupplyLimitLabel.TextSize = 14
    SupplyLimitLabel.ZIndex = 2002
    SupplyLimitLabel.Parent = MainFrame

    local SupplyLimitTextBox = Instance.new("TextBox")
    SupplyLimitTextBox.Size = UDim2.new(0.4, 0, 0, 40)
    SupplyLimitTextBox.Position = UDim2.new(0.075, 0, 0.79, 0)
    SupplyLimitTextBox.Text = tostring(CONFIG.SUPPLY_LIMIT)
    SupplyLimitTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SupplyLimitTextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    SupplyLimitTextBox.Font = Enum.Font.Gotham
    SupplyLimitTextBox.TextSize = 16
    SupplyLimitTextBox.ZIndex = 2002
    SupplyLimitTextBox.Parent = MainFrame
    local txtCorner2 = Instance.new("UICorner")
    txtCorner2.CornerRadius = UDim.new(0, 8)
    txtCorner2.Parent = SupplyLimitTextBox
    local txtStroke2 = Instance.new("UIStroke")
    txtStroke2.Thickness = 1
    txtStroke2.Color = Color3.fromRGB(0, 150, 255)
    txtStroke2.Parent = SupplyLimitTextBox

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0.85, 0, 0, 30)
    StatusLabel.Position = UDim2.new(0.075, 0, 0.91, 0)
    StatusLabel.Text = "Status: Desativado"
    StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamSemibold
    StatusLabel.TextSize = 14
    StatusLabel.ZIndex = 2002
    StatusLabel.Parent = MainFrame

    -- Manipuladores de Eventos
    AuraTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(AuraTextBox.Text)
            if newValue and newValue > 0 then
                if newValue > CONFIG.MAX_AURA then
                    CONFIG.AURA_DISTANCE = CONFIG.MAX_AURA
                    AuraTextBox.Text = tostring(CONFIG.MAX_AURA)
                    warn("⚠️ Alcance da aura excedeu o limite (2000)! Ajustado para 2000.")
                else
                    CONFIG.AURA_DISTANCE = newValue
                end
                print("🔄 Alcance da aura atualizado para:", CONFIG.AURA_DISTANCE, "studs")
            else
                warn("❌ Valor inválido para aura! Revertendo para:", CONFIG.AURA_DISTANCE)
                AuraTextBox.Text = tostring(CONFIG.AURA_DISTANCE)
            end
        end
    end)

    SupplyLimitTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(SupplyLimitTextBox.Text)
            if newValue and newValue > 0 then
                if newValue > CONFIG.MAX_SUPPLIES then
                    CONFIG.SUPPLY_LIMIT = CONFIG.MAX_SUPPLIES
                    SupplyLimitTextBox.Text = tostring(CONFIG.MAX_SUPPLIES)
                    warn("⚠️ Limite de suprimentos excedeu (100)! Ajustado para 100.")
                else
                    CONFIG.SUPPLY_LIMIT = newValue
                end
                print("🔄 Limite de suprimentos atualizado para:", CONFIG.SUPPLY_LIMIT)
            else
                warn("❌ Valor inválido para limite de suprimentos! Revertendo para:", CONFIG.SUPPLY_LIMIT)
                SupplyLimitTextBox.Text = tostring(CONFIG.SUPPLY_LIMIT)
            end
        end
    end)

    ToggleButton.MouseButton1Click:Connect(function()
        print("🔲 Botão de teleporte clicado!")
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("❌ Personagem ou HumanoidRootPart não encontrado!")
            return
        end

        isTeleportActive = not isTeleportActive
        if isTeleportActive then
            originalCFrame = character.HumanoidRootPart.CFrame
            print("📍 Posição original salva:", originalCFrame)
            ToggleButton.Text = "Desativar"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            StatusLabel.Text = "Status: Teleporte Ativo"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
            spawn(teleportSuppliesAndPlayer)
            print("🚀 Teleporte de suprimentos ativado!")
        else
            ToggleButton.Text = "Teleportar"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
            if originalCFrame then
                local success, err = pcall(function()
                    local tween = createTween(character.HumanoidRootPart, originalCFrame, CONFIG.TWEEN_DURATION)
                    tween.Completed:Wait()
                end)
                if not success then
                    warn("❌ Falha no tween de retorno:", err)
                    character.HumanoidRootPart.CFrame = originalCFrame
                    print("🔄 Fallback: Teleporte direto para:", originalCFrame)
                end
                print("🔙 Retornado à posição original:", originalCFrame)
            else
                warn("❌ originalCFrame não está definido! Não é possível retornar à posição original.")
            end
            print("🛑 Teleporte de suprimentos desativado!")
        end
    end)

    FlingButton.MouseButton1Click:Connect(function()
        print("🔲 Botão de fling clicado!")
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("❌ Personagem ou HumanoidRootPart não encontrado!")
            return
        end

        isFlingActive = not isFlingActive
        if isFlingActive then
            originalCFrame = character.HumanoidRootPart.CFrame
            print("📍 Posição original salva:", originalCFrame)
            FlingButton.Text = "Desativar"
            FlingButton.BackgroundColor3 = Color3.fromRGB(150, 60, 0)
            StatusLabel.Text = "Status: Fling Ativo"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
            spawn(flingSupplies)
            print("💨 Fling de suprimentos ativado!")
        else
            FlingButton.Text = "Fling"
            FlingButton.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
            if originalCFrame then
                local success, err = pcall(function()
                    local tween = createTween(character.HumanoidRootPart, originalCFrame, CONFIG.TWEEN_DURATION)
                    tween.Completed:Wait()
                end)
                if not success then
                    warn("❌ Falha no tween de retorno:", err)
                    character.HumanoidRootPart.CFrame = originalCFrame
                    print("🔄 Fallback: Teleporte direto para:", originalCFrame)
                end
                print("🔙 Retornado à posição original:", originalCFrame)
            end
            print("🛑 Fling de suprimentos desativado!")
        end
    end)

    ButtonTeleportButton.MouseButton1Click:Connect(function()
        print("🔲 Botão Turbo Unpressed clicado!")
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("❌ Personagem ou HumanoidRootPart não encontrado!")
            return
        end

        isButtonTeleportActive = not isButtonTeleportActive
        if isButtonTeleportActive then
            originalCFrame = character.HumanoidRootPart.CFrame
            print("📍 Posição original salva:", originalCFrame)
            ButtonTeleportButton.Text = "Desativar"
            ButtonTeleportButton.BackgroundColor3 = Color3.fromRGB(150, 100, 80)
            StatusLabel.Text = "Status: Turbo Unpressed Ativo"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
            spawn(teleportToButtons)
            print("🚀 Teleporte Turbo para partes Unpressed ativado!")
        else
            ButtonTeleportButton.Text = "Turbo Unpressed"
            ButtonTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
            StatusLabel.Text = "Status: Desativado"
            StatusLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            if originalCFrame then
                local success, err = pcall(function()
                    local tween = createTween(character.HumanoidRootPart, originalCFrame, CONFIG.TWEEN_DURATION)
                    tween.Completed:Wait()
                end)
                if not success then
                    warn("❌ Falha no tween de retorno:", err)
                    character.HumanoidRootPart.CFrame = originalCFrame
                    print("🔄 Fallback: Teleporte direto para:", originalCFrame)
                end
                print("🔙 Retornado à posição original:", originalCFrame)
            end
            print("🛑 Teleporte Turbo para partes Unpressed desativado!")
        end
    end)

    spawn(function()
        while wait(1) do
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local playerPosition = character.HumanoidRootPart.Position
                local supplyFolder = Workspace:FindFirstChild("AllSupplyBoxes")
                if supplyFolder then
                    local count = countSupplies(supplyFolder)
                    StatusLabel.Text = "Status: " .. count .. " Suprimentos"
                else
                    StatusLabel.Text = "Status: Desativado (Pasta não encontrada)"
                end
            end
        end
    end)

    return ToggleButton, FlingButton, ButtonTeleportButton, StatusLabel
end

-- Inicialização
wait(3)
findRemote()
local ToggleButton, FlingButton, ButtonTeleportButton, StatusLabel = createGui()
print("🚀 Supply Teleporter Pro Turbo inicializado com sucesso!")
