# 1. Baixa o script do seu GitHub e salva na máquina local
 $scriptPath = "C:\Temp\Aplicar-Hostname.ps1"
if (-not (Test-Path "C:\Temp")) { New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null }
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Datasaferti/hostname/main/Aplicar-Hostname.ps1" -OutFile $scriptPath -UseBasicParsing

# 2. Pega o nome do usuário que está logado na tela no momento
 $loggedInUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName

if ($loggedInUser) {
    # 3. Cria uma tarefa agendada rodando INVISÍVEL na sessão do usuário logado
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $principal = New-ScheduledTaskPrincipal -UserId $loggedInUser -LogonType Interactive -RunLevel Highest
    $task = Register-ScheduledTask -TaskName "TempHostBg" -Action $action -Principal $principal -Force
    
    # 4. Dispara a tarefa e aplica o wallpaper na tela do usuário agora
    Start-ScheduledTask -TaskName "TempHostBg"
    
    # 5. Aguarda 5 segundos para o script terminar de desenjar o wallpaper e apaga a tarefa
    Start-Sleep -Seconds 5
    Unregister-ScheduledTask -TaskName "TempHostBg" -Confirm:$false
    Write-Host "Sucesso! O hostname foi aplicado na tela do usuário $loggedInUser." -ForegroundColor Green
} else {
    Write-Host "Nenhum usuário ativo na tela no momento. Será aplicado no próximo login." -ForegroundColor Yellow
}

# 6. Garante que TODOS os futuros usuários que logarem na máquina também recebam o hostname
 $regRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regRun -Name "AplicarHostname" -Value "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`"" -Force
Write-Host "Configurado para rodar automaticamente em todos os próximos logins." -ForegroundColor Cyan
