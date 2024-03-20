using Octokit;
public static class GitHubClientManager
{
    private static TimeSpan jwtExpireTime = TimeSpan.FromMinutes(10);
    private static AccessToken installationToken = null;
    private static GitHubClient client = null;
    private static Octokit.GraphQL.Connection graphQLConnection = null;
    

    public static async Task<GitHubClient> GetClient(string org, string repo, int appId, string appKey)
    {
        if (client != null && installationToken != null && DateTimeOffset.UtcNow < installationToken.ExpiresAt)
        {
            return client;
        }

        var jwtToken = CreateJWTToken(appId, appKey);
        client = new GitHubClient(new ProductHeaderValue(Consts.AppName)) { Credentials = new Credentials(jwtToken, AuthenticationType.Bearer) };
        var installation = await client.GitHubApps.GetRepositoryInstallationForCurrent(org, repo);
        installationToken = await client.GitHubApps.CreateInstallationToken(installation.Id);
        client = new GitHubClient(new ProductHeaderValue(Consts.AppName)) { Credentials = new Credentials(installationToken.Token, AuthenticationType.Bearer) };
        return client;
    }

    public static async Task<Octokit.GraphQL.Connection> GetGraphQLConnection(string org, string repo, int appId, string appKey)
    {
        if (graphQLConnection != null && installationToken != null && DateTimeOffset.UtcNow < installationToken.ExpiresAt)
        {
            return graphQLConnection;
        }

        await GetClient(org, repo, appId, appKey);
        graphQLConnection = new Octokit.GraphQL.Connection(new Octokit.GraphQL.ProductHeaderValue(Consts.AppName), installationToken.Token);
        return graphQLConnection;
    }

    private static string CreateJWTToken(int appId, string appKey)
    {
        // create a new token
        var generator = new GitHubJwt.GitHubJwtFactory(
                new GitHubJwt.StringPrivateKeySource(appKey),
                new GitHubJwt.GitHubJwtFactoryOptions
                {
                    AppIntegrationId = appId,
                    ExpirationSeconds = (int)jwtExpireTime.TotalSeconds
                });
        return generator.CreateEncodedJwtToken();
    }
}
