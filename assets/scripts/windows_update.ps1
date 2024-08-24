param (
    [string]$zipFilePath,
    [string]$destinationDir,
    [string]$appPath
)

# 解压 ZIP 文件到指定目录
Expand-Archive -Path $zipFilePath -DestinationPath $destinationDir -Force

# 等待解压完成
Start-Sleep -Seconds 2

# 启动应用程序
Start-Process -FilePath $appPath

# 退出 PowerShell 脚本
exit
