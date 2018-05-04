require("mkmf")

module GUBG
    module MSVC
        def self.load_compiler(arch)
            base = "c:/Program Files (x86)/Microsoft Visual Studio/2017/Community"
            dirs = {
                base: base,
                vc: "#{base}/VC",
                tools: "#{base}/VC/Tools",
                msvc: "#{base}/VC/Tools/MSVC",
            }
            version = find_versions(dirs[:msvc]).last
            raise "No msvc version found" unless version
            puts "Found msvc version #{version}"
            dirs[:version] = "#{dirs[:msvc]}/#{version}"

            dirs.each { |sym,dir| dir.gsub!("/", "\\") }

            vars, path = nil
            case arch
            when :x86
                #This is the diff between running "set" before and after loading "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvars32.bat"
                #Note that the Path env var is handled separately: we cannot simply overwrite it, but need to prepend the MSVC part befor what is already present
                vars = %Q[
CommandPromptType=Native
DevEnvDir=#{dirs[:base]}\\Common7\\IDE\\
ExtensionSdkDir=C:\\Program Files (x86)\\Microsoft SDKs\\Windows Kits\\10\\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\\windows\\Microsoft.NET\\Framework\\
FrameworkDIR32=C:\\windows\\Microsoft.NET\\Framework\\
FrameworkVersion=v4.0.30319
FrameworkVersion32=v4.0.30319
INCLUDE=#{dirs[:version]}\\ATLMFC\\include;#{dirs[:version]}\\include;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\include\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\ucrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\shared;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\winrt;
LIB=#{dirs[:version]}\\ATLMFC\\lib\\x86;#{dirs[:version]}\\lib\\x86;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\lib\\um\\x86;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.15063.0\\ucrt\\x86;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.15063.0\\um\\x86;
LIBPATH=#{dirs[:version]}\\ATLMFC\\lib\\x86;#{dirs[:version]}\\lib\\x86;C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\10.0.15063.0\\;C:\\Program Files (x86)\\Windows Kits\\10\\References\\10.0.15063.0\\;C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319;
NETFXSDKDir=C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\
Platform=x86
UCRTVersion=10.0.15063.0
UniversalCRTSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
VCIDEInstallDir=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\VC\\
VCINSTALLDIR=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\
VCToolsInstallDir=#{dirs[:version]}\\
VCToolsRedistDir=#{dirs[:vc]}\\Redist\\MSVC\\#{version}\\
VisualStudioVersion=15.0
VS150COMNTOOLS=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\Tools\\
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x86
VSCMD_ARG_TGT_ARCH=x86
VSCMD_VER=15.0.26430.6
VSINSTALLDIR=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\
WindowsLibPath=C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\10.0.15063.0\\;C:\\Program Files (x86)\\Windows Kits\\10\\References\\10.0.15063.0\\
WindowsSdkBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\
WindowsSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
WindowsSDKLibVersion=10.0.15063.0\\
WindowsSdkVerBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.15063.0\\
WindowsSDKVersion=10.0.15063.0\\
WindowsSDK_ExecutablePath_x64=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\x64\\
WindowsSDK_ExecutablePath_x86=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\
__DOTNET_ADD_32BIT=1
__DOTNET_PREFERRED_BITNESS=32
                ]
                path = "#{dirs[:version]}\\bin\\HostX86\\x86;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\VC\\VCPackages;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\bin\\Roslyn;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Team Tools\\Performance Tools;C:\\Program Files (x86)\\Microsoft Visual Studio\\Shared\\Common\\VSPerfCollectionTools\\;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x86;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.15063.0\\x86;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\\\MSBuild\\15.0\\bin;C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\Tools\\;"
            when :x64
                #This is the diff between running "set" before and after loading "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvars64.bat"
                #Note that the Path env var is handled separately: we cannot simply overwrite it, but need to prepend the MSVC part befor what is already present
                vars = %Q[
CommandPromptType=Native
DevEnvDir=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\
ExtensionSdkDir=C:\\Program Files (x86)\\Microsoft SDKs\\Windows Kits\\10\\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\\windows\\Microsoft.NET\\Framework64\\
FrameworkDIR64=C:\\windows\\Microsoft.NET\\Framework64
FrameworkVersion=v4.0.30319
FrameworkVersion64=v4.0.30319
INCLUDE=#{dirs[:version]}\\ATLMFC\\include;#{dirs[:version]}\\include;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\include\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\ucrt;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\shared;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\um;C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.15063.0\\winrt;
LIB=#{dirs[:version]}\\ATLMFC\\lib\\x64;#{dirs[:version]}\\lib\\x64;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\lib\\um\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.15063.0\\ucrt\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\lib\\10.0.15063.0\\um\\x64;
LIBPATH=#{dirs[:version]}\\ATLMFC\\lib\\x64;#{dirs[:version]}\\lib\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\10.0.15063.0\\;C:\\Program Files (x86)\\Windows Kits\\10\\References\\10.0.15063.0\\;C:\\windows\\Microsoft.NET\\Framework64\\v4.0.30319;
NETFXSDKDir=C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\
Platform=x64
UCRTVersion=10.0.15063.0
UniversalCRTSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
VCIDEInstallDir=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\VC\\
VCINSTALLDIR=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\
VCToolsInstallDir=#{dirs[:version]}\\
VCToolsRedistDir=#{dirs[:vc]}\\Redist\\MSVC\\#{version}\\
VisualStudioVersion=15.0
VS150COMNTOOLS=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\Tools\\
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x64
VSCMD_ARG_TGT_ARCH=x64
VSCMD_VER=15.0.26430.6
VSINSTALLDIR=c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\
WindowsLibPath=C:\\Program Files (x86)\\Windows Kits\\10\\UnionMetadata\\10.0.15063.0\\;C:\\Program Files (x86)\\Windows Kits\\10\\References\\10.0.15063.0\\
WindowsSdkBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\
WindowsSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
WindowsSDKLibVersion=10.0.15063.0\\
WindowsSdkVerBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.15063.0\\
WindowsSDKVersion=10.0.15063.0\\
WindowsSDK_ExecutablePath_x64=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\x64\\
WindowsSDK_ExecutablePath_x86=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\
__DOTNET_ADD_64BIT=1
__DOTNET_PREFERRED_BITNESS=64
                ]
                path = "#{dirs[:version]}\\bin\\HostX64\\x64;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\VC\\VCPackages;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\bin\\Roslyn;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Team Tools\\Performance Tools;C:\\Program Files (x86)\\Microsoft Visual Studio\\Shared\\Common\\VSPerfCollectionTools\\;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.15063.0\\x64;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\\\MSBuild\\15.0\\bin;C:\\windows\\Microsoft.NET\\Framework64\\v4.0.30319;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\IDE\\;c:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\Common7\\Tools\\;"
            end
            vars.each_line do |line|
                line.chomp!
                line.strip!
                next if line.empty?
                k,v = *line.split("=")
                ENV[k] = v
            end
            ENV["Path"] = path+ENV["Path"]
        end
        def self.find_versions(dir)
            versions = Dir["#{dir}/*"]
            versions.map! do |path|
                path["#{dir}/"] = ""
                path
            end
            versions
        end
    end
end
