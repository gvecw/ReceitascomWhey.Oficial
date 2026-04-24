$port = 9999
$basePath = $PSScriptRoot
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
    $listener.Start()
    Write-Host "Servidor rodando em http://localhost:$port"
    Write-Host "Base path: $basePath"
} catch {
    Write-Host "Falha ao iniciar: $($_.Exception.Message)"
    exit 1
}

while($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object IO.StreamReader($stream)
        $requestLine = $reader.ReadLine()
        if($null -ne $requestLine) {
            $parts = $requestLine.Split(' ')
            if($parts.Length -ge 2 -and $parts[0] -eq 'GET') {
                $path = $parts[1].Split('?')[0].TrimStart('/')
                if ($path -eq '' -or $path -eq '/') { $path = 'index.html' }
                $localPath = [IO.Path]::Combine($basePath, $path.Replace('/','\\'))

                $writer = New-Object IO.StreamWriter($stream)
                $writer.AutoFlush = $true
                if ([IO.File]::Exists($localPath)) {
                    $bytes = [IO.File]::ReadAllBytes($localPath)
                    $writer.WriteLine("HTTP/1.1 200 OK")
                    $ext = [IO.Path]::GetExtension($localPath).ToLower()
                    switch ($ext) {
                        ".js"    { $writer.WriteLine("Content-Type: application/javascript") }
                        ".css"   { $writer.WriteLine("Content-Type: text/css") }
                        ".html"  { $writer.WriteLine("Content-Type: text/html; charset=utf-8") }
                        ".jpg"   { $writer.WriteLine("Content-Type: image/jpeg") }
                        ".jpeg"  { $writer.WriteLine("Content-Type: image/jpeg") }
                        ".png"   { $writer.WriteLine("Content-Type: image/png") }
                        ".gif"   { $writer.WriteLine("Content-Type: image/gif") }
                        ".svg"   { $writer.WriteLine("Content-Type: image/svg+xml") }
                        ".webp"  { $writer.WriteLine("Content-Type: image/webp") }
                        ".ico"   { $writer.WriteLine("Content-Type: image/x-icon") }
                        ".woff"  { $writer.WriteLine("Content-Type: font/woff") }
                        ".woff2" { $writer.WriteLine("Content-Type: font/woff2") }
                        ".ttf"   { $writer.WriteLine("Content-Type: font/ttf") }
                        default  { $writer.WriteLine("Content-Type: application/octet-stream") }
                    }
                    $writer.WriteLine("Content-Length: " + $bytes.Length)
                    $writer.WriteLine("Connection: close")
                    $writer.WriteLine("Access-Control-Allow-Origin: *")
                    $writer.WriteLine("")
                    $stream.Write($bytes, 0, $bytes.Length)
                    Write-Host "200 OK: $path"
                } else {
                    $writer.WriteLine("HTTP/1.1 404 Not Found")
                    $writer.WriteLine("Content-Type: text/plain")
                    $writer.WriteLine("Connection: close")
                    $writer.WriteLine("")
                    Write-Host "404 Not Found: $path"
                }
            }
        }
        $client.Close()
    } catch {
        Write-Host "Erro: $($_.Exception.Message)"
        continue
    }
}
