from pathlib import Path
import hashlib
root = Path('ios')
def uid(name): return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
files = sorted((root/'repQ').glob('*.swift'))
objects = []
def obj(key, val): objects.append(f'{uid(key)} = {{ {val} }};')
for f in files:
    obj(f.name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f.name}; sourceTree = "<group>";')
    obj('build'+f.name, f'isa = PBXBuildFile; fileRef = {uid(f.name)};')
obj('Assets.xcassets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
obj('buildAssets.xcassets', f'isa = PBXBuildFile; fileRef = {uid("Assets.xcassets")};')
obj('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = repQ.app; sourceTree = BUILT_PRODUCTS_DIR;')
obj('sources', 'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(uid('build'+f.name) for f in files)+'); runOnlyForDeploymentPostprocessing = 0;')
obj('frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
obj('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({uid("buildAssets.xcassets")}); runOnlyForDeploymentPostprocessing = 0;')
obj('sourceGroup', 'isa = PBXGroup; children = ('+','.join(uid(f.name) for f in files)+f',{uid("Assets.xcassets")}); path = repQ; sourceTree = "<group>";')
obj('products', f'isa = PBXGroup; children = ({uid("product")}); name = Products; sourceTree = "<group>";')
obj('mainGroup', f'isa = PBXGroup; children = ({uid("sourceGroup")},{uid("products")}); sourceTree = "<group>";')
for name in ('Debug','Release'):
    obj('project'+name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 5.0; }};')
    obj('target'+name, f'''isa = XCBuildConfiguration; name = {name}; buildSettings = {{
      PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.sep.repq;
      ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
      GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = RepQ;
      INFOPLIST_KEY_NSCameraUsageDescription = "Scan the QR code on a machine to check in and keep the floor accurate.";
      INFOPLIST_KEY_UILaunchScreen_Generation = YES;
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
      INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
      TARGETED_DEVICE_FAMILY = 1; CODE_SIGN_STYLE = Automatic;
      SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_OPTIMIZATION_LEVEL = "{'-Onone' if name == 'Debug' else '-O'}";
    }};''')
for scope in ('project','target'):
    obj(scope+'ConfigList', 'isa = XCConfigurationList; buildConfigurations = ('+','.join(uid(scope+n) for n in ('Debug','Release'))+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("targetConfigList")}; buildPhases = ({uid("sources")},{uid("frameworks")},{uid("resources")}); buildRules = (); dependencies = (); name = repQ; productName = repQ; productReference = {uid("product")}; productType = "com.apple.product-type.application";')
obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {uid("projectConfigList")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base); mainGroup = {uid("mainGroup")}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; targets = ({uid("target")});')
(root/'repQ.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+'\n}; rootObject = '+uid('project')+'; }\n')
ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="repQ.app" BlueprintName="repQ" ReferencedContainer="container:repQ.xcodeproj"/>'
(root/'repQ.xcodeproj/xcshareddata/xcschemes/repQ.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
