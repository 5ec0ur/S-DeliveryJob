local QBCore = exports['qb-core']:GetCoreObject()
local isOnJob = false
local currentDelivery = 1
local deliveryVehicle = nil
local deliveryBlip = nil
local totalPayment = 0

-- Function to create a blip for the delivery location
local function CreateDeliveryBlip(coords)
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, 0.8)
    SetBlipColour(deliveryBlip, 5)
    SetBlipAsShortRange(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(deliveryBlip)
end

-- Function to start the delivery job
local function StartJob()
    if isOnJob then
        QBCore.Functions.Notify("You are already on a job.", "error")
        return
    end

    isOnJob = true
    currentDelivery = 1
    totalPayment = Config.Payment
    QBCore.Functions.Notify("Job started. Deliver the packages to the marked locations.", "success")
    SetNewWaypoint(Config.DeliveryLocations[currentDelivery].coords.x, Config.DeliveryLocations[currentDelivery].coords.y)
    CreateDeliveryBlip(Config.DeliveryLocations[currentDelivery].coords)
end

-- Function to end the delivery job
local function EndJob()
    if not isOnJob then
        QBCore.Functions.Notify("You are not on a job.", "error")
        return
    end

    isOnJob = false
    currentDelivery = 1
    if deliveryVehicle then
        DeleteVehicle(deliveryVehicle)
        deliveryVehicle = nil
    end
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    TriggerServerEvent('deliveryjob:pay', totalPayment)
    QBCore.Functions.Notify("Job completed. You have been paid $" .. totalPayment, "success")
end

-- Function to handle package delivery
local function DeliverPackage()
    if not isOnJob then
        QBCore.Functions.Notify("You are not on a job.", "error")
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local deliveryCoords = Config.DeliveryLocations[currentDelivery].coords

    if #(playerCoords - vector3(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z)) < 5.0 then
        ExecuteCommand("e box")
        QBCore.Functions.Progressbar("deliver_package", "Delivering package...", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- On success
            ClearPedTasks(PlayerPedId())
            ExecuteCommand("e c")
            totalPayment = totalPayment * 2
            currentDelivery = currentDelivery + 1
            if currentDelivery > #Config.DeliveryLocations then
                EndJob()
            else
                QBCore.Functions.Notify("Package delivered. Proceed to the next location.", "success")
                SetNewWaypoint(Config.DeliveryLocations[currentDelivery].coords.x, Config.DeliveryLocations[currentDelivery].coords.y)
                CreateDeliveryBlip(Config.DeliveryLocations[currentDelivery].coords)
            end
        end, function() -- On cancel
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.Notify("Delivery canceled.", "error")
        end)
    else
        QBCore.Functions.Notify("You are not at the delivery location.", "error")
    end
end

-- Function to spawn the delivery vehicle
local function SpawnVehicle()
    local vehicleModel = GetHashKey(Config.VehicleModel)
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(1)
    end

    deliveryVehicle = CreateVehicle(vehicleModel, Config.VehicleSpawnLocation.x, Config.VehicleSpawnLocation.y, Config.VehicleSpawnLocation.z, Config.VehicleSpawnLocation.w, true, false)
    SetVehicleNumberPlateText(deliveryVehicle, "DELIVERY")
    SetEntityAsMissionEntity(deliveryVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), deliveryVehicle, -1)
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(deliveryVehicle))
    QBCore.Functions.Notify("Delivery vehicle spawned. Get the packages from the vehicle.", "success")
end

-- Create the ped at the start location and add a blip for the start location
CreateThread(function()
    local pedModel = GetHashKey(Config.PedModel)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end

    local ped = CreatePed(4, pedModel, Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z - 1.0, Config.StartLocation.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "deliveryjob:startJob",
                icon = "fas fa-briefcase",
                label = "Start Delivery Job",
            },
            {
                type = "client",
                event = "deliveryjob:endJob",
                icon = "fas fa-briefcase",
                label = "End Delivery Job",
            },
            {
                type = "client",
                event = "deliveryjob:spawnVehicle",
                icon = "fas fa-truck",
                label = "Spawn Delivery Vehicle",
            },
        },
        distance = 2.5
    })

    -- Add a blip for the start location
    local startBlip = AddBlipForCoord(Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z)
    SetBlipSprite(startBlip, 67)
    SetBlipDisplay(startBlip, 4)
    SetBlipScale(startBlip, 0.8)
    SetBlipColour(startBlip, 3)
    SetBlipAsShortRange(startBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Job")
    EndTextCommandSetBlipName(startBlip)
end)

-- Create the peds at the delivery locations
CreateThread(function()
    for _, location in ipairs(Config.DeliveryLocations) do
        local pedModel = GetHashKey(location.pedModel)
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(1)
        end

        local ped = CreatePed(4, pedModel, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    event = "deliveryjob:deliverPackage",
                    icon = "fas fa-box",
                    label = "Deliver Package",
                },
            },
            distance = 2.5
        })
    end
end)

-- Register the events to start and end the job
RegisterNetEvent('deliveryjob:startJob', function()
    StartJob()
end)

RegisterNetEvent('deliveryjob:endJob', function()
    EndJob()
end)

RegisterNetEvent('deliveryjob:spawnVehicle', function()
    SpawnVehicle()
end)

-- Register the event to deliver the package
RegisterNetEvent('deliveryjob:deliverPackage', function()
    DeliverPackage()
end)