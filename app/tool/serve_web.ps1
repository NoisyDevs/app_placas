param(
  [int]$Port = 48213,
  [string]$Root = "C:\Users\agusm\OneDrive\Documentos\Proyectos Note\app_placas\app\build\web"
)

Add-Type -AssemblyName System.Net.HttpListener -ErrorAction SilentlyContinue

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $Root on http://localhost:$Port/"

$mime = @{
  ".html" = "text/html"
  ".js"   = "application/javascript"
  ".mjs"  = "application/javascript"
  ".json" = "application/json"
  ".wasm" = "application/wasm"
  ".css"  = "text/css"
  ".png"  = "image/png"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
  ".woff2"= "font/woff2"
}

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $req = $context.Request
  $res = $context.Response
  try {
    $path = $req.Url.AbsolutePath
    if ($path -eq "/") { $path = "/index.html" }
    $filePath = Join-Path $Root ($path.TrimStart("/"))
    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath)
      $contentType = $mime[$ext]
      if (-not $contentType) { $contentType = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $res.ContentType = $contentType
      $res.Headers.Add("Cache-Control", "no-store")
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("Not found: $path")
      $res.OutputStream.Write($msg, 0, $msg.Length)
    }
  } catch {
    Write-Output "Error: $_"
  } finally {
    $res.OutputStream.Close()
  }
}
