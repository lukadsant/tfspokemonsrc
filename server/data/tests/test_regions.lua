dofile('data/lib/regions.lua')

local testCases = {
    {pos = {x=725, y=1025, z=7}, expectedRegion = "Kanto", expectedSubregion = "Viridian Forest"},
    {pos = {x=780, y=1050, z=7}, expectedRegion = "Kanto", expectedSubregion = "Viridian Forest"},
    {pos = {x=625, y=1000, z=7}, expectedRegion = "Kanto", expectedSubregion = "Route 2"},
    {pos = {x=100, y=100, z=7}, expectedRegion = "Unknown Region", expectedSubregion = "Unknown Area"},
}

for i, test in ipairs(testCases) do
    local region, subregion = getRegionFromPosition(test.pos)
    if region == test.expectedRegion and subregion == test.expectedSubregion then
        print("Test " .. i .. " PASSED")
    else
        print("Test " .. i .. " FAILED. Expected " .. test.expectedRegion .. " - " .. test.expectedSubregion .. ", got " .. region .. " - " .. subregion)
    end
end
