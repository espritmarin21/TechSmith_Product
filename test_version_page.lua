-- test_version_page.lua
-- صفحة للتحقق من إصدار Camtasia باستخدام File.Download (AutoPlay)

--- دالة لجلب محتوى HTML من URL باستخدام File.Download
local function fetchHTML(url)
    local tempFile = System.GetWindowsFolder(SHF_TEMP) .. "\\version_check.html"
    
    -- تنزيل الصفحة إلى ملف مؤقت
    local success = File.Download(url, tempFile)
    if not success then
        return nil, "download_failed"
    end
    
    -- قراءة المحتوى
    local content = File.GetText(tempFile)
    
    -- حذف الملف المؤقت
    File.Delete(tempFile)
    
    return content
end

--- دالة لاستخراج آخر إصدار Camtasia 2026 من صفحة TechSmith
local function getLatestCamtasiaVersion()
    local url = "https://support.techsmith.com/hc/en-us/articles/41261973472269-Camtasia-Windows-2026-Version-History"
    local html, err = fetchHTML(url)
    if not html then
        return nil, "fetch_failed: " .. tostring(err)
    end

    -- نمط البحث عن إصدار مثل 2026.x.x
    local pattern = "(2026%.%d+%.%d+)"
    local firstMatch = html:match(pattern)
    if not firstMatch then
        return nil, "version_not_found"
    end

    return firstMatch
end

--- تحويل إصدار نصي "2026.2.2" إلى رقم قابل للمقارنة (2622)
local function versionToNumber(verStr)
    -- نتوقع نمط: YYYY.x.x
    local year, major, minor = verStr:match("^(%d+)%.(%d+)%.(%d+)$")
    if not year then
        return nil
    end
    local y = tonumber(year)
    local maj = tonumber(major)
    local min = tonumber(minor)
    -- نبسط: (y-2000)*100 + maj*10 + min
    return (y - 2000) * 100 + maj * 10 + min
end

--- دالة رئيسية للتحقق من التحديث
function CheckForCamtasiaUpdate()
    local localVersionNum = _G.LocalCamtasiaVersionNum
    if not localVersionNum then
        return { status = "no_local_version", message = "لا يوجد إصدار محلي معروف" }
    end

    local latestVerStr, err = getLatestCamtasiaVersion()
    if not latestVerStr then
        return { status = "fetch_error", message = "فشل جلب الإصدار: " .. tostring(err) }
    end

    local latestNum = versionToNumber(latestVerStr)
    if not latestNum then
        return { status = "parse_error", message = "فشل تحليل الإصدار: " .. latestVerStr }
    end

    if latestNum > localVersionNum then
        return {
            status = "update_available",
            localVersion = localVersionNum,
            latestVersion = latestVerStr,
            latestVersionNum = latestNum,
            message = "يتوفر إصدار أحدث: " .. latestVerStr
        }
    else
        return {
            status = "up_to_date",
            localVersion = localVersionNum,
            latestVersion = latestVerStr,
            latestVersionNum = latestNum,
            message = "الإصدار محدّث"
        }
    end
end

-- استدعاء الدالة تلقائيًا عند تحميل الصفحة
_G.LocalCamtasiaVersionNum = _G.LocalCamtasiaVersionNum or 2622
local result = CheckForCamtasiaUpdate()
Dialog.Message(result.message, "Camtasia Version Check")
