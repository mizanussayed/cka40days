# ---------- Build Stage ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

# Copy csproj first (better layer caching)
COPY *.csproj ./
RUN dotnet restore -r linux-musl-x64

# Copy everything else
COPY . ./

# Publish self-contained with aggressive trimming
RUN dotnet publish \
    -c Release \
    -r linux-musl-x64 \
    --self-contained true \
    --no-restore \
    -o /app/publish \
    /p:PublishTrimmed=true \
    /p:PublishSingleFile=false \
    /p:TrimMode=full \
    /p:EnableCompressionInSingleFile=true \
    /p:DebugType=none \
    /p:DebugSymbols=false

# ---------- Runtime Stage ----------
FROM mcr.microsoft.com/dotnet/runtime-deps:10.0-alpine AS runtime

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=build /app/publish .

# Security best practice
USER appuser

# ASP.NET configuration
ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_EnableDiagnostics=0 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

EXPOSE 8080

ENTRYPOINT ["./dotnet-api"]

