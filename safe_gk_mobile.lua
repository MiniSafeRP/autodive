--==================================================================
--  SAFE GK HUB — MOBILE EDITION
--  Hitbox + Auto Dive + Auto Catch + Teclado Virtual Mobile
--==================================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

local FORCE_MOBILE_TEST = false
local isMobile = UserInputService.TouchEnabled or FORCE_MOBILE_TEST

print("[SAFE GK DEBUG] SCRIPT INICIOU")

print("[SAFE GK DEBUG] TouchEnabled:", UserInputService.TouchEnabled)
print("[SAFE GK DEBUG] KeyboardEnabled:", UserInputService.KeyboardEnabled)
print("[SAFE GK DEBUG] MouseEnabled:", UserInputService.MouseEnabled)
print("[SAFE GK DEBUG] Mobile:", isMobile)
print("[SAFE GK DEBUG] ForceMobileTest:", FORCE_MOBILE_TEST)

local function MobileDebug(...)
    if not isMobile then return end
    if State and State.MobileDebugEnabled == false then return end
    print("[AUTO DIVE MOBILE]", ...)
end

local function MobileDebugWarn(...)
    if not isMobile then return end
    if State and State.MobileDebugEnabled == false then return end
    warn("[AUTO DIVE MOBILE]", ...)
end

--==================================================================
-- [REMOTES]
--==================================================================
local ApplyGKReact = ReplicatedStorage:WaitForChild("ApplyGKReact", 10)
local CatchBall    = ReplicatedStorage:WaitForChild("CatchBall", 10)
local Release      = ReplicatedStorage:FindFirstChild("Release")

--==================================================================
-- [ESTADO]
--==================================================================
local State = {
    hitboxEnabled = true,
    hitbox        = nil,
    touchDebounce = {},
    hitboxSize    = { X = 13, Y = 7, Z = 6 },
    currentMode   = "ENCAIXAR",
    armed         = false,
    ARM_TIMEOUT   = 3,
    ARM_WINDOW    = 1.0,
    lastKeyTime   = 0,
    MIN_BALL_SPEED_LOW  = 15,
    MIN_BALL_SPEED_HIGH = 10,
    HEIGHT_THRESHOLD    = 1.5,
    systemEnabled = true,
    GK_BlockUntil = 0,
    texturesRemoved     = false,
    scrollToggleEnabled = true,
    predictEnabled      = false,
    DEFAULT_FOV        = Camera and Camera.FieldOfView or 70,
    DEFAULT_BRIGHTNESS = Lighting.Brightness,

    -- Auto Dive
    AutoDiveAtivado = false,
    AutoDiveInverterLado = false,
    AutoDiveAntecipacaoBolaAlta  = 1.5,
    AutoDiveAntecipacaoBolaPerto = 2.5,
    AutoDiveAntecipacaoBolaLonge = 4.0,
    AutoDiveDistanciaLonge = 25,
    AutoDiveZonaMeio       = 3.5,
    AutoDiveFollowLateral        = true,
    AutoDiveFollowLateralForca   = 0.6,
    AutoDiveFollowLateralMinimo  = 0.5,
    AutoDiveFollowLateralMaximo  = 3.5,
    AutoDiveAlturaMuitoAlta = 5.0,
    AutoDiveAlturaAlta      = 2.0,
    AutoDiveHitboxLateral  = 6,
    AutoDiveHitboxFrontal  = 4,
    AutoDiveCooldown       = 0.65,
    AutoDiveUltimoDive     = 0,
    AutoDiveBallLock = nil,
    AutoDiveBallLockUntilReset = false,
    AutoDiveCooldownPuloAlto = 2.0,
    AutoDiveUltimoPuloAlto   = 0,
    AutoDiveVelocidadeMinima = 10,
    AutoDiveDistanciaMaxima = 75,
    AutoDiveVelocidadeAproximacaoMinima = 4,
    AutoDiveVelocidadeLateralMinima = 2,
    AutoDiveTempoReacaoReta = 0.28,
    AutoDiveTempoReacaoDiagonal = 1.10,
    AutoDiveTempoReacaoDiagonalLeve = 0.34,
    AutoDiveTempoReacaoDiagonalMedia = 0.48,
    AutoDiveTempoReacaoDiagonalAberta = 0.72,
    AutoDiveLateralMinimaDiagonalAberta = 11,
    AutoDiveLateralReacaoMaxima = 20,
    AutoDiveLateralAntecipacaoMaxima = 1.25,
    AutoDiveLateralAntecipacaoInicio = 10,
    AutoDiveLateralAlcanceMaximo = 34,
    AutoDiveLateralAbertaInicio = 8,
    AutoDiveLateralAbertaReacao = 0.78,
    AutoDiveLateralMuitoAbertaInicio = 15,
    AutoDiveLateralMuitoAbertaReacao = 1.15,
    AutoDiveLateralProximaFrenteMinima = 6,
    AutoDiveLateralVelocidadeCentroMinima = 3,
    AutoDiveDefesaFrontal = true,
    AutoDiveFrontalLateralMaxima = 2.75,
    AutoDiveFrontalVelocidadeLateralMaxima = 4.5,
    AutoDiveFrontalAlturaPes = -1.25,
    AutoDiveFrontalAlturaPeito = 0.55,
    AutoDiveFrontalAlturaCabeca = 2.15,
    AutoDiveFrontalTempoReacaoBaixa = 0.30,
    AutoDiveFrontalTempoReacaoMedia = 0.26,
    AutoDiveFrontalTempoReacaoAlta = 0.32,
    AutoDiveTeclaFrontalBaixa = Enum.KeyCode.F,
    AutoDiveTeclaFrontalMedia = Enum.KeyCode.R,
    AutoDiveTeclaPulo = Enum.KeyCode.Space,
    AutoDiveFrontalRMaisF = true,
    AutoDiveEnviandoTecla = false,
    MobileLastBackend = "",
    MobileDebugEnabled = true,
    MobileDebugLastButton = "",
    MobileDebugLastAction = "",
    AutoDivePularSeLonge = true,
    AutoDiveDistanciaPuloLonge = 30,
    AutoDiveTeclas = {
        DireitaAlto   = Enum.KeyCode.E,
        DireitaBaixo  = Enum.KeyCode.C,
        EsquerdaAlto  = Enum.KeyCode.Q,
        EsquerdaBaixo = Enum.KeyCode.Z,
    },

    -- Reach Perna
    gkReachEnabled = true,
    gkReachDebounce = {},
    phantomLegs = {},
    gkReachDistance  = 0,
    gkReachExtension = 6,
    gkReachYOffset   = 0,
    gkReachPulseDur  = 0.2,
    GK_REACH_COOLDOWN = 0.15,
    gkReachPulseUntil = 0,
    gkReachCurrentExt = 0,
    gkReachCooldownGlobal = 0,
    gkCharLocked = false,
    gkMouse1BloqueiaReach = true,
    gkBallArmBlockEnabled = true,
    gkBallArmDistance     = 4,
    gkLastKeyTime = 0,
    gkOnlyWithKeysPressed = false,
    gkHitboxSempreArmada = false,
    gkDebugToast = false,
    gkSystemEnabled = false,

    InputsPressed = {},
    gkActiveKeys = {},

    FogoAtivado = false,
    CorFogoSelecionada = "Default",
    FogoEfeito = nil,
    FogoRainbow = false,

    CharsSelecionado = nil,
    CharsLista = {},

    PredictAtivado = false,
    PredictPasta = nil,
    PredictHolder = nil,
    PredictSegmentos = {},
    PredictMax = 22,
    PredictVel = Vector3.zero,
    PredictUltimaBola = nil,
    PredictPontoFinal = nil,

    BloquearAutoDiveComInput = true,
    IncluirWASDNoBloqueio = false,

    PularNaBolaAtivado = true,
    PularNaBolaForca   = 50,
    PularNaBolaCooldown = 0.5,
    UltimoPuloNaBola   = 0,
}


if isMobile then
    MobileDebug("Mobile: verificacao de GK Tool DESATIVADA (mobile nao usa Tool).")
end

local MOVIMENTO_KEYS = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
}

local GK_TRIGGER_KEYS = {
    [Enum.KeyCode.E] = true, [Enum.KeyCode.C] = true,
    [Enum.KeyCode.R] = true, [Enum.KeyCode.F] = true,
    [Enum.KeyCode.Q] = true, [Enum.KeyCode.Z] = true,
}

local GK_REACH_KEYS = {
    [Enum.KeyCode.Q] = true, [Enum.KeyCode.E] = true, [Enum.KeyCode.R] = true,
    [Enum.KeyCode.T] = true, [Enum.KeyCode.Y] = true, [Enum.KeyCode.F] = true,
    [Enum.KeyCode.G] = true, [Enum.KeyCode.H] = true, [Enum.KeyCode.Z] = true,
    [Enum.KeyCode.X] = true, [Enum.KeyCode.C] = true, [Enum.KeyCode.V] = true,
    [Enum.KeyCode.B] = true, [Enum.KeyCode.N] = true, [Enum.KeyCode.M] = true,
}

local GK_BRACOS = {
    "Left Arm","Right Arm","LeftArm","RightArm",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm",
    "LeftUpperArm","RightUpperArm",
}

--==================================================================
-- [UTILITÁRIOS]
--==================================================================
local function isBallPart(part)
    if not part then return false end
    local n = string.lower(part.Name)
    if string.find(n, "ball", 1, true) then return true end
    if n == "tps" or n == "esa" or n == "mrs" or n == "prs" or n == "mps" then
        return true
    end
    local a = part.Parent
    while a and a ~= Workspace do
        local an = string.lower(a.Name)
        if string.find(an, "ball", 1, true) then return true end
        a = a.Parent
    end
    return false
end

local function getBall()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and isBallPart(obj) then return obj end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isBallPart(obj) then return obj end
    end
    return nil
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function hasGKTool()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local name = string.lower(tool.Name)
    return name == "gk"
        or string.find(name, "gk", 1, true) ~= nil
        or string.find(name, "goleiro", 1, true) ~= nil
        or string.find(name, "goalkeeper", 1, true) ~= nil
end

local function getBallSpeed(ball)
    if not ball then return 0 end
    local ok, vel = pcall(function() return ball.AssemblyLinearVelocity end)
    if ok and vel then return vel.Magnitude end
    local ok2, vel2 = pcall(function() return ball.Velocity end)
    if ok2 and vel2 then return vel2.Magnitude end
    return 0
end

local function classifyBall(ball)
    local spd = getBallSpeed(ball)
    local hrp = getHRP()
    if not hrp then return false, spd, false end
    local alturaRelativa = ball.Position.Y - hrp.Position.Y
    local isHigh = alturaRelativa > State.HEIGHT_THRESHOLD
    local minSpeed = isHigh and State.MIN_BALL_SPEED_HIGH or State.MIN_BALL_SPEED_LOW
    return spd > minSpeed, spd, isHigh
end

local function ArmouRecentemente()
    return (os.clock() - State.gkLastKeyTime) <= State.ARM_WINDOW
end

local function AlgumaTeclaCatchPressionada()
    for _, v in pairs(State.gkActiveKeys) do
        if v then return true end
    end
    return false
end

local function UsuarioApertandoAlgo()
    -- Mobile: NAO bloquear (senao nunca age)
    if isMobile then return false end

    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return true
    end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        return true
    end
    for key, _ in pairs(State.InputsPressed) do
        if not GK_TRIGGER_KEYS[key] then
            if State.IncluirWASDNoBloqueio or not MOVIMENTO_KEYS[key] then
                return true
            end
        end
    end
    return false
end

local function PodeAgir()
    if not isMobile and not hasGKTool() then return false end
    if os.clock() < State.GK_BlockUntil then return false end
    if State.BloquearAutoDiveComInput and UsuarioApertandoAlgo() then return false end
    return true
end

local function gkBolaPertoDoBraco(ball)
    if not State.gkBallArmBlockEnabled then return false end
    if not ball or not ball.Parent then return false end
    local c = LocalPlayer.Character
    if not c then return false end
    local bpos = ball.Position
    for _, nome in ipairs(GK_BRACOS) do
        local p = c:FindFirstChild(nome)
        if p and p:IsA("BasePart") then
            if (p.Position - bpos).Magnitude <= State.gkBallArmDistance then
                return true
            end
        end
    end
    return false
end

--==================================================================
-- [PULAR NA BOLA]
--==================================================================
local function PularNaBola(ball)
    if not State.PularNaBolaAtivado then return end
    if not ball or not ball.Parent then return end
    local agora = tick()
    if agora - State.UltimoPuloNaBola < State.PularNaBolaCooldown then return end
    State.UltimoPuloNaBola = agora

    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    local direcao = (ball.Position - hrp.Position)
    if direcao.Magnitude > 0.1 then
        local forca = math.clamp(State.PularNaBolaForca, 10, 200)
        local empurrao = direcao.Unit * forca
        local velAtual = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(empurrao.X, math.max(velAtual.Y, 30), empurrao.Z)
    end
end

--==================================================================
-- [REACH PERNA]
--==================================================================
local function gkDestroyPhantomLegs()
    for _, info in ipairs(State.phantomLegs) do
        if info.Part and info.Part.Parent then
            pcall(function() info.Part:Destroy() end)
        end
    end
    State.phantomLegs = {}
end

local function gkGetRealLegs()
    local c = LocalPlayer.Character
    if not c then return {} end
    local legs = {}
    for _, n in ipairs({"Left Leg", "Right Leg"}) do
        local p = c:FindFirstChild(n)
        if p and p:IsA("BasePart") then table.insert(legs, p) end
    end
    for _, n in ipairs({
        "LeftUpperLeg","RightUpperLeg","LeftLowerLeg",
        "RightLowerLeg","LeftFoot","RightFoot"
    }) do
        local p = c:FindFirstChild(n)
        if p and p:IsA("BasePart") then table.insert(legs, p) end
    end
    return legs
end

local function gkCreatePhantomLegs()
    local c = LocalPlayer.Character
    if not c then return end
    gkDestroyPhantomLegs()
    local hrp = getHRP()
    if not hrp then return end
    local reals = gkGetRealLegs()
    if #reals == 0 then reals = { hrp } end

    for _, real in ipairs(reals) do
        local ph = Instance.new("Part")
        ph.Name = real.Name; ph.Size = real.Size
        ph.Transparency = 1; ph.Anchored = true
        ph.CanCollide = false; ph.CanQuery = false; ph.CanTouch = false
        ph.Massless = true; ph.CastShadow = false
        ph.Material = real.Material or Enum.Material.SmoothPlastic
        if real:IsA("Part") then ph.Shape = real.Shape end
        ph.Parent = c
        ph:SetAttribute("IsPhantomLeg", true)

        local relOffset = hrp.CFrame:PointToObjectSpace(real.Position)
        local baseSize = real.Size

        table.insert(State.phantomLegs, {
            Part = ph, RelOffset = relOffset,
            BaseSize = baseSize, RealName = real.Name,
        })

        ph.Touched:Connect(function(otherPart)
            if not isBallPart(otherPart) then return end
            if _G.GK_ProcessReachTouch then
                _G.GK_ProcessReachTouch(otherPart, "LegTouched:" .. ph.Name)
            end
        end)
    end
end

local function gkUpdatePhantomLegs()
    local hrp = getHRP()
    if not hrp then return end
    local ext = State.gkReachCurrentExt * State.gkReachExtension
    local active = State.gkReachCurrentExt > 0.05
    for _, info in ipairs(State.phantomLegs) do
        local ph = info.Part
        if ph and ph.Parent then
            local b = info.BaseSize
            ph.Size = Vector3.new(b.X, b.Y, b.Z + ext)
            local newOffset = info.RelOffset
                + Vector3.new(0, State.gkReachYOffset, -(ext / 2 + State.gkReachDistance))
            ph.CFrame = hrp.CFrame * CFrame.new(newOffset)
            ph.Transparency = 1
            ph.CanTouch = active
        end
    end
end

local function gkForceTouchLegBall(ball)
    if not ball then return end
    for _, info in ipairs(State.phantomLegs) do
        local ph = info.Part
        if ph and ph.Parent then
            pcall(function()
                firetouchinterest(ph, ball, 0)
                firetouchinterest(ph, ball, 1)
            end)
        end
    end
end

local function gkFireReachChangeValue()
    local ChangeValueRemote = ReplicatedStorage:FindFirstChild("ChangeValue")
    if not ChangeValueRemote then return end
    local tps = Workspace:FindFirstChild("TPS")
    if not tps then return end
    pcall(function() ChangeValueRemote:FireServer(tps) end)
end

local function gkTriggerReachPulse()
    if not State.gkReachEnabled or not State.gkSystemEnabled then return end
    if os.clock() < State.GK_BlockUntil then return end
    if State.gkMouse1BloqueiaReach then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            return
        end
    end
    if not hasGKTool() then return end
    State.gkReachPulseUntil = os.clock() + State.gkReachPulseDur
end

local function gkIsReachActive()
    return os.clock() < State.gkReachPulseUntil
end

local function gkProcessReachTouch(part, origem)
    if not State.gkReachEnabled or not State.gkSystemEnabled then return end
    if os.clock() < State.GK_BlockUntil then return end
    if not gkIsReachActive() then return end
    if not part then return end
    if gkBolaPertoDoBraco(part) then return end
    if State.gkMouse1BloqueiaReach then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            return
        end
    end
    local now = os.clock()
    if now - State.gkReachCooldownGlobal < State.GK_REACH_COOLDOWN then return end
    if State.gkReachDebounce[part] and (now - State.gkReachDebounce[part]) < 0.3 then return end
    State.gkReachDebounce[part] = now
    State.gkReachCooldownGlobal = now
    State.gkReachPulseUntil = 0
    gkForceTouchLegBall(part)
    gkFireReachChangeValue()
end

_G.GK_ProcessReachTouch = gkProcessReachTouch

--==================================================================
-- [LOCK HRP]
--==================================================================
local function LockHRP(duration)
    if State.gkCharLocked then return end
    local hrp = getHRP()
    if not hrp then return end
    State.gkCharLocked = true
    local savedCFrame = hrp.CFrame
    local savedX = savedCFrame.X
    local savedZ = savedCFrame.Z
    local savedRot = savedCFrame - savedCFrame.Position
    local lastY = savedCFrame.Y
    local v0 = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity  = Vector3.new(0, v0.Y, 0)
    hrp.AssemblyAngularVelocity = Vector3.zero
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < duration do
            local h = getHRP()
            if h then
                local curY = h.Position.Y
                if curY > lastY then curY = lastY end
                lastY = curY
                h.CFrame = CFrame.new(savedX, curY, savedZ) * savedRot
                local v = h.AssemblyLinearVelocity
                h.AssemblyLinearVelocity  = Vector3.new(0, v.Y, 0)
                h.AssemblyAngularVelocity = Vector3.zero
            end
            RunService.Heartbeat:Wait()
        end
        State.gkCharLocked = false
    end)
end

--==================================================================
-- [FIRE]
--==================================================================
local function TriggerCatchBall(ball)
    if not State.systemEnabled then return end
    if not CatchBall or not ball then return end
    if not hasGKTool() then return end
    if gkBolaPertoDoBraco(ball) then return end
    if not ArmouRecentemente() and not State.gkHitboxSempreArmada then return end
    local isFast, spd, isHigh = classifyBall(ball)
    if not isFast then return end
    LockHRP(0.85)
    pcall(function() CatchBall:FireServer(ball) end)
end

local function TriggerGKReact(ball)
    if not State.systemEnabled then return end
    if not ApplyGKReact or not ball then return end
    if not hasGKTool() then return end
    if gkBolaPertoDoBraco(ball) then return end
    if not ArmouRecentemente() and not State.gkHitboxSempreArmada then return end
    local isFast, spd, isHigh = classifyBall(ball)
    if not isFast then return end
    pcall(function() ApplyGKReact:FireServer(ball, ball.CFrame) end)
end

local function TriggerRelease(ball)
    if not State.systemEnabled then return end
    if not Release or not ball then return end
    if not hasGKTool() then return end
    pcall(function() Release:FireServer(ball) end)
end

--==================================================================
-- [DISPATCH]
--==================================================================
local function processBallTouch(ball, origem)
    if not ball then return end
    if gkBolaPertoDoBraco(ball) then return end
    if not ArmouRecentemente() and not State.gkHitboxSempreArmada then return end
    local now = os.clock()
    if State.touchDebounce[ball] and (now - State.touchDebounce[ball]) < 0.5 then return end
    State.touchDebounce[ball] = now
    State.armed = false
    PularNaBola(ball)
    if State.currentMode == "ENCAIXAR" then
        TriggerCatchBall(ball)
    elseif State.currentMode == "REBOTE" then
        TriggerGKReact(ball)
    end
end

--==================================================================
-- [HITBOX]
--==================================================================
local function createHitbox()
    if State.hitbox and State.hitbox.Parent then return State.hitbox end
    local hb = Instance.new("Part")
    hb.Name = "ClientHitbox"
    hb.Size = Vector3.new(State.hitboxSize.X, State.hitboxSize.Y, State.hitboxSize.Z)
    hb.Transparency = 0.7
    hb.Material = Enum.Material.ForceField
    hb.Color = Color3.fromRGB(0, 170, 255)
    hb.Anchored = true
    hb.CanCollide = false
    hb.CanQuery = false
    hb.CanTouch = true
    hb.Massless = true
    hb.CastShadow = false
    hb.Parent = Workspace
    hb.Touched:Connect(function(otherPart)
        if not State.systemEnabled then return end
        if not State.hitboxEnabled then return end
        if not State.armed then return end
        -- Mobile nao possui GK Tool.
        if not isMobile and not hasGKTool() then return end
        if not isBallPart(otherPart) then return end
        local ball = getBall() or otherPart
        processBallTouch(ball, "Touched")
    end)
    State.hitbox = hb
    return hb
end

local function destroyHitbox()
    if State.hitbox then State.hitbox:Destroy(); State.hitbox = nil end
    table.clear(State.touchDebounce)
end

--==================================================================
-- [AUTO DIVE]
--==================================================================
-- MOBILE INPUT / AUTO DIVE
--
-- IMPORTANTE:
-- O teclado virtual abaixo e uma interface manual opcional.
-- O AUTO DIVE NAO clica nesses botoes.
--
-- Quando o Auto Dive detecta a defesa:
--   bola -> calcula direcao/altura -> simula keypress -> keyrelease
--
-- Ordem de backend no MOBILE:
--   1) keypress/keyrelease (quando fornecidos pelo ambiente)
--   2) VirtualInput
--   3) VirtualInputManager
--
-- Space tambem passa pelo mesmo caminho de keypress.
--==================================================================

local AutoDiveVirtualInput = nil

local function GetAutoDiveVirtualInput()
    if AutoDiveVirtualInput then return AutoDiveVirtualInput end

    pcall(function()
        if UserInputService and type(UserInputService.CreateVirtualInput) == "function" then
            AutoDiveVirtualInput = UserInputService:CreateVirtualInput()
        end
    end)

    return AutoDiveVirtualInput
end

local function GetVirtualInputManager()
    local vim = nil
    pcall(function()
        vim = game:GetService("VirtualInputManager")
    end)
    return vim
end

local function NomeTecla(kc)
    return kc and string.lower(kc.Name) or ""
end

-- Simula uma tecla no MOBILE sem depender de clicar no teclado GUI.
local MobileTouchId = 700

local function ProximoTouchId()
    MobileTouchId += 1
    if MobileTouchId > 2147483000 then
        MobileTouchId = 700
    end
    return MobileTouchId
end

-- Procura o botao REAL do jogo pelo texto que aparece na tela.
-- Assim o Auto Dive nao depende de coordenadas fixas do screenshot:
-- se o celular mudar resolucao/escala, usamos AbsolutePosition/AbsoluteSize.
-- No mobile, os controles do jogo ficam no PlayerGui.
-- No PC nao fazemos nenhuma busca desses botoes.
--
-- Esta lista limita a procura aos botoes relacionados ao GK que
-- apareceram no Explorer enviado pelo usuario.
local GKMobileButtonNames = {
    ["GK"] = true,
    ["GK C"] = true,
    ["GK C2"] = true,
    ["GK H"] = true,
    ["GK Z"] = true,
    ["GK H"] = true,
    ["GK Z2"] = true,
    ["GKRush"] = true,
    ["GKSwitch"] = true,

    ["Header"] = true,
    ["BackHeader"] = true,
    ["SideHeader"] = true,
    ["High Catch"] = true,
    ["Low Catch"] = true,
    ["Reflex"] = true,

    ["Left"] = true,
    ["Right"] = true,
    ["SlideTackle"] = true,
    ["Tackle Right"] = true,

    ["Throw"] = true,
    ["Drop Ball"] = true,
    ["Volley"] = true,
    ["VolleyDois"] = true,
    ["Special"] = true,
}

local function NomeGuiNormalizado(s)
    return string.lower(
        tostring(s or ""):gsub("[%s_%-]+", "")
    )
end

local function EncontrarBotaoGKMobile(nomes)
    if not isMobile then
        return nil
    end

    if not PlayerGui then
        MobileDebugWarn("PlayerGui nao encontrado.")
        return nil
    end

    MobileDebug("Procurando controle GK em TODO PlayerGui:",
        table.concat(nomes, " / "))

    local procurados = {}
    for _, nome in ipairs(nomes) do
        procurados[NomeGuiNormalizado(nome)] = true
    end

    local candidatos = {}

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("GuiObject")
            and obj.Visible
            and GKMobileButtonNames[obj.Name]
            and procurados[NomeGuiNormalizado(obj.Name)]
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0 then

            local alvo = obj

            -- Se o objeto nomeado for um TextLabel/ImageLabel,
            -- tenta achar o GuiButton interativo mais proximo.
            if not obj:IsA("GuiButton") then
                local parent = obj.Parent
                while parent and parent ~= PlayerGui do
                    if parent:IsA("GuiButton") and parent.Visible then
                        alvo = parent
                        break
                    end
                    parent = parent.Parent
                end
            end

            table.insert(candidatos, alvo)

            MobileDebug(
                "Candidato:",
                obj:GetFullName(),
                "| classe:", obj.ClassName,
                "| alvo touch:", alvo:GetFullName(),
                "| Pos:", alvo.AbsolutePosition,
                "| Size:", alvo.AbsoluteSize
            )
        end
    end

    -- Evita duplicatas e prioriza GuiButton real.
    local vistos = {}
    local primeiro = nil

    for _, botao in ipairs(candidatos) do
        if not vistos[botao] then
            vistos[botao] = true
            primeiro = primeiro or botao

            if botao:IsA("GuiButton") then
                MobileDebug("Botao interativo selecionado:",
                    botao:GetFullName())
                return botao
            end
        end
    end

    if primeiro then
        MobileDebugWarn(
            "Encontrei o controle, mas ele nao e GuiButton:",
            primeiro:GetFullName(),
            "| classe:", primeiro.ClassName
        )
        return primeiro
    end

    MobileDebugWarn(
        "Nenhum controle GK encontrado em PlayerGui para:",
        table.concat(nomes, " / ")
    )

    return nil
end


local function ListarBotoesGKMobile()
    if not isMobile or not PlayerGui then
        return {}
    end

    local encontrados = {}

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("GuiButton")
            and obj.Visible
            and GKMobileButtonNames[obj.Name] then

            table.insert(encontrados, obj)
        end
    end

    return encontrados
end


local function CentroDoBotao(btn)
    local pos = btn.AbsolutePosition
    local size = btn.AbsoluteSize

    return Vector2.new(
        pos.X + size.X * 0.5,
        pos.Y + size.Y * 0.5
    )
end

local function GetVirtualInputManagerTouch()
    local vim = nil

    pcall(function()
        vim = game:GetService("VirtualInputManager")
    end)

    return vim
end

-- Simula um dedo tocando fisicamente o botao do jogo.
-- O ponto do toque e calculado pela posicao/tamanho atual do GuiButton.
local function SimularTouchBotaoMobile(textos, duracao)
    if not isMobile then return false end

    duracao = duracao or 0.09

    MobileDebug("Tentando TOUCH:", table.concat(textos, " / "),
        "| Duracao:", duracao)

    local botao = EncontrarBotaoGKMobile(textos)

    if not botao then
        MobileDebugWarn("Botao nao encontrado:", table.concat(textos, " / "))
        return false
    end

    if not botao.Parent or not botao.Visible then
        return false
    end

    local pos = CentroDoBotao(botao)
    local touchId = ProximoTouchId()
    local vim = GetVirtualInputManagerTouch()

    if not vim then
        MobileDebugWarn("VirtualInputManager indisponivel.")
        return false
    end

    MobileDebug("VIM encontrado. Enviando Touch Begin em:",
        botao.Name, "|", math.floor(pos.X), math.floor(pos.Y))

    -- UserInputState.Begin / End correspondem ao dedo entrando/saindo.
    local beginState = Enum.UserInputState.Begin
    local endState = Enum.UserInputState.End

    local ok, err = pcall(function()
        vim:SendTouchEvent(touchId, beginState, pos.X, pos.Y)
        task.wait(duracao)
        vim:SendTouchEvent(touchId, endState, pos.X, pos.Y)
    end)

    if ok then
        MobileDebug("Touch Begin/End enviado com sucesso:",
            botao.Name, "|", math.floor(pos.X), math.floor(pos.Y))

        State.MobileLastBackend =
            string.format(
                "touch:%s @ %.0f,%.0f",
                botao.Text,
                pos.X,
                pos.Y
            )

        return true
    end

    MobileDebugWarn("Falha no touch:", tostring(botao.Name), "| erro:", tostring(err))
    return false
end

-- Mapeia a acao logica do Auto Dive para o nome do GuiButton REAL.
-- No mobile, o Auto Dive nunca chama keypress/keyrelease.
local MobileButtonMap = {
    -- Mapeamento principal pelos nomes GK encontrados no PlayerGui.
    Q     = {"GK Z", "Left"},
    E     = {"GK C2", "Right", "GK C"},
    Z     = {"GK Z2", "GK Z"},
    C     = {"GK C", "GK C2"},

    -- Defesa frontal.
    R     = {"GK H", "High Catch", "Header"},
    F     = {"GK", "Low Catch", "Reflex"},

    -- Pulo/defesa alta.
    Space = {"Header", "SideHeader", "BackHeader", "GK H"},
}

local function SimularAcaoTouchMobile(kc, duracao)
    if not isMobile or not kc then return false end

    local nome = tostring(kc.Name)
    MobileDebug("Auto Dive escolheu acao mobile:", nome)
    local textos = MobileButtonMap[nome]

    if not textos then
        MobileDebugWarn("Sem mapeamento touch para:", nome)
        return false
    end

    -- Nao simula keypress aqui.
    -- Simula o dedo tocando o botao real do jogo.
    return SimularTouchBotaoMobile(textos, duracao or 0.09)
end


local function SimularComboMobile(k1, k2, duracao, intervalo)
    if not isMobile or not k1 or not k2 then return false end

    MobileDebug("Auto Dive combo mobile:",
        tostring(k1.Name), "+", tostring(k2.Name))

    duracao = duracao or 0.10
    intervalo = intervalo or 0.01

    local nome1 = tostring(k1.Name)
    local nome2 = tostring(k2.Name)

    local textos1 = MobileButtonMap[nome1]
    local textos2 = MobileButtonMap[nome2]

    if not textos1 or not textos2 then
        return false
    end

    local b1 = EncontrarBotaoGKMobile(textos1)
    local b2 = EncontrarBotaoGKMobile(textos2)

    if not b1 or not b2 then
        MobileDebugWarn("Botoes do combo nao encontrados.")
        return false
    end

    MobileDebug("Combo encontrado:",
        b1:GetFullName(), "+", b2:GetFullName())

    local vim = GetVirtualInputManagerTouch()
    if not vim then
        MobileDebugWarn("VirtualInputManager indisponivel para combo.")
        return false
    end

    local p1 = CentroDoBotao(b1)
    local p2 = CentroDoBotao(b2)

    local id1 = ProximoTouchId()
    local id2 = ProximoTouchId()

    local beginState = Enum.UserInputState.Begin
    local endState = Enum.UserInputState.End

    -- Dois dedos: o primeiro toca, depois o segundo toca,
    -- ambos ficam pressionados durante o intervalo e depois saem.
    local ok = pcall(function()
        vim:SendTouchEvent(id1, beginState, p1.X, p1.Y)
        task.wait(intervalo)

        vim:SendTouchEvent(id2, beginState, p2.X, p2.Y)
        task.wait(duracao)

        vim:SendTouchEvent(id2, endState, p2.X, p2.Y)
        vim:SendTouchEvent(id1, endState, p1.X, p1.Y)
    end)

    if ok then
        MobileDebug("Touch combo enviado:", b1.Name, "+", b2.Name)
        State.MobileLastBackend =
            string.format(
                "touch_combo:%s + %s",
                b1.Text,
                b2.Text
            )

        return true
    end

    return false
end


local function ApertarTecla(kc, duracao)
    if not kc then return false end
    duracao = duracao or 0.09

    -- MOBILE:
    -- Touch-only: nao usa keypress/keyrelease no mobile.
    if isMobile then
        MobileDebug("ApertarTecla -> caminho TOUCH mobile:", tostring(kc.Name))
        return SimularAcaoTouchMobile(kc, duracao)
    end

    -- PC
    local k = NomeTecla(kc)

    if type(keypress) == "function" and type(keyrelease) == "function" then
        local ok = pcall(function()
            keypress(k)
            task.wait(duracao)
            keyrelease(k)
        end)
        if ok then return true end
    end

    local vi = GetAutoDiveVirtualInput()
    if vi then
        local ok = pcall(function()
            vi:SendKey(true, kc, false)
            task.wait(duracao)
            vi:SendKey(false, kc, false)
        end)
        if ok then return true end
    end

    local vim = GetVirtualInputManager()
    if vim then
        local ok = pcall(function()
            vim:SendKeyEvent(true, kc, false, game)
            task.wait(duracao)
            vim:SendKeyEvent(false, kc, false, game)
        end)
        if ok then return true end
    end

    warn("[AUTO DIVE] Falha: " .. k)
    return false
end

local function PressionarDuasTeclas(k1, k2, duracao, intervalo)
    if not k1 or not k2 then return false end

    duracao = duracao or 0.12
    intervalo = intervalo or 0.015

    -- MOBILE:
    -- Touch-only nos GuiButtons reais do PlayerGui.
    if isMobile then
        return SimularComboMobile(k1, k2, duracao, intervalo)
    end

    -- PC
    local a = NomeTecla(k1)
    local b = NomeTecla(k2)

    if type(keypress) == "function" and type(keyrelease) == "function" then
        local ok = pcall(function()
            keypress(a)
            task.wait(intervalo)
            keypress(b)
            task.wait(duracao)
            keyrelease(b)
            keyrelease(a)
        end)
        if ok then return true end
    end

    local vi = GetAutoDiveVirtualInput()
    if vi then
        local ok = pcall(function()
            vi:SendKey(true, k1, false)
            task.wait(intervalo)
            vi:SendKey(true, k2, false)
            task.wait(duracao)
            vi:SendKey(false, k2, false)
            vi:SendKey(false, k1, false)
        end)
        if ok then return true end
    end

    local vim = GetVirtualInputManager()
    if vim then
        local ok = pcall(function()
            vim:SendKeyEvent(true, k1, false, game)
            task.wait(intervalo)
            vim:SendKeyEvent(true, k2, false, game)
            task.wait(duracao)
            vim:SendKeyEvent(false, k2, false, game)
            vim:SendKeyEvent(false, k1, false, game)
        end)
        if ok then return true end
    end

    warn("[AUTO DIVE] Falha combo " .. a .. "+" .. b)
    return false
end

local function ApertarDefesaFrontal(acao)
    if acao == "BAIXA" then
        return ApertarTecla(State.AutoDiveTeclaFrontalBaixa, 0.08)

    elseif acao == "MEDIA" then
        if State.AutoDiveFrontalRMaisF then
            return PressionarDuasTeclas(
                State.AutoDiveTeclaFrontalMedia,
                State.AutoDiveTeclaFrontalBaixa,
                0.10,
                0.01
            )
        end

        return ApertarTecla(State.AutoDiveTeclaFrontalMedia, 0.08)

    elseif acao == "ALTA" then
        return PressionarDuasTeclas(
            State.AutoDiveTeclaPulo,
            State.AutoDiveTeclaFrontalMedia,
            0.10,
            0.01
        )
    end

    return false
end

local function CalcularAlturaPrevista(hrp, ball, eta)
    local bolaLocal = hrp.CFrame:PointToObjectSpace(ball.Position)
    local velLocal = hrp.CFrame:VectorToObjectSpace(ball.AssemblyLinearVelocity)

    eta = math.clamp(eta or 0, 0, 0.60)

    return bolaLocal.Y + velLocal.Y * eta
end

local function EscolherDefesaFrontal(hrp, ball, etaFrente, lateralPrevista, velocidadeLateral)
    if not State.AutoDiveDefesaFrontal then return nil end
    if not hrp or not ball then return nil end
    if lateralPrevista == nil then return nil end

    if math.abs(lateralPrevista) > State.AutoDiveFrontalLateralMaxima then
        return nil
    end

    if math.abs(velocidadeLateral or 0) > State.AutoDiveFrontalVelocidadeLateralMaxima then
        return nil
    end

    local bolaLocal = hrp.CFrame:PointToObjectSpace(ball.Position)
    local velLocal = hrp.CFrame:VectorToObjectSpace(ball.AssemblyLinearVelocity)

    local frente = -bolaLocal.Z

    if frente < -5 then return nil end
    if velLocal.Z <= 0.05 then return nil end

    local eta = etaFrente

    if not eta or eta == math.huge then
        eta = math.max(0, frente / math.max(velLocal.Z, 0.01))
    end

    if eta > 0.65 then return nil end

    local altura = CalcularAlturaPrevista(hrp, ball, eta)

    local lowLimit = State.AutoDiveFrontalAlturaPes
    local head = State.AutoDiveFrontalAlturaCabeca

    if altura >= head then
        if eta <= State.AutoDiveFrontalTempoReacaoAlta then
            return "ALTA"
        end
        return nil
    end

    if altura <= lowLimit then
        if eta <= State.AutoDiveFrontalTempoReacaoBaixa then
            return "BAIXA"
        end
        return nil
    end

    if eta <= State.AutoDiveFrontalTempoReacaoMedia then
        return "MEDIA"
    end

    return nil
end

local function EscolherTeclaAutoDive(hrp, ball, alvoX, alvoY)
    if not hrp or not ball then return nil end

    local bolaLocal = hrp.CFrame:PointToObjectSpace(ball.Position)
    local velLocal = hrp.CFrame:VectorToObjectSpace(ball.AssemblyLinearVelocity)

    local x = alvoX
    if x == nil then
        x = bolaLocal.X + velLocal.X * 0.20
    end

    local direita

    if math.abs(x) > 0.8 then
        direita = x > 0
    elseif math.abs(velLocal.X) > 0.8 then
        direita = velLocal.X > 0
    else
        direita = bolaLocal.X >= 0
    end

    local altura = alvoY

    if altura == nil then
        altura = bolaLocal.Y + velLocal.Y * 0.20
    end

    local alto = altura > State.HEIGHT_THRESHOLD

    if altura > State.AutoDiveAlturaMuitoAlta then
        alto = true
    elseif altura < 0 then
        alto = false
    end

    if State.AutoDiveInverterLado then
        direita = not direita
    end

    if direita then
        return alto
            and State.AutoDiveTeclas.DireitaAlto
            or State.AutoDiveTeclas.DireitaBaixo
    else
        return alto
            and State.AutoDiveTeclas.EsquerdaAlto
            or State.AutoDiveTeclas.EsquerdaBaixo
    end
end

local AutoDiveMobileHeartbeatLog = 0
local AutoDiveGateDebugLog = 0

local function AutoDiveUpdate()
    local agoraDebug = os.clock()

    if not State.AutoDiveAtivado then
        if isMobile and agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
            AutoDiveMobileHeartbeatLog = agoraDebug
            MobileDebug("AutoDiveUpdate rodando, mas AutoDiveAtivado = false. Ative o Auto Dive.")
        end
        return
    end

    if not State.systemEnabled then
        return
    end

    if isMobile and agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
        AutoDiveMobileHeartbeatLog = agoraDebug
        MobileDebug("AutoDiveUpdate: ATIVO | Mobile: SIM | GK Tool: ignorada")
    end

    if agoraDebug < (State.GK_BlockUntil or 0) then
        return
    end

    -- No mobile nao existe Tool de GK.
    -- O controle mobile e a propria interface, entao o Auto Dive
    -- nao pode bloquear aqui por falta de Tool.
    if not isMobile and not hasGKTool() then
        if agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
            AutoDiveMobileHeartbeatLog = agoraDebug
            print("[AUTO DIVE] PC: GK Tool nao encontrada.")
        end
        return
    end


    local hrp = getHRP()
    local hum = getHumanoid()

    if not hrp or not hum or hum.Health <= 0 then
        if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
            AutoDiveGateDebugLog = agoraDebug
            MobileDebug("STOP: personagem/HRP/Humanoid invalido.")
        end
        return
    end

    local agora = os.clock()
    local bola = getBall()

    if not bola or not bola.Parent then
        if isMobile and agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
            AutoDiveMobileHeartbeatLog = agoraDebug
            MobileDebug("Auto Dive ativo, mas nenhuma bola foi encontrada.")
        end
        State.AutoDiveBallLock = nil
        State.AutoDiveBallLockUntilReset = false
        return
    end

    local velWorld = bola.AssemblyLinearVelocity
    local velocidade = velWorld.Magnitude

    if velocidade < 10 then
        if isMobile and agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
            AutoDiveMobileHeartbeatLog = agoraDebug
            MobileDebug("Bola encontrada:", bola:GetFullName(),
                "| velocidade:", string.format("%.2f", velocidade),
                "| abaixo do minimo 10.")
        end
        return
    end

    if isMobile and agoraDebug - AutoDiveMobileHeartbeatLog > 2 then
        AutoDiveMobileHeartbeatLog = agoraDebug
        MobileDebug("AUTO DIVE MONITORANDO bola:",
            bola:GetFullName(),
            "| velocidade:", string.format("%.2f", velocidade))
    end

    if State.AutoDiveBallLockUntilReset then
        local lockLocal = hrp.CFrame:PointToObjectSpace(bola.Position)
        local distLock = (bola.Position - hrp.Position).Magnitude

        local unlockDist = isMobile and 110 or 85
        local unlockZ = isMobile and 30 or 24

        if velocidade < 6
            or distLock > unlockDist
            or lockLocal.Z > unlockZ then

            State.AutoDiveBallLock = nil
            State.AutoDiveBallLockUntilReset = false
        else
            return
        end
    end

    if State.AutoDiveEnviandoTecla then return end

    if agora - State.AutoDiveUltimoDive < State.AutoDiveCooldown then
        return
    end

    local bolaLocal = hrp.CFrame:PointToObjectSpace(bola.Position)
    local velLocal = hrp.CFrame:VectorToObjectSpace(velWorld)

    local x = bolaLocal.X
    local z = bolaLocal.Z
    local vx = velLocal.X
    local vz = velLocal.Z
    local frente = -z

    local horizontalSpeed = math.sqrt(vx * vx + vz * vz)

    if horizontalSpeed < 10 then return end

    local distXZ = math.sqrt(x * x + z * z)

    if distXZ < 0.1 then return end

    local aproximacao = -(x * vx + z * vz) / distXZ

    if aproximacao < 1.0 then return end

    local etaLinha = math.huge
    local xLinha = nil

    if vz > 0.05 and frente > -6 then
        etaLinha = math.max(0, -z / vz)
        xLinha = x + vx * etaLinha
    end

    local etaProximo = math.huge
    local xProximo = nil

    local speed2 = vx * vx + vz * vz
    local tProximo = -(x * vx + z * vz) / speed2

    if tProximo >= 0 and tProximo <= 2.5 then
        etaProximo = tProximo
        xProximo = x + vx * tProximo
    end

    local eta = etaLinha
    local xPrevisto = xLinha

    if eta == math.huge then
        eta = etaProximo
        xPrevisto = xProximo
    elseif eta > 1.7 and etaProximo < eta and xProximo then
        eta = etaProximo
        xPrevisto = xProximo
    end

    if eta == math.huge or not xPrevisto then
        if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
            AutoDiveGateDebugLog = agoraDebug
            MobileDebug("STOP: nao conseguiu prever a linha da bola.")
        end
        return
    end

    local lateralPrevista = math.abs(xPrevisto)

    local angulo = math.deg(
        math.atan2(
            math.abs(vx),
            math.max(math.abs(vz), 0.01)
        )
    )

    local alcanceNormal = 34
    local alcanceMuitoAberto = 50

    local chuteMuitoAberto =
        lateralPrevista > alcanceNormal
        and lateralPrevista <= alcanceMuitoAberto
        and angulo >= 45
        and math.abs(vx) >= 10
        and frente >= 12

    if lateralPrevista > alcanceNormal and not chuteMuitoAberto then
        if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
            AutoDiveGateDebugLog = agoraDebug
            MobileDebug(
                "STOP: lateral fora do alcance.",
                "| lateral:", string.format("%.2f", lateralPrevista),
                "| alcance:", alcanceNormal
            )
        end
        return
    end

    local tipo

    if lateralPrevista <= 3.25 and angulo <= 22 then
        tipo = "RETA"
    elseif lateralPrevista <= 7 and angulo <= 34 then
        tipo = "DIAGONAL_LEVE"
    elseif lateralPrevista <= 14 and angulo <= 50 then
        tipo = "DIAGONAL_MEDIA"
    else
        tipo = "DIAGONAL_ABERTA"
    end

    local reacao

    if tipo == "RETA" then
        reacao = 0.30

    elseif tipo == "DIAGONAL_LEVE" then
        reacao = 0.34

    elseif tipo == "DIAGONAL_MEDIA" then
        reacao = 0.44
            + math.clamp((lateralPrevista - 7) / 7, 0, 1) * 0.12

    else
        reacao = 0.58
            + math.clamp((lateralPrevista - 14) / 20, 0, 1) * 0.34

        if angulo >= 55 then
            reacao += 0.10
        end
    end

    if chuteMuitoAberto then
        reacao = math.max(reacao, 0.95)
    end

    if frente <= 5 then
        reacao = math.min(reacao, 0.14)
    elseif frente <= 9 then
        reacao = math.min(reacao, 0.20)
    elseif frente <= 14 then
        reacao = math.min(reacao, 0.28)
    elseif frente <= 20 and not chuteMuitoAberto then
        reacao = math.min(reacao, 0.38)
    elseif frente <= 26 and tipo ~= "DIAGONAL_ABERTA" then
        reacao = math.min(reacao, 0.45)
    end

    if eta > 2.50 or eta > reacao then
        if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
            AutoDiveGateDebugLog = agoraDebug
            MobileDebug(
                "STOP: ainda nao e hora do dive.",
                "| eta:", string.format("%.2f", eta),
                "| reacao:", string.format("%.2f", reacao),
                "| lateral:", string.format("%.2f", lateralPrevista)
            )
        end
        return
    end

    local etaAcao = math.clamp(eta, 0, 0.60)

    local alturaPrevista =
        bolaLocal.Y + velLocal.Y * etaAcao

    local xAcao =
        x + vx * etaAcao

    if math.abs(xPrevisto) <= 3.25 and angulo <= 35 then
        local defesa = EscolherDefesaFrontal(
            hrp,
            bola,
            etaLinha,
            xPrevisto,
            math.abs(vx)
        )

        if defesa then
            State.AutoDiveEnviandoTecla = true

            local enviado = ApertarDefesaFrontal(defesa)

            State.AutoDiveEnviandoTecla = false

            if enviado then
                State.AutoDiveUltimoDive = agora
                State.AutoDiveBallLock = bola
                State.AutoDiveBallLockUntilReset = true
                State.AutoDiveUltimaAcao = defesa
                return
            else
                State.AutoDiveBallLockUntilReset = false
            end
        end
    end

    local tecla = EscolherTeclaAutoDive(
        hrp,
        bola,
        xAcao,
        alturaPrevista
    )

    if not tecla then
        if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
            AutoDiveGateDebugLog = agoraDebug
            MobileDebug("STOP: EscolherTeclaAutoDive retornou nil.")
        end
        return
    end

    if isMobile and agoraDebug - AutoDiveGateDebugLog > 2 then
        AutoDiveGateDebugLog = agoraDebug
        MobileDebug(
            "DIVE DECIDIDO:",
            tostring(tecla.Name),
            "| eta:", string.format("%.2f", eta),
            "| lateral:", string.format("%.2f", lateralPrevista),
            "| altura:", string.format("%.2f", alturaPrevista)
        )
    end

    State.AutoDiveEnviandoTecla = true

    -- AQUI acontece o auto dive:
    -- nenhuma tecla virtual da GUI e clicada.
    -- A tecla e simulada diretamente.
    local enviado = ApertarTecla(tecla, 0.09)

    State.AutoDiveEnviandoTecla = false

    if enviado then
        if isMobile then
            MobileDebug("AUTO DIVE MOBILE executado:", State.AutoDiveUltimaAcao or tecla.Name)
        end

        State.AutoDiveUltimoDive = agora
        State.AutoDiveBallLock = bola
        State.AutoDiveBallLockUntilReset = true
        State.AutoDiveUltimaAcao = tecla.Name
    else
        if isMobile then
            MobileDebugWarn("DIVE DECIDIDO, mas o TOUCH falhou para:", tostring(tecla.Name))
        end

        State.AutoDiveUltimoDive =
            agora - State.AutoDiveCooldown * 0.5

        State.AutoDiveBallLockUntilReset = false
    end
end

--==================================================================
-- [CHAT]
--==================================================================
local function sendChatMessage(message)
    local ok1 = pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels then
            local general = channels:FindFirstChild("RBXGeneral")
                or channels:FindFirstChildWhichIsA("TextChannel")
            if general then
                general:SendAsync(message)
                return true
            end
        end
        return false
    end)
    if ok1 then return true end

    local ok2 = pcall(function()
        local evt = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
        if evt then
            local say = evt:WaitForChild("SayMessageRequest", 3)
            if say then
                say:FireServer(message, "All")
                return true
            end
        end
        return false
    end)
    return ok2
end

--==================================================================
-- [UI LEGADA — OCULTA]
--==================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HitboxControllerGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui
screenGui.Enabled = false  -- escondida, so WindUI aparece

--==================================================================
-- [BOTÕES MOBILE FLUTUANTES]
--==================================================================
function setHitboxEnabled(state)
    State.hitboxEnabled = state
    if state then
        createHitbox()
    else
        destroyHitbox()
        State.armed = false
    end
end

function setArmed(state)
    State.armed = state
end

function CriarBotaoMobile()
    if not isMobile then return end

    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Size = UDim2.new(0, 72, 0, 72)
    mobileBtn.Position = UDim2.new(1, -88, 0.12, 0)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
    mobileBtn.BackgroundTransparency = 0.10
    mobileBtn.BorderSizePixel = 0
    mobileBtn.Text = "GK"
    mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.TextSize = 20
    mobileBtn.Parent = PlayerGui
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", mobileBtn)
    stroke.Thickness = 2
    stroke.Transparency = 0.4

    local cooldown = 0
    mobileBtn.Activated:Connect(function()
        local now = os.clock()
        if now - cooldown < 0.30 then return end
        cooldown = now
        State.systemEnabled = not State.systemEnabled
        if State.systemEnabled then
            mobileBtn.Text = "GK"
            mobileBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
            setHitboxEnabled(true)
        else
            mobileBtn.Text = "OFF"
            mobileBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            setArmed(false)
            setHitboxEnabled(false)
        end
    end)
    State.MobileToggleButton = mobileBtn
end

function CriarBotaoMobileAutoDive()
    if not isMobile then return end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 72, 0, 72)
    btn.Position = UDim2.new(1, -88, 0.12, 88)
    btn.BackgroundColor3 = Color3.fromRGB(90, 60, 60)
    btn.BackgroundTransparency = 0.10
    btn.BorderSizePixel = 0
    btn.Text = "DIVE\nOFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextWrapped = true
    btn.Parent = PlayerGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 2
    stroke.Transparency = 0.4

    local cooldown = 0
    btn.Activated:Connect(function()
        local now = os.clock()
        if now - cooldown < 0.30 then return end
        cooldown = now
        State.AutoDiveAtivado = not State.AutoDiveAtivado
        if State.AutoDiveAtivado then
            btn.Text = "DIVE\nON"
            btn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
        else
            btn.Text = "DIVE\nOFF"
            btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        end
        State.AutoDiveBallLock = nil
        State.AutoDiveBallLockUntilReset = false
    end)
    State.MobileAutoDiveButton = btn
end

--==================================================================
-- [AUTO-ARM MOBILE]
--==================================================================
if isMobile then
    task.spawn(function()
        while task.wait(0.15) do
            if State.systemEnabled
               and State.hitboxEnabled
               and not State.armed then
                -- Mobile nao usa GK Tool.
                State.armed = true
                State.gkLastKeyTime = os.clock()
                MobileDebug("Mobile auto-arm: armed = true (sem GK Tool).")
            end
        end
    end)
end

--==================================================================
-- [HEARTBEAT]
--==================================================================
RunService.Heartbeat:Connect(function()
    local autoDiveOK, autoDiveErr = pcall(AutoDiveUpdate)
    if not autoDiveOK then
        warn("[AUTO DIVE] Erro: " .. tostring(autoDiveErr))
    end

    if not State.hitboxEnabled then return end
    if not State.systemEnabled then return end
    if not State.armed then return end
    if not isMobile and not hasGKTool() then return end

    local part = State.hitbox
    if not part or not part.Parent then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isBallPart(obj) then
            local localPos = part.CFrame:PointToObjectSpace(obj.Position)
            local halfX = part.Size.X * 0.5
            local halfY = part.Size.Y * 0.5
            local halfZ = part.Size.Z * 0.5
            if math.abs(localPos.X) <= halfX
                and math.abs(localPos.Y) <= halfY
                and math.abs(localPos.Z) <= halfZ then
                processBallTouch(obj, "Proximidade")
                break
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not State.hitboxEnabled then return end
    local hrp = getHRP()
    if not hrp then return end
    local part = State.hitbox or createHitbox()
    if (isMobile or hasGKTool()) and State.systemEnabled then
        if part.Transparency ~= 0.7 then
            part.Transparency = 0.7
            part.CanTouch = true
        end
    else
        if part.Transparency ~= 1 then
            part.Transparency = 1
            part.CanTouch = false
        end
    end
    part.Size = Vector3.new(State.hitboxSize.X, State.hitboxSize.Y, State.hitboxSize.Z)
    part.CFrame = hrp.CFrame
    if gkIsReachActive() then State.gkReachCurrentExt = 1
    else State.gkReachCurrentExt = 0 end
    pcall(gkUpdatePhantomLegs)
end)

--==================================================================
-- [INPUT PC]
--==================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        State.InputsPressed[input.KeyCode] = true
        if GK_TRIGGER_KEYS[input.KeyCode] then
            State.gkLastKeyTime = os.clock()
            State.gkActiveKeys[input.KeyCode] = true
        end
        if gameProcessed then return end
        if not State.systemEnabled then return end

        local key = input.KeyCode
        if key == Enum.KeyCode.E or key == Enum.KeyCode.C
        or key == Enum.KeyCode.Q or key == Enum.KeyCode.Z then
            if not State.hitboxEnabled then return end
            if not hasGKTool() then return end
            State.armed = true
            State.gkLastKeyTime = os.clock()
            return
        end
        if key == Enum.KeyCode.R or key == Enum.KeyCode.F then
            if not hasGKTool() then return end
            local ball = getBall()
            if ball then TriggerCatchBall(ball) end
            return
        end
        if key == Enum.KeyCode.G then
            if not hasGKTool() then return end
            local ball = getBall()
            if ball then TriggerRelease(ball) end
            return
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        State.InputsPressed[input.KeyCode] = nil
        State.gkActiveKeys[input.KeyCode] = nil
    end
end)

--==================================================================
-- [RESPAWN]
--==================================================================
LocalPlayer.CharacterAdded:Connect(function(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    State.gkCharLocked = false
    State.armed = false
    if State.hitboxEnabled and State.systemEnabled then
        destroyHitbox()
        local hb = createHitbox()
        if hrp and hb then hb.CFrame = hrp.CFrame end
        task.wait(0.5)
        if State.gkReachEnabled then gkCreatePhantomLegs() end
    end
end)

--==================================================================
-- [TEXTURAS]
--==================================================================
local savedMaterials, savedDecals = {}, {}
local function removeTextures()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not savedMaterials[obj] then savedMaterials[obj] = obj.Material end
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not savedDecals[obj] then savedDecals[obj] = obj.Transparency end
            obj.Transparency = 1
        end
    end
end
local function restoreTextures()
    for obj, mat in pairs(savedMaterials) do
        if obj and obj.Parent then obj.Material = mat end
    end
    for obj, t in pairs(savedDecals) do
        if obj and obj.Parent then obj.Transparency = t end
    end
    savedMaterials, savedDecals = {}, {}
end

--==================================================================
-- [PREDICT]
--==================================================================
local predictDots = {}
local PREDICT_DOT_COUNT = 14
local PREDICT_TIME = 0.65
local function ensurePredictDots()
    for i = 1, PREDICT_DOT_COUNT do
        local d = predictDots[i]
        if not d or not d.Parent then
            d = Instance.new("Part")
            d.Name = "ClientPredictDot" .. i
            d.Shape = Enum.PartType.Ball
            d.Anchored = true; d.CanCollide = false
            d.CanQuery = false; d.CanTouch = false
            d.Massless = true; d.CastShadow = false
            d.Material = Enum.Material.Neon
            d.Color = Color3.fromRGB(255, 90, 90)
            d.Size = Vector3.new(0.4, 0.4, 0.4)
            d.Transparency = 0.2
            d.Parent = Workspace
            predictDots[i] = d
        end
    end
end
local function hidePredictDots()
    for _, d in ipairs(predictDots) do
        if d and d.Parent then d.Transparency = 1 end
    end
end
local function updatePredict()
    if not State.predictEnabled then return end
    local ball = getBall()
    if not ball then hidePredictDots(); return end
    ensurePredictDots()
    local vel = Vector3.zero
    local ok, v = pcall(function() return ball.AssemblyLinearVelocity end)
    if ok and v then vel = v end
    if vel.Magnitude < 0.5 then hidePredictDots(); return end
    local origin = ball.Position
    for i, d in ipairs(predictDots) do
        local t = i / PREDICT_DOT_COUNT
        local pos = origin + vel * (PREDICT_TIME * t)
        local scale = 1 - (t * 0.65)
        local trans = 0.15 + (t * 0.75)
        d.Size = Vector3.new(0.4 * scale, 0.4 * scale, 0.4 * scale)
        d.Position = pos
        d.Transparency = trans
    end
end

--==================================================================
-- [WINDUI]
--==================================================================
function setTexturesState(value)
    State.texturesRemoved = value
    if value then removeTextures() else restoreTextures() end
end
function setPredictState(value)
    State.predictEnabled = value
    if value then ensurePredictDots() else hidePredictDots() end
end
function setAutoCatchState(value)
    State.gkSystemEnabled = value
    if value then
        if State.gkReachEnabled then gkCreatePhantomLegs() end
    else
        gkDestroyPhantomLegs()
    end
end
function setSystemState(value)
    State.systemEnabled = value
    if not value then
        State.armed = false
        setHitboxEnabled(false)
    elseif not State.hitboxEnabled then
        setHitboxEnabled(true)
    end
end

function InitWindUI()
    local okLoad, WindUI = pcall(function()
        return loadstring(game:HttpGet(
            'https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua'
        ))()
    end)
    if not okLoad or not WindUI then
        warn('[SAFE GK] WindUI nao carregou: ' .. tostring(WindUI))
        return
    end

    local okWindow, Window = pcall(function()
        return WindUI:CreateWindow({
            Title = 'Safe GK Hub',
            Author = 'SafeDev',
            Folder = 'SafeGKHub',
            Icon = 'shield',
            NewElements = true,
            HideSearchBar = false,
            OpenButton = {
                Title = 'Abrir Safe GK',
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 2,
                Enabled = true,
                Draggable = true,
                OnlyMobile = false,
                Scale = 0.55,
            },
            Topbar = { Height = 44, ButtonsType = 'Mac' },
        })
    end)
    if not okWindow or not Window then
        warn('[SAFE GK] Falha ao criar janela WindUI: ' .. tostring(Window))
        return
    end

    pcall(function()
        Window:Tag({ Title = 'GK', Icon = 'shield', Border = true })
    end)

    local MainTab = Window:Tab({Title='Goleiro', Desc='Sistema principal e hitbox', Icon='shield'})
    local DiveTab = Window:Tab({Title='Auto Dive', Desc='Defesa automatica e timing', Icon='zap'})
    local ReachTab = Window:Tab({Title='Reach', Desc='Alcance da perna', Icon='move'})
    local VisualTab = Window:Tab({Title='Visual', Desc='Camera, brilho e predict', Icon='eye'})
    local MobileTab = Window:Tab({Title='Mobile', Desc='Teclado virtual e botoes', Icon='smartphone'})

    MainTab:Section({Title='Sistema', Box=true, Opened=true})
    MainTab:Toggle({Title='Sistema', Desc='Liga ou desliga o sistema inteiro', Value=State.systemEnabled, Callback=setSystemState})
    MainTab:Toggle({Title='Hitbox', Desc='Ativa a hitbox do goleiro', Value=State.hitboxEnabled, Callback=setHitboxEnabled})
    MainTab:Dropdown({
        Title='Modo',
        Values={'ENCAIXAR','REBOTE'},
        Value=State.currentMode,
        AllowNone=false,
        Callback=function(value)
            if value=='ENCAIXAR' or value=='REBOTE' then
                State.currentMode=value
            end
        end,
    })
    MainTab:Toggle({Title='Auto Catch', Desc='Usa a defesa armada', Value=State.gkSystemEnabled, Callback=setAutoCatchState})
    MainTab:Toggle({Title='Pular na Bola', Value=State.PularNaBolaAtivado, Callback=function(v) State.PularNaBolaAtivado=v end})
    MainTab:Slider({Title='Forca do pulo', Step=1, Value={Min=10,Max=200,Default=State.PularNaBolaForca}, Callback=function(v) State.PularNaBolaForca=v end})

    MainTab:Section({Title='Hitbox', Box=true, Opened=true})
    MainTab:Slider({Title='Largura X', Step=0.5, Value={Min=1,Max=100,Default=State.hitboxSize.X}, Callback=function(v) State.hitboxSize.X=v end})
    MainTab:Slider({Title='Altura Y', Step=0.5, Value={Min=1,Max=100,Default=State.hitboxSize.Y}, Callback=function(v) State.hitboxSize.Y=v end})
    MainTab:Slider({Title='Profundidade Z', Step=0.5, Value={Min=1,Max=100,Default=State.hitboxSize.Z}, Callback=function(v) State.hitboxSize.Z=v end})

    DiveTab:Section({Title='Principal', Box=true, Opened=true})
    DiveTab:Toggle({
        Title='Auto Dive',
        Desc='Detecta a trajetoria e envia a defesa',
        Value=State.AutoDiveAtivado,
        Callback=function(v)
            State.AutoDiveAtivado=v
            State.AutoDiveBallLock=nil
            State.AutoDiveBallLockUntilReset=false
        end,
    })
    DiveTab:Toggle({Title='Inverter lado', Value=State.AutoDiveInverterLado, Callback=function(v) State.AutoDiveInverterLado=v end})
    DiveTab:Slider({Title='Velocidade minima', Step=1, Value={Min=10,Max=100,Default=math.max(10,State.AutoDiveVelocidadeMinima)}, Callback=function(v) State.AutoDiveVelocidadeMinima=v end})
    DiveTab:Slider({Title='Cooldown', Step=0.05, Value={Min=0.1,Max=2,Default=State.AutoDiveCooldown}, Callback=function(v) State.AutoDiveCooldown=v end})
    DiveTab:Slider({Title='Alcance lateral', Step=1, Value={Min=5,Max=60,Default=State.AutoDiveLateralAlcanceMaximo}, Callback=function(v) State.AutoDiveLateralAlcanceMaximo=v end})
    DiveTab:Slider({Title='Antecip. diag. aberta', Step=0.05, Value={Min=0.2,Max=1.5,Default=State.AutoDiveLateralMuitoAbertaReacao}, Callback=function(v) State.AutoDiveLateralMuitoAbertaReacao=v end})
    DiveTab:Slider({Title='Antecip. diag. media', Step=0.05, Value={Min=0.1,Max=1.2,Default=State.AutoDiveTempoReacaoDiagonalMedia}, Callback=function(v) State.AutoDiveTempoReacaoDiagonalMedia=v end})

    DiveTab:Section({Title='Defesa frontal', Box=true, Opened=true})
    DiveTab:Toggle({Title='Defesa frontal', Desc='F / R / Space + R', Value=State.AutoDiveDefesaFrontal, Callback=function(v) State.AutoDiveDefesaFrontal=v end})
    DiveTab:Toggle({Title='Peito: R + F', Value=State.AutoDiveFrontalRMaisF, Callback=function(v) State.AutoDiveFrontalRMaisF=v end})
    DiveTab:Slider({Title='Altura dos pes', Step=0.05, Value={Min=-3,Max=0,Default=State.AutoDiveFrontalAlturaPes}, Callback=function(v) State.AutoDiveFrontalAlturaPes=v end})
    DiveTab:Slider({Title='Altura do peito', Step=0.05, Value={Min=-0.5,Max=2,Default=State.AutoDiveFrontalAlturaPeito}, Callback=function(v) State.AutoDiveFrontalAlturaPeito=v end})
    DiveTab:Slider({Title='Altura da cabeca', Step=0.05, Value={Min=1,Max=4,Default=State.AutoDiveFrontalAlturaCabeca}, Callback=function(v) State.AutoDiveFrontalAlturaCabeca=v end})

    DiveTab:Section({Title='Testes', Box=true, Opened=false})
    DiveTab:Button({Title='Testar E', Callback=function() ApertarTecla(State.AutoDiveTeclas.DireitaAlto) end})
    DiveTab:Button({Title='Testar C', Callback=function() ApertarTecla(State.AutoDiveTeclas.DireitaBaixo) end})
    DiveTab:Button({Title='Testar Q', Callback=function() ApertarTecla(State.AutoDiveTeclas.EsquerdaAlto) end})
    DiveTab:Button({Title='Testar Z', Callback=function() ApertarTecla(State.AutoDiveTeclas.EsquerdaBaixo) end})
    DiveTab:Button({Title='Testar F', Callback=function() ApertarTecla(State.AutoDiveTeclaFrontalBaixa) end})
    DiveTab:Button({Title='Testar R', Callback=function() ApertarTecla(State.AutoDiveTeclaFrontalMedia) end})
    DiveTab:Button({Title='Testar R + F', Callback=function() PressionarDuasTeclas(State.AutoDiveTeclaFrontalMedia,State.AutoDiveTeclaFrontalBaixa,0.10,0.01) end})
    DiveTab:Button({Title='Testar Space + R', Callback=function() PressionarDuasTeclas(State.AutoDiveTeclaPulo,State.AutoDiveTeclaFrontalMedia,0.10,0.01) end})

    ReachTab:Section({Title='Reach da perna', Box=true, Opened=true})
    ReachTab:Toggle({
        Title='Reach da perna',
        Value=State.gkReachEnabled,
        Callback=function(v)
            State.gkReachEnabled=v
            if v and State.gkSystemEnabled then gkCreatePhantomLegs() else gkDestroyPhantomLegs() end
        end,
    })
    ReachTab:Slider({Title='Extensao', Step=0.5, Value={Min=0,Max=20,Default=State.gkReachExtension}, Callback=function(v) State.gkReachExtension=v end})
    ReachTab:Slider({Title='Distancia', Step=0.5, Value={Min=0,Max=30,Default=State.gkReachDistance}, Callback=function(v) State.gkReachDistance=v end})

    VisualTab:Section({Title='Visual', Box=true, Opened=true})
    VisualTab:Slider({Title='FOV', Step=1, Value={Min=1,Max=120,Default=Camera and Camera.FieldOfView or 70}, Callback=function(v) if Camera then Camera.FieldOfView=v end end})
    VisualTab:Slider({Title='Brilho', Step=0.1, Value={Min=0,Max=10,Default=Lighting.Brightness}, Callback=function(v) Lighting.Brightness=v end})
    VisualTab:Toggle({Title='Texturas', Value=not State.texturesRemoved, Callback=function(v) setTexturesState(not v) end})
    VisualTab:Toggle({Title='Scroll ativo', Value=State.scrollToggleEnabled, Callback=function(v) State.scrollToggleEnabled=v end})
    VisualTab:Toggle({Title='Predict', Value=State.predictEnabled, Callback=setPredictState})
    VisualTab:Input({Title='Comando de chat', Value=':char MPS_CR72008', Placeholder=':char MPS_CR72008', Callback=function(v) State.WindUIChatCommand=v end})
    VisualTab:Button({Title='Enviar comando', Icon='send', Callback=function() sendChatMessage(State.WindUIChatCommand or ':char MPS_CR72008') end})

    MobileTab:Section({Title='Controles mobile', Box=true, Opened=true})
    MobileTab:Paragraph({
        Title=isMobile and '📱 Mobile detectado' or '💻 PC detectado',
        Desc=isMobile and 'No mobile, o Auto Dive simula toque nos botoes reais da tela (E, C, Q, Z, R, F e Pular).' or 'Abra no celular para usar o teclado virtual.',
    })
    MobileTab:Toggle({
        Title='Mostrar teclado virtual',
        Value=isMobile,
        Callback=function(v)
            if type(CriarTecladoVirtualMobile) == 'function' then
                CriarTecladoVirtualMobile()
            end

            if State.MobileKeyboardGui then
                State.MobileKeyboardGui.Enabled = v
            end

            -- Ativar o teclado virtual no mobile tambem ativa
            -- o Auto Dive. O Auto Dive usa touch nos botoes reais;
            -- os botoes do teclado virtual continuam sendo opcionais.
            if isMobile then
                State.AutoDiveAtivado = v
                State.AutoDiveBallLock = nil
                State.AutoDiveBallLockUntilReset = false
            end
        end,
    })
    MobileTab:Button({
        Title='Criar / mostrar teclado',
        Icon='keyboard',
        Callback=function()
            if type(CriarTecladoVirtualMobile) == 'function' then
                CriarTecladoVirtualMobile()
            end

            if State.MobileKeyboardGui then
                State.MobileKeyboardGui.Enabled = true
            end

            if isMobile then
                State.AutoDiveAtivado = true
                State.AutoDiveBallLock = nil
                State.AutoDiveBallLockUntilReset = false
            end
        end,
    })
    MobileTab:Button({
        Title='Verificar botoes GK mobile',
        Icon='search',
        Callback=function()
            if not isMobile then
                warn("[AUTO DIVE MOBILE] Este dispositivo nao foi detectado como mobile.")
                return
            end

            local encontrados = ListarBotoesGKMobile()
            MobileDebug("Diagnostico: encontrados", #encontrados, "botoes GK no PlayerGui.")

            for _, obj in ipairs(encontrados) do
                MobileDebug("BOTAO:", obj.Name,
                    "|", obj:GetFullName(),
                    "| Pos:", obj.AbsolutePosition,
                    "| Size:", obj.AbsoluteSize)
            end
        end,
    })
    MobileTab:Button({Title='Ver metodo de touch/input', Callback=function()
        local msg = State.MobileLastBackend ~= '' and State.MobileLastBackend or 'nenhum'
        WindUI:Notify({Title='Input Mobile', Content='Ultimo metodo: ' .. msg, Icon='smartphone', Duration=3})
    end})

    pcall(function()
        Window:OnClose(function() print('[SAFE GK] WindUI fechada.') end)
    end)

    State.WindUIWindow = Window
    State.WindUI = WindUI
    print('[SAFE GK] WindUI carregada.')
end

--==================================================================
-- [TECLADO VIRTUAL MOBILE]
--==================================================================
function CriarTecladoVirtualMobile()
    if not isMobile then return end
    if State.MobileKeyboardGui and State.MobileKeyboardGui.Parent then
        State.MobileKeyboardGui.Enabled = true
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SafeGKMobileKeyboard"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui
    State.MobileKeyboardGui = gui

    -- Container principal
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.new(0, 330, 0, 230)
    root.Position = UDim2.new(0.5, -165, 1, -250)
    root.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    root.BackgroundTransparency = 0.08
    root.BorderSizePixel = 0
    root.Active = true
    root.Draggable = true
    root.Parent = gui
    Instance.new("UICorner", root).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", root)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(80, 80, 110)
    stroke.Transparency = 0.5

    -- Titulo
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 26)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "⌨  TECLADO GK MOBILE"
    title.TextColor3 = Color3.fromRGB(180, 220, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = root

    -- Botao fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -32, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = root
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.Activated:Connect(function()
        gui.Enabled = false
    end)

    -- Grid de teclas E/C/Q/Z/R/F/Space
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -20, 0, 160)
    grid.Position = UDim2.new(0, 10, 0, 38)
    grid.BackgroundTransparency = 1
    grid.Parent = root

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 60, 0, 46)
    layout.CellPadding = UDim2.new(0, 6, 0, 6)
    layout.FillDirectionMaxCells = 5
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = grid

    local keys = {
        {"Q", "Esq.Alto",  Enum.KeyCode.Q,       Color3.fromRGB(70, 100, 180)},
        {"E", "Dir.Alto",  Enum.KeyCode.E,       Color3.fromRGB(70, 100, 180)},
        {"Z", "Esq.Baixo", Enum.KeyCode.Z,       Color3.fromRGB(70, 130, 160)},
        {"C", "Dir.Baixo", Enum.KeyCode.C,       Color3.fromRGB(70, 130, 160)},
        {"R", "Catch Alto",Enum.KeyCode.R,       Color3.fromRGB(160, 120, 60)},
        {"F", "Catch Baixo",Enum.KeyCode.F,      Color3.fromRGB(160, 120, 60)},
        {"␣", "Pular",     Enum.KeyCode.Space,   Color3.fromRGB(100, 80, 160)},
    }

    for _, item in ipairs(keys) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = item[4]
        btn.BorderSizePixel = 0
        btn.Text = item[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Parent = grid
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        -- Descricao abaixo
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 12)
        lbl.Position = UDim2.new(0, 0, 1, -2)
        lbl.BackgroundTransparency = 1
        lbl.Text = item[2]
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 9
        lbl.Parent = btn

        btn.Activated:Connect(function()
            -- Uso manual: chama o backend mobile (touch) ou o input do PC.
            ApertarTecla(item[3], 0.08)
        end)
    end

    -- Combos
    local comboFrame = Instance.new("Frame")
    comboFrame.Size = UDim2.new(1, -20, 0, 40)
    comboFrame.Position = UDim2.new(0, 10, 1, -48)
    comboFrame.BackgroundTransparency = 1
    comboFrame.Parent = root

    local comboLayout = Instance.new("UIListLayout")
    comboLayout.FillDirection = Enum.FillDirection.Horizontal
    comboLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    comboLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    comboLayout.Padding = UDim.new(0, 8)
    comboLayout.Parent = comboFrame

    local function criarCombo(texto, k1, k2, cor)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 34)
        btn.Text = texto
        btn.BackgroundColor3 = cor or Color3.fromRGB(50, 55, 70)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = comboFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.Activated:Connect(function()
            PressionarDuasTeclas(k1, k2, 0.10, 0.01)
        end)
    end

    criarCombo("R + F", State.AutoDiveTeclaFrontalMedia, State.AutoDiveTeclaFrontalBaixa, Color3.fromRGB(130, 90, 50))
    criarCombo("Space + R", State.AutoDiveTeclaPulo, State.AutoDiveTeclaFrontalMedia, Color3.fromRGB(90, 70, 140))

    print("[SAFE GK] Teclado virtual mobile criado.")
    MobileDebug("Teclado virtual criado. O Auto Dive nao usa os botoes deste teclado; ele toca os GuiButtons reais do jogo.")
end

--==================================================================
-- [INIT]
--==================================================================
CriarBotaoMobile()
CriarBotaoMobileAutoDive()
CriarTecladoVirtualMobile()

-- No mobile, o Auto Dive fica ativo por padrao.
-- O botao DIVE ON/OFF continua podendo desativar/ativar.
if isMobile then
    State.AutoDiveAtivado = true
    MobileDebug("Auto Dive ativado automaticamente no mobile.")
end

pcall(function() InitWindUI() end)

print("[INIT] ✅ Safe GK Mobile carregado")
print("[INIT] Mobile:", isMobile and "SIM" or "NÃO")
