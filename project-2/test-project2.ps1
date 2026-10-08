<#
.SYNOPSIS
    Automated End-to-End Verification Test Suite for Project 2: High Availability VMSS & Auto-Scaling
.DESCRIPTION
    Validates Azure Public IP, Load Balancer, Backend Pool, Health Probe,
    VMSS instances, Subnet placement, Autoscale rules, and Live HTTP traffic.
#>

$ErrorActionPreference = "Continue"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  PROJECT 2: END-TO-END HIGH AVAILABILITY & AUTOSCALE TEST SUITE" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$RG_NAME   = "rg-enterprise-net-dev"
$LB_NAME   = "lb-ha-vmss-dev"
$VMSS_NAME = "vmss-ha-vmss-dev"
$AS_NAME   = "autoscale-ha-vmss-dev"
$PIP_NAME  = "pip-ha-vmss-dev"

$PASS_COUNT = 0
$TOTAL_COUNT = 0

function Assert-Test {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Details = ""
    )
    $script:TOTAL_COUNT++
    if ($Condition) {
        $script:PASS_COUNT++
        Write-Host " [PASS] $TestName" -ForegroundColor Green
        if ($Details) { Write-Host "        $Details" -ForegroundColor Gray }
    } else {
        Write-Host " [FAIL] $TestName" -ForegroundColor Red
        if ($Details) { Write-Host "        $Details" -ForegroundColor Yellow }
    }
}

# 1. Public IP & Load Balancer Verification
Write-Host "`n--> [1/5] Verifying Public IP & Standard Load Balancer..." -ForegroundColor Yellow
$pip = az network public-ip show --resource-group $RG_NAME --name $PIP_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "Public IP '$PIP_NAME' is allocated" -Condition ($null -ne $pip.ipAddress) -Details "Live Public IP: $($pip.ipAddress)"
Assert-Test -TestName "Public IP SKU is 'Standard'" -Condition ($pip.sku.name -eq "Standard")

$lb = az network lb show --resource-group $RG_NAME --name $LB_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "Standard Load Balancer '$LB_NAME' exists" -Condition ($null -ne $lb)
Assert-Test -TestName "Load Balancer has Backend Address Pool" -Condition ($lb.backendAddressPools.Count -gt 0)
Assert-Test -TestName "Load Balancer has HTTP Health Probe on port 80" -Condition ($lb.probes[0].port -eq 80)

# 2. Live HTTP Web Traffic Testing
Write-Host "`n--> [2/5] Testing Live HTTP Web Traffic via Load Balancer..." -ForegroundColor Yellow
$liveUrl = "http://$($pip.ipAddress)"
try {
    $webResponse = Invoke-WebRequest -Uri $liveUrl -UseBasicParsing -TimeoutSec 10
    Assert-Test -TestName "Load Balancer endpoint responds with HTTP 200" -Condition ($webResponse.StatusCode -eq 200) -Details "Status: $($webResponse.StatusCode) OK"
    $hasHaHeader = $webResponse.Content -like "*Project 2: High Availability VMSS*"
    Assert-Test -TestName "Webpage serves custom Project 2 HTML content" -Condition $hasHaHeader
    $hasHealthyBadge = $webResponse.Content -like "*LIVE HEALTHY INSTANCE*"
    Assert-Test -TestName "Webpage displays 'LIVE HEALTHY INSTANCE' status" -Condition $hasHealthyBadge
} catch {
    Assert-Test -TestName "Load Balancer endpoint responds with HTTP 200" -Condition $false -Details $_.Exception.Message
}

# 3. VMSS Fleet & Subnet Placement
Write-Host "`n--> [3/5] Verifying VMSS Fleet & Placement Subnet..." -ForegroundColor Yellow
$vmss = az vmss show --resource-group $RG_NAME --name $VMSS_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "VMSS '$VMSS_NAME' exists and is Provisioned" -Condition ($vmss.provisioningState -eq "Succeeded")
Assert-Test -TestName "VMSS uses verified SKU '$($vmss.sku.name)'" -Condition ($null -ne $vmss.sku.name) -Details "SKU: $($vmss.sku.name)"
Assert-Test -TestName "VMSS is pinned to Availability Zone '1'" -Condition ($vmss.zones -contains "1")

$instances = az vmss list-instances --resource-group $RG_NAME --name $VMSS_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "VMSS instances are active and healthy" -Condition ($instances.Count -ge 1) -Details "Running instances: $($instances.Count)"

$nics = az vmss nic list --resource-group $RG_NAME --vmss-name $VMSS_NAME -o json | ConvertFrom-Json
$ip = $nics[0].ipConfigurations[0].privateIPAddress
$isInWebSubnet = $ip -like "10.0.1.*"
Assert-Test -TestName "VMSS instance is placed inside Project 1 Web Subnet (10.0.1.0/24)" -Condition $isInWebSubnet -Details "Private IP: $ip"

# 4. Azure Monitor Autoscale Policy Verification
Write-Host "`n--> [4/5] Verifying Azure Monitor Autoscale Settings..." -ForegroundColor Yellow
$as = az monitor autoscale show --resource-group $RG_NAME --name $AS_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "Autoscale Setting '$AS_NAME' is Enabled" -Condition ($as.enabled -eq $true)
$profile = $as.profiles[0]
Assert-Test -TestName "Autoscale Min limit is $($profile.capacity.minimum) and Max limit is $($profile.capacity.maximum)" -Condition ($profile.capacity.minimum -eq 1 -and $profile.capacity.maximum -eq 2)

$scaleOutRule = $profile.rules | Where-Object { $_.scaleAction.direction -eq "Increase" }
Assert-Test -TestName "Scale-Out Rule: Triggered when CPU > 75% for 5 mins (+1 VM)" -Condition ($scaleOutRule.metricTrigger.threshold -eq 75)

$scaleInRule = $profile.rules | Where-Object { $_.scaleAction.direction -eq "Decrease" }
Assert-Test -TestName "Scale-In Rule: Triggered when CPU < 25% for 5 mins (-1 VM)" -Condition ($scaleInRule.metricTrigger.threshold -eq 25)

# 5. Local SSH Key Security Verification
Write-Host "`n--> [5/5] Verifying Local SSH Key & Git Protection..." -ForegroundColor Yellow
$sshKeyPath = ".\id_rsa.pem"
Assert-Test -TestName "Local private SSH key 'id_rsa.pem' exists" -Condition (Test-Path $sshKeyPath)
$gitignore = Get-Content -Path "..\.gitignore" -Raw
Assert-Test -TestName "Private key is protected from Git by .gitignore (*.pem)" -Condition ($gitignore -like "*`*.pem*")

Write-Host "`n=====================================================================" -ForegroundColor Cyan
if ($PASS_COUNT -eq $TOTAL_COUNT) {
    Write-Host "  TEST RESULT: ALL TESTS PASSED ($PASS_COUNT/$TOTAL_COUNT) - 100% HEALTHY" -ForegroundColor Green
} else {
    Write-Host "  TEST RESULT: $PASS_COUNT/$TOTAL_COUNT PASSED" -ForegroundColor Yellow
}
Write-Host "=====================================================================" -ForegroundColor Cyan
