using VanDwellers.Core.Models;

namespace VanDwellers.Core.Services;

public static class CampsiteCatalog
{
    public static IReadOnlyList<CampsiteDto> All { get; } =
    [
        Site("cape-trib", "Cape Tribulation", "Queensland",
            "Rainforest meets reef. Popular with 4WD campers and van lifers exploring the Daintree.",
            4.6, ["Showers", "BBQ", "Beach access", "Pet friendly"], -16.1700, 145.4180, true, true),
        Site("lake-argyle", "Lake Argyle", "Western Australia",
            "Massive freshwater lake with sunset views and wide open camping areas.",
            4.8, ["Boat ramp", "Swimming", "Powered sites", "Camp kitchen"], -16.1111, 128.7397, true, true),
        Site("wilsons-prom", "Wilsons Promontory", "Victoria",
            "Coastal walks, wildlife, and sheltered bays at the southern tip of mainland Australia.",
            4.7, ["Hiking", "Wildlife", "Toilets", "National park"], -39.0333, 146.3167, true, false),
        Site("flinders-ranges", "Flinders Ranges", "South Australia",
            "Red dirt, ancient ranges, and star-filled skies in the outback.",
            4.5, ["Campfires", "Scenic drives", "4WD tracks", "Dump point"], -31.4214, 138.6977, true, false),
        Site("byron-hinterland", "Byron Hinterland", "New South Wales",
            "Rolling hills and quiet free camps a short drive from the coast.",
            4.4, ["Free camp", "Water nearby", "Shade", "Community friendly"], -28.6474, 153.6020, false, false),
        Site("cradle-area", "Cradle Mountain area", "Tasmania",
            "Cool-climate camping with alpine lakes and wombats on the doorstep.",
            4.6, ["Walking tracks", "Wildlife", "Fire pits", "Ranger info"], -41.5853, 145.9394, true, true),
        Site("great-ocean", "Great Ocean Road", "Victoria",
            "Clifftop pull-offs and caravan parks along one of Australia's best drives.",
            4.3, ["Ocean views", "Powered sites", "Dump point", "Cafe nearby"], -38.6470, 143.0620, true, true),
        Site("kakadu-edge", "Kakadu edge camps", "Northern Territory",
            "Dry-season base camps for exploring waterfalls, wetlands, and rock art.",
            4.5, ["Seasonal access", "Swimming holes", "4WD recommended", "Toilets"], -12.6667, 132.8333, true, false),
    ];

    private static CampsiteDto Site(
        string id,
        string title,
        string region,
        string description,
        double rating,
        List<string> amenities,
        double latitude,
        double longitude,
        bool hasToilet,
        bool hasTap) =>
        new(id, title, region, description, rating, amenities, latitude, longitude,
            hasToilet, hasTap, []);
}
