-- رابط صفحة إصدارات Snagit 2026
local VersionUrl =
    "https://support.techsmith.com/hc/en-us/articles/42674936732685-Snagit-Windows-2026-Version-History"

-- ملف مؤقت في مجلد TEMP
local Temp = os.getenv("TEMP")
local VersionFile = Temp .. "\\snagit_version_check.html"

-- حذف ملف قديم إن وُجد
if File.DoesExist(VersionFile) then
    File.Delete(VersionFile)
end

-- تنزيل صفحة HTTPS
HTTP.DownloadSecure(
    VersionUrl,
    VersionFile,
    MODE_BINARY,
    20,
    443,
    nil,
    nil,
    nil
)

-- التحقق من نجاح التنزيل
if not File.DoesExist(VersionFile) then
    Dialog.Message(
        "Failed to download the version page from TechSmith (Snagit).",
        "Error",
        0,
        48
    )
    return
end

-- قراءة HTML
local Handle = io.open(VersionFile, "rb")

if not Handle then
    Dialog.Message(
        "Downloaded, but could not open the file for reading.",
        "Error",
        0,
        48
    )
    return
end

local Html = Handle:read("*a")
Handle:close()

-- حذف الملف المؤقت
File.Delete(VersionFile)

-- استخراج الإصدار: يقبل 2026.3.1 أو 26.3.1 أو 26.3.1.xxxxx
local Version =
    Html:match("(26%.%d+%.%d+%.%d+)") or
    Html:match("(26%.%d+%.%d+)") or
    Html:match("(2026%.%d+%.%d+)") or
    Html:match("(2026%.%d+)")

if not Version then
    Dialog.Message(
        "Downloaded the page, but could not find a version number.",
        "Error",
        0,
        48
    )
    return
end

-- بناء القائمة للـ ComboBox بأرقام دقيقة
local ComboList = {
    Version,              -- آخر إصدار (مثلاً 26.3.1)
    "2025: 2025.4.3",     -- 2025 النهائي
    "2024: 2024.3.8",     -- 2024 النهائي
    "2023: 2023.2.6"      -- 2023 النهائي
}

-- إنشاء ComboBox
local Selected = Dialog.ComboBox(
    "Snagit Versions",
    "Final versions:",
    ComboList,
    Version,   -- DefaultItem = الإصدار الأخير يظهر محددًا
    false,     -- SortItems
    false,     -- Editable
    64         -- Icon = MB_ICONINFORMATION
)

if Selected ~= "" and Selected ~= "CANCEL" then
    Dialog.Message(
        "You selected:\n" .. Selected,
        "Version Info",
        0,
        64
    )
end