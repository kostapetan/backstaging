using Octokit.GraphQL;

var appId = Environment.GetEnvironmentVariable("GH_APP_ID");
var appKey = Environment.GetEnvironmentVariable("GH_PRIVATE_KEY");
var org = Environment.GetEnvironmentVariable("GH_ORG");
var repo = Environment.GetEnvironmentVariable("GH_REPO");

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/discussions", async () => 
{
    var connection = await GitHubClientManager.GetGraphQLConnection(org, repo, int.Parse(appId), appKey);
    var query = new Query()
    .Repository(repo, org)
    .Discussions()
    .AllPages()
    .Select(d => new RadarQueryResult
    {
        url = d.Url,
        key = d.Id.Value,
        id = d.Id.Value,
        title = d.Title,
        labels = d.Labels(100,null,null,null,null)
                .Nodes
                .Select(l => l.Name).ToList(),
        description = d.BodyText,
        category = d.Category.Name,
        date = d.CreatedAt
    });
    var results = await connection.Run(query);
    var mappedResults =  results.Select(r => new RadarResult {
        url = r.url,
        key = r.key,
        id = r.id,
        title = r.title,
        quadrant = RadarResult.GetQuadrant(r.labels),
        description = r.description,
        timeline = [
            new() {
            moved = RadarResult.GetTrends(r.labels),
            ringId = r.category.ToLower(),
            date = r.date.Date.ToString("o"),
            description = r.description
        }]
    });

    return new {
        entries = mappedResults,
        rings = Consts.Rings,
        quadrants = Consts.Quadrants
    };
});

app.Run();


