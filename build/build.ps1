# Сборка БыстрыйПереносРегистров.cfe из XML-исходников расширения.
#
# Предпосылки:
#   1. XML-исходники расширения выгружены из EDT: Export -> Configuration to XML files
#      (или уже лежат в -SrcXml). Формат - штатный DumpConfigToFiles.
#   2. Есть ИБ-хост (-HostIB): любая ФАЙЛОВАЯ ИБ, в которую можно грузить расширение.
#      Подойдёт пустая; конфигурация хоста не трогается (работаем только с -Extension).
#      ЗАР: не указывайте сюда живую рабочую ИБ - DESIGNER берёт монопольную блокировку.
#
# Пример:
#   .\build.ps1 -HostIB "D:\ib\build_host" -SrcXml "D:\src\cfe_xml"
param(
    [Parameter(Mandatory = $true)][string]$HostIB,       # файловая ИБ-хост (папка с 1Cv8.1CD)
    [Parameter(Mandatory = $true)][string]$SrcXml,       # папка с XML-исходниками расширения
    [string]$Platform = "C:\Program Files\1cv8\8.5.1.1343\bin\1cv8.exe",
    [string]$ExtensionName = "БыстрыйПереносРегистровРасш",
    [string]$Out = (Join-Path $PSScriptRoot "БыстрыйПереносРегистров.cfe")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $Platform)) { throw "Платформа не найдена: $Platform (укажите -Platform)" }
if (-not (Test-Path (Join-Path $HostIB "1Cv8.1CD"))) { throw "В $HostIB нет 1Cv8.1CD - нужна файловая ИБ-хост" }
if (-not (Test-Path (Join-Path $SrcXml "Configuration.xml"))) { throw "В $SrcXml нет Configuration.xml - укажите папку XML-выгрузки расширения" }

$logLoad = Join-Path $HostIB "build_load.log"
$logDump = Join-Path $HostIB "build_dump.log"

Write-Host "[1/2] Загрузка расширения из XML в ИБ-хост..."
$p = Start-Process -FilePath $Platform -Wait -PassThru -ArgumentList @(
    'DESIGNER', '/F', $HostIB,
    '/LoadConfigFromFiles', $SrcXml,
    '-Extension', $ExtensionName,
    '/UpdateDBCfg',
    '/Out', $logLoad,
    '/DisableStartupDialogs', '/DisableStartupMessages')
if ($p.ExitCode -ne 0) { Get-Content $logLoad; throw "LoadConfigFromFiles упал с кодом $($p.ExitCode), лог: $logLoad" }

Write-Host "[2/2] Дамп расширения в .cfe..."
$p = Start-Process -FilePath $Platform -Wait -PassThru -ArgumentList @(
    'DESIGNER', '/F', $HostIB,
    '/DumpCfg', $Out,
    '-Extension', $ExtensionName,
    '/Out', $logDump,
    '/DisableStartupDialogs', '/DisableStartupMessages')
if ($p.ExitCode -ne 0) { Get-Content $logDump; throw "DumpCfg упал с кодом $($p.ExitCode), лог: $logDump" }

$f = Get-Item $Out
Write-Host "Готово: $($f.FullName) ($([math]::Round($f.Length / 1KB)) КБ)"
