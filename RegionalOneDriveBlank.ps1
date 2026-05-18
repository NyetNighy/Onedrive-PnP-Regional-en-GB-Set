$AdminUrl = "https://YOURTENANT-admin.sharepoint.com"
$ClientId = "YOUR-CLIENT-ID"
$AdminUser = "365AdminUser"

# ==============================
# CONNECT TO SHAREPOINT ADMIN
# ==============================

$AdminConnection = Connect-PnPOnline `
    -Url $AdminUrl `
    -Interactive `
    -ClientId $ClientId `
    -ReturnConnection

# ==============================
# GET ONEDRIVE SITES
# ==============================

$OneDriveSites = Get-PnPTenantSite `
    -IncludeOneDriveSites `
    -Connection $AdminConnection `
    -Filter "Url -like '-my.sharepoint.com/personal/'"

# ==============================
# PASS 1 - ADD SITE ADMINS
# ==============================

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "PASS 1 - ADDING SITE ADMINS" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

foreach ($Site in $OneDriveSites)
{
    Write-Host "Checking admin access for $($Site.Url)" -ForegroundColor Cyan

    try
    {
        # Skip non-active sites
        if ($Site.Status -ne "Active")
        {
            Write-Host "Skipping non-active site" -ForegroundColor Yellow
            continue
        }

        # Connect to OneDrive
        Connect-PnPOnline `
            -Url $Site.Url `
            -Interactive `
            -ClientId $ClientId

        # Get current site collection admins
        $Admins = Get-PnPSiteCollectionAdmin -ErrorAction Stop

        # Check if admin already exists
        $AdminExists = $Admins | Where-Object {
            $_.LoginName -match $AdminUser
        }

        if ($AdminExists)
        {
            Write-Host "$AdminUser already has access" -ForegroundColor Green
        }
        else
        {
            Write-Host "Adding admin access..." -ForegroundColor Yellow

            Set-PnPTenantSite `
                -Identity $Site.Url `
                -Owners $AdminUser `
                -Connection $AdminConnection `
                -ErrorAction Stop

            Write-Host "Admin added successfully" -ForegroundColor Green
        }
    }
    catch
    {
        Write-Host "FAILED: $($Site.Url)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# ==============================
# WAIT FOR PROPAGATION
# ==============================

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "WAITING FOR PERMISSION PROPAGATION" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

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

# ==============================
# PASS 2 - UPDATE REGIONAL SETTINGS
# ==============================

Write-Host ""
Write-Host "==============================" -ForegroundColor Yellow
Write-Host "PASS 2 - UPDATING REGIONAL SETTINGS" -ForegroundColor Yellow
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

        # Connect to OneDrive
        Connect-PnPOnline `
            -Url $Site.Url `
            -Interactive `
            -ClientId $ClientId

        # Get web
        $Web = Get-PnPWeb

        # Set locale to English UK
        $Web.RegionalSettings.LocaleId = 2057

        $Web.Update()

        Invoke-PnPQuery

        Write-Host "Regional settings updated successfully" -ForegroundColor Green
    }
    catch
    {
        Write-Host "FAILED: $($Site.Url)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# ==============================
# COMPLETE
# ==============================

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "PROCESSING COMPLETE" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
