# SWD — Rice leaf disease detection

**.NET 9** API (EF Core, SQL Server, ONNX) + **Flutter** app.

## Run

**API** — `BackEnd/MyApp/`

1. Set `ConnectionStrings:DefaultConnection` in `appsettings.json`.
2. `dotnet ef database update` (migrations already in repo).
3. `dotnet run` — URL in `Properties/launchSettings.json` (often `http://localhost:5299`). Swagger at `/swagger`.

**App** — `FrontEnd/app/`

```bash
flutter pub get
flutter run
```

Point the app at your API (e.g. `--dart-define=API_BASE_URL=http://localhost:5299` or project defaults).

## Layout

- `BackEnd/MyApp` — API, domain, EF migrations, `uploads/images`
- `FrontEnd/app` — Flutter `lib/`, platforms under `app/`
