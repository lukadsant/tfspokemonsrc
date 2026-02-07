-- Weather Configuration
WeatherEffects = {
    ["Clear"] = nil,
    ["Cloudy"] = nil,
    ["Rain"] = "Rain",
    ["Thunderstorm"] = "Electric Terrain",
    ["Snow"] = "Hail",
    ["Blizzard"] = "Hail",
    ["Harsh sunlight"] = "Harsh sunlight",
    ["Sandstorm"] = "Sandstorm",
    ["Fog"] = "Misty Terrain"
}

-- Current active weather [Region][Subregion] = "WeatherName"
CurrentRegionWeathers = {}

Regioes = {
    ["Kanto"] = {
        ["Viridian Forest"] = {
            areas = {
                {from={x=700,y=1000,z=7}, to={x=750,y=1050,z=7}},
                {from={x=760,y=1000,z=7}, to={x=800,y=1100,z=7}},
            },
            weatherProbabilities = {
                ["Clear"] = 50,
                ["Rain"] = 30,
                ["Thunderstorm"] = 20
            }
        },
        ["Route 2"] = {
            areas = {
                {from={x=600,y=900,z=7}, to={x=650,y=1200,z=7}}
            },
            weatherProbabilities = {
                ["Clear"] = 80,
                ["Cloudy"] = 20
            }
        }
    }
}

function getRegionFromPosition(pos)
    for regionName, subregions in pairs(Regioes) do
        for subregionName, data in pairs(subregions) do
            -- Compatibility check: support new structure {areas=..., weather=...} or old structure {{...}}
            local areas = data.areas or data
            
            for _, area in ipairs(areas) do
                if pos.x >= area.from.x and pos.x <= area.to.x and
                   pos.y >= area.from.y and pos.y <= area.to.y and
                   pos.z >= area.from.z and pos.z <= area.to.z then
                    return regionName, subregionName
                end
            end
        end
    end
    return "Unknown Region", "Unknown Area"
end

function getRegionWeather(region, subregion)
    if not CurrentRegionWeathers[region] then return "Clear", nil end
    local weather = CurrentRegionWeathers[region][subregion] or "Clear"
    return weather, WeatherEffects[weather]
end

-- Localized Weather Overrides (e.g., Rain Dance)
-- Key: integer ID, Value: {pos=Position, radius=number, weather=string, endTime=number}
LocalizedWeathers = {}
local LocalizedWeatherID = 0

function addLocalizedWeather(pos, radius, weather, duration)
    LocalizedWeatherID = LocalizedWeatherID + 1
    local id = LocalizedWeatherID
    
    LocalizedWeathers[id] = {
        pos = pos,
        radius = radius,
        weather = weather,
        endTime = os.time() + duration
    }
    
    -- Schedule cleanup
    addEvent(function(fid) 
        LocalizedWeathers[fid] = nil 
    end, duration * 1000, id)
    
    return id
end

function getWeatherFromPosition(pos)
    -- 1. Check Localized Overrides
    for id, info in pairs(LocalizedWeathers) do
        if pos:getDistance(info.pos) <= info.radius then
            return info.weather, WeatherEffects[info.weather]
        end
    end

    -- 2. Check Regional Weather
    local region, subregion = getRegionFromPosition(pos)
    if not region then return "Clear", nil end
    return getRegionWeather(region, subregion)
end

function setRegionWeather(region, subregion, weather)
    if not CurrentRegionWeathers[region] then
        CurrentRegionWeathers[region] = {}
    end
    
    if not WeatherEffects[weather] and weather ~= "Clear" and weather ~= "Cloudy" then
        return false
    end

    CurrentRegionWeathers[region][subregion] = weather
    return true
end

function doUpdateGlobalWeather()
    for regionName, subregions in pairs(Regioes) do
        if not CurrentRegionWeathers[regionName] then
            CurrentRegionWeathers[regionName] = {}
        end
        
        for subregionName, data in pairs(subregions) do
            local probs = data.weatherProbabilities
            if probs then
                local rand = math.random(1, 100)
                local sum = 0
                for weather, chance in pairs(probs) do
                    sum = sum + chance
                    if rand <= sum then
                        CurrentRegionWeathers[regionName][subregionName] = weather
                        break
                    end
                end
            else
                CurrentRegionWeathers[regionName][subregionName] = "Clear"
            end
        end
    end
    print("[Weather System] Updated global weather.")
end

-- Initialize weather on load
doUpdateGlobalWeather()
