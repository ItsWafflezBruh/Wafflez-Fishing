local managerPed
local rodObject

local ped = nil
local playerRod
local fishing = false
local catching = false

local function createManagerPed()
    local pedData = Config.PedData

    RequestModel(pedData.model)
    while not HasModelLoaded(pedData.model) do
        Wait(1)
        RequestModel(pedData.model)
        dbug('Requesting Model: ' .. pedData.model)
    end

    managerPed = CreatePed(1, pedData.model, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1, pedData.coords.w, - 1, pedData.coords.w, false, false)
    FreezeEntityPosition(managerPed, true)
    SetEntityInvincible(managerPed, true)
    SetBlockingOfNonTemporaryEvents(managerPed, true)

    local rodProp = `prop_fishing_rod_01`
    RequestModel(rodProp)
    while not HasModelLoaded(rodProp) do
        Wait(1)
        RequestModel(rodProp)
        dbug('Requesting Model: ' .. rodProp)
    end

    local animDict = 'amb@world_human_stand_fishing@idle_a'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
        RequestModel(animDict)
        dbug('Requesting Animation: ' .. animDict)
    end    

    TaskPlayAnim(managerPed, animDict, 'idle_b', 2.0, 2.0, -1, 51, 0, false, false, false)
    rodObject = CreateObject(rodProp, pedData.coords.x, pedData.coords.y, pedData.coords.z, false, false, false)
    AttachEntityToEntity(rodObject, managerPed, GetPedBoneIndex(managerPed, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

end

local function GetFishZone(plrPed)
    local coords = GetEntityCoords(plrPed)
    local forwardVec = GetEntityForwardVector(plrPed)

    local pointX = coords.x + (forwardVec.x * 10)
    local pointY = coords.y + (forwardVec.y * 10)
    local pointZ = coords.z + (forwardVec.z * 10)

    local inWater, castPoint = TestProbeAgainstWater(
        coords.x,
        coords.y,
        coords.z,
        pointX,
        pointY,
        pointZ - 1
    )

    local waterType = 'unknown'

    if inWater then
        zone = GetNameOfZone(castPoint.x, castPoint.y, castPoint.z)

        for _, fw in ipairs(Config.FishAreas.freshwater) do
           if zone == fw then
            waterType = 'freshwater'
            break
           end 
        end
        for _, sw in ipairs(Config.FishAreas.saltwater) do
           if zone == fw then
            waterType = 'saltwater'
            break
           end 
        end
    end

    return inWater, waterType
end

local function CatchFish(waterType)
    catching = true
  print(waterType)


  exports['boii_minigames']:skill_bar({
    style = 'default',
    icon = 'fas fa-fish',
    orientation = 2,
    area_size = 20,
    perfect_area_size = 5,
    speed = 0.5,
    moving_icon = true,
    icon_speed = 3,}, 
  function(success) -- Game callback
    if success == 'perfect' then
      lib.callback.await('wafflez-fishing:server:giveFish', false, waterType)
    elseif success == 'success' then
      lib.callback.await('wafflez-fishing:server:giveFish', false, waterType)
    elseif success == 'failed' then
      -- If failed do something
      print('skill_bar fail')
    end
  end)

  catching = false
end

local function StartFishing(level, waterType)
    fishing = true
    catching = false

    FreezeEntityPosition(ped, true)
    Citizen.CreateThread(function()
        while fishing do
            DisableControlAction(0, 24, true) -- Disable Attack
            DisableControlAction(0, 25, true) -- Disable Aim
            DisableControlAction(0, 21, true) -- Disable Sprint
            DisableControlAction(0, 22, true) -- Disable jump
            DisableControlAction(0, 30, true) -- disable hori movement
            DisableControlAction(0, 31, true) -- disable vert movemnet
            DisableControlAction(0, 75, true) -- Disable exit vehicle
            Wait(0)
        end
    end)

    playerRod = CreateObject(`prop_fishing_rod_01`, 0,0,0, true, false, false)
    AttachEntityToEntity(playerRod, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    local animDict = "amb@world_human_stand_fishing@idle_a"
    local animClip = "idle_b"
    Citizen.CreateThread(function()
        while fishing do
            if not IsEntityPlayingAnim(ped, animDict, animClip, 3) then
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Wait(1)
                    RequestAnimDict(animDict)
                end
                TaskPlayAnim(ped, animDict, animClip, 2.0, 2.0, -1, 51, 0, false, false, false)
            end
            Wait(5000)       
        end
    end)

    local waitTime = 0

    if level == 1 then
        waitTime = math.random(22000, 27000)
    elseif level == 2 then
        waitTime = math.random(17000, 27000)
    elseif level == 3 then
        waitTime = math.random(10000, 15000)
    else
        print('Does not have a fishing level')
        return
    end

    Citizen.CreateThread(function()
        while fishing do
            Wait(waitTime)
            if not catching and fishing then
                CatchFish(waterType)
            end
        end
    end)
end

local function StopFishing()
    DeleteEntity(playerRod)
    FreezeEntityPosition(ped, false)
end

Citizen.CreateThread(function ()
    createManagerPed()

    exports.ox_target:addLocalEntity(managerPed, {
        {
            distance = 1.5,
            name = 'fishing_manager',
            icon = Config.PedData.target.icon,
            label = Config.PedData.target.label,
            onSelect = function ()
                BuildManagerContext()
            end
        }
    })

    if Config.PedData.blip.enabled then
        local blipData = Config.PedData.blip
        local blip = AddBlipForCoord(Config.PedData.coords.xyz)
        SetBlipSprite(blip, blipData.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.size)
        SetBlipColour(blip, blipData.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.title)
        EndTextCommandSetBlipName(blip)
        dbug('blip created')
    end
end)

RegisterNetEvent('wafflez-fishing:server:useRod', function (level)
    dbug('used a level ' .. level .. ' rod!')
    fishing = not fishing
    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)

    if not fishing then
        StopFishing()
        return
    end

    local inWater, zone = GetFishZone(ped)

    if not inWater or zone == 'unknown' then
        lib.notify({
            title = 'Fishing',
            description = 'You can not fish here!',
            type = 'error',
            duration = 2500,
            showDuration = true,
        })
        return
    end

    if lib.progressCircle({
        duration = 1700,
        position = 'bottom',
        label = 'Casting Line',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
        },
        anim = {
            dict = 'anim@heists@narcotics@trash',
            clip = 'throw_b',
        }
    }) 
    then
        ClearPedTasksImmediately(ped)
        StartFishing(level, zone)
    else

    end
end)


AddEventHandler('onResourceStop', function()
    if resource ~= GetCurrentResourceName() then return end

    DeleteObject(rodObject)
end)