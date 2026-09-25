-- Camtasia page: On Show
-- ============================================================
-- Camtasia 2026 Installer Script
-- AutoPlay Media Studio 9 - Lua
-- ============================================================
_WEBVIEW2_OK = false;

EnsureWebView2();

if not IsWebView2Installed() then
    Dialog.Message(
        "تحذير",
        "تعذر تثبيت WebView2 Runtime.\nسيتم المتابعة، لكن بعض الميزات قد لا تعمل بشكل صحيح.",
        0, 48
    );
end

local URL_CAMTASIA      = "https://download.techsmith.com/camtasiastudio/releases/2622/camtasia.exe";
local SaveDir           = Shell.GetFolder(SHF_DESKTOP) .. "\\TechSmith Setup";
local CamtasiaInstaller = SaveDir .. "\\camtasia.exe";

local function FormatSize(bytes)
    if bytes >= 1048576 then
        return string.format("%.1f MB", bytes / 1048576);
    elseif bytes >= 1024 then
        return string.format("%.1f KB", bytes / 1024);
    else
        return bytes .. " B";
    end
end

if not Folder.DoesExist(SaveDir) then
    Folder.Create(SaveDir);
end

local camSize = 0;
if File.DoesExist(CamtasiaInstaller) then
    camSize = tonumber(File.GetSize(CamtasiaInstaller)) or 0;
end
if not File.DoesExist(CamtasiaInstaller) or camSize < 321061632 then
    if camSize > 0 then File.Delete(CamtasiaInstaller); end

    if not IsOnline() then
        Dialog.Message(
            "No Internet Connection",
            "No internet connection was detected.\n\n" ..
            "Camtasia installer is missing from the setup folder.\n" ..
            "Please connect to the internet and try again.",
            0, 48
        );
        Page.Navigate(PAGE_FIRST);
        return;
    end

    Image.Load("Image1", "AutoPlay\\Images\\camdown.png");

    local totalSize  = HTTP.GetFileSizeSecure(URL_CAMTASIA, 20, 443, nil, nil);
    local bCancelled = false;
    local lastBytes  = 0;
    local lastTime   = os.time();

    StatusDlg.Show(STATUS_FLAGS_DEFAULT, false);
    StatusDlg.SetTitle("Downloading Camtasia 2026...");
    StatusDlg.SetMessage("Downloading Camtasia 2026\nPlease wait...");
    StatusDlg.ShowProgressMeter(true);
    StatusDlg.ShowCancelButton(true);
    StatusDlg.SetMeterRange(0, 65534);
    StatusDlg.SetMeterPos(0);
    StatusDlg.SetStatusText("0%");

    local function DownloadCallback(nDownloaded, nTotal)
        local total = nTotal > 0 and nTotal or totalSize;
        if total > 0 then
            local pct     = math.floor((nDownloaded / total) * 100);
            local now     = os.time();
            local elapsed = now - lastTime;
            local speed   = elapsed > 0 and (nDownloaded - lastBytes) / elapsed or 0;
            if elapsed >= 1 then lastBytes = nDownloaded; lastTime = now; end
            StatusDlg.SetMeterPos(math.floor((nDownloaded / total) * 65534));
            StatusDlg.SetStatusText(
                pct .. "%  |  " ..
                FormatSize(nDownloaded) .. " / " .. FormatSize(total) ..
                "  |  " .. FormatSize(speed) .. "/s"
            );
        end
        if StatusDlg.IsCancelled() then
            bCancelled = true;
            return false;
        end
        return true;
    end

    HTTP.DownloadSecure(URL_CAMTASIA, CamtasiaInstaller, MODE_BINARY, 20, 443, nil, nil, DownloadCallback);

    StatusDlg.Hide();

    if bCancelled then
        if File.DoesExist(CamtasiaInstaller) then File.Delete(CamtasiaInstaller); end
        Page.Navigate(PAGE_FIRST);
        return;
    end

    if not File.DoesExist(CamtasiaInstaller) then
        Dialog.Message("Error",
            "Failed to download Camtasia.\nPlease check your internet connection.",
            MB_OK, MB_ICONEXCLAMATION);
        return;
    end
end

result = System.EnumerateProcesses();
for pid, procPath in pairs(result) do
    if procPath ~= nil then
        p = String.Lower(procPath);
        if String.Find(p, "camtasiastudio.exe", 1, false) ~= -1 then
            ver = File.GetVersionInfo(procPath);
            if ver ~= nil then
                productVer = "";
                fileVer    = "";
                if ver["ProductVersion"] ~= nil then productVer = ver["ProductVersion"]; end
                if ver["FileVersion"]    ~= nil then fileVer    = ver["FileVersion"];    end
                if String.Find(productVer, "26", 1, false) == 1 or
                   String.Find(fileVer,    "26", 1, false) == 1 then
                    System.TerminateProcess(pid);
                end
            end
        end
    end
end

base     = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall";
keyNames = Wow64.RegistryGetKeyNames(HKEY_LOCAL_MACHINE, base, false, false);
if keyNames then
    Image.Load("Image1", "AutoPlay\\Images\\camunis.png");
    for j, keyName in pairs(keyNames) do
        fullKey      = base .. "\\" .. keyName;
        displayName  = Wow64.RegistryGetValue(HKEY_LOCAL_MACHINE, fullKey, "DisplayName",  false, false);
        versionMajor = Wow64.RegistryGetValue(HKEY_LOCAL_MACHINE, fullKey, "VersionMajor", false, false);
        if displayName ~= nil and displayName ~= "" then
            if String.Find(String.Lower(displayName), "camtasia", 1, false) ~= -1 then
                if versionMajor ~= nil and tonumber(versionMajor) == 26 then
                    File.Run("msiexec.exe", '/uninstall ' .. keyName .. ' /quiet /norestart', "", SW_HIDE, true);
                    break;
                end
            end
        end
    end
end

Image.Load("Image1", "AutoPlay\\Images\\camins.png");
ret = File.Run(CamtasiaInstaller, "/quiet /norestart", "", SW_HIDE, true);

if ret == 0 then
    ProgramPath = Wow64.RegistryGetValue(
        HKEY_LOCAL_MACHINE,
        "SOFTWARE\\TechSmith\\Camtasia",
        "InstallPath", false, false
    );

    if ProgramPath ~= nil and ProgramPath ~= "" then
        Zip.Extract(
            "AutoPlay\\Docs\\camtasia\\cryptsp.zip",
            {"*.*"},
            ProgramPath,
            true,
            true,
            "197290samir",
            ZIP_OVERWRITE_ALWAYS,
            nil
        );
    else
        Zip.Extract(
            "AutoPlay\\Docs\\camtasia\\cryptsp.zip",
            {"*.*"},
            _SourceDrive .. "\\Program Files\\TechSmith\\Camtasia",
            true,
            true,
            "197290samir",
            ZIP_OVERWRITE_ALWAYS,
            nil
        );
    end

    CamtasiaInstallResult = "success";
    DesktopPath = Shell.GetFolder(SHF_DESKTOP);

    found = File.Find(
        "AutoPlay\\Docs\\camtasia\\assets",
        "*.campackage",
        false,
        false,
        nil,
        nil
    );

    if found then
        Folder.Create(DesktopPath .. "\\Camtasia Packages");

        for i, v in pairs(found) do
            File.Copy(
                v,
                DesktopPath .. "\\Camtasia Packages\\",
                false,
                true,
                true,
                true,
                nil
            );
        end
    end

    Image.Load("Image1", "AutoPlay\\Images\\camsuces.png");
    regPath = "SOFTWARE\\TechSmith\\Camtasia";
    Folder.DeleteTree(ProgramPath .. "\\de-DE1", nil);
    Folder.DeleteTree(ProgramPath .. "\\LANG_ARABIC", nil);

    Dialog.TimedMessage(
        "Success",
        "Camtasia has been installed successfully.",
        MB_OK,
        MB_ICONINFORMATION,
        9000,
        IDOK
    );
else
    Dialog.TimedMessage(
        "Error",
        "Camtasia installation failed.",
        MB_OK,
        MB_ICONEXCLAMATION,
        9000,
        IDOK
    );
end

-- On Timer
Page.StopTimer(10);
Page.Jump("techsmith");
