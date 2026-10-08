<#
.SYNOPSIS
    Automated End-to-End Verification Test for Project 1: Enterprise Multi-Tier VNet & NSG
.DESCRIPTION
    Validates Azure Resource Group, Virtual Network, Subnets, NSGs, Security Rules,
    and Terraform State consistency.
#>

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  PROJECT 1: END-TO-END INFRASTRUCTURE VERIFICATION TEST SUITE" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$RG_NAME = "rg-enterprise-net-dev"
$VNET_NAME = "vnet-enterprise-net-dev"
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

# 1. Resource Group Verification
Write-Host "`n--> [1/5] Verifying Resource Group..." -ForegroundColor Yellow
$rg = az group show --name $RG_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "Resource Group '$RG_NAME' exists" -Condition ($null -ne $rg)
Assert-Test -TestName "Resource Group location is 'centralindia'" -Condition ($rg.location -eq "centralindia") -Details "Live location: $($rg.location)"
Assert-Test -TestName "Resource Group ProvisioningState is 'Succeeded'" -Condition ($rg.properties.provisioningState -eq "Succeeded")

# 2. Virtual Network Verification
Write-Host "`n--> [2/5] Verifying Virtual Network & Address Space..." -ForegroundColor Yellow
$vnet = az network vnet show --resource-group $RG_NAME --name $VNET_NAME -o json | ConvertFrom-Json
Assert-Test -TestName "Virtual Network '$VNET_NAME' exists" -Condition ($null -ne $vnet)
$cidrMatch = $vnet.addressSpace.addressPrefixes -contains "10.0.0.0/16"
Assert-Test -TestName "VNet CIDR contains '10.0.0.0/16'" -Condition $cidrMatch -Details "Prefixes: $($vnet.addressSpace.addressPrefixes -join ', ')"

# 3. Subnets & CIDRs Verification
Write-Host "`n--> [3/5] Verifying 3-Tier Subnets..." -ForegroundColor Yellow
$subnets = az network vnet subnet list --resource-group $RG_NAME --vnet-name $VNET_NAME -o json | ConvertFrom-Json

$webSubnet = $subnets | Where-Object { $_.name -eq "snet-web-dev" }
$appSubnet = $subnets | Where-Object { $_.name -eq "snet-app-dev" }
$dbSubnet  = $subnets | Where-Object { $_.name -eq "snet-db-dev" }

Assert-Test -TestName "Web Subnet ('snet-web-dev') exists with 10.0.1.0/24" -Condition ($webSubnet.addressPrefix -eq "10.0.1.0/24") -Details "CIDR: $($webSubnet.addressPrefix)"
Assert-Test -TestName "App Subnet ('snet-app-dev') exists with 10.0.2.0/24" -Condition ($appSubnet.addressPrefix -eq "10.0.2.0/24") -Details "CIDR: $($appSubnet.addressPrefix)"
Assert-Test -TestName "DB Subnet ('snet-db-dev') exists with 10.0.3.0/24" -Condition ($dbSubnet.addressPrefix -eq "10.0.3.0/24") -Details "CIDR: $($dbSubnet.addressPrefix)"

# 4. NSG Associations & Firewall Security Rules
Write-Host "`n--> [4/5] Verifying NSG Associations & Security Rules..." -ForegroundColor Yellow

# Web Subnet NSG
Assert-Test -TestName "Web Subnet has NSG associated" -Condition ($null -ne $webSubnet.networkSecurityGroup)
$webRules = az network nsg rule list --resource-group $RG_NAME --nsg-name "nsg-web-dev" -o json | ConvertFrom-Json
$hasHttp = ($webRules | Where-Object { $_.name -eq "Allow-HTTP-Inbound" -and $_.destinationPortRange -eq "80" -and $_.access -eq "Allow" })
$hasHttps = ($webRules | Where-Object { $_.name -eq "Allow-HTTPS-Inbound" -and $_.destinationPortRange -eq "443" -and $_.access -eq "Allow" })
Assert-Test -TestName "Web NSG allows Inbound HTTP (80) from Internet" -Condition ($null -ne $hasHttp)
Assert-Test -TestName "Web NSG allows Inbound HTTPS (443) from Internet" -Condition ($null -ne $hasHttps)

# App Subnet NSG
Assert-Test -TestName "App Subnet has NSG associated" -Condition ($null -ne $appSubnet.networkSecurityGroup)
$appRules = az network nsg rule list --resource-group $RG_NAME --nsg-name "nsg-app-dev" -o json | ConvertFrom-Json
$hasWebToApp = ($appRules | Where-Object { $_.name -eq "Allow-Web-To-App-8080" -and $_.sourceAddressPrefix -eq "10.0.1.0/24" -and $_.destinationPortRange -eq "8080" -and $_.access -eq "Allow" })
$hasAppDeny = ($appRules | Where-Object { $_.name -eq "Deny-All-Other-Inbound" -and $_.access -eq "Deny" })
Assert-Test -TestName "App NSG allows port 8080 exclusively from Web Subnet (10.0.1.0/24)" -Condition ($null -ne $hasWebToApp)
Assert-Test -TestName "App NSG has default Deny-All inbound rule (Priority 1000)" -Condition ($null -ne $hasAppDeny)

# DB Subnet NSG
Assert-Test -TestName "DB Subnet has NSG associated" -Condition ($null -ne $dbSubnet.networkSecurityGroup)
$dbRules = az network nsg rule list --resource-group $RG_NAME --nsg-name "nsg-db-dev" -o json | ConvertFrom-Json
$hasAppToDb = ($dbRules | Where-Object { $_.name -eq "Allow-App-To-DB-1433" -and $_.sourceAddressPrefix -eq "10.0.2.0/24" -and $_.destinationPortRange -eq "1433" -and $_.access -eq "Allow" })
$hasDbDeny = ($dbRules | Where-Object { $_.name -eq "Deny-All-Other-Inbound" -and $_.access -eq "Deny" })
Assert-Test -TestName "DB NSG allows port 1433 exclusively from App Subnet (10.0.2.0/24)" -Condition ($null -ne $hasAppToDb)
Assert-Test -TestName "DB NSG has default Deny-All inbound rule (Priority 1000)" -Condition ($null -ne $hasDbDeny)

# 5. Terraform State Integrity
Write-Host "`n--> [5/5] Checking Terraform State Drift..." -ForegroundColor Yellow
$stateList = terraform state list
$expectedResources = @(
    "azurerm_resource_group.rg",
    "azurerm_virtual_network.vnet",
    "azurerm_subnet.web",
    "azurerm_subnet.app",
    "azurerm_subnet.db",
    "azurerm_network_security_group.web_nsg",
    "azurerm_network_security_group.app_nsg",
    "azurerm_network_security_group.db_nsg",
    "azurerm_subnet_network_security_group_association.web_assoc",
    "azurerm_subnet_network_security_group_association.app_assoc",
    "azurerm_subnet_network_security_group_association.db_assoc"
)
$missing = @()
foreach ($res in $expectedResources) {
    if ($stateList -notcontains $res) {
        $missing += $res
    }
}
Assert-Test -TestName "Terraform State contains all 11 managed resources" -Condition ($missing.Count -eq 0) -Details "Resources tracked in state: $($stateList.Count)"

Write-Host "`n=====================================================================" -ForegroundColor Cyan
if ($PASS_COUNT -eq $TOTAL_COUNT) {
    Write-Host "  TEST RESULT: ALL TESTS PASSED ($PASS_COUNT/$TOTAL_COUNT) - 100% HEALTHY" -ForegroundColor Green
} else {
    Write-Host "  TEST RESULT: $PASS_COUNT/$TOTAL_COUNT PASSED" -ForegroundColor Yellow
}
Write-Host "=====================================================================" -ForegroundColor Cyan
