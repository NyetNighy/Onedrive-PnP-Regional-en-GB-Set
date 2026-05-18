$AdminUrl = "https://YOURTENANT-admin.sharepoint.com"
$ClientId = "YOUR-CLIENT-ID"
$AdminUser = "365AdminUser"

# Connect once to SharePoint Admin Center
$AdminConnection = Connect-PnPOnline `
    -Url $AdminUrl `
    -Interactive `
    -ClientId $ClientId `
    -ReturnConnection

# Get OneDrive sites
$OneDriveSites = Get-PnPTenantSite `
    -IncludeOneDriveSites `
    -Connection $AdminConnection `
    -Filter "Url -like '-my.sharepoint.com/personal/'"

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "PASS 1 - Adding Site Admins" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

foreach ($Site in $OneDriveSites)
{
    Write-Host "Adding admin to $($Site.Url)" -ForegroundColor Cyan

    try
    {
        # Skip non-active sites
        if ($Site.Status -ne "Active")
        {
            Write-Host "Skipping non-active site" -ForegroundColor Yellow
            continue
        }

        # Add Site Collection Admin
        Set-PnPTenantSite `
            -Identity $Site.Url `
            -Owners $AdminUser `
            -Connection $AdminConnection `
            -ErrorAction Stop

        Write-Host "Admin added successfully" -ForegroundColor Green
    }
    catch
    {
        Write-Host "FAILED: $($Site.Url)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "Waiting for permission propagation..." -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

# Wait 5 minutes with countdown
$WaitSeconds = 300

for ($i = $WaitSeconds; $i -ge 1; $i--)
{
    $Minutes = [math]::Floor($i / 60)
    $Seconds = $i % 60

    Write-Progress `
        -Activity "Waiting for SharePoint permission propagation" `
        -Status "$Minutes minutes $Seconds seconds remaining" `
        -PercentComplete ((($WaitSeconds - $i) / $WaitSeconds) * 100)

    Start-Sleep -Seconds 1
}

Write-Progress `
    -Activity "Waiting for SharePoint permission propagation" `
    -Completed

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "PASS 2 - Updating Regional Settings" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

foreach ($Site in $OneDriveSites)
{
    Write-Host "Processing $($Site.Url)" -ForegroundColor Cyan

    try
    {
        # Skip non-active sites
        if ($Site.Status -ne "Active")
        {
            Write-Host "Skipping non-active site" -ForegroundColor Yellow
            continue
        }

        # Reuse existing admin authentication
        $ODConnection = Connect-PnPOnline `
            -Url $Site.Url `
            -ClientId $ClientId `
            -Connection $AdminConnection `
            -ReturnConnection

        # Get web
        $Web = Get-PnPWeb -Connection $ODConnection

        # Set Locale to English UK
        $Web.RegionalSettings.LocaleId = 2057

        $Web.Update()

        Invoke-PnPQuery -Connection $ODConnection

        Write-Host "Regional settings updated successfully" -ForegroundColor Green
    }
    catch
    {
        Write-Host "FAILED: $($Site.Url)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "Processing Complete" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
