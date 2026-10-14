# Memory Card Game - simple local web server
# Runs with built-in PowerShell on Windows (no Python needed)
# Usage: double-click the .bat file in the same folder

$root = $PSScriptRoot
$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

try {
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "No permission to listen on port $port."
    Write-Host "Restarting as administrator - please click YES on the popup."
    Write-Host ""
    $arg = '-NoProfile -ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '"'
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arg
        Write-Host "New window opened as administrator. You can close this one."
    } catch {
        Write-Host "Failed to request administrator permission."
        Write-Host "Fix: right-click the .bat file and choose 'Run as administrator'."
        Read-Host "Press Enter to close"
    }
    exit
}

$ip = $null
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress
} catch { }

Write-Host ""
Write-Host "=============================================="
Write-Host "  Memory Game server started"
Write-Host "  PC test:    http://127.0.0.1:$port"
if ($ip) { Write-Host "  Phone URL:  http://${ip}:${port}" }
Write-Host "  Phone and PC must be on the same Wi-Fi"
Write-Host "  Stop server: close this window"
Write-Host "=============================================="
Write-Host ""

$contentTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.md'   = 'text/markdown; charset=utf-8'
}

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
    if ($path -eq '') { $path = 'index.html' }
    $file = Join-Path $root ($path -replace '/', '\')
    try {
        if (Test-Path $file -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($contentTypes.ContainsKey($ext)) { $ctx.Response.ContentType = $contentTypes[$ext] }
            else { $ctx.Response.ContentType = 'application/octet-stream' }
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
    } finally {
        $ctx.Response.OutputStream.Close()
        $ctx.Response.Close()
    }
}
