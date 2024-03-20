FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5267

ENV ASPNETCORE_URLS=http://+:5267

USER app
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG configuration=Release
WORKDIR /src
COPY ["src/radar-discussions/radar-discussions-csharp.csproj", "src/radar-discussions/"]
RUN dotnet restore "src/radar-discussions/radar-discussions-csharp.csproj"
COPY . .
WORKDIR "/src/src/radar-discussions"
RUN dotnet build "radar-discussions-csharp.csproj" -c $configuration -o /app/build

FROM build AS publish
ARG configuration=Release
RUN dotnet publish "radar-discussions-csharp.csproj" -c $configuration -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "radar-discussions-csharp.dll"]
