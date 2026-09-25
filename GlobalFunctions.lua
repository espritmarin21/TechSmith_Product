-- التحقق من الاتصال بالإنترنت
function IsOnline()
    return HTTP.TestConnection("http://www.google.com", 10, 80, nil, nil);
end

-- التحقق من تثبيت WebView2
function IsWebView2Installed()
    local guid       = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}";
    local keyMachine = "SOFTWARE\\WOW6432Node\\Microsoft\EdgeUpdate\\Clients\\" .. guid;
    local keyUser    = "Software\\Microsoft\EdgeUpdate\\Clients\\" .. guid;

    local pv = Wow64.RegistryGetValue(HKEY_LOCAL_MACHINE, keyMachine, "pv", false, false);
    if pv ~= nil and pv ~= "" and pv ~= "0.0.0.0" then
        return true;
    end

    pv = Wow64.RegistryGetValue(HKEY_CURRENT_USER, keyUser, "pv", false, false);
    if pv ~= nil and pv ~= "" and pv ~= "0.0.0.0" then
        return true;
    end

    return false;
end

-- تنسيق حجم البيانات
local function FormatSize(bytes)
    if bytes >= 1048576 then
        return string.format("%.1f MB", bytes / 1048576);
    elseif bytes >= 1024 then
        return string.format("%.1f KB", bytes / 1024);
    else
        return bytes .. " B";
    end
end

-- التأكد من تثبيت WebView2 أو تنزيله إن لزم
function EnsureWebView2()
    local SW_HIDE = 0;
    local SaveDir = Shell.GetFolder(SHF_DESKTOP) .. "\\TechSmith Setup";
    local Wv2File = SaveDir .. "\\MicrosoftEdgeWebView2RuntimeInstallerX64.exe";
    local Wv2Url  = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/e4dd9b83-b7e3-4d17-8d7c-e14cdd7c3a51/MicrosoftEdgeWebView2RuntimeInstallerX64.exe";

    -- إذا كان مثبتًا مسبقًا لا حاجة لشيء
    if IsWebView2Installed() then
        _WEBVIEW2_OK = true;
        return true;
    end

    -- الملف غير موجود ؟ نحتاج إنترنت
    if not File.DoesExist(Wv2File) then

        -- افحص الإنترنت أولًا
        if not IsOnline() then
            Dialog.Message(
                "No Internet Connection",
                "No internet connection was detected.\n\n" ..
                "A required file (WebView2) is missing from the setup folder.\n" ..
                "Please connect to the internet and try again.",
                0, 48
            );
            Page.Navigate(PAGE_FIRST);
            return false;
        end

        local totalSize = HTTP.GetFileSizeSecure(Wv2Url, 20, 443, nil, nil);

        local bCancelled = false;
        local lastBytes  = 0;
        local lastTime   = os.time();

        StatusDlg.Show(0, false);
        StatusDlg.ShowProgressMeter(true);
        StatusDlg.ShowCancelButton(true);
        StatusDlg.SetTitle("Downloading WebView2...");
        StatusDlg.SetMeterRange(0, 65534);
        StatusDlg.SetMeterPos(0);
        StatusDlg.SetMessage("Downloading WebView2 Runtime\nPlease wait...");
        StatusDlg.SetStatusText("0%");

        local function DownloadCallback(nDownloaded, nTotal)
            local total = nTotal > 0 and nTotal or totalSize;
            if total > 0 then
                local pct     = math.floor((nDownloaded / total) * 100);
                local now     = os.time();
                local elapsed = now - lastTime;
                local speed   = elapsed > 0 and (nDownloaded - lastBytes) / elapsed or 0;

                if elapsed >= 1 then
                    lastBytes = nDownloaded;
                    lastTime  = now;
                end

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

        HTTP.DownloadSecure(
            Wv2Url,
            Wv2File,
            MODE_BINARY,
            20,
            443,
            nil,
            nil,
            DownloadCallback
        );

        StatusDlg.Hide();

        -- عند الإلغاء: احذف الملف + رسالة + رجوع للصفحة الأولى
        if bCancelled then
            if File.DoesExist(Wv2File) then File.Delete(Wv2File); end
            Dialog.Message(
                "Installation Cancelled",
                "Cannot complete installation without Microsoft WebView2 Runtime.\n\n" ..
                "Please try again when you are ready.",
                0, 48
            );
            Page.Navigate(PAGE_FIRST);
            return false;
        end

        if not File.DoesExist(Wv2File) then
            Dialog.Message("Error", "WebView2 download failed.", 0, 48);
            Page.Navigate(PAGE_FIRST);
            return false;
        end
    end

    -- الملف موجود ؟ ثبّت
    File.Run(Wv2File, "/silent /install", "", SW_HIDE, true);

    _WEBVIEW2_OK = IsWebView2Installed();

    if not _WEBVIEW2_OK then
        Dialog.Message("Error", "WebView2 installation failed.", 0, 48);
        Page.Navigate(PAGE_FIRST);
        return false;
    end

    return true;
end
