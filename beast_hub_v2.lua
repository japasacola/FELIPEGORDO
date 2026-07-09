-- ============================================================
--  BEAST HUB v2 — BLOX FRUITS
--  Built with real remotes: CommF_, requestEntrance, KeySystem
--  Level-based auto quest | Auto Farm | Auto Raid
--  Executor: Synapse X / KRNL / Fluxus / Delta
-- ============================================================

-- ╔══════════════════════════════════╗
-- ║  CORE SERVICES & LOCALS         ║
-- ╚══════════════════════════════════╝
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local VIM              = game:GetService("VirtualInputManager")
local UIS              = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local LP               = Players.LocalPlayer
local Char             = LP.Character or LP.CharacterAdded:Wait()
local HRP              = Char:WaitForChild("HumanoidRootPart")
local Hum              = Char:WaitForChild("Humanoid")

-- Wait for game to finish loading
repeat
    local ok = pcall(function()
        LP.PlayerGui:WaitForChild("Main"):WaitForChild("Loading")
    end)
    task.wait()
until game:IsLoaded()

-- ╔══════════════════════════════════╗
-- ║  WORLD DETECTION                ║
-- ╚══════════════════════════════════╝
local World1, World2, World3 = false, false, false
local PlaceId = game.PlaceId
if PlaceId == 2753915549 or PlaceId == 85211729168715 then
    World1 = true
elseif PlaceId == 4442272183 or PlaceId == 79091703265657 then
    World2 = true
elseif PlaceId == 7449423635 or PlaceId == 100117331123089 then
    World3 = true
end

-- ╔══════════════════════════════════╗
-- ║  STATE                          ║
-- ╚══════════════════════════════════╝
local _G = getgenv and getgenv() or {}

local State = {
    AutoFarm       = false,
    AutoRaid       = false,
    AutoQuest      = false,
    AutoCollect    = false,
    SpeedHack      = false,
    LowCPU         = false,
    AntiAFK        = true,
    BringMobs      = false,
    Running        = true,

    -- farm internals
    FarmMon        = nil,   -- current mob name
    FarmCFrame     = nil,   -- mob spawn CFrame
    QuestCFrame    = nil,   -- quest NPC CFrame
    QuestName      = nil,   -- quest remote name
    LevelQuest     = 1,     -- quest slot
    PosMon         = Vector3.new(0,0,0),
}

local Threads = {}

-- ╔══════════════════════════════════╗
-- ║  HELPERS                        ║
-- ╚══════════════════════════════════╝
local function GetChar() return LP.Character end
local function GetHRP()
    local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function IsAlive()
    local h = GetHum(); return h and h.Health > 0
end
local function MyLevel()
    local ok, v = pcall(function() return LP.Data.Level.Value end)
    return ok and v or 1
end

-- Tween-based smooth teleport (same trick as reference script)
local AnchorPart = Instance.new("Part", workspace)
AnchorPart.Size        = Vector3.new(1,1,1)
AnchorPart.Name        = "BeastHubAnchor"
AnchorPart.Anchored    = true
AnchorPart.CanCollide  = false
AnchorPart.CanTouch    = false
AnchorPart.Transparency = 1

-- Keep character on anchor
task.spawn(function()
    while State.Running do
        pcall(function()
            local hrp = GetHRP()
            if hrp and State.AutoFarm then
                if (hrp.Position - AnchorPart.Position).Magnitude <= 200 then
                    hrp.CFrame = AnchorPart.CFrame
                else
                    AnchorPart.CFrame = hrp.CFrame
                end
                local c = GetChar()
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end)
        task.wait()
    end
end)

local function _tp(cf)
    local hrp = GetHRP()
    if not hrp then return end
    local dist = (cf.Position - hrp.Position).Magnitude
    local ti   = TweenInfo.new(dist / 300, Enum.EasingStyle.Linear)
    local tw   = TweenService:Create(AnchorPart, ti, { CFrame = cf })
    tw:Play()
    -- cancel tween if farm stops
    task.spawn(function()
        while tw.PlaybackState == Enum.PlaybackState.Playing do
            if not State.AutoFarm then tw:Cancel() break end
            task.wait(0.1)
        end
    end)
end

local function HardTP(cf)
    -- instant no-tween TP
    local hrp = GetHRP()
    if hrp then hrp.CFrame = cf end
end

-- Fire CommF_ (the main BF server invoke)
local function CommF(...)
    return pcall(function()
        return RS.Remotes.CommF_:InvokeServer(...)
    end)
end

-- Fire proximity prompt safely
local function FirePP(pp)
    pcall(fireproximityprompt, pp)
end

-- Send virtual key
local function PressKey(key)
    VIM:SendKeyEvent(true,  key, false, game)
    VIM:SendKeyEvent(false, key, false, game)
end

-- Equip weapon by name
local function EquipTool(name)
    if not name then return end
    local tool = LP.Backpack:FindFirstChild(name)
    if tool then
        local hum = GetHum()
        if hum then hum:EquipTool(tool) end
    end
end

-- Use skill by ToolTip category + key
local function UseSkill(category, key)
    -- find tool matching category tooltip
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == category then
            EquipTool(t.Name)
            task.wait(0.05)
            PressKey(key)
            return
        end
    end
    -- also check equipped
    local c = GetChar()
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.ToolTip == category then
                PressKey(key)
                return
            end
        end
    end
end

-- Kill thread safely
local function Kill(key)
    if Threads[key] then
        pcall(task.cancel, Threads[key])
        Threads[key] = nil
    end
end

-- ╔══════════════════════════════════╗
-- ║  BRING MOBS (BringEnemy clone)  ║
-- ╚══════════════════════════════════╝
local function BringMobs()
    if not State.BringMobs then return end
    for _, mob in ipairs(workspace.Enemies:GetChildren()) do
        local mHum = mob:FindFirstChildOfClass("Humanoid")
        local mHRP = mob:FindFirstChild("HumanoidRootPart")
        if mHum and mHRP and mHum.Health > 0 then
            if (mHRP.Position - State.PosMon).Magnitude <= 300 then
                mHRP.CFrame = CFrame.new(State.PosMon)
                mHum.WalkSpeed  = 0
                mHum.JumpPower  = 0
                -- kill animator to freeze
                local anim = mHum:FindFirstChild("Animator")
                if anim then anim:Destroy() end
            end
        end
    end
end

-- ╔══════════════════════════════════╗
-- ║  LEVEL → QUEST MAP              ║
-- ╚══════════════════════════════════╝
-- Direct port from the reference script, all CFrames intact
local function CheckQuest()
    local lv = MyLevel()

    -- ════ WORLD 1 ════
    if World1 then
        if     lv >= 1   and lv <= 9   then State.FarmMon="Bandit";           State.LevelQuest=1; State.QuestName="BanditQuest1";    State.QuestCFrame=CFrame.new(1059.37195,15.4495068,1550.4231,.939700544,0,-0.341998369,0,1,0,.341998369,0,.939700544); State.FarmCFrame=CFrame.new(1045.9626,27.0025,1560.8203)
        elseif lv >= 10  and lv <= 14  then State.FarmMon="Monkey";           State.LevelQuest=1; State.QuestName="JungleQuest";      State.QuestCFrame=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); State.FarmCFrame=CFrame.new(-1448.518,67.853,11.465)
        elseif lv >= 15  and lv <= 29  then State.FarmMon="Gorilla";          State.LevelQuest=2; State.QuestName="JungleQuest";      State.QuestCFrame=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); State.FarmCFrame=CFrame.new(-1129.883,40.463,-525.423)
        elseif lv >= 30  and lv <= 39  then State.FarmMon="Pirate";           State.LevelQuest=1; State.QuestName="BuggyQuest1";      State.QuestCFrame=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-0.258804798,0,1,0,.258804798,0,.965929627); State.FarmCFrame=CFrame.new(-1103.513,13.752,3896.091)
        elseif lv >= 40  and lv <= 59  then State.FarmMon="Brute";            State.LevelQuest=2; State.QuestName="BuggyQuest1";      State.QuestCFrame=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-0.258804798,0,1,0,.258804798,0,.965929627); State.FarmCFrame=CFrame.new(-1140.083,14.809,4322.921)
        elseif lv >= 60  and lv <= 74  then State.FarmMon="Desert Bandit";    State.LevelQuest=1; State.QuestName="DesertQuest";      State.QuestCFrame=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-0.573571265,0,1,0,.573571265,0,.819155693); State.FarmCFrame=CFrame.new(924.799,6.448,4481.585)
        elseif lv >= 75  and lv <= 89  then State.FarmMon="Desert Officer";   State.LevelQuest=2; State.QuestName="DesertQuest";      State.QuestCFrame=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-0.573571265,0,1,0,.573571265,0,.819155693); State.FarmCFrame=CFrame.new(1608.282,8.614,4371.007)
        elseif lv >= 90  and lv <= 99  then State.FarmMon="Snow Bandit";      State.LevelQuest=1; State.QuestName="SnowQuest";        State.QuestCFrame=CFrame.new(1389.74451,88.1519318,-1298.90796,-0.342042685,0,.939684391,0,1,0,-0.939684391,0,-0.342042685); State.FarmCFrame=CFrame.new(1354.347,87.272,-1393.946)
        elseif lv >= 100 and lv <= 119 then State.FarmMon="Snowman";          State.LevelQuest=2; State.QuestName="SnowQuest";        State.QuestCFrame=CFrame.new(1389.74451,88.1519318,-1298.90796,-0.342042685,0,.939684391,0,1,0,-0.939684391,0,-0.342042685); State.FarmCFrame=CFrame.new(1201.641,144.579,-1550.067)
        elseif lv >= 120 and lv <= 149 then State.FarmMon="Chief Petty Officer"; State.LevelQuest=1; State.QuestName="MarineQuest2"; State.QuestCFrame=CFrame.new(-5039.58643,27.3500385,4324.68018,0,0,-1,0,1,0,1,0,0); State.FarmCFrame=CFrame.new(-4881.230,22.652,4273.752)
        elseif lv >= 150 and lv <= 174 then State.FarmMon="Sky Bandit";       State.LevelQuest=1; State.QuestName="SkyQuest";         State.QuestCFrame=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-0.500031412,0,.866007268); State.FarmCFrame=CFrame.new(-4953.207,295.744,-2899.229)
        elseif lv >= 175 and lv <= 189 then State.FarmMon="Dark Master";      State.LevelQuest=2; State.QuestName="SkyQuest";         State.QuestCFrame=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-0.500031412,0,.866007268); State.FarmCFrame=CFrame.new(-5259.844,391.397,-2229.035)
        elseif lv >= 190 and lv <= 209 then State.FarmMon="Prisoner";         State.LevelQuest=1; State.QuestName="PrisonerQuest";    State.QuestCFrame=CFrame.new(5308.93115,1.65517521,475.120514,-0.0894274712,-5.00292918e-09,-0.995993316,1.60817859e-09,1,-5.16744869e-09,.995993316,-2.06384709e-09,-0.0894274712); State.FarmCFrame=CFrame.new(5098.973,-0.320,474.237)
        elseif lv >= 210 and lv <= 249 then State.FarmMon="Dangerous Prisoner"; State.LevelQuest=2; State.QuestName="PrisonerQuest"; State.QuestCFrame=CFrame.new(5308.93115,1.65517521,475.120514,-0.0894274712,-5.00292918e-09,-0.995993316,1.60817859e-09,1,-5.16744869e-09,.995993316,-2.06384709e-09,-0.0894274712); State.FarmCFrame=CFrame.new(5654.563,15.633,866.299)
        elseif lv >= 250 and lv <= 274 then State.FarmMon="Toga Warrior";     State.LevelQuest=1; State.QuestName="ColosseumQuest";   State.QuestCFrame=CFrame.new(-1580.04663,6.35000277,-2986.47534,-0.515037298,0,-0.857167721,0,1,0,.857167721,0,-0.515037298); State.FarmCFrame=CFrame.new(-1820.214,51.683,-2740.665)
        elseif lv >= 275 and lv <= 299 then State.FarmMon="Gladiator";        State.LevelQuest=2; State.QuestName="ColosseumQuest";   State.QuestCFrame=CFrame.new(-1580.04663,6.35000277,-2986.47534,-0.515037298,0,-0.857167721,0,1,0,.857167721,0,-0.515037298); State.FarmCFrame=CFrame.new(-1292.838,56.380,-3339.031)
        elseif lv >= 300 and lv <= 324 then State.FarmMon="Military Soldier"; State.LevelQuest=1; State.QuestName="MagmaQuest";       State.QuestCFrame=CFrame.new(-5313.37012,10.9500084,8515.29395,-0.499959469,0,.866048813,0,1,0,-0.866048813,0,-0.499959469); State.FarmCFrame=CFrame.new(-5411.164,11.081,8454.292)
        elseif lv >= 325 and lv <= 374 then State.FarmMon="Military Spy";     State.LevelQuest=2; State.QuestName="MagmaQuest";       State.QuestCFrame=CFrame.new(-5313.37012,10.9500084,8515.29395,-0.499959469,0,.866048813,0,1,0,-0.866048813,0,-0.499959469); State.FarmCFrame=CFrame.new(-5802.868,86.262,8828.859)
        elseif lv >= 375 and lv <= 399 then State.FarmMon="Fishman Warrior";  State.LevelQuest=1; State.QuestName="FishmanQuest";     State.QuestCFrame=CFrame.new(61122.652,18.497,1569.399); State.FarmCFrame=CFrame.new(60878.300,18.482,1543.757); CommF("requestEntrance",Vector3.new(61163.8515625,11.6796875,1819.7841796875))
        elseif lv >= 400 and lv <= 449 then State.FarmMon="Fishman Commando"; State.LevelQuest=2; State.QuestName="FishmanQuest";     State.QuestCFrame=CFrame.new(61122.652,18.497,1569.399); State.FarmCFrame=CFrame.new(61922.632,18.482,1493.934); CommF("requestEntrance",Vector3.new(61163.8515625,11.6796875,1819.7841796875))
        elseif lv >= 450 and lv <= 474 then State.FarmMon="God's Guard";      State.LevelQuest=1; State.QuestName="SkyExp1Quest";     State.QuestCFrame=CFrame.new(-4721.88867,843.874695,-1949.96643,.996191859,0,-0.0871884301,0,1,0,.0871884301,0,.996191859); State.FarmCFrame=CFrame.new(-4710.042,845.276,-1927.307); CommF("requestEntrance",Vector3.new(-4607.82275,872.54248,-1667.55688))
        elseif lv >= 475 and lv <= 524 then State.FarmMon="Shanda";           State.LevelQuest=2; State.QuestName="SkyExp1Quest";     State.QuestCFrame=CFrame.new(-7859.09814,5544.19043,-381.476196,-0.422592998,0,.906319618,0,1,0,-0.906319618,0,-0.422592998); State.FarmCFrame=CFrame.new(-7678.489,5566.403,-497.215); CommF("requestEntrance",Vector3.new(-7894.6176757813,5547.1416015625,-380.29119873047))
        elseif lv >= 525 and lv <= 549 then State.FarmMon="Royal Squad";      State.LevelQuest=1; State.QuestName="SkyExp2Quest";     State.QuestCFrame=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); State.FarmCFrame=CFrame.new(-7624.252,5658.133,-1467.354)
        elseif lv >= 550 and lv <= 624 then State.FarmMon="Royal Soldier";    State.LevelQuest=2; State.QuestName="SkyExp2Quest";     State.QuestCFrame=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); State.FarmCFrame=CFrame.new(-7836.753,5645.664,-1790.623)
        elseif lv >= 625 and lv <= 649 then State.FarmMon="Galley Pirate";    State.LevelQuest=1; State.QuestName="FountainQuest";    State.QuestCFrame=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-0.996196866,0,.087131381); State.FarmCFrame=CFrame.new(5551.021,78.901,3930.412)
        elseif lv >= 650                then State.FarmMon="Galley Captain";   State.LevelQuest=2; State.QuestName="FountainQuest";    State.QuestCFrame=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-0.996196866,0,.087131381); State.FarmCFrame=CFrame.new(5441.951,42.502,4950.093)
        end

    -- ════ WORLD 2 ════
    elseif World2 then
        if     lv >= 700  and lv <= 724  then State.FarmMon="Raider";             State.LevelQuest=1; State.QuestName="Area1Quest";        State.QuestCFrame=CFrame.new(-429.543518,71.7699966,1836.18188,-0.22495985,0,-0.974368095,0,1,0,.974368095,0,-0.22495985); State.FarmCFrame=CFrame.new(-728.326,52.779,2345.770)
        elseif lv >= 725  and lv <= 774  then State.FarmMon="Mercenary";          State.LevelQuest=2; State.QuestName="Area1Quest";        State.QuestCFrame=CFrame.new(-429.543518,71.7699966,1836.18188,-0.22495985,0,-0.974368095,0,1,0,.974368095,0,-0.22495985); State.FarmCFrame=CFrame.new(-1004.324,80.158,1424.619)
        elseif lv >= 775  and lv <= 799  then State.FarmMon="Swan Pirate";        State.LevelQuest=1; State.QuestName="Area2Quest";        State.QuestCFrame=CFrame.new(638.43811,71.769989,918.282898,.139203906,0,.99026376,0,1,0,-0.99026376,0,.139203906); State.FarmCFrame=CFrame.new(1068.664,137.614,1322.106)
        elseif lv >= 800  and lv <= 874  then State.FarmMon="Factory Staff";      State.LevelQuest=2; State.QuestName="Area2Quest";        State.QuestCFrame=CFrame.new(632.698608,73.1055908,918.666321,-0.0319722369,8.96074881e-10,-0.999488771,1.36326533e-10,1,8.92172336e-10,.999488771,-1.07732087e-10,-0.0319722369); State.FarmCFrame=CFrame.new(73.078,81.863,-27.470)
        elseif lv >= 875  and lv <= 899  then State.FarmMon="Marine Lieutenant";  State.LevelQuest=1; State.QuestName="MarineQuest3";      State.QuestCFrame=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-0.500031412,0,.866007268); State.FarmCFrame=CFrame.new(-2821.372,75.897,-3070.089)
        elseif lv >= 900  and lv <= 949  then State.FarmMon="Marine Captain";     State.LevelQuest=2; State.QuestName="MarineQuest3";      State.QuestCFrame=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-0.500031412,0,.866007268); State.FarmCFrame=CFrame.new(-1861.231,80.176,-3254.697)
        elseif lv >= 950  and lv <= 974  then State.FarmMon="Zombie";             State.LevelQuest=1; State.QuestName="ZombieQuest";       State.QuestCFrame=CFrame.new(-5497.06152,47.5923004,-795.237061,-0.29242146,0,-0.95628953,0,1,0,.95628953,0,-0.29242146); State.FarmCFrame=CFrame.new(-5657.776,78.969,-928.687)
        elseif lv >= 975  and lv <= 999  then State.FarmMon="Vampire";            State.LevelQuest=2; State.QuestName="ZombieQuest";       State.QuestCFrame=CFrame.new(-5497.06152,47.5923004,-795.237061,-0.29242146,0,-0.95628953,0,1,0,.95628953,0,-0.29242146); State.FarmCFrame=CFrame.new(-6037.667,32.184,-1340.659)
        elseif lv >= 1000 and lv <= 1049 then State.FarmMon="Snow Trooper";      State.LevelQuest=1; State.QuestName="SnowMountainQuest"; State.QuestCFrame=CFrame.new(609.858826,400.119904,-5372.25928,-0.374604106,0,.92718488,0,1,0,-0.92718488,0,-0.374604106); State.FarmCFrame=CFrame.new(549.147,427.387,-5563.698)
        elseif lv >= 1050 and lv <= 1099 then State.FarmMon="Winter Warrior";    State.LevelQuest=2; State.QuestName="SnowMountainQuest"; State.QuestCFrame=CFrame.new(609.858826,400.119904,-5372.25928,-0.374604106,0,.92718488,0,1,0,-0.92718488,0,-0.374604106); State.FarmCFrame=CFrame.new(1142.745,475.639,-5199.416)
        elseif lv >= 1100 and lv <= 1124 then State.FarmMon="Lab Subordinate";   State.LevelQuest=1; State.QuestName="IceSideQuest";      State.QuestCFrame=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-0.891015649,0,1,0,.891015649,0,.453972578); State.FarmCFrame=CFrame.new(-5707.471,15.951,-4513.392)
        elseif lv >= 1125 and lv <= 1174 then State.FarmMon="Horned Warrior";    State.LevelQuest=2; State.QuestName="IceSideQuest";      State.QuestCFrame=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-0.891015649,0,1,0,.891015649,0,.453972578); State.FarmCFrame=CFrame.new(-6341.366,15.951,-5723.162)
        elseif lv >= 1175 and lv <= 1199 then State.FarmMon="Magma Ninja";       State.LevelQuest=1; State.QuestName="FireSideQuest";     State.QuestCFrame=CFrame.new(-5428.03174,15.0622921,-5299.43457,-0.882952213,0,.469463557,0,1,0,-0.469463557,0,-0.882952213); State.FarmCFrame=CFrame.new(-5449.672,76.658,-5808.200)
        elseif lv >= 1200 and lv <= 1249 then State.FarmMon="Lava Pirate";       State.LevelQuest=2; State.QuestName="FireSideQuest";     State.QuestCFrame=CFrame.new(-5428.03174,15.0622921,-5299.43457,-0.882952213,0,.469463557,0,1,0,-0.469463557,0,-0.882952213); State.FarmCFrame=CFrame.new(-4857.562,74.651,-5905.487)
        elseif lv >= 1250 and lv <= 1274 then State.FarmMon="Water Fighter";     State.LevelQuest=1; State.QuestName="WaterQuest";        State.QuestCFrame=CFrame.new(-3397.58862,239.007935,-10542.418,-0.469480276,0,.882960856,0,1,0,-0.882960856,0,-0.469480276); State.FarmCFrame=CFrame.new(-3385,239,-10542)
        elseif lv >= 1275 and lv <= 1324 then State.FarmMon="Tide Keeper";       State.LevelQuest=2; State.QuestName="WaterQuest";        State.QuestCFrame=CFrame.new(-3397.58862,239.007935,-10542.418,-0.469480276,0,.882960856,0,1,0,-0.882960856,0,-0.469480276); State.FarmCFrame=CFrame.new(-3500,300,-10800)
        elseif lv >= 1325 and lv <= 1374 then State.FarmMon="Galley Pirate";     State.LevelQuest=1; State.QuestName="FountainQuest";     State.QuestCFrame=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-0.996196866,0,.087131381); State.FarmCFrame=CFrame.new(5551.021,78.901,3930.412)
        elseif lv >= 1375                then State.FarmMon="Galley Captain";     State.LevelQuest=2; State.QuestName="FountainQuest";     State.QuestCFrame=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-0.996196866,0,.087131381); State.FarmCFrame=CFrame.new(5441.951,42.502,4950.093)
        end

    -- ════ WORLD 3 ════
    elseif World3 then
        if     lv >= 1500 and lv <= 1524 then State.FarmMon="Jungle Pirate";     State.LevelQuest=1; State.QuestName="ForestQuest";      State.QuestCFrame=CFrame.new(-12289.0517578125,331.77392578125,-10577.2734375); State.FarmCFrame=CFrame.new(-11778,426,-10592)
        elseif lv >= 1525 and lv <= 1574 then State.FarmMon="Forest Pirate";     State.LevelQuest=2; State.QuestName="ForestQuest";      State.QuestCFrame=CFrame.new(-12289.0517578125,331.77392578125,-10577.2734375); State.FarmCFrame=CFrame.new(-13446,413,-7760)
        elseif lv >= 1575 and lv <= 1624 then State.FarmMon="Mythological Pirate";State.LevelQuest=1;State.QuestName="MythQuest";        State.QuestCFrame=CFrame.new(-13650,584,-6987); State.FarmCFrame=CFrame.new(-13510,584,-6987)
        elseif lv >= 1625 and lv <= 1674 then State.FarmMon="Musketeer Pirate";  State.LevelQuest=2; State.QuestName="MythQuest";        State.QuestCFrame=CFrame.new(-13650,584,-6987); State.FarmCFrame=CFrame.new(-13282,496,-9565)
        elseif lv >= 1675 and lv <= 1724 then State.FarmMon="Fishman Raider";    State.LevelQuest=1; State.QuestName="FishDeepQuest";    State.QuestCFrame=CFrame.new(-10941,332,-8760); State.FarmCFrame=CFrame.new(-10941,332,-8760)
        elseif lv >= 1725 and lv <= 1799 then State.FarmMon="Fishman Captain";   State.LevelQuest=2; State.QuestName="FishDeepQuest";    State.QuestCFrame=CFrame.new(-10941,332,-8760); State.FarmCFrame=CFrame.new(-11035,332,-9087)
        elseif lv >= 1800 and lv <= 1849 then State.FarmMon="Reborn Skeleton";   State.LevelQuest=1; State.QuestName="WyperQuest";       State.QuestCFrame=CFrame.new(-8764,142,5963); State.FarmCFrame=CFrame.new(-8764,142,5963)
        elseif lv >= 1850 and lv <= 1924 then State.FarmMon="Living Zombie";     State.LevelQuest=2; State.QuestName="WyperQuest";       State.QuestCFrame=CFrame.new(-8764,142,5963); State.FarmCFrame=CFrame.new(-10227,421,6161)
        elseif lv >= 1925 and lv <= 1974 then State.FarmMon="Demonic Soul";      State.LevelQuest=1; State.QuestName="DemonicQuest";     State.QuestCFrame=CFrame.new(-9579,6,6194); State.FarmCFrame=CFrame.new(-9579,6,6194)
        elseif lv >= 1975 and lv <= 2024 then State.FarmMon="Peanut Scout";      State.LevelQuest=1; State.QuestName="PeanutQuest";      State.QuestCFrame=CFrame.new(-1993,187,-10103); State.FarmCFrame=CFrame.new(-1993,187,-10103)
        elseif lv >= 2025 and lv <= 2074 then State.FarmMon="Peanut President";  State.LevelQuest=2; State.QuestName="PeanutQuest";      State.QuestCFrame=CFrame.new(-1993,187,-10103); State.FarmCFrame=CFrame.new(-2215,159,-10474)
        elseif lv >= 2075 and lv <= 2124 then State.FarmMon="Ice Cream Chef";    State.LevelQuest=1; State.QuestName="CakeQuest";        State.QuestCFrame=CFrame.new(-877,118,-11032); State.FarmCFrame=CFrame.new(-877,118,-11032)
        elseif lv >= 2125 and lv <= 2174 then State.FarmMon="Ice Cream Commander";State.LevelQuest=2;State.QuestName="CakeQuest";        State.QuestCFrame=CFrame.new(-877,118,-11032); State.FarmCFrame=CFrame.new(-877,118,-11032)
        elseif lv >= 2175 and lv <= 2224 then State.FarmMon="Cookie Crafter";    State.LevelQuest=1; State.QuestName="CakeFarm1";        State.QuestCFrame=CFrame.new(-2021,38,-12028); State.FarmCFrame=CFrame.new(-2021,38,-12028)
        elseif lv >= 2225 and lv <= 2274 then State.FarmMon="Cake Guard";        State.LevelQuest=2; State.QuestName="CakeFarm1";        State.QuestCFrame=CFrame.new(-2021,38,-12028); State.FarmCFrame=CFrame.new(-2024,38,-12026)
        elseif lv >= 2275 and lv <= 2349 then State.FarmMon="Baking Staff";      State.LevelQuest=1; State.QuestName="CakeFarm2";        State.QuestCFrame=CFrame.new(-1932,38,-12848); State.FarmCFrame=CFrame.new(-1932,38,-12848)
        elseif lv >= 2350 and lv <= 2449 then State.FarmMon="Head Baker";        State.LevelQuest=2; State.QuestName="CakeFarm2";        State.QuestCFrame=CFrame.new(-1932,38,-12848); State.FarmCFrame=CFrame.new(-1932,38,-12848)
        elseif lv >= 2450 and lv <= 2524 then State.FarmMon="Cocoa Warrior";     State.LevelQuest=1; State.QuestName="CakeFarm3";        State.QuestCFrame=CFrame.new(95,73,-12309); State.FarmCFrame=CFrame.new(95,73,-12309)
        elseif lv >= 2525 and lv <= 2624 then State.FarmMon="Chocolate Bar Battler";State.LevelQuest=2;State.QuestName="CakeFarm3";     State.QuestCFrame=CFrame.new(95,73,-12309); State.FarmCFrame=CFrame.new(647,42,-12401)
        elseif lv >= 2625 and lv <= 2699 then State.FarmMon="Sweet Thief";       State.LevelQuest=1; State.QuestName="CakeFarm4";        State.QuestCFrame=CFrame.new(116,36,-12478); State.FarmCFrame=CFrame.new(116,36,-12478)
        elseif lv >= 2700                then State.FarmMon="Candy Rebel";        State.LevelQuest=2; State.QuestName="CakeFarm4";        State.QuestCFrame=CFrame.new(116,36,-12478); State.FarmCFrame=CFrame.new(47,61,-12889)
        end
    end
end

-- ╔══════════════════════════════════╗
-- ║  QUEST LOGIC                    ║
-- ╚══════════════════════════════════╝
local function HasQuest()
    local ok, visible = pcall(function()
        return LP.PlayerGui.Main.Quest.Visible
    end)
    return ok and visible
end

local function AcceptQuest()
    if not State.QuestName or not State.QuestCFrame then return end
    -- TP to quest NPC
    HardTP(State.QuestCFrame)
    task.wait(0.8)
    -- Fire accept via CommF_ (the real BF remote)
    CommF("AskForQuest", State.QuestName, State.LevelQuest)
    task.wait(0.3)
end

-- ╔══════════════════════════════════╗
-- ║  MOB FINDER                     ║
-- ╚══════════════════════════════════╝
local function FindMob(name)
    for _, mob in ipairs(workspace.Enemies:GetChildren()) do
        if mob.Name == name then
            local mHum = mob:FindFirstChildOfClass("Humanoid")
            local mHRP = mob:FindFirstChild("HumanoidRootPart")
            if mHum and mHRP and mHum.Health > 0 then
                return mob
            end
        end
    end
    -- also check RS (some mobs spawn there temporarily)
    for _, mob in ipairs(RS:GetChildren()) do
        if mob.Name == name and mob:IsA("Model") then
            local mHum = mob:FindFirstChildOfClass("Humanoid")
            local mHRP = mob:FindFirstChild("HumanoidRootPart")
            if mHum and mHRP and mHum.Health > 0 then
                return mob
            end
        end
    end
    return nil
end

-- ╔══════════════════════════════════╗
-- ║  ATTACK MOB                     ║
-- ╚══════════════════════════════════╝
local function AttackMob(mob)
    if not mob then return end
    local mHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mHRP then return end

    State.PosMon = mHRP.Position
    BringMobs()

    -- Lock position attribute (same as reference script)
    if not mob:GetAttribute("Locked") then
        mob:SetAttribute("Locked", mHRP.CFrame)
    end

    -- TP on top of mob (exact same offset as f.Kill in reference)
    local c = GetChar()
    local equippedTool = c and c:FindFirstChildOfClass("Tool")
    local toolTip = equippedTool and equippedTool.ToolTip or ""

    if toolTip == "Blox Fruit" then
        _tp((mHRP.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0))
    else
        _tp((mHRP.CFrame * CFrame.new(0, 30, 0)) * CFrame.Angles(0, math.rad(180), 0))
    end

    -- Use skills Z X C
    UseSkill("Blox Fruit", "Z")
    task.wait(0.05)
    UseSkill("Blox Fruit", "X")
    task.wait(0.05)
    UseSkill("Melee",      "Z")
    task.wait(0.05)
    UseSkill("Sword",      "Z")
end

-- ╔══════════════════════════════════╗
-- ║  AUTO FARM LOOP                 ║
-- ╚══════════════════════════════════╝
local function StartAutoFarm()
    return task.spawn(function()
        while State.AutoFarm do
            pcall(function()
                if not IsAlive() then task.wait(2) return end

                -- Refresh quest/mob data for current level
                CheckQuest()

                -- Accept quest if needed
                if not HasQuest() and State.QuestName then
                    AcceptQuest()
                end

                -- Find and attack mob
                local mob = State.FarmMon and FindMob(State.FarmMon)
                if mob then
                    AttackMob(mob)
                elseif State.FarmCFrame then
                    -- No mob found → TP to spawn area and wait
                    _tp(State.FarmCFrame)
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ╔══════════════════════════════════╗
-- ║  AUTO RAID                      ║
-- ╚══════════════════════════════════╝
-- Raids in BF work by: get fragment → go to Mysterious Scientist → start raid → farm mobs
local RaidNPCPos = {
    World1 = CFrame.new(897.6, 15.0, 1724.0),   -- Mysterious Scientist Sea 1
    World2 = CFrame.new(-1588.0, 52.0, -577.0),  -- Sea 2
    World3 = CFrame.new(5839.0, 96.0, -1270.0),  -- Sea 3
}
local function GetRaidNPC()
    if World1 then return RaidNPCPos.World1
    elseif World2 then return RaidNPCPos.World2
    else return RaidNPCPos.World3 end
end

local function StartAutoRaid()
    return task.spawn(function()
        while State.AutoRaid do
            pcall(function()
                if not IsAlive() then task.wait(2) return end

                -- Step 1: go to Mysterious Scientist, buy/start raid
                HardTP(GetRaidNPC())
                task.wait(0.8)
                CommF("NPCTalk", "Mysterious Scientist")
                task.wait(0.3)
                CommF("StartRaid", LP.Data.Level.Value) -- server decides raid tier
                task.wait(1)

                -- Step 2: fire any raid proximity prompts
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        local t = (v.ActionText .. v.ObjectText):lower()
                        if t:find("raid") or t:find("enter") or t:find("start") then
                            FirePP(v)
                            break
                        end
                    end
                end
                task.wait(1)

                -- Step 3: farm raid mobs for 90 seconds
                local raidTimer = tick()
                while tick() - raidTimer < 90 and State.AutoRaid do
                    if not IsAlive() then break end
                    -- Find raid enemy (any mob in workspace.Enemies during raid)
                    local mob = nil
                    local bestDist = 400
                    local hrp = GetHRP()
                    if hrp then
                        for _, m in ipairs(workspace.Enemies:GetChildren()) do
                            local mH = m:FindFirstChildOfClass("Humanoid")
                            local mR = m:FindFirstChild("HumanoidRootPart")
                            if mH and mR and mH.Health > 0 then
                                local d = (mR.Position - hrp.Position).Magnitude
                                if d < bestDist then bestDist=d; mob=m end
                            end
                        end
                    end
                    if mob then AttackMob(mob) end
                    task.wait(0.1)
                end

                task.wait(5) -- cooldown before next raid
            end)
            task.wait(1)
        end
    end)
end

-- ╔══════════════════════════════════╗
-- ║  ANTI-AFK                       ║
-- ╚══════════════════════════════════╝
local function StartAntiAFK()
    return task.spawn(function()
        while State.AntiAFK do
            task.wait(math.random(55, 85))
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end)
end

-- ╔══════════════════════════════════╗
-- ║  SPEED HACK                     ║
-- ╚══════════════════════════════════╝
local function ApplySpeed(on)
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = on and 80 or 16
        hum.JumpPower = on and 75 or 50
    end
end

LP.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    if State.SpeedHack then
        local h = c:WaitForChild("Humanoid")
        h.WalkSpeed = 80
        h.JumpPower = 75
    end
    if State.AutoFarm then
        -- re-apply body velocity
        local hrp = c:WaitForChild("HumanoidRootPart")
        local bv = Instance.new("BodyVelocity")
        bv.Name      = "BeastClip"
        bv.MaxForce  = Vector3.new(1e5,1e5,1e5)
        bv.Velocity  = Vector3.new(0,0,0)
        bv.Parent    = hrp
    end
end)

-- ╔══════════════════════════════════╗
-- ║  TOGGLE HANDLER                 ║
-- ╚══════════════════════════════════╝
local function SetToggle(key, val, cb)
    State[key] = val
    -- update checkbox
    if cb then
        cb.BackgroundColor3 = val and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
        cb.Text = val and "✓" or ""
    end

    Kill(key)
    if val then
        if key == "AutoFarm"  then Threads[key] = StartAutoFarm()
        elseif key == "AutoRaid"  then Threads[key] = StartAutoRaid()
        elseif key == "AntiAFK"  then Threads[key] = StartAntiAFK()
        elseif key == "SpeedHack" then ApplySpeed(true)
        end
    else
        if key == "SpeedHack" then ApplySpeed(false) end
    end
end

-- ╔══════════════════════════════════╗
-- ║  GUI                            ║
-- ╚══════════════════════════════════╝
local old = LP.PlayerGui:FindFirstChild("BeastHubV2")
if old then old:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name           = "BeastHubV2"
GUI.ResetOnSpawn   = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent         = LP.PlayerGui

-- ── MAIN FRAME ──
local Win = Instance.new("Frame")
Win.Name             = "Window"
Win.Size             = UDim2.new(0, 680, 0, 440)
Win.Position         = UDim2.new(0.5,-340,0.5,-220)
Win.BackgroundColor3 = Color3.fromRGB(10,10,18)
Win.BorderSizePixel  = 0
Win.Active           = true
Win.Draggable        = true
Win.ClipsDescendants = true
Win.Parent           = GUI

Instance.new("UICorner", Win).CornerRadius = UDim.new(0,12)

local Stroke = Instance.new("UIStroke")
Stroke.Color     = Color3.fromRGB(138,43,226)
Stroke.Thickness = 1.5
Stroke.Parent    = Win

-- ── TOPBAR ──
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1,0,0,48)
TopBar.BackgroundColor3 = Color3.fromRGB(18,18,28)
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Win

local TG = Instance.new("UIGradient")
TG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90,20,160)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(40,10,80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,28)),
})
TG.Rotation = 90
TG.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Text = "  ⚡  the_real_Beast Hub  :  Blox Fruits"
Title.Size = UDim2.new(0.75,0,1,0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(200,140,255)
Title.Font       = Enum.Font.GothamBold
Title.TextSize   = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent     = TopBar

local function HeaderBtn(txt, bg, xOff)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0,38,0,28)
    b.Position         = UDim2.new(1,xOff,0.5,-14)
    b.BackgroundColor3 = bg
    b.Text             = txt
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 14
    b.BorderSizePixel  = 0
    b.Parent           = TopBar
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end
local CloseBtn = HeaderBtn("✕", Color3.fromRGB(180,30,60), -44)
local MinBtn   = HeaderBtn("─", Color3.fromRGB(60,60,80),  -88)
CloseBtn.MouseButton1Click:Connect(function() Win.Visible = not Win.Visible end)
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Win.Size = minimized and UDim2.new(0,680,0,48) or UDim2.new(0,680,0,440)
end)

-- ── SIDEBAR ──
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0,180,1,-48)
Sidebar.Position         = UDim2.new(0,0,0,48)
Sidebar.BackgroundColor3 = Color3.fromRGB(14,14,22)
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Win

local SearchBox = Instance.new("TextBox")
SearchBox.Size              = UDim2.new(0.9,0,0,30)
SearchBox.Position          = UDim2.new(0.05,0,0,8)
SearchBox.BackgroundColor3  = Color3.fromRGB(22,22,34)
SearchBox.TextColor3        = Color3.fromRGB(220,220,220)
SearchBox.PlaceholderText   = "🔍  Search section or fu"
SearchBox.PlaceholderColor3 = Color3.fromRGB(100,100,120)
SearchBox.Text              = ""
SearchBox.Font              = Enum.Font.Gotham
SearchBox.TextSize          = 12
SearchBox.ClearTextOnFocus  = false
SearchBox.BorderSizePixel   = 0
SearchBox.TextXAlignment    = Enum.TextXAlignment.Left
SearchBox.Parent            = Sidebar
Instance.new("UICorner",SearchBox).CornerRadius = UDim.new(0,6)
local SP = Instance.new("UIPadding"); SP.PaddingLeft = UDim.new(0,8); SP.Parent = SearchBox

local SideList = Instance.new("Frame")
SideList.Size             = UDim2.new(1,0,1,-52)
SideList.Position         = UDim2.new(0,0,0,48)
SideList.BackgroundTransparency = 1
SideList.Parent           = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding   = UDim.new(0,2)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent    = SideList

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop   = UDim.new(0,4)
SidePad.PaddingLeft  = UDim.new(0,6)
SidePad.PaddingRight = UDim.new(0,6)
SidePad.Parent       = SideList

-- ── CONTENT AREA ──
local ContentArea = Instance.new("Frame")
ContentArea.Name             = "ContentArea"
ContentArea.Size             = UDim2.new(1,-180,1,-48)
ContentArea.Position         = UDim2.new(0,180,0,48)
ContentArea.BackgroundColor3 = Color3.fromRGB(12,12,20)
ContentArea.BorderSizePixel  = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent           = Win

-- divider
local Div = Instance.new("Frame")
Div.Size             = UDim2.new(0,1,1,-48)
Div.Position         = UDim2.new(0,180,0,48)
Div.BackgroundColor3 = Color3.fromRGB(80,30,140)
Div.BorderSizePixel  = 0
Div.Parent           = Win

-- ── STATUS BAR ──
local SBar = Instance.new("Frame")
SBar.Size             = UDim2.new(1,-180,0,24)
SBar.Position         = UDim2.new(0,180,1,-24)
SBar.BackgroundColor3 = Color3.fromRGB(8,8,14)
SBar.BorderSizePixel  = 0
SBar.Parent           = Win

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size               = UDim2.new(1,-10,1,0)
StatusLbl.Position           = UDim2.new(0,10,0,0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3         = Color3.fromRGB(120,100,170)
StatusLbl.Font               = Enum.Font.Gotham
StatusLbl.TextSize           = 11
StatusLbl.TextXAlignment     = Enum.TextXAlignment.Left
StatusLbl.Parent             = SBar

local VerLbl = Instance.new("TextLabel")
VerLbl.Size               = UDim2.new(0,220,1,0)
VerLbl.Position           = UDim2.new(1,-225,0,0)
VerLbl.BackgroundTransparency = 1
VerLbl.TextColor3         = Color3.fromRGB(80,70,110)
VerLbl.Font               = Enum.Font.Gotham
VerLbl.TextSize           = 11
VerLbl.Text               = "v2.0-BeastHub | RightAlt = toggle"
VerLbl.TextXAlignment     = Enum.TextXAlignment.Right
VerLbl.Parent             = SBar

-- ── GUI HELPERS ──
local function MakeScrollFrame()
    local sf = Instance.new("ScrollingFrame")
    sf.Size                   = UDim2.new(1,0,1,-24)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 4
    sf.ScrollBarImageColor3   = Color3.fromRGB(138,43,226)
    sf.CanvasSize             = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    sf.Visible                = false
    sf.Parent                 = ContentArea
    return sf
end

local function SectionLabel(parent, text, y)
    local l = Instance.new("TextLabel")
    l.Text          = text
    l.Size          = UDim2.new(1,-20,0,32)
    l.Position      = UDim2.new(0,10,0,y)
    l.BackgroundTransparency = 1
    l.TextColor3    = Color3.fromRGB(138,43,226)
    l.Font          = Enum.Font.GothamBold
    l.TextSize      = 14
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Parent        = parent
    return l
end

local function CheckRow(parent, label, key, y)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,-20,0,46)
    row.Position         = UDim2.new(0,10,0,y)
    row.BackgroundColor3 = Color3.fromRGB(18,18,30)
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(28,20,45)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(18,18,30)}):Play()
    end)

    local lbl = Instance.new("TextLabel")
    lbl.Text          = label
    lbl.Size          = UDim2.new(1,-60,1,0)
    lbl.Position      = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3    = Color3.fromRGB(215,215,230)
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent        = row

    local cb = Instance.new("TextButton")
    cb.Size             = UDim2.new(0,22,0,22)
    cb.Position         = UDim2.new(1,-36,0.5,-11)
    cb.BackgroundColor3 = State[key] and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
    cb.Text             = State[key] and "✓" or ""
    cb.TextColor3       = Color3.fromRGB(255,255,255)
    cb.Font             = Enum.Font.GothamBold
    cb.TextSize         = 13
    cb.BorderSizePixel  = 0
    cb.Parent           = row
    Instance.new("UICorner",cb).CornerRadius = UDim.new(0,4)
    local cbs = Instance.new("UIStroke")
    cbs.Color=Color3.fromRGB(100,50,180); cbs.Thickness=1.5; cbs.Parent=cb

    local function onToggle()
        SetToggle(key, not State[key], cb)
    end
    cb.MouseButton1Click:Connect(onToggle)
    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then onToggle() end
    end)
    return row
end

-- ╔══════════════════════════════════╗
-- ║  SECTION CONTENT FRAMES         ║
-- ╚══════════════════════════════════╝
local Sections   = {"Farm","Config","Raid","Misc"}
local SideButtons = {}
local Contents   = {}
local CurSection = "Farm"

local function ShowSection(name)
    CurSection = name
    for _, f in pairs(Contents) do f.Visible = false end
    if Contents[name] then Contents[name].Visible = true end
    for n, b in pairs(SideButtons) do
        if n == name then
            b.BackgroundColor3 = Color3.fromRGB(35,20,60)
            b.TextColor3 = Color3.fromRGB(200,140,255)
        else
            b.BackgroundColor3 = Color3.fromRGB(14,14,22)
            b.TextColor3 = Color3.fromRGB(180,180,200)
        end
    end
end

-- ── FARM section ──
local FarmF = MakeScrollFrame()
SectionLabel(FarmF,"Farm",8)
CheckRow(FarmF,"Auto Farm Level",   "AutoFarm",  48)
CheckRow(FarmF,"Bring Mobs",        "BringMobs", 100)
SectionLabel(FarmF,"Quest / Misc",  160)
CheckRow(FarmF,"Auto Quest",        "AutoQuest", 200)
CheckRow(FarmF,"Auto Collect Fruits","AutoCollect",252)
Contents["Farm"] = FarmF

-- ── RAID section ──
local RaidF = MakeScrollFrame()
SectionLabel(RaidF,"Raid",8)
CheckRow(RaidF,"Auto Raid",         "AutoRaid",  48)
Contents["Raid"] = RaidF

-- ── CONFIG section ──
local CfgF = MakeScrollFrame()
SectionLabel(CfgF,"Config",8)
CheckRow(CfgF,"Speed Hack",         "SpeedHack", 48)
CheckRow(CfgF,"Anti AFK",           "AntiAFK",   100)

-- Level display
local LvInfo = Instance.new("TextLabel")
LvInfo.Size               = UDim2.new(1,-20,0,28)
LvInfo.Position           = UDim2.new(0,10,0,158)
LvInfo.BackgroundTransparency = 1
LvInfo.TextColor3         = Color3.fromRGB(160,130,220)
LvInfo.Font               = Enum.Font.Gotham
LvInfo.TextSize           = 13
LvInfo.TextXAlignment     = Enum.TextXAlignment.Left
LvInfo.Parent             = CfgF

-- Mob info
local MobInfo = Instance.new("TextLabel")
MobInfo.Size              = UDim2.new(1,-20,0,28)
MobInfo.Position          = UDim2.new(0,10,0,188)
MobInfo.BackgroundTransparency = 1
MobInfo.TextColor3        = Color3.fromRGB(130,180,130)
MobInfo.Font              = Enum.Font.Gotham
MobInfo.TextSize          = 13
MobInfo.TextXAlignment    = Enum.TextXAlignment.Left
MobInfo.Parent            = CfgF

Contents["Config"] = CfgF

-- ── MISC section ──
local MiscF = MakeScrollFrame()
SectionLabel(MiscF,"Miscellanea",8)

-- Low CPU btn
local LcBtn = Instance.new("TextButton")
LcBtn.Size             = UDim2.new(0.9,0,0,38)
LcBtn.Position         = UDim2.new(0.05,0,0,48)
LcBtn.BackgroundColor3 = Color3.fromRGB(80,30,140)
LcBtn.Text             = "⚡ Low CPU Mode"
LcBtn.TextColor3       = Color3.fromRGB(255,255,255)
LcBtn.Font             = Enum.Font.GothamBold
LcBtn.TextSize         = 13
LcBtn.BorderSizePixel  = 0
LcBtn.Parent           = MiscF
Instance.new("UICorner",LcBtn).CornerRadius = UDim.new(0,6)
LcBtn.MouseButton1Click:Connect(function()
    -- Low CPU mode (port from reference LowCpu())
    local ws = workspace
    local lt = Lighting
    ws.Terrain.WaterWaveSize   = 0
    ws.Terrain.WaterWaveSpeed  = 0
    ws.Terrain.WaterReflectance= 0
    ws.Terrain.WaterTransparency = 0
    lt.GlobalShadows = false
    lt.FogEnd        = 9e9
    lt.Brightness    = 0
    settings().Rendering.QualityLevel = "Level01"
    for _, v in ipairs(game:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpotLight") then
                v.Enabled = false
            elseif v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end)
    end
    LcBtn.BackgroundColor3 = Color3.fromRGB(40,180,100)
    LcBtn.Text = "✓ Low CPU Active"
end)

-- ServerHop btn
local ShBtn = Instance.new("TextButton")
ShBtn.Size             = UDim2.new(0.9,0,0,38)
ShBtn.Position         = UDim2.new(0.05,0,0,96)
ShBtn.BackgroundColor3 = Color3.fromRGB(60,30,100)
ShBtn.Text             = "🔀 Server Hop"
ShBtn.TextColor3       = Color3.fromRGB(255,255,255)
ShBtn.Font             = Enum.Font.GothamBold
ShBtn.TextSize         = 13
ShBtn.BorderSizePixel  = 0
ShBtn.Parent           = MiscF
Instance.new("UICorner",ShBtn).CornerRadius = UDim.new(0,6)
ShBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local TS = game:GetService("TeleportService")
        for i = math.random(1,50), 100 do
            local ok, servers = pcall(function()
                return RS.__ServerBrowser:InvokeServer(i)
            end)
            if ok and servers then
                for jobId, data in next, servers do
                    if type(data) == "table" and tonumber(data.Count) and tonumber(data.Count) < 12 then
                        TS:TeleportToPlaceInstance(game.PlaceId, jobId)
                        return
                    end
                end
            end
        end
    end)
end)

Contents["Misc"] = MiscF

-- ── SIDEBAR BUILD ──
local AllSections = {
    {Name="Farm"}, {Name="Config"}, {Name="Raid"}, {Name="Misc"}
}
for _, sec in ipairs(AllSections) do
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1,0,0,34)
    b.BackgroundColor3 = Color3.fromRGB(14,14,22)
    b.Text             = "  " .. sec.Name
    b.TextColor3       = Color3.fromRGB(180,180,200)
    b.Font             = Enum.Font.Gotham
    b.TextSize         = 13
    b.TextXAlignment   = Enum.TextXAlignment.Left
    b.BorderSizePixel  = 0
    b.Parent           = SideList
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)

    b.MouseEnter:Connect(function()
        if CurSection ~= sec.Name then
            TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(25,15,45)}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if CurSection ~= sec.Name then
            TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(14,14,22)}):Play()
        end
    end)
    b.MouseButton1Click:Connect(function() ShowSection(sec.Name) end)
    SideButtons[sec.Name] = b
end

-- ── KEYBIND ──
UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.RightAlt then
        Win.Visible = not Win.Visible
    end
end)

-- ── STATUS UPDATE ──
task.spawn(function()
    while true do
        pcall(function()
            CheckQuest()
            local hum = GetHum()
            local hp  = hum and math.floor(hum.Health) or 0
            local maxhp = hum and math.floor(hum.MaxHealth) or 0
            local lv  = MyLevel()

            StatusLbl.Text = string.format(
                "Lv: %s | HP: %s/%s | Mob: %s | Farm: %s | Raid: %s",
                lv, hp, maxhp,
                State.FarmMon or "?",
                State.AutoFarm and "ON" or "OFF",
                State.AutoRaid and "ON" or "OFF"
            )
            LvInfo.Text  = "Level: " .. lv .. " | World: " .. (World1 and "1" or World2 and "2" or "3")
            MobInfo.Text = "Target: " .. (State.FarmMon or "None") .. " | Quest: " .. (State.QuestName or "?")
        end)
        task.wait(1)
    end
end)

-- ── INIT ──
ShowSection("Farm")
Threads.AntiAFK = StartAntiAFK()

print("✅ Beast Hub v2 loaded! RightAlt = toggle GUI")
print("   Auto Farm → picks mob by your level automatically")
print("   Quest = CommF_ AskForQuest (real BF remote)")
