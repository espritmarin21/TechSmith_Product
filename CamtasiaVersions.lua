-- رابط صفحة إصدارات Camtasia 2026
local VersionUrl =
    "https://support.techsmith.com/hc/en-us/articles/41261973472269-Camtasia-Windows-2026-Version-History"

-- ملف مؤقت داخل مجلد الإعداد الموجود لديك
local VersionFile = SetupFolder .. "\\version_check.html"

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
        "Failed to download the version page from TechSmith.",
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

-- استخراج الإصدار: يقبل 2026.2.2 أو 26.2.2 أو 26.2.2.xxxxx
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

-- بناء القائمة للـ ComboBox
local ComboList = {
    Version,              -- 26.2.2 (آخر إصدار)
    "2025: 2025.2.6",
    "2024: 2024.1.9",
    "2023: 2023.4.10"
}

-- إنشاء ComboBox
local Selected = Dialog.ComboBox(
    "Camtasia Versions",
    "Final versions:",
    ComboList,
    Version,   -- DefaultItem = 26.2.2 تظهر محددة عند الفتح
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