# Corre la app contra el proyecto Supabase hosteado.
# La key pública (publishable/anon) se lee de una variable de entorno para no
# dejarla escrita en el repo:
#   $env:SUPABASE_ANON_KEY = '<publishable key>'
#   .\tool\run_hosted.ps1 -Device chrome
param(
  [string]$Device = 'chrome',
  [string]$BackendUrl = 'http://127.0.0.1:8000'
)

if (-not $env:SUPABASE_ANON_KEY) {
  Write-Error 'Falta $env:SUPABASE_ANON_KEY (Dashboard -> Settings -> API Keys -> publishable).'
  exit 1
}

$env:Path = "$env:Path;C:\src\flutter\bin"

flutter run -d $Device `
  --dart-define=SUPABASE_URL=https://kqctrpapevhlukcnnnzw.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
  --dart-define=BACKEND_BASE_URL=$BackendUrl
