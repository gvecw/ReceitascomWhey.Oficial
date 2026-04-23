$port = 9999
$basePath = "C:\Users\dejes\OneDrive\PENDRIVERS\RECEITAS DE WHEY"
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
    $listener.Start()
} catch {
    Write-Host "Failed to start"
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
                $localPath = [IO.Path]::Combine($basePath, $path.Replace('/','\'))
                
                $writer = New-Object IO.StreamWriter($stream)
                $writer.AutoFlush = $true
                if ([IO.File]::Exists($localPath)) {
                    $bytes = [IO.File]::ReadAllBytes($localPath)
                    $writer.WriteLine("HTTP/1.1 200 OK")
                    if ($localPath.EndsWith(".js")) { $writer.WriteLine("Content-Type: application/javascript") }
                    elseif ($localPath.EndsWith(".css")) { $writer.WriteLine("Content-Type: text/css") }
                    else { $writer.WriteLine("Content-Type: text/html") }
                    $writer.WriteLine("Content-Length: " + $bytes.Length)
                    $writer.WriteLine("Connection: close")
                    $writer.WriteLine("Access-Control-Allow-Origin: *")
                    $writer.WriteLine("")
                    $stream.Write($bytes, 0, $bytes.Length)
                } else {
                    $writer.WriteLine("HTTP/1.1 404 Not Found")
                    $writer.WriteLine("Connection: close")
                    $writer.WriteLine("")
                }
            }
        }
        $client.Close()
    } catch {
        continue
    }
}
