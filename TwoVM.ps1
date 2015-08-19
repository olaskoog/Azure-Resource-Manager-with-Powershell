Switch-AzureMode AzureResourceManager

$testName = "mvaiaasv2twovm"

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2012-R2-Datacenter"
$version = "latest"

$resourceGroupName = $testName
$location = "West US"
$domainName = $testName
$subnetName = "Subnet-1"


New-AzureResourceGroup -Name $resourceGroupName -Location $location

$vip = New-AzurePublicIpAddress -ResourceGroupName $resourceGroupName -Name "VIP1" `
   -Location "West US" -AllocationMethod Dynamic -DomainNameLabel $domainName


$subnet = New-AzureVirtualNetworkSubnetConfig -Name $subnetName `
   -AddressPrefix "10.0.64.0/24"

$vnet = New-AzureVirtualNetwork -Name "VNET" `
   -ResourceGroupName $resourceGroupName `
   -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet

$subnet = Get-AzureVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet


$feIpConfig = New-AzureLoadBalancerFrontendIpConfig -Name $testName -PublicIpAddress $vip

$inboundNatRule1 = New-AzureLoadBalancerInboundNatRuleConfig -Name "RDP1" `
    -FrontendIpConfiguration $feIpConfig `
    -Protocol TCP -FrontendPort 3441 -BackendPort 3389

$inboundNatRule2 = New-AzureLoadBalancerInboundNatRuleConfig -Name "RDP2" `
    -FrontendIpConfiguration $feIpConfig `
    -Protocol TCP -FrontendPort 3442 -BackendPort 3389

$beAddressPool = New-AzureLoadBalancerBackendAddressPoolConfig -Name "LBBE"


$healthProbe = New-AzureLoadBalancerProbeConfig -Name "HealthProbe" `
   -RequestPath "HealthProbe.aspx" -Protocol http -Port 80 `
   -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureLoadBalancerRuleConfig -Name "HTTP" `
   -FrontendIpConfiguration $feIpConfig -BackendAddressPool $beAddressPool `
   -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$alb = New-AzureLoadBalancer -ResourceGroupName $resourceGroupName `
   -Name "ALB" -Location $location -FrontendIpConfiguration $feIpConfig `
   -InboundNatRule $inboundNatRule1,$inboundNatRule2 `
   -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool `
   -Probe $healthProbe

$nic1 = New-AzureNetworkInterface -ResourceGroupName $resourceGroupName `
   -Name "nic1" -Subnet $subnet -Location $location `
   -LoadBalancerInboundNatRule $alb.InboundNatRules[0] `
   -LoadBalancerBackendAddressPool $alb.BackendAddressPools[0]

$nic2 = New-AzureNetworkInterface -ResourceGroupName $resourceGroupName `
   -Name "nic2" -Subnet $subnet -Location $location `
   -LoadBalancerInboundNatRule $alb.InboundNatRules[1] `
   -LoadBalancerBackendAddressPool $alb.BackendAddressPools[0]


New-AzureAvailabilitySet -ResourceGroupName $resourceGroupName `
   -Name "AVSet" -Location $location

$avset = Get-AzureAvailabilitySet -ResourceGroupName $resourceGroupName -Name "AVSet"

New-AzureStorageAccount -ResourceGroupName $resourceGroupName `
   -Name $testName -Location $location -Type Standard_LRS

Get-AzureStorageAccount -ResourceGroupName $resourceGroupName

$cred = Get-Credential

[array]$nics = @($nic1,$nic2)

For ($i=0; $i -le 1; $i++)  { 
       
    $vmName = "$testName-w$i"

    $vmConfig = New-AzureVMConfig -VMName $vmName -VMSize "Standard_A1" `
       -AvailabilitySetId $avSet.Id |

        Set-AzureVMOperatingSystem -Windows -ComputerName $vmName `
           -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  |

        Set-AzureVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku `
           -Version $version |

        Set-AzureVMOSDisk -Name $vmName -VhdUri "https://$testName.blob.core.windows.net/vhds/$vmName-os.vhd" `
           -Caching ReadWrite -CreateOption fromImage  |

        Add-AzureVMNetworkInterface -Id $nics[$i].Id

    New-AzureVM -ResourceGroupName $resourceGroupName -Location $location `
       -VM $vmConfig -Name  $vmName
}


(Get-AzurePublicIpAddress -ResourceGroupName $resourceGroupName).IpAddress

Get-AzureResourceGroup $resourceGroupName

