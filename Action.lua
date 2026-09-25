-- ينفّذ مرة واحدة عند تشغيل الاسطوانة
SetupFolder = Shell.GetFolder(SHF_DESKTOP) .. "\\TechSmith Setup";
Folder.Create(SetupFolder);

-- false = أنشئ ملف جديد (true = أضف للملف الموجود)
File.Copy("AutoPlay\\Docs\\snagit\\snagit.mst", SetupFolder, true, true, false, true, nil);
File.Copy("AutoPlay\\Docs\\espritmarin_info.txt", SetupFolder, true, false, false, true, nil);

-- جلب معلومات Windows
local ver = System.GetOSVersionInfo()
local build = tonumber(ver.BuildNumber)

-- تحقق من Win10/11 و 64-bit
local winOK = (build >= 10240)
local is64  = System.Is64BitOS()

-- القرار الصحيح
if  winOK and is64 then
    -- ? متوافق - لا تفعل شيء
else
    -- ? غير متوافق - اذهب لصفحة nocompat
    Page.Navigate(PAGE_LAST)
end 

CamtasiaInstallResult = "";
SnagitInstallResult = "";
