$port = 3000
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving at http://localhost:$port"

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".json" = "application/json"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $urlPath = $req.Url.LocalPath
    if ($urlPath -eq "/") { $urlPath = "/index.html" }
    $filePath = Join-Path $root ($urlPath.TrimStart("/").Replace("/", "\"))
    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $res.ContentType = $mime
      $res.StatusCode = 200
      $res.SendChunked = $true
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
      $res.SendChunked = $true
      $res.OutputStream.Write($body, 0, $body.Length)
    }
  } catch {
    Write-Host "Error: $_"
  } finally {
    $res.OutputStream.Close()
  }
}
