-- ============================================================
--  BEAST HUB v5 — BLOX FRUITS
--  FLUXO: pega missão → mata mobs → terminou → pega de novo
--  FIXES: quest via Data direto | flutua no ar | só fighting style
-- ============================================================

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local TweenSvc = game:GetService("TweenService")
local VIM      = game:GetService("VirtualInputManager")
local UIS      = game:GetService("UserInputService")

local LP   = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()

-- ── WORLD ──
local World1 = game.PlaceId==2753915549 or game.PlaceId==85211729168715
local World2 = game.PlaceId==4442272183 or game.PlaceId==79091703265657
local World3 = game.PlaceId==7449423635 or game.PlaceId==100117331123089

-- ── STATE ──
local S = {
    AutoFarm  = false,
    AutoRaid  = false,
    SpeedHack = false,
    AntiAFK   = false,

    -- preenchido por UpdateQuest()
    FarmMon   = nil,  -- nome do mob
    FarmCF    = nil,  -- CFrame spawn do mob
    QuestCF   = nil,  -- CFrame do NPC de quest
    QuestName = nil,  -- nome interno da quest
    QuestSlot = 1,    -- slot (1 ou 2)
}
local Threads = {}

-- ── HELPERS ──
local function Try(fn) pcall(fn) end
local function GetChar() return LP.Character end
local function GetHRP()  local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive() local h=GetHum();  return h and h.Health > 0 end
local function MyLv()
    local ok,v = pcall(function() return LP.Data.Level.Value end)
    return ok and tonumber(v) or 1
end

-- ── VERIFICAÇÃO DE QUEST ──
-- Usa LP.Data.QuestName.Value -- vazio = sem quest
local function QuestAtiva()
    local ok, v = pcall(function()
        return LP.Data.QuestName.Value
    end)
    return ok and v ~= nil and v ~= ""
end

-- Fecha qualquer diálogo aberto (safety)
local function FecharDialogo()
    Try(function()
        local main = LP.PlayerGui:FindFirstChild("Main")
        if main then
            local dlg = main:FindFirstChild("Dialogue")
            if dlg then dlg.Visible = false end
        end
    end)
end

-- ── TELEPORTE ──
local function TP(cf)
    Try(function()
        local hrp = GetHRP()
        if hrp then hrp.CFrame = cf end
    end)
end

-- ── FLUTUAR (BodyVelocity no eixo Y) ──
local function StartFloat()
    Try(function()
        local hrp = GetHRP()
        if not hrp then return end
        if hrp:FindFirstChild("BeastFloat") then
            hrp.BeastFloat:Destroy()
        end
        local bv = Instance.new("BodyVelocity")
        bv.Name     = "BeastFloat"
        bv.Velocity  = Vector3.new(0,0,0)
        bv.MaxForce  = Vector3.new(0,1e5,0)
        bv.P         = 1e4
        bv.Parent    = hrp
    end)
end
local function StopFloat()
    Try(function()
        local hrp = GetHRP()
        if hrp and hrp:FindFirstChild("BeastFloat") then
            hrp.BeastFloat:Destroy()
        end
    end)
end

-- ── CLIQUE DO MOUSE (fighting style sem skills) ──
local function Click()
    Try(function()
        VIM:SendMouseButtonEvent(0,0,0,true, game,1)
        VIM:SendMouseButtonEvent(0,0,0,false,game,1)
    end)
end

-- ── CommF_ ──
local function CommF(...)
    local args={...}
    pcall(function()
        RS.Remotes.CommF_:InvokeServer(table.unpack(args))
    end)
end

-- ── KILL THREAD ──
local function Kill(k)
    if Threads[k] then pcall(task.cancel,Threads[k]); Threads[k]=nil end
end

-- ╔══════════════════════════════╗
-- ║       QUEST MAP              ║
-- ╚══════════════════════════════╝
local function UpdateQuest()
    local lv = MyLv()
    if World1 then
        if     lv<10  then S.FarmMon="Bandit";             S.QuestName="BanditQuest1";  S.QuestSlot=1; S.QuestCF=CFrame.new(1059.37195,15.4495068,1550.4231,.939700544,0,-.341998369,0,1,0,.341998369,0,.939700544); S.FarmCF=CFrame.new(1045.9626,27.0025,1560.8203)
        elseif lv<15  then S.FarmMon="Monkey";             S.QuestName="JungleQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); S.FarmCF=CFrame.new(-1448.518,67.853,11.465)
        elseif lv<30  then S.FarmMon="Gorilla";            S.QuestName="JungleQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(-1598.08911,35.5501175,153.377838,0,0,1,0,1,0,-1,0,0); S.FarmCF=CFrame.new(-1129.883,40.463,-525.423)
        elseif lv<40  then S.FarmMon="Pirate";             S.QuestName="BuggyQuest1";   S.QuestSlot=1; S.QuestCF=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-.258804798,0,1,0,.258804798,0,.965929627); S.FarmCF=CFrame.new(-1103.513,13.752,3896.091)
        elseif lv<60  then S.FarmMon="Brute";              S.QuestName="BuggyQuest1";   S.QuestSlot=2; S.QuestCF=CFrame.new(-1141.07483,4.10001802,3831.5498,.965929627,0,-.258804798,0,1,0,.258804798,0,.965929627); S.FarmCF=CFrame.new(-1140.083,14.809,4322.921)
        elseif lv<75  then S.FarmMon="Desert Bandit";      S.QuestName="DesertQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-.573571265,0,1,0,.573571265,0,.819155693); S.FarmCF=CFrame.new(924.799,6.448,4481.585)
        elseif lv<90  then S.FarmMon="Desert Officer";     S.QuestName="DesertQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(894.488647,5.14000702,4392.43359,.819155693,0,-.573571265,0,1,0,.573571265,0,.819155693); S.FarmCF=CFrame.new(1608.282,8.614,4371.007)
        elseif lv<100 then S.FarmMon="Snow Bandit";        S.QuestName="SnowQuest";     S.QuestSlot=1; S.QuestCF=CFrame.new(1389.74451,88.1519318,-1298.90796,-.342042685,0,.939684391,0,1,0,-.939684391,0,-.342042685); S.FarmCF=CFrame.new(1354.347,87.272,-1393.946)
        elseif lv<120 then S.FarmMon="Snowman";            S.QuestName="SnowQuest";     S.QuestSlot=2; S.QuestCF=CFrame.new(1389.74451,88.1519318,-1298.90796,-.342042685,0,.939684391,0,1,0,-.939684391,0,-.342042685); S.FarmCF=CFrame.new(1201.641,144.579,-1550.067)
        elseif lv<150 then S.FarmMon="Chief Petty Officer";S.QuestName="MarineQuest2";  S.QuestSlot=1; S.QuestCF=CFrame.new(-5039.58643,27.3500385,4324.68018,0,0,-1,0,1,0,1,0,0); S.FarmCF=CFrame.new(-4881.230,22.652,4273.752)
        elseif lv<175 then S.FarmMon="Sky Bandit";         S.QuestName="SkyQuest";      S.QuestSlot=1; S.QuestCF=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); S.FarmCF=CFrame.new(-4953.207,295.744,-2899.229)
        elseif lv<190 then S.FarmMon="Dark Master";        S.QuestName="SkyQuest";      S.QuestSlot=2; S.QuestCF=CFrame.new(-4839.53027,716.368591,-2619.44165,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); S.FarmCF=CFrame.new(-5259.844,391.397,-2229.035)
        elseif lv<210 then S.FarmMon="Prisoner";           S.QuestName="PrisonerQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(5308.93115,1.65517521,475.120514,-.0894274712,-5.00292918e-09,-.995993316,1.60817859e-09,1,-5.16744869e-09,.995993316,-2.06384709e-09,-.0894274712); S.FarmCF=CFrame.new(5098.973,-0.320,474.237)
        elseif lv<250 then S.FarmMon="Dangerous Prisoner"; S.QuestName="PrisonerQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(5308.93115,1.65517521,475.120514,-.0894274712,-5.00292918e-09,-.995993316,1.60817859e-09,1,-5.16744869e-09,.995993316,-2.06384709e-09,-.0894274712); S.FarmCF=CFrame.new(5654.563,15.633,866.299)
        elseif lv<275 then S.FarmMon="Toga Warrior";       S.QuestName="ColosseumQuest";S.QuestSlot=1; S.QuestCF=CFrame.new(-1580.04663,6.35000277,-2986.47534,-.515037298,0,-.857167721,0,1,0,.857167721,0,-.515037298); S.FarmCF=CFrame.new(-1820.214,51.683,-2740.665)
        elseif lv<300 then S.FarmMon="Gladiator";          S.QuestName="ColosseumQuest";S.QuestSlot=2; S.QuestCF=CFrame.new(-1580.04663,6.35000277,-2986.47534,-.515037298,0,-.857167721,0,1,0,.857167721,0,-.515037298); S.FarmCF=CFrame.new(-1292.838,56.380,-3339.031)
        elseif lv<325 then S.FarmMon="Military Soldier";   S.QuestName="MagmaQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-5313.37012,10.9500084,8515.29395,-.499959469,0,.866048813,0,1,0,-.866048813,0,-.499959469); S.FarmCF=CFrame.new(-5411.164,11.081,8454.292)
        elseif lv<375 then S.FarmMon="Military Spy";       S.QuestName="MagmaQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-5313.37012,10.9500084,8515.29395,-.499959469,0,.866048813,0,1,0,-.866048813,0,-.499959469); S.FarmCF=CFrame.new(-5802.868,86.262,8828.859)
        elseif lv<400 then S.FarmMon="Fishman Warrior";    S.QuestName="FishmanQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(61122.652,18.497,1569.399); S.FarmCF=CFrame.new(60878.300,18.482,1543.757); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<450 then S.FarmMon="Fishman Commando";   S.QuestName="FishmanQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(61122.652,18.497,1569.399); S.FarmCF=CFrame.new(61922.632,18.482,1493.934); CommF("requestEntrance",Vector3.new(61163,11,1819))
        elseif lv<475 then S.FarmMon="God's Guard";        S.QuestName="SkyExp1Quest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-4721.88867,843.874695,-1949.96643,.996191859,0,-.0871884301,0,1,0,.0871884301,0,.996191859); S.FarmCF=CFrame.new(-4710.042,845.276,-1927.307); CommF("requestEntrance",Vector3.new(-4607,872,-1667))
        elseif lv<525 then S.FarmMon="Shanda";             S.QuestName="SkyExp1Quest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-7859.09814,5544.19043,-381.476196,-.422592998,0,.906319618,0,1,0,-.906319618,0,-.422592998); S.FarmCF=CFrame.new(-7678.489,5566.403,-497.215)
        elseif lv<550 then S.FarmMon="Royal Squad";        S.QuestName="SkyExp2Quest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); S.FarmCF=CFrame.new(-7624.252,5658.133,-1467.354)
        elseif lv<625 then S.FarmMon="Royal Soldier";      S.QuestName="SkyExp2Quest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-7906.81592,5634.6626,-1411.99194,0,0,-1,0,1,0,1,0,0); S.FarmCF=CFrame.new(-7836.753,5645.664,-1790.623)
        elseif lv<650 then S.FarmMon="Galley Pirate";      S.QuestName="FountainQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-.996196866,0,.087131381); S.FarmCF=CFrame.new(5551.021,78.901,3930.412)
        else               S.FarmMon="Galley Captain";     S.QuestName="FountainQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(5259.81982,37.3500175,4050.0293,.087131381,0,.996196866,0,1,0,-.996196866,0,.087131381); S.FarmCF=CFrame.new(5441.951,42.502,4950.093)
        end
    elseif World2 then
        if     lv<725  then S.FarmMon="Raider";            S.QuestName="Area1Quest";        S.QuestSlot=1; S.QuestCF=CFrame.new(-429.543518,71.7699966,1836.18188,-.22495985,0,-.974368095,0,1,0,.974368095,0,-.22495985); S.FarmCF=CFrame.new(-728.326,52.779,2345.770)
        elseif lv<775  then S.FarmMon="Mercenary";         S.QuestName="Area1Quest";        S.QuestSlot=2; S.QuestCF=CFrame.new(-429.543518,71.7699966,1836.18188,-.22495985,0,-.974368095,0,1,0,.974368095,0,-.22495985); S.FarmCF=CFrame.new(-1004.324,80.158,1424.619)
        elseif lv<800  then S.FarmMon="Swan Pirate";       S.QuestName="Area2Quest";        S.QuestSlot=1; S.QuestCF=CFrame.new(638.43811,71.769989,918.282898,.139203906,0,.99026376,0,1,0,-.99026376,0,.139203906); S.FarmCF=CFrame.new(1068.664,137.614,1322.106)
        elseif lv<875  then S.FarmMon="Factory Staff";     S.QuestName="Area2Quest";        S.QuestSlot=2; S.QuestCF=CFrame.new(632.698608,73.1055908,918.666321,-.0319722369,8.96074881e-10,-.999488771,1.36326533e-10,1,8.92172336e-10,.999488771,-1.07732087e-10,-.0319722369); S.FarmCF=CFrame.new(73.078,81.863,-27.470)
        elseif lv<900  then S.FarmMon="Marine Lieutenant"; S.QuestName="MarineQuest3";      S.QuestSlot=1; S.QuestCF=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); S.FarmCF=CFrame.new(-2821.372,75.897,-3070.089)
        elseif lv<950  then S.FarmMon="Marine Captain";    S.QuestName="MarineQuest3";      S.QuestSlot=2; S.QuestCF=CFrame.new(-2440.79639,71.7140732,-3216.06812,.866007268,0,.500031412,0,1,0,-.500031412,0,.866007268); S.FarmCF=CFrame.new(-1861.231,80.176,-3254.697)
        elseif lv<975  then S.FarmMon="Zombie";            S.QuestName="ZombieQuest";       S.QuestSlot=1; S.QuestCF=CFrame.new(-5497.06152,47.5923004,-795.237061,-.29242146,0,-.95628953,0,1,0,.95628953,0,-.29242146); S.FarmCF=CFrame.new(-5657.776,78.969,-928.687)
        elseif lv<1000 then S.FarmMon="Vampire";           S.QuestName="ZombieQuest";       S.QuestSlot=2; S.QuestCF=CFrame.new(-5497.06152,47.5923004,-795.237061,-.29242146,0,-.95628953,0,1,0,.95628953,0,-.29242146); S.FarmCF=CFrame.new(-6037.667,32.184,-1340.659)
        elseif lv<1050 then S.FarmMon="Snow Trooper";      S.QuestName="SnowMountainQuest"; S.QuestSlot=1; S.QuestCF=CFrame.new(609.858826,400.119904,-5372.25928,-.374604106,0,.92718488,0,1,0,-.92718488,0,-.374604106); S.FarmCF=CFrame.new(549.147,427.387,-5563.698)
        elseif lv<1100 then S.FarmMon="Winter Warrior";    S.QuestName="SnowMountainQuest"; S.QuestSlot=2; S.QuestCF=CFrame.new(609.858826,400.119904,-5372.25928,-.374604106,0,.92718488,0,1,0,-.92718488,0,-.374604106); S.FarmCF=CFrame.new(1142.745,475.639,-5199.416)
        elseif lv<1125 then S.FarmMon="Lab Subordinate";   S.QuestName="IceSideQuest";      S.QuestSlot=1; S.QuestCF=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-.891015649,0,1,0,.891015649,0,.453972578); S.FarmCF=CFrame.new(-5707.471,15.951,-4513.392)
        elseif lv<1175 then S.FarmMon="Horned Warrior";    S.QuestName="IceSideQuest";      S.QuestSlot=2; S.QuestCF=CFrame.new(-6064.06885,15.2422857,-4902.97852,.453972578,0,-.891015649,0,1,0,.891015649,0,.453972578); S.FarmCF=CFrame.new(-6341.366,15.951,-5723.162)
        elseif lv<1200 then S.FarmMon="Magma Ninja";       S.QuestName="FireSideQuest";     S.QuestSlot=1; S.QuestCF=CFrame.new(-5428.03174,15.0622921,-5299.43457,-.882952213,0,.469463557,0,1,0,-.469463557,0,-.882952213); S.FarmCF=CFrame.new(-5449.672,76.658,-5808.200)
        else               S.FarmMon="Lava Pirate";        S.QuestName="FireSideQuest";     S.QuestSlot=2; S.QuestCF=CFrame.new(-5428.03174,15.0622921,-5299.43457,-.882952213,0,.469463557,0,1,0,-.469463557,0,-.882952213); S.FarmCF=CFrame.new(-4857.562,74.651,-5905.487)
        end
    elseif World3 then
        if     lv<1525 then S.FarmMon="Jungle Pirate";           S.QuestName="ForestQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-12289,331,-10577); S.FarmCF=CFrame.new(-11778,426,-10592)
        elseif lv<1575 then S.FarmMon="Forest Pirate";           S.QuestName="ForestQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-12289,331,-10577); S.FarmCF=CFrame.new(-13446,413,-7760)
        elseif lv<1625 then S.FarmMon="Mythological Pirate";     S.QuestName="MythQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-13650,584,-6987); S.FarmCF=CFrame.new(-13510,584,-6987)
        elseif lv<1675 then S.FarmMon="Musketeer Pirate";        S.QuestName="MythQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-13650,584,-6987); S.FarmCF=CFrame.new(-13282,496,-9565)
        elseif lv<1725 then S.FarmMon="Fishman Raider";          S.QuestName="FishDeepQuest";S.QuestSlot=1; S.QuestCF=CFrame.new(-10941,332,-8760); S.FarmCF=CFrame.new(-10941,332,-8760)
        elseif lv<1800 then S.FarmMon="Fishman Captain";         S.QuestName="FishDeepQuest";S.QuestSlot=2; S.QuestCF=CFrame.new(-10941,332,-8760); S.FarmCF=CFrame.new(-11035,332,-9087)
        elseif lv<1850 then S.FarmMon="Reborn Skeleton";         S.QuestName="WyperQuest";   S.QuestSlot=1; S.QuestCF=CFrame.new(-8764,142,5963); S.FarmCF=CFrame.new(-8764,142,5963)
        elseif lv<1925 then S.FarmMon="Living Zombie";           S.QuestName="WyperQuest";   S.QuestSlot=2; S.QuestCF=CFrame.new(-8764,142,5963); S.FarmCF=CFrame.new(-10227,421,6161)
        elseif lv<2025 then S.FarmMon="Peanut Scout";            S.QuestName="PeanutQuest";  S.QuestSlot=1; S.QuestCF=CFrame.new(-1993,187,-10103); S.FarmCF=CFrame.new(-1993,187,-10103)
        elseif lv<2075 then S.FarmMon="Peanut President";        S.QuestName="PeanutQuest";  S.QuestSlot=2; S.QuestCF=CFrame.new(-1993,187,-10103); S.FarmCF=CFrame.new(-2215,159,-10474)
        elseif lv<2125 then S.FarmMon="Ice Cream Chef";          S.QuestName="CakeQuest";    S.QuestSlot=1; S.QuestCF=CFrame.new(-877,118,-11032); S.FarmCF=CFrame.new(-877,118,-11032)
        elseif lv<2175 then S.FarmMon="Ice Cream Commander";     S.QuestName="CakeQuest";    S.QuestSlot=2; S.QuestCF=CFrame.new(-877,118,-11032); S.FarmCF=CFrame.new(-877,118,-11032)
        elseif lv<2225 then S.FarmMon="Cookie Crafter";          S.QuestName="CakeFarm1";    S.QuestSlot=1; S.QuestCF=CFrame.new(-2021,38,-12028); S.FarmCF=CFrame.new(-2021,38,-12028)
        elseif lv<2275 then S.FarmMon="Cake Guard";              S.QuestName="CakeFarm1";    S.QuestSlot=2; S.QuestCF=CFrame.new(-2021,38,-12028); S.FarmCF=CFrame.new(-2024,38,-12026)
        elseif lv<2350 then S.FarmMon="Baking Staff";            S.QuestName="CakeFarm2";    S.QuestSlot=1; S.QuestCF=CFrame.new(-1932,38,-12848); S.FarmCF=CFrame.new(-1932,38,-12848)
        elseif lv<2450 then S.FarmMon="Head Baker";              S.QuestName="CakeFarm2";    S.QuestSlot=2; S.QuestCF=CFrame.new(-1932,38,-12848); S.FarmCF=CFrame.new(-1932,38,-12848)
        elseif lv<2525 then S.FarmMon="Cocoa Warrior";           S.QuestName="CakeFarm3";    S.QuestSlot=1; S.QuestCF=CFrame.new(95,73,-12309); S.FarmCF=CFrame.new(95,73,-12309)
        elseif lv<2625 then S.FarmMon="Chocolate Bar Battler";   S.QuestName="CakeFarm3";    S.QuestSlot=2; S.QuestCF=CFrame.new(95,73,-12309); S.FarmCF=CFrame.new(647,42,-12401)
        else               S.FarmMon="Candy Rebel";              S.QuestName="CakeFarm4";    S.QuestSlot=2; S.QuestCF=CFrame.new(116,36,-12478); S.FarmCF=CFrame.new(47,61,-12889)
        end
    else
        -- fallback world nao detectado
        S.FarmMon="Bandit"; S.QuestName="BanditQuest1"; S.QuestSlot=1
        S.QuestCF=CFrame.new(1059,15,1550); S.FarmCF=CFrame.new(1045,27,1560)
    end
end

-- ╔══════════════════════════════╗
-- ║    PEGAR MISSÃO              ║
-- ╚══════════════════════════════╝
-- ╔══════════════════╗
-- ║    PEGAR MISSÃO     ║
-- ╚══════════════════╝
-- NAO precisa teleportar para o NPC!
-- CommF_ funciona de qualquer lugar do mapa
-- TP perto do NPC = bug (abre dialogo automatico)
local function PegarMissao()
    if not S.QuestName then return end
    -- Dispara o remote direto -- sem TP, sem dialogo
    CommF("AskForQuest", S.QuestName, S.QuestSlot)
    task.wait(0.8)
    FecharDialogo() -- fecha qualquer dialogo que abriu
end

-- ╔══════════════════════════════╗
-- ║    ENCONTRAR MOB             ║
-- ╚══════════════════════════════╝
local function FindMob(nome)
    for _, m in ipairs(workspace.Enemies:GetChildren()) do
        if m.Name == nome then
            local mh = m:FindFirstChildOfClass("Humanoid")
            local mr = m:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health > 0 then return m end
        end
    end
end

-- ╔══════════════════════════════╗
-- ║    ATACAR (do AR)            ║
-- ╚══════════════════════════════╝
local function Atacar(mob)
    if not mob then return end
    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end

    -- 55 studs acima — completamente fora do alcance
    TP(mr.CFrame * CFrame.new(0, 55, 0))
    task.wait(0.04)
    StartFloat()  -- garante que não cai

    -- aponta mouse pro mob
    Try(function()
        local cam = workspace.CurrentCamera
        local sp, vis = cam:WorldToScreenPoint(mr.Position)
        if vis then VIM:SendMouseMoveEvent(sp.X, sp.Y, game) end
    end)

    -- 6 cliques = fighting style, sem skills
    for i = 1, 6 do
        Click()
        task.wait(0.02)
    end
end

-- ╔══════════════════════════════╗
-- ║    FARM LOOP PRINCIPAL       ║
-- ╚══════════════════════════════╝
--  FLUXO CORRETO:
--  1. Verifica quest via LP.Data.QuestName
--  2. Se sem quest → vai ao NPC → pega missão
--  3. Mata mobs até quest terminar
--  4. Quest terminou → volta ao passo 1
local function FarmLoop()
    return task.spawn(function()
        StartFloat()
        UpdateQuest()

        while S.AutoFarm do
            Try(function()
                if not IsAlive() then
                    StopFloat()
                    task.wait(3)
                    StartFloat()
                    return
                end

                UpdateQuest()

                -- Sem quest? pega direto via remote, sem TP
                if not QuestAtiva() then
                    PegarMissao()
                    task.wait(1)
                    return
                end

                -- Tem quest: mata mob
                local mob = S.FarmMon and FindMob(S.FarmMon)
                if mob then
                    Atacar(mob)
                else
                    TP(S.FarmCF)
                    task.wait(0.3)
                end
            end)
            task.wait(0.05)
        end

        StopFloat()
    end)
end

-- ╔══════════════════════════════╗
-- ║    TOGGLE                    ║
-- ╚══════════════════════════════╝
local function Toggle(key, val, cb)
    S[key] = val
    if cb then
        cb.BackgroundColor3 = val and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
        cb.Text = val and "✓" or ""
    end
    Kill(key)
    if val then
        if     key=="AutoFarm"  then Threads[key]=FarmLoop()
        elseif key=="SpeedHack" then
            Try(function() local h=GetHum(); if h then h.WalkSpeed=80; h.JumpPower=75 end end)
        elseif key=="AntiAFK"   then
            Threads[key]=task.spawn(function()
                while S.AntiAFK do
                    task.wait(math.random(60,90))
                    Try(function()
                        VIM:SendMouseButtonEvent(0,0,0,true,game,1)
                        VIM:SendMouseButtonEvent(0,0,0,false,game,1)
                    end)
                end
            end)
        end
    else
        if key=="SpeedHack" then
            Try(function() local h=GetHum(); if h then h.WalkSpeed=16; h.JumpPower=50 end end)
        end
        if key=="AutoFarm" then StopFloat() end
    end
end

-- respawn
LP.CharacterAdded:Connect(function(c)
    task.wait(1.2)
    if S.SpeedHack then
        local h=c:WaitForChild("Humanoid")
        h.WalkSpeed=80; h.JumpPower=75
    end
    if S.AutoFarm then StartFloat() end
end)

-- ╔══════════════════════════════╗
-- ║         GUI                  ║
-- ╚══════════════════════════════╝
pcall(function() LP.PlayerGui:FindFirstChild("BH5"):Destroy() end)

local GUI=Instance.new("ScreenGui")
GUI.Name="BH5"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=LP.PlayerGui

local Win=Instance.new("Frame",GUI)
Win.Name="Win"; Win.Size=UDim2.new(0,540,0,360)
Win.Position=UDim2.new(0.5,-270,0.5,-180)
Win.BackgroundColor3=Color3.fromRGB(10,10,18)
Win.BorderSizePixel=0; Win.Active=true; Win.Draggable=true
Win.ClipsDescendants=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local ws=Instance.new("UIStroke",Win)
ws.Color=Color3.fromRGB(138,43,226); ws.Thickness=1.5

-- topbar
local Top=Instance.new("Frame",Win)
Top.Size=UDim2.new(1,0,0,46); Top.BackgroundColor3=Color3.fromRGB(18,18,28)
Top.BorderSizePixel=0
local tg=Instance.new("UIGradient",Top)
tg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(90,20,160)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(18,18,28))
}); tg.Rotation=90
local ttl=Instance.new("TextLabel",Top)
ttl.Text="  ⚡ Beast Hub v5"; ttl.Size=UDim2.new(1,-100,1,0)
ttl.BackgroundTransparency=1; ttl.TextColor3=Color3.fromRGB(200,140,255)
ttl.Font=Enum.Font.GothamBold; ttl.TextSize=15; ttl.TextXAlignment=Enum.TextXAlignment.Left

local function HBtn(txt,col,x)
    local b=Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,34,0,24); b.Position=UDim2.new(1,x,0.5,-12)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
HBtn("✕",Color3.fromRGB(180,30,60),-40).MouseButton1Click:Connect(function() Win.Visible=not Win.Visible end)
local mini=false
HBtn("─",Color3.fromRGB(50,50,70),-80).MouseButton1Click:Connect(function()
    mini=not mini
    Win.Size=mini and UDim2.new(0,540,0,46) or UDim2.new(0,540,0,360)
end)

-- content
local CA=Instance.new("ScrollingFrame",Win)
CA.Size=UDim2.new(1,0,1,-70); CA.Position=UDim2.new(0,0,0,46)
CA.BackgroundTransparency=1; CA.BorderSizePixel=0
CA.ScrollBarThickness=4; CA.ScrollBarImageColor3=Color3.fromRGB(138,43,226)
CA.CanvasSize=UDim2.new(0,0,0,0); CA.AutomaticCanvasSize=Enum.AutomaticSize.Y
local CAL=Instance.new("UIListLayout",CA)
CAL.Padding=UDim.new(0,8); CAL.SortOrder=Enum.SortOrder.LayoutOrder
CAL.HorizontalAlignment=Enum.HorizontalAlignment.Center
local CAP=Instance.new("UIPadding",CA)
CAP.PaddingTop=UDim.new(0,10); CAP.PaddingLeft=UDim.new(0,12); CAP.PaddingRight=UDim.new(0,12)

-- row builder
local function Row(lbl, key)
    local row=Instance.new("Frame",CA)
    row.Size=UDim2.new(1,0,0,48); row.BackgroundColor3=Color3.fromRGB(18,18,30)
    row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    row.MouseEnter:Connect(function() TweenSvc:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(26,18,44)}):Play() end)
    row.MouseLeave:Connect(function() TweenSvc:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(18,18,30)}):Play() end)

    local l=Instance.new("TextLabel",row)
    l.Text=lbl; l.Size=UDim2.new(1,-60,1,0); l.Position=UDim2.new(0,14,0,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(220,220,235)
    l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Left

    local cb=Instance.new("TextButton",row)
    cb.Size=UDim2.new(0,24,0,24); cb.Position=UDim2.new(1,-36,0.5,-12)
    cb.BackgroundColor3=S[key] and Color3.fromRGB(138,43,226) or Color3.fromRGB(30,30,40)
    cb.Text=S[key] and "✓" or ""; cb.TextColor3=Color3.fromRGB(255,255,255)
    cb.Font=Enum.Font.GothamBold; cb.TextSize=13; cb.BorderSizePixel=0
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",cb).Color=Color3.fromRGB(100,50,180)

    local function go() Toggle(key, not S[key], cb) end
    cb.MouseButton1Click:Connect(go)
    row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then go() end end)
    return cb
end

-- section label
local function SLbl(txt)
    local l=Instance.new("TextLabel",CA)
    l.Text=txt; l.Size=UDim2.new(1,0,0,26)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(138,43,226)
    l.Font=Enum.Font.GothamBold; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
end

SLbl("  Farm")
Row("🌾  Auto Farm Level",  "AutoFarm")
SLbl("  Extras")
Row("⚡  Speed Hack",       "SpeedHack")
Row("🛡️  Anti AFK",         "AntiAFK")

-- info box
local Info=Instance.new("TextLabel",CA)
Info.Size=UDim2.new(1,0,0,44); Info.BackgroundColor3=Color3.fromRGB(14,14,24)
Info.BorderSizePixel=0; Info.TextColor3=Color3.fromRGB(160,130,220)
Info.Font=Enum.Font.Gotham; Info.TextSize=12; Info.TextWrapped=true
Info.TextXAlignment=Enum.TextXAlignment.Left
Instance.new("UICorner",Info).CornerRadius=UDim.new(0,7)
local IP=Instance.new("UIPadding",Info); IP.PaddingLeft=UDim.new(0,8)

-- status bar
local SBar=Instance.new("Frame",Win)
SBar.Size=UDim2.new(1,0,0,22); SBar.Position=UDim2.new(0,0,1,-22)
SBar.BackgroundColor3=Color3.fromRGB(8,8,14); SBar.BorderSizePixel=0
local SLb=Instance.new("TextLabel",SBar)
SLb.Size=UDim2.new(1,-10,1,0); SLb.Position=UDim2.new(0,8,0,0)
SLb.BackgroundTransparency=1; SLb.TextColor3=Color3.fromRGB(100,80,150)
SLb.Font=Enum.Font.Gotham; SLb.TextSize=11; SLb.TextXAlignment=Enum.TextXAlignment.Left

-- keybind
UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.RightAlt then
        Win.Visible=not Win.Visible
    end
end)

-- status update
task.spawn(function()
    while true do
        Try(function()
            UpdateQuest()
            local h=GetHum()
            local lv=MyLv()
            local qa=QuestAtiva()
            Info.Text=string.format("  Lv %s | Mob: %s | Quest: %s | %s",
                lv, S.FarmMon or "?", S.QuestName or "?",
                qa and "✅ Ativa" or "⏳ Pegando...")
            SLb.Text=string.format("HP: %s/%s | Farm: %s | Speed: %s | RightAlt = toggle",
                h and math.floor(h.Health) or "?",
                h and math.floor(h.MaxHealth) or "?",
                S.AutoFarm and "ON" or "OFF",
                S.SpeedHack and "ON" or "OFF"
            )
        end)
        task.wait(1)
    end
end)

print("[BeastHub v5] ✅ Loaded! RightAlt = toggle | Quest via LP.Data 🔥")
