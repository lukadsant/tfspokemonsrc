Regioes = {
    ["Kanto"] = {
        ["Viridian Forest"] = {
            {from={x=700,y=1000,z=7}, to={x=750,y=1050,z=7}},
            {from={x=760,y=1000,z=7}, to={x=800,y=1100,z=7}},
        },
        ["Route 2"] = {
            {from={x=600,y=900,z=7}, to={x=650,y=1200,z=7}}
        }
    }
}

function getRegionFromPosition(pos)
    for regionName, subregions in pairs(Regioes) do
        for subregionName, areas in pairs(subregions) do
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
