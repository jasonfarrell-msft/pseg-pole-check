# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["Farrellsoft.PSEG.PoleImageApi.csproj", "./"]
RUN dotnet restore "Farrellsoft.PSEG.PoleImageApi.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "Farrellsoft.PSEG.PoleImageApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Farrellsoft.PSEG.PoleImageApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Expose port
EXPOSE 8080
EXPOSE 8081

# Copy published app
COPY --from=publish /app/publish .

# Set environment to Production
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "Farrellsoft.PSEG.PoleImageApi.dll"]
