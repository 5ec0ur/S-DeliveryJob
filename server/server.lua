local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or {}

-- Event to pay the player for completing the job
RegisterNetEvent('deliveryjob:pay')
AddEventHandler('deliveryjob:pay', function(totalPayment)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney('bank', totalPayment, 'delivery-job-payment')
end)