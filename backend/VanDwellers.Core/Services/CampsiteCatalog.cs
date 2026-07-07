using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public static class CampsiteCatalog
{
    public static IReadOnlyList<CampsiteDto> All { get; } =
    [
        new("cape-trib", "Cape Tribulation", "Queensland",
            "Rainforest meets reef. Popular with 4WD campers and van lifers exploring the Daintree.",
            4.6, ["Showers", "BBQ", "Beach access", "Pet friendly"]),
        new("lake-argyle", "Lake Argyle", "Western Australia",
            "Massive freshwater lake with sunset views and wide open camping areas.",
            4.8, ["Boat ramp", "Swimming", "Powered sites", "Camp kitchen"]),
        new("wilsons-prom", "Wilsons Promontory", "Victoria",
            "Coastal walks, wildlife, and sheltered bays at the southern tip of mainland Australia.",
            4.7, ["Hiking", "Wildlife", "Toilets", "National park"]),
        new("flinders-ranges", "Flinders Ranges", "South Australia",
            "Red dirt, ancient ranges, and star-filled skies in the outback.",
            4.5, ["Campfires", "Scenic drives", "4WD tracks", "Dump point"]),
        new("byron-hinterland", "Byron Hinterland", "New South Wales",
            "Rolling hills and quiet free camps a short drive from the coast.",
            4.4, ["Free camp", "Water nearby", "Shade", "Community friendly"]),
        new("cradle-area", "Cradle Mountain area", "Tasmania",
            "Cool-climate camping with alpine lakes and wombats on the doorstep.",
            4.6, ["Walking tracks", "Wildlife", "Fire pits", "Ranger info"]),
        new("great-ocean", "Great Ocean Road", "Victoria",
            "Clifftop pull-offs and caravan parks along one of Australia's best drives.",
            4.3, ["Ocean views", "Powered sites", "Dump point", "Cafe nearby"]),
        new("kakadu-edge", "Kakadu edge camps", "Northern Territory",
            "Dry-season base camps for exploring waterfalls, wetlands, and rock art.",
            4.5, ["Seasonal access", "Swimming holes", "4WD recommended", "Toilets"]),
    ];
}
