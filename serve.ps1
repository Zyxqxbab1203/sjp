# 小确幸盲盒 - 零依赖本地静态服务器 (PowerShell TcpListener)
$ErrorActionPreference = 'SilentlyContinue'
$port = 5173
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
$listener.Start()

$types = @{
  '.html' = 'text/html; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.wasm' = 'application/wasm'
  '.task' = 'application/octet-stream'
  '.png'  = 'image/png'
  '.ico'  = 'image/x-icon'
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $client.ReceiveTimeout = 5000
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 8192, $true)
    $req = $reader.ReadLine()
    if (-not $req) { throw 'empty' }
    while (($line = $reader.ReadLine()) -and $line -ne '') {}

    $path = ($req -split ' ')[1].TrimStart('/')
    if ($path -eq '' -or $path -eq '/') { $path = 'index.html' }
    $path = ($path -split '\?')[0]
    if ($path -match '\.\.') { throw 'bad' }

    $file = Join-Path $root ($path -replace '/', '\')
    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
      $head = "HTTP/1.1 200 OK`r`nContent-Type: $ct`r`nContent-Length: $($bytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
      $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
      $stream.Write($hb, 0, $hb.Length)
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Flush()
      Start-Sleep -Milliseconds 50
    } else {
      $hb = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Length: 3`r`nConnection: close`r`n`r`n404")
      $stream.Write($hb, 0, $hb.Length)
    }
  } catch {}
  finally { try { $client.Close() } catch {} }
}
