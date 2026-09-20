--==================================================================
-- SAFE GK HUB — MOBILE EDITION
-- Hitbox + Auto Dive + Auto Catch + Teclado Virtual Mobile
-- Repository: MiniSafeRP/autodive
--==================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local State = {
    systemEnabled = true,
    hitboxEnabled = true,
    autoDiveEnabled = false,
    autoCatchEnabled = true,
    armed = false,
    mode = "ENCAIXAR",
    hitboxSize = Vector3.new(13, 7, 6),
    lastArm = 0,
    armWindow = 1,
    cooldown = 0.65,
    lastDive = 0,
    touchDebounce = {},
}

local TriggerKeys = {
    [Enum.KeyCode.E] = true, [Enum.KeyCode.C] = true,
    [Enum.KeyCode.Q] = true, [Enum.KeyCode.Z] = true,
    [Enum.KeyCode.R] = true, [Enum.KeyCode.F] = true,
}

local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function hasGKTool()
    local character = getCharacter()
    if not character then return false end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local name = string.lower(tool.Name)
    return name == "gk"
        or string.find(name, "gk", 1, true) ~= nil
        or string.find(name, "goleiro", 1, true) ~= nil
        or string.find(name, "goalkeeper", 1, true) ~= nil
end

local function isBall(part)
    if not part or not part:IsA("BasePart") then return false end
    local name = string.lower(part.Name)
    if string.find(name, "ball", 1, true) then return true end
    return name == "tps" or name == "mps" or name == "esa"
end

local function getBall()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if isBall(object) then return object end
    end
end

local function arm()
    State.armed = true
    State.lastArm = os.clock()
end

local function recentlyArmed()
    return State.armed and os.clock() - State.lastArm <= State.armWindow
end

local function fireCatch(ball)
    if not State.systemEnabled or not State.autoCatchEnabled then return end
    if not ball or not hasGKTool() or not recentlyArmed() then return end
    local remote = ReplicatedStorage:FindFirstChild("CatchBall")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(ball) end)
    end
end

local function fireReact(ball)
    if not State.systemEnabled or not ball or not hasGKTool() then return end
    local remote = ReplicatedStorage:FindFirstChild("ApplyGKReact")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(ball, ball.CFrame) end)
    end
end

local function processBall(ball)
    if not ball or not recentlyArmed() then return end
    local now = os.clock()
    if State.touchDebounce[ball] and now - State.touchDebounce[ball] < 0.5 then return end
    State.touchDebounce[ball] = now
    State.armed = false
    if State.mode == "ENCAIXAR" then fireCatch(ball) else fireReact(ball) end
end

local hitbox
local function createHitbox()
    if hitbox and hitbox.Parent then return hitbox end
    hitbox = Instance.new("Part")
    hitbox.Name = "SafeGKClientHitbox"
    hitbox.Size = State.hitboxSize
    hitbox.Transparency = 0.7
    hitbox.Material = Enum.Material.ForceField
    hitbox.Color = Color3.fromRGB(0, 170, 255)
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.CanQuery = false
    hitbox.CanTouch = true
    hitbox.Parent = Workspace
    hitbox.Touched:Connect(function(part)
        if State.systemEnabled and State.hitboxEnabled and isBall(part) and hasGKTool() then
            processBall(part)
        end
    end)
    return hitbox
end

local function destroyHitbox()
    if hitbox then hitbox:Destroy(); hitbox = nil end
    table.clear(State.touchDebounce)
end

local function nearestDiveKey(ball, root)
    local localPosition = root.CFrame:PointToObjectSpace(ball.Position)
    local high = localPosition.Y > 1.5
    if localPosition.X >= 0 then
        return high and Enum.KeyCode.E or Enum.KeyCode.C
    end
    return high and Enum.KeyCode.Q or Enum.KeyCode.Z
end

local function pressKey(keyCode, duration)
    duration = duration or 0.09
    -- Mobile controls should use the game's own buttons when available.
    if isMobile then
        for _, object in ipairs(PlayerGui:GetDescendants()) do
            if object:IsA("GuiButton") and object.Visible then
                local label = string.lower(object.Name .. " " .. (object:IsA("TextButton") and object.Text or ""))
                if string.find(label, string.lower(keyCode.Name), 1, true) then
                    pcall(function() object:Activate() end)
                    return true
                end
            end
        end
        return false
    end
    if type(keypress) == "function" and type(keyrelease) == "function" then
        local ok = pcall(function()
            keypress(string.lower(keyCode.Name))
            task.wait(duration)
            keyrelease(string.lower(keyCode.Name))
        end)
        return ok
    end
    return false
end

local function autoDive()
    if not State.systemEnabled or not State.autoDiveEnabled or not hasGKTool() then return end
    if os.clock() - State.lastDive < State.cooldown then return end
    local ball, root = getBall(), getRoot()
    if not ball or not root then return end
    local velocity = ball.AssemblyLinearVelocity
    if velocity.Magnitude < 10 then return end
    local relative = ball.Position - root.Position
    if relative:Dot(velocity) >= 0 then return end
    State.lastDive = os.clock()
    pressKey(nearestDiveKey(ball, root))
end

local gui = Instance.new("ScreenGui")
gui.Name = "SafeGKMobileControls"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local toggle = Instance.new("TextButton")
toggle.Name = "GKToggle"
toggle.Size = UDim2.fromOffset(72, 72)
toggle.Position = UDim2.new(1, -88, 0.12, 0)
toggle.Text = "GK"
toggle.TextSize = 20
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
toggle.Parent = gui
toggle.Activated:Connect(function()
    State.systemEnabled = not State.systemEnabled
    State.hitboxEnabled = State.systemEnabled
    toggle.Text = State.systemEnabled and "GK" or "OFF"
    toggle.BackgroundColor3 = State.systemEnabled and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(180, 50, 50)
    if State.systemEnabled then createHitbox() else destroyHitbox() end
end)

local dive = Instance.new("TextButton")
dive.Name = "AutoDiveToggle"
dive.Size = UDim2.fromOffset(72, 72)
dive.Position = UDim2.new(1, -88, 0.12, 88)
dive.Text = "DIVE\nOFF"
dive.TextWrapped = true
dive.TextSize = 14
dive.TextColor3 = Color3.new(1, 1, 1)
dive.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
dive.Parent = gui
dive.Activated:Connect(function()
    State.autoDiveEnabled = not State.autoDiveEnabled
    dive.Text = State.autoDiveEnabled and "DIVE\nON" or "DIVE\nOFF"
    dive.BackgroundColor3 = State.autoDiveEnabled and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(180, 50, 50)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if TriggerKeys[input.KeyCode] then arm() end
    if processed or not State.systemEnabled then return end
    if input.KeyCode == Enum.KeyCode.G then
        local ball = getBall()
        local remote = ReplicatedStorage:FindFirstChild("Release")
        if ball and remote and remote:IsA("RemoteEvent") then pcall(function() remote:FireServer(ball) end) end
    end
end)

RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if root and State.hitboxEnabled and State.systemEnabled then
        local part = createHitbox()
        part.Size = State.hitboxSize
        part.CFrame = root.CFrame
        if State.armed and hasGKTool() then
            for _, object in ipairs(Workspace:GetDescendants()) do
                if isBall(object) then
                    local p = part.CFrame:PointToObjectSpace(object.Position)
                    local h = part.Size / 2
                    if math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z then
                        processBall(object)
                        break
                    end
                end
            end
        end
    end
    autoDive()
end)

LocalPlayer.CharacterAdded:Connect(function()
    State.armed = false
    task.wait(0.5)
    if State.systemEnabled and State.hitboxEnabled then createHitbox() end
end)

createHitbox()
print("[SAFE GK] Mobile edition loaded", isMobile and "(mobile)" or "(PC)")
