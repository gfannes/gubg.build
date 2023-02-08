require("mkmf")

module Gubg
    module MSVC
        def self.load_compiler(arch)
            msvc, msvc_version = nil
            begin
                bases = {
                    2019 => 'c:/Program Files (x86)/Microsoft Visual Studio/2019/Community',
                    2022 => 'c:/Program Files/Microsoft Visual Studio/2022/Community',
                }
                base = bases.values().find{|b|File.exist?(b)}
                raise("Could not find a MSVC installation") unless base
                msvc = {
                    base: base,
                    vc: "#{base}/VC",
                    tools: "#{base}/VC/Tools",
                    msvc: "#{base}/VC/Tools/MSVC",
                }
                msvc_version = find_versions(msvc[:msvc]).last
                raise "No msvc version found" unless msvc_version
                puts "Found msvc version #{msvc_version}"
                msvc[:version] = "#{msvc[:msvc]}/#{msvc_version}"
                msvc.each { |sym,dir| dir.gsub!("/", "\\") }
            end

            kits, kit_version = nil
            begin
                base = "C:/Program Files (x86)/Windows Kits"
                kits = {
                    base: base,
                    fx: "#{base}/NETFXSDK",
                    v10: "#{base}/10",
                }
                kit_version = find_versions("#{kits[:v10]}/Include").last
                raise "No kits version found" unless kit_version
                puts "Found kits version #{kit_version}"
                kits[:include] = "#{kits[:v10]}/Include/#{kit_version}"
                kits[:lib] = "#{kits[:v10]}/lib/#{kit_version}"
                kits[:bin] = "#{kits[:v10]}/bin/#{kit_version}"
                kits[:umd] = "#{kits[:v10]}/UnionMetadata/#{kit_version}"
                kits[:refs] = "#{kits[:v10]}/References/#{kit_version}"
            end

            vars, path = nil
            case arch
            when :x86
                #This is the diff between running "set" before and after loading "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvars32.bat"
                #Note that the Path env var is handled separately: we cannot simply overwrite it, but need to prepend the MSVC part befor what is already present
                vars = %Q[
CommandPromptType=Native
DevEnvDir=#{msvc[:base]}\\Common7\\IDE\\
ExtensionSdkDir=#{kits[:v10]}\\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\\windows\\Microsoft.NET\\Framework\\
FrameworkDIR32=C:\\windows\\Microsoft.NET\\Framework\\
FrameworkVersion=v4.0.30319
FrameworkVersion32=v4.0.30319
INCLUDE=#{msvc[:version]}\\ATLMFC\\include;#{msvc[:version]}\\include;#{kits[:fx]}\\4.6.1\\include\\um;#{kits[:include]}\\ucrt;#{kits[:include]}\\shared;#{kits[:include]}\\um;#{kits[:include]}\\winrt;
LIB=#{msvc[:version]}\\ATLMFC\\lib\\x86;#{msvc[:version]}\\lib\\x86;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\lib\\um\\x86;#{kits[:lib]}\\ucrt\\x86;#{kits[:lib]}\\um\\x86;
LIBPATH=#{msvc[:version]}\\ATLMFC\\lib\\x86;#{msvc[:version]}\\lib\\x86;#{kits[:umd]}\\;#{kits[:refs]}\\;C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319;
NETFXSDKDir=C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\
Platform=x86
UCRTVersion=#{kit_version}
UniversalCRTSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
VCIDEInstallDir=#{msvc[:base]}\\Common7\\IDE\\VC\\
VCINSTALLDIR=#{msvc[:vc]}\\
VCToolsInstallDir=#{msvc[:version]}\\
VCToolsRedistDir=#{msvc[:vc]}\\Redist\\MSVC\\#{msvc_version}\\
VisualStudioVersion=15.0
VS150COMNTOOLS=#{msvc[:base]}\\Common7\\Tools\\
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x86
VSCMD_ARG_TGT_ARCH=x86
VSCMD_VER=15.0.26430.6
VSINSTALLDIR=#{msvc[:base]}\\
WindowsLibPath=#{kits[:umd]}\\;#{kits[:refs]}\\
WindowsSdkBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\
WindowsSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
WindowsSDKLibVersion=#{kit_version}\\
WindowsSdkVerBinPath=#{kits[:bin]}\\
WindowsSDKVersion=#{kit_version}\\
WindowsSDK_ExecutablePath_x64=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\x64\\
WindowsSDK_ExecutablePath_x86=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\
__DOTNET_ADD_32BIT=1
__DOTNET_PREFERRED_BITNESS=32
                ]
                path = "#{msvc[:version]}\\bin\\HostX86\\x86;#{msvc[:base]}\\Common7\\IDE\\VC\\VCPackages;#{msvc[:base]}\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;#{msvc[:base]}\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;#{msvc[:base]}\\MSBuild\\15.0\\bin\\Roslyn;#{msvc[:base]}\\Team Tools\\Performance Tools;C:\\Program Files (x86)\\Microsoft Visual Studio\\Shared\\Common\\VSPerfCollectionTools\\;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\;#{kits[:v10]}\\bin\\x86;#{kits[:bin]}\\x86;#{msvc[:base]}\\MSBuild\\15.0\\bin;C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319;#{msvc[:base]}\\Common7\\IDE\\;#{msvc[:base]}\\Common7\\Tools\\;"
            when :x64
                #This is the diff between running "set" before and after loading "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvars64.bat"
                #Note that the Path env var is handled separately: we cannot simply overwrite it, but need to prepend the MSVC part befor what is already present
                vars = %Q[
CommandPromptType=Native
DevEnvDir=#{msvc[:base]}\\Common7\\IDE\\
ExtensionSdkDir=C:\\Program Files (x86)\\Microsoft SDKs\\Windows Kits\\10\\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\\windows\\Microsoft.NET\\Framework64\\
FrameworkDIR64=C:\\windows\\Microsoft.NET\\Framework64
FrameworkVersion=v4.0.30319
FrameworkVersion64=v4.0.30319
INCLUDE=#{msvc[:version]}\\ATLMFC\\include;#{msvc[:version]}\\include;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\include\\um;#{kits[:include]}\\ucrt;#{kits[:include]}\\shared;#{kits[:include]}\\um;#{kits[:include]}\\winrt;
LIB=#{msvc[:version]}\\ATLMFC\\lib\\x64;#{msvc[:version]}\\lib\\x64;C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\lib\\um\\x64;#{kits[:lib]}\\ucrt\\x64;#{kits[:lib]}\\um\\x64;
LIBPATH=#{msvc[:version]}\\ATLMFC\\lib\\x64;#{msvc[:version]}\\lib\\x64;#{kits[:umd]}\\;#{kits[:refs]}\\;C:\\windows\\Microsoft.NET\\Framework64\\v4.0.30319;
NETFXSDKDir=C:\\Program Files (x86)\\Windows Kits\\NETFXSDK\\4.6.1\\
Platform=x64
UCRTVersion=#{kit_version}
UniversalCRTSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
VCIDEInstallDir=#{msvc[:base]}\\Common7\\IDE\\VC\\
VCINSTALLDIR=#{msvc[:vc]}\\
VCToolsInstallDir=#{msvc[:version]}\\
VCToolsRedistDir=#{msvc[:vc]}\\Redist\\MSVC\\#{msvc_version}\\
VisualStudioVersion=15.0
VS150COMNTOOLS=#{msvc[:base]}\\Common7\\Tools\\
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x64
VSCMD_ARG_TGT_ARCH=x64
VSCMD_VER=15.0.26430.6
VSINSTALLDIR=#{msvc[:base]}\\
WindowsLibPath=#{kits[:umd]}\\;#{kits[:refs]}\\
WindowsSdkBinPath=C:\\Program Files (x86)\\Windows Kits\\10\\bin\\
WindowsSdkDir=C:\\Program Files (x86)\\Windows Kits\\10\\
WindowsSDKLibVersion=#{kit_version}\\
WindowsSdkVerBinPath=#{kits[:bin]}\\
WindowsSDKVersion=#{kit_version}\\
WindowsSDK_ExecutablePath_x64=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\x64\\
WindowsSDK_ExecutablePath_x86=C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\
__DOTNET_ADD_64BIT=1
__DOTNET_PREFERRED_BITNESS=64
                ]
                path = "#{msvc[:version]}\\bin\\HostX64\\x64;#{msvc[:base]}\\Common7\\IDE\\VC\\VCPackages;#{msvc[:base]}\\Common7\\IDE\\CommonExtensions\\Microsoft\\TestWindow;#{msvc[:base]}\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer;#{msvc[:base]}\\MSBuild\\15.0\\bin\\Roslyn;#{msvc[:base]}\\Team Tools\\Performance Tools;C:\\Program Files (x86)\\Microsoft Visual Studio\\Shared\\Common\\VSPerfCollectionTools\\;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6.1 Tools\\;#{kits[:v10]}\\bin\\x64;#{kits[:bin]}\\x64;#{msvc[:base]}\\MSBuild\\15.0\\bin;C:\\windows\\Microsoft.NET\\Framework64\\v4.0.30319;#{msvc[:base]}\\Common7\\IDE\\;#{msvc[:base]}\\Common7\\Tools\\;"
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
            versions.sort
        end
    end
end
