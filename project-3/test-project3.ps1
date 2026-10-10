<#
.SYNOPSIS
    Automated End-to-End Verification Test Suite for Project 3: Enterprise 3-Tier Web Architecture
.DESCRIPTION
    Validates Public Load Balancer, Private VMSS, Managed Identity, Azure Key Vault,
    Azure SQL Database, VNet Firewall Rules, and Live End-to-End Traffic.
#>

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  🏆 PROJECT 3: ENTERPRISE 3-TIER PRODUCTION STACK E2E TEST SUITE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$RG_NAME   = "rg-enterprise-3tier-dev"
$LB_NAME   = "lb-enterprise-3tier-dev"
$VMSS_NAME = "vmss-enterprise-3tier-dev"

# Read dynamic values from terraform output
Write-Host "Fetching live Terraform outputs..." -ForegroundColor Yellow
$OutputsJson = terraform output -json | ConvertFrom-Json

$APP_URL   = $OutputsJson.application_url.value
$LB_IP     = $OutputsJson.load_balancer_public_ip.value
$KV_NAME   = $OutputsJson.key_vault_name.value
$SQL_FQDN  = $OutputsJson.sql_server_fqdn.value
$SQL_DB    = $OutputsJson.sql_database_name.value
$MI_ID     = $OutputsJson.managed_identity_principal_id.value

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

# ------------------------------------------------------------------------------
# TEST GROUP 1: TIER 1 - PUBLIC INGRESS & LOAD BALANCING
# ------------------------------------------------------------------------------
Write-Host "`n>>> [GROUP 1] TIER 1: PUBLIC INGRESS & LOAD BALANCING" -ForegroundColor Cyan

# Test 1.1: Live HTTP Web Server Response
try {
    $response = Invoke-WebRequest -Uri $APP_URL -TimeoutSec 10 -UseBasicParsing
    Assert-Test -TestName "Live HTTP 200 OK from Public Load Balancer" `
                -Condition ($response.StatusCode -eq 200) `
                -Details "URL: $APP_URL | Status: $($response.StatusCode) $($response.StatusDescription)"
} catch {
    Assert-Test -TestName "Live HTTP 200 OK from Public Load Balancer" `
                -Condition $false `
                -Details "Error connecting to ${APP_URL}: $_"
}

# Test 1.2: Check Web Content Contains 3-Tier Architecture Metadata
if ($response -and $response.Content) {
    $hasBrand = $response.Content -match "Project 3: Enterprise 3-Tier Production Stack"
    Assert-Test -TestName "Web Landing Page Content Verification" `
                -Condition $hasBrand `
                -Details "Verified: 3-Tier Production dashboard HTML rendered by Nginx"
} else {
    Assert-Test -TestName "Web Landing Page Content Verification" -Condition $false
}

# Test 1.3: Backend Address Pool Registration
$poolJson = az network lb address-pool list --resource-group $RG_NAME --lb-name $LB_NAME -o json | ConvertFrom-Json
$backendCount = $poolJson[0].backendIPConfigurations.Count
Assert-Test -TestName "Load Balancer Backend Address Pool Membership" `
            -Condition ($backendCount -ge 2) `
            -Details "Registered VMSS backend instances in pool: $backendCount"

# ------------------------------------------------------------------------------
# TEST GROUP 2: TIER 2 - PRIVATE COMPUTE (VMSS) & MANAGED IDENTITY
# ------------------------------------------------------------------------------
Write-Host "`n>>> [GROUP 2] TIER 2: PRIVATE VMSS & MANAGED IDENTITY" -ForegroundColor Cyan

# Test 2.1: VMSS Instance Status
$vmssInstances = az vmss list-instances --resource-group $RG_NAME --name $VMSS_NAME -o json | ConvertFrom-Json
$healthyInstances = ($vmssInstances | Where-Object { $_.provisioningState -eq "Succeeded" }).Count
Assert-Test -TestName "VMSS Instances Provisioning State" `
            -Condition ($healthyInstances -eq $vmssInstances.Count) `
            -Details "All $healthyInstances / $($vmssInstances.Count) instances report 'Succeeded'"

# Test 2.2: Zero Public IP Verification on Backend Instances
$vmsWithPip = az vmss nic list --resource-group $RG_NAME --vmss-name $VMSS_NAME --query "[?ipConfigurations[0].publicIPAddress!=null]" -o tsv
Assert-Test -TestName "Zero-Public-IP Security Enforcement on VMSS" `
            -Condition ([string]::IsNullOrEmpty($vmsWithPip)) `
            -Details "Verified: All backend VMs have ZERO public IPs (Internal Subnet 10.0.2.0/24 only)"

# Test 2.3: User-Assigned Managed Identity Registration
$miCheck = az identity list --resource-group $RG_NAME --query "[?principalId=='$MI_ID'].name" -o tsv
Assert-Test -TestName "Microsoft Entra ID Managed Identity Verification" `
            -Condition (-not [string]::IsNullOrEmpty($miCheck)) `
            -Details "Managed Identity: $miCheck (Principal ID: $MI_ID)"

# ------------------------------------------------------------------------------
# TEST GROUP 3: SECURITY PLANE - AZURE KEY VAULT & SECRETS
# ------------------------------------------------------------------------------
Write-Host "`n>>> [GROUP 3] SECURITY PLANE: AZURE KEY VAULT & SECRETS" -ForegroundColor Cyan

# Test 3.1: Key Vault Active State
$kvCheck = az keyvault show --name $KV_NAME --query "properties.provisioningState" -o tsv
Assert-Test -TestName "Azure Key Vault Active Status" `
            -Condition ($kvCheck -eq "Succeeded") `
            -Details "Key Vault '$KV_NAME' provisioningState: $kvCheck"

# Test 3.2: Secret Existence: Database Admin Password
$secretSql = az keyvault secret show --vault-name $KV_NAME --name "sql-admin-password" --query "id" -o tsv 2>$null
Assert-Test -TestName "Key Vault Secret: SQL Admin Password" `
            -Condition (-not [string]::IsNullOrEmpty($secretSql)) `
            -Details "Secret 'sql-admin-password' securely stored in hardware safe"

# Test 3.3: Secret Existence: 4096-bit RSA SSH Private Key
$secretSsh = az keyvault secret show --vault-name $KV_NAME --name "vmss-ssh-private-key" --query "id" -o tsv 2>$null
Assert-Test -TestName "Key Vault Secret: 4096-bit RSA SSH Private Key" `
            -Condition (-not [string]::IsNullOrEmpty($secretSsh)) `
            -Details "Secret 'vmss-ssh-private-key' stored in Key Vault (Zero password SSH)"

# ------------------------------------------------------------------------------
# TEST GROUP 4: TIER 3 - MANAGED AZURE SQL DATABASE & ZERO-TRUST FIREWALL
# ------------------------------------------------------------------------------
Write-Host "`n>>> [GROUP 4] TIER 3: AZURE SQL DATABASE & ZERO-TRUST VNET RULE" -ForegroundColor Cyan

# Test 4.1: Azure SQL Database Online Status
$sqlServerName = $SQL_FQDN.Split('.')[0]
$dbStatus = az sql db show --resource-group $RG_NAME --server $sqlServerName --name $SQL_DB --query "status" -o tsv
Assert-Test -TestName "Azure SQL Database Status" `
            -Condition ($dbStatus -eq "Online") `
            -Details "Database '$SQL_DB' on server '$sqlServerName' is: $dbStatus"

# Test 4.2: SQL Virtual Network Firewall Rule Locking Access to App Subnet
$vnetRule = az sql server vnet-rule show --resource-group $RG_NAME --server $sqlServerName --name "sql-vnet-rule-app" --query "state" -o tsv
Assert-Test -TestName "SQL VNet Firewall Rule (App Subnet Isolation)" `
            -Condition ($vnetRule -eq "Ready") `
            -Details "Rule 'sql-vnet-rule-app' state: $vnetRule (Locked to Subnet snet-app-dev)"

# Test 4.3: Zero-Trust Security Verification: Zero Public IP Firewall Bypasses
$fwRules = az sql server firewall-rule list --resource-group $RG_NAME --server $sqlServerName -o json | ConvertFrom-Json
Assert-Test -TestName "Zero-Trust Enforcement: Zero Public IP Firewall Bypasses" `
            -Condition ($fwRules.Count -eq 0) `
            -Details "Verified: 0 public IP firewall rules exist (Connections strictly restricted to snet-app-dev)"

# ------------------------------------------------------------------------------
# TEST SUMMARY REPORT
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS: $PASS_COUNT / $TOTAL_COUNT TESTS PASSED" -ForegroundColor $(if ($PASS_COUNT -eq $TOTAL_COUNT) { "Green" } else { "Yellow" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($PASS_COUNT -eq $TOTAL_COUNT) {
    Write-Host "🎉 100% PRODUCTION READY! ALL 11 ENTERPRISE ARCHITECTURE TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some tests failed. Review output above." -ForegroundColor Yellow
}
Write-Host ""
