
#Enter name of the ResourceGroup in which you want to create VM
$resourceGroupNameNodes ='RG-PHD-VMNODES-TST1'

$nodeSufix = "1"

#Enter name of the Managed Disk
$diskName = 'phd-disk-node' + $nodeSufix


#Enter the name of the virtual machine to be created
$virtualMachineName = 'PHD-NODE' + $nodeSufix


#Enter name of the ResourceGroup in which you have the snapshots
$resourceGroupName ='RG-PHD-VM-SNAPSHOT'



#Enter name of the snapshot that will be used to create Managed Disks
$snapshotName = 'PHD-VM-DISC'

#Enter size of the disk in GB
$diskSize = '128'

#Enter the storage type for Disk. PremiumLRS / StandardLRS.
$storageType = 'Standard_LRS'

#Enter the Azure region where Managed Disk will be created. It should be same as Snapshot location
$location = 'westeurope'

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId '2d335f20-77b0-4a56-ac60-dc7018c9e5ee'

#Get the Snapshot ID by using the details provided
$snapshot = Get-AzureRmSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName 

#Create a new Managed Disk from the Snapshot provided 
$disk = New-AzureRmDiskConfig -AccountType $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id



New-AzureRmResourceGroup -Name $resourceGroupNameNodes -Location "West Europe"

New-AzureRmDisk -Disk $disk -ResourceGroupName $resourceGroupNameNodes -DiskName $diskName

# Create Public IP
$publicIpName = $virtualMachineName + 'pubIp'

$publicIp = New-AzPublicIpAddress -ResourceGroupName $rgName -Name $publicIpName -location $snapshot.Location -AllocationMethod Dynamic

# CREATE VM

$disk = Get-AzureRmDisk -ResourceGroupName $resourceGroupNameNodes -DiskName $diskName

#Enter the name of an existing virtual network where virtual machine will be created
$virtualNetworkName = 'RG-PHD-vnet'


#Provide the size of the virtual machine
$virtualMachineSize = 'Standard_D2_v3'

#Initialize virtual machine configuration
$VirtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize

#(Optional Step) Add data disk to the configuration. Enter DataDisk Id
# $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -Name $dataDiskName -ManagedDiskId $disk -Lun "0" -CreateOption "Attach"

#Use the Managed Disk Resource Id to attach it to the virtual machine. Use OS type based on the OS present in the disk - Windows / Linux
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

#Create a public IP 
$publicIp = New-AzureRmPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupNameNodes -Location $snapshot.Location -AllocationMethod Dynamic

#Get VNET Information
$vnet = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName 'RG-PHD'

# Create NIC for the VM
$nic = New-AzureRmNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupNameNodes -Location $snapshot.Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $resourceGroupNameNodes -Location $snapshot.Location -PublicIpAddressName 