# Onedrive-PnP-Regional-en-GB-Set
# Step-by-step: Create the Entra App Registration for PnP.PowerShell

This creates the app registration needed for modern PnP.PowerShell authentication.

---

# 1. Open Microsoft Entra Admin Center

https://entra.microsoft.com

Sign in as:
- Global Administrator
or
- Application Administrator

---

# 2. Create the App Registration

Go to:

- Identity
- Applications
- App registrations
- New registration

Fill in:

| Setting | Value |
|---|---|
| Name | `PnP.PowerShell` |
| Supported account types | `Accounts in this organizational directory only` |

Click:

```text
Register
```

---

# 3. Copy the Client ID

After creation, copy:

```text
Application (client) ID
```

This is the value used in PowerShell:

```powershell
$ClientId = "YOUR-CLIENT-ID"
```

---

# 4. Configure Authentication

Go to:

- Authentication
- Add a platform

Choose:

```text
Mobile and desktop applications
```

Enable BOTH redirect URIs:

```text
https://login.microsoftonline.com/common/oauth2/nativeclient
```

and

```text
http://localhost
```

---

# 5. Enable Public Client Flow

Still under Authentication:

Set:

| Setting | Value |
|---|---|
| Allow public client flows | Yes |

Click:

```text
Save
```

---

# 6. Add SharePoint Permissions

Go to:

- API permissions
- Add a permission

Choose:

```text
SharePoint
```

Then:

```text
Delegated permissions
```

Search for:

```text
AllSites.FullControl
```

Tick it.

Click:

```text
Add permissions
```

---

# 7. Grant Admin Consent

Still under API permissions:

Click:

```text
Grant admin consent for bctec.co.uk
```

The status should become:

```text
Granted for bctec.co.uk
```

---

# 8. Install PowerShell 7

Modern PnP works best in PowerShell 7.

Download:

https://github.com/PowerShell/PowerShell/releases

Then launch:

```powershell
pwsh
```

---

# 9. Install PnP.PowerShell

Run:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

---

# 10. Connect to SharePoint

Use:

```powershell
Connect-PnPOnline `
    -Url "https://YOURTENANT-admin.sharepoint.com" `
    -Interactive `
    -ClientId "YOUR-CLIENT-ID"
```

Example:

```powershell
Connect-PnPOnline `
    -Url "https://bcteccouk-admin.sharepoint.com" `
    -Interactive `
    -ClientId "23cccbe2-78f8-4659-8c4e-d7f828df07d4"
```

---

# 11. Verify Connection

Run:

```powershell
Get-PnPConnection
```

If connected successfully, you’re ready to automate SharePoint and OneDrive administration.
