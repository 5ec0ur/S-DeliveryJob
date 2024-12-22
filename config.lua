Config = {}

-- Start location and ped model
Config.StartLocation = vector4(90.99, -1603.62, 31.08, 232.41)
Config.PedModel = "s_m_m_postal_01"

-- Delivery locations and ped models
Config.DeliveryLocations = {
    { coords = vector4(189.83, 309.19, 105.39, 175.45), pedModel = "a_m_m_business_01" },
    { coords = vector4(1169.04, -291.73, 69.02, 322.88), pedModel = "a_m_m_business_01" },
    { coords = vector4(1142.64, -986.7, 45.9, 278.02), pedModel = "a_m_m_business_01" },
    -- Add more locations as needed
}

-- Payment amount payment is multiplied by x 2 for each delivery made 
Config.Payment = 500

-- Delivery vehicle model and spawn location
Config.VehicleModel = "boxville"
Config.VehicleSpawnLocation = vector4(99.62, -1608.59, 29.48, 247.28)