Switch-AzureMode AzureResourceManager

$testName = "mvaiaasv2onevm"

$resourceGroupName = $testName
$location = "West US"

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2012-R2-Datacenter"
$version = "latest"

$subnetName = "Subnet-1"

New-AzureResourceGroup -Name $resourceGroupName -Location $location


New-AzureStorageAccount -ResourceGroupName $resourceGroupName `
   -Name $testName -Location $location -Type Standard_LRS


$subnet = New-AzureVirtualNetworkSubnetConfig -Name $subnetName `
   -AddressPrefix "10.0.64.0/24"

$vnet = New-AzureVirtualNetwork -Name "VNET" `
   -ResourceGroupName $resourceGroupName `
   -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet


$subnet = Get-AzureVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet


$pip = New-AzurePublicIpAddress -ResourceGroupName $resourceGroupName -Name "vip1" `
   -Location $location -AllocationMethod Dynamic -DomainNameLabel $testName


$nic = New-AzureNetworkInterface -ResourceGroupName $resourceGroupName `
   -Name "nic1" -Subnet $subnet -Location $location -PublicIpAddress $pip -PrivateIpAddress "10.0.64.4" 

New-AzureAvailabilitySet -ResourceGroupName $resourceGroupName `
   -Name "AVSet" -Location $location

$avset = Get-AzureAvailabilitySet -ResourceGroupName $resourceGroupName -Name "AVSet"

$cred = Get-Credential

$vmConfig = New-AzureVMConfig -VMName "$testName-w1" -VMSize "Standard_A1" `
   -AvailabilitySetId $avSet.Id | 

    Set-AzureVMOperatingSystem -Windows -ComputerName "contoso-w1" `
       -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  | 

    Set-AzureVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku `
       -Version $version | 

    Set-AzureVMOSDisk -Name "$testName-w1" -VhdUri "https://$testName.blob.core.windows.net/vhds/$testName-w1-os.vhd" `
       -Caching ReadWrite -CreateOption fromImage  | 

    Add-AzureVMNetworkInterface -Id $nic.Id


New-AzureVM -ResourceGroupName $resourceGroupName -Location $location `
   -VM $vmConfig -Name "$testName-w1"

(Get-AzurePublicIpAddress -ResourceGroupName $resourceGroupName).IpAddress

