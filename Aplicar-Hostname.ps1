# Caminho onde a imagem modificada será salva temporariamente
 $wallpaperPath = "C:\Temp\Wallpaper_Host_Overlay.png"
 $dir = Split-Path $wallpaperPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

 $hostname = $env:COMPUTERNAME

# Carrega as bibliotecas gráficas do Windows
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Captura a resolução da tela
 $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
 $width = $screen.Width
 $height = $screen.Height

# 1. Tenta encontrar o papel de parede ATUAL do usuário
 $wpReg = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
 $wpTranscoded = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"

 $sourceImage = $null
if ($wpReg -and (Test-Path $wpReg)) { 
    $sourceImage = [System.Drawing.Image]::FromFile($wpReg) 
} elseif (Test-Path $wpTranscoded) { 
    $sourceImage = [System.Drawing.Image]::FromFile($wpTranscoded) 
}

# Cria a nova imagem baseada no tamanho da tela
 $bmp = New-Object System.Drawing.Bitmap($width, $height)
 $graph = [System.Drawing.Graphics]::FromImage($bmp)
 $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
 $graph.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

if ($sourceImage) {
    # Se achou o papel de parede do usuário, desenha a imagem original de fundo
    $graph.DrawImage($sourceImage, 0, 0, $width, $height)
    $sourceImage.Dispose()
} else {
    # Se o usuário usa cor sólida, cria fundo cinza escuro como fallback
    $graph.Clear([System.Drawing.Color]::FromArgb(20, 20, 20))
}

# 2. Configurações do Texto e do "Quadradinho"
 $fontSize = [math]::Round($height / 35) # Fonte adaptável ao tamanho do monitor
 $font = New-Object System.Drawing.Font("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold)
 $stringFormat = New-Object System.Drawing.StringFormat
 $stringSize = $graph.MeasureString($hostname, $font)

# Medidas do quadradinho (com margem de 15px do canto da tela)
 $pad = 10
 $boxWidth = $stringSize.Width + ($pad * 2)
 $boxHeight = $stringSize.Height + ($pad * 2)
 $boxX = $width - $boxWidth - 15
 $boxY = 15

# 3. Desenha o Quadradinho (Preto com 80% de opacidade para ficar discreto)
 $boxBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0)) # 180 = 70% opaco
 $graph.FillRectangle($boxBrush, $boxX, $boxY, $boxWidth, $boxHeight)

# 4. Desenha o texto (Hostname) dentro do quadradinho
 $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
 $graph.DrawString($hostname, $font, $textBrush, ($boxX + $pad), ($boxY + $pad))

# Salva a imagem final
 $graph.Dispose()
 $bmp.Save($wallpaperPath, [System.Drawing.Imaging.ImageFormat]::Png)

# 5. Aplica o novo papel de parede no Windows via API
 $signature = @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type -TypeDefinition $signature -ErrorAction SilentlyContinue
[Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3) | Out-Null

# Garante no registro
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $wallpaperPath
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "2"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"

Write-Host "Hostname aplicado no canto superior direito sem alterar o fundo original do usuario!"
