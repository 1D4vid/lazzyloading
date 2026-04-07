local EspTracer = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- SISTEMA ANTI-DUPLICAÇÃO PARA LAZY LOADING & SAVE CONFIG
-- Destrói as linhas e loops antigos se o módulo for recarregado
-- =========================================================
if getgenv()._EspTracer_Conn then
    getgenv()._EspTracer_Conn:Disconnect()
    getgenv()._EspTracer_Conn = nil
end
if getgenv()._EspTracer_Lines then
    for _, line in pairs(getgenv()._EspTracer_Lines) do
        if line then line:Remove() end
    end
end

-- Usa o ambiente global para guardar as linhas atuais
getgenv()._EspTracer_Lines = {}
local tracerLines = getgenv()._EspTracer_Lines

local tracerEnabled = false
local tracerOrigin = "Inferior"

local BEAST_WEAPON_NAMES = {["Hammer"] = true, ["Gemstone Hammer"] = true, ["Iron Hammer"] = true, ["Mallet"] = true}

local function isBeast(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    for name in pairs(BEAST_WEAPON_NAMES) do
        if backpack and backpack:FindFirstChild(name) then return true end
        if character and character:FindFirstChild(name) then return true end
    end
    if player.Team and player.Team.Name == "Beast" then return true end
    return false
end

local function getRoot(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function isAlive(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function createLine(player)
    if player ~= LocalPlayer and not tracerLines[player] then
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Transparency = 1
        line.Visible = false
        tracerLines[player] = line
    end
end

-- O loop principal agora fica sempre rodando (1 única vez), mas se a toggle for desativada, ele esconde tudo.
getgenv()._EspTracer_Conn = RunService.RenderStepped:Connect(function()
    if not tracerEnabled then
        -- Se estiver desligado, garante que nenhuma linha fique na tela e pausa a execução
        for _, line in pairs(tracerLines) do
            if line and line.Visible then
                line.Visible = false
            end
        end
        return
    end

    local viewportSize = Camera.ViewportSize
    local from = Vector2.new(viewportSize.X / 2, viewportSize.Y) -- Padrão Inferior

    if tracerOrigin == "Topo" then
        from = Vector2.new(viewportSize.X / 2, 0)
    elseif tracerOrigin == "Torso" then
        local localChar = LocalPlayer.Character
        local localRoot = getRoot(localChar)
        if localRoot and isAlive(localChar) then
            local origin3D = localRoot.Position
            local origin2D, originVisible = Camera:WorldToViewportPoint(origin3D)
            if not originVisible then
                local camForward = Camera.CFrame.LookVector
                local adjusted = origin3D + (camForward * 2)
                origin2D = Camera:WorldToViewportPoint(adjusted)
            end
            from = Vector2.new(origin2D.X, origin2D.Y)
        end
    end

    for player, line in pairs(tracerLines) do
        if not line then continue end
        
        local char = player.Character
        local root = getRoot(char)

        if root and isAlive(char) then
            local pos, visible = Camera:WorldToViewportPoint(root.Position)
            if visible then
                line.From = from
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = isBeast(player) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end)

function EspTracer.Toggle(state)
    tracerEnabled = state
    if state then
        -- Quando ativado, cria linha para todos os players que já estão no jogo
        for _, p in ipairs(Players:GetPlayers()) do
            createLine(p)
        end
    end
end

function EspTracer.SetOrigin(val)
    tracerOrigin = val
end

-- Eventos de conexão
Players.PlayerAdded:Connect(createLine)

Players.PlayerRemoving:Connect(function(p)
    if tracerLines[p] then 
        tracerLines[p]:Remove()
        tracerLines[p] = nil 
    end
end)

return EspTracer
