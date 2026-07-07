using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public static class CampsiteCatalog
{
    public static IReadOnlyList<CampsiteDto> All { get; } =
    [
        new("cape-trib", "Cape Tribulation", "Queensland",
            "Rainforest meets reef. Popular with 4WD campers and van lifers exploring the Daintree.",
            4.6, ["Showers", "BBQ", "Beach access", "Pet friendly"], -16.0870, 145.4630),
        new("lake-argyle", "Lake Argyle", "Western Australia",
            "Massive freshwater lake with sunset views and wide open camping areas.",
            4.8, ["Boat ramp", "Swimming", "Powered sites", "Camp kitchen"], -16.1042, 128.7397),
        new("wilsons-prom", "Wilsons Promontory", "Victoria",
            "Coastal walks, wildlife, and sheltered bays at the southern tip of mainland Australia.",
            4.7, ["Hiking", "Wildlife", "Toilets", "National park"], -39.0350, 146.3190),
        new("flinders-ranges", "Flinders Ranges", "South Australia",
            "Red dirt, ancient ranges, and star-filled skies in the outback.",
            4.5, ["Campfires", "Scenic drives", "4WD tracks", "Dump point"], -31.4230, 138.7050),
        new("byron-hinterland", "Byron Hinterland", "New South Wales",
            "Rolling hills and quiet free camps a short drive from the coast.",
            4.4, ["Free camp", "Water nearby", "Shade", "Community friendly"], -28.6474, 153.6020),
        new("cradle-area", "Cradle Mountain area", "Tasmania",
            "Cool-climate camping with alpine lakes and wombats on the doorstep.",
            4.6, ["Walking tracks", "Wildlife", "Fire pits", "Ranger info"], -41.6526, 145.9510),
        new("great-ocean", "Great Ocean Road", "Victoria",
            "Clifftop pull-offs and caravan parks along one of Australia's best drives.",
            4.3, ["Ocean views", "Powered sites", "Dump point", "Cafe nearby"], -38.6806, 143.1050),
        new("kakadu-edge", "Kakadu edge camps", "Northern Territory",
            "Dry-season base camps for exploring waterfalls, wetlands, and rock art.",
            4.5, ["Seasonal access", "Swimming holes", "4WD recommended", "Toilets"], -12.4330, 132.8010),
    ];

    public static CampsiteDto? GetById(string id) =>
        All.FirstOrDefault(c => c.Id == id);
}
