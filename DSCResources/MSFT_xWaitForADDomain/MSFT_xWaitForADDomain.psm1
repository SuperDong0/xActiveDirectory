function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory=$false)]
        [PSCredential]$DomainUserCredential,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [bool]$Terminate = $true
    )

    if($DomainUserCredential)
    {
        $convertToCimCredential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$DomainUserCredential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
    }
    else
    {
        $convertToCimCredential = $null
    }

    $returnValue = @{
        DomainName = $DomainName
        DomainUserCredential = $convertToCimCredential
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
        Terminate = $terminate
    }
    
    $returnValue
}


function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory=$false)]
        [PSCredential]$DomainUserCredential,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [bool]$Terminate = $true
    )

    $domainFound = $false
    Write-Verbose -Message "Checking for domain $DomainName ..."

    for($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $context = $null
            
            if($DomainUserCredential)
            {
                $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $domainName, $DomainUserCredential.UserName, $DomainUserCredential.GetNetworkCredential().Password)
            }
            else
            {
	            $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain',$domainName)
            }
 	    
            $domainController = $null  
            $domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($context)
            Write-Verbose -Message "Found domain $DomainName"
            $domainFound = $true
            break;
        }
        catch
        {
            Write-Verbose -Message "Domain $DomainName not found. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
        }
    }

    if(! $domainFound) 
    {
        if($Terminate)
        {
            throw "Domain '$($DomainName)' NOT found after $RetryCount attempts."
        }
        else
        {
            Write-Verbose -Message  "Domain $DomainName not found after $count attempts with $RetryIntervalSec sec interval. Rebooting."
            $global:DSCMachineStatus = 1
        }
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory=$false)]
        [PSCredential]$DomainUserCredential,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [bool]$Terminate = $true
    )

    Write-Verbose -Message "Checking for domain $DomainName ..."
    try
    {
        if($DomainUserCredential)
        {
            $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $domainName, $DomainUserCredential.UserName, $DomainUserCredential.GetNetworkCredential().Password)
        }
        else
        {
	       $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain',$domainName)
        }
 	        
        $domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($context)
        Write-Verbose -Message "Found domain $DomainName"
        $true
    }
    catch
    {
        Write-Verbose -Message "Domain $DomainName not found"
        $false
    }
}

