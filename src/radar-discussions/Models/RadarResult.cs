public class RadarResult 
{
    public string url { get; set; }
    public string key { get; set; }
    public string id { get; set; }
    public string title { get; set; }
    public string quadrant { get; set; }
    public string description { get; set; }
    public List<RadarResultTimeline> timeline { get; set; }

    public static int GetTrends(List<string> labels)
    {
        if (labels.Contains("up")) return 1;
        else if (labels.Contains("down")) return -1;
        else return 0;
    }

    public static string GetQuadrant(List<string> labels)
    {
        foreach (var label in labels)
        {
            if (Consts.QuadrantsMap.ContainsKey(label)) return Consts.QuadrantsMap[label];
        }
        return Consts.QuadrantsMap["trends"];
    }
}

public class RadarResultTimeline
{
    public int moved { get; set; }
    public string ringId { get; set; }
    public string date { get; set; }
    public string description { get; set; }
}

public class Rings 
{
    public string id { get; set; }
    public string name { get; set; }
    public string color { get; set; }
}

public class Quadrant 
{
    public string id { get; set; }
    public string name { get; set; }
}

public static class Consts
{
    public static Dictionary<string,string> QuadrantsMap = new Dictionary<string, string>{
        { "trends", "1" },
        { "infrastructure", "2" },
        { "frameworks", "3" },
        { "languages", "4" }
    };

    public static Quadrant[] Quadrants = [
        new() { id = "1", name = "TRENDS" },
        new() { id = "2", name = "INFRASTRUCTURE" },
        new() { id = "3", name = "FRAMEWORKS" },
        new() { id = "4", name = "LANGUAGES" }
    ];
    public static Rings[] Rings = [
        new() { id = "scale", name = "SCALE", color = "#93c47d" },
        new() { id = "trial", name = "TRIAL", color = "#93d2c2" },
        new() { id = "assess", name = "ASSESS", color = "#fbdb84" },
        new() { id = "hold", name = "HOLD", color = "#efafa9" }
    ];

    public static string AppName = "Tech-Radar";
}