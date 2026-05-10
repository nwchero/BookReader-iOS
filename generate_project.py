#!/usr/bin/env python3
"""Generate a complete valid Xcode project for BookReader iOS app."""

import os, sys, uuid, json

def uid(s=''):
    return str(uuid.uuid4()).replace('-','').upper()[:24] + s

def quote_val(v):
    return f'"{v}"'

def main():
    proj_path = "BookReader"
    name = "BookReader"
    
    P=uid('P'); MG=uid('G'); PG=uid('G'); T=uid('T')
    P_BCL=uid('C'); P_DBG=uid('C'); P_REL=uid('C')
    T_BCL=uid('C'); T_DBG=uid('C'); T_REL=uid('C')
    PR=uid('F'); SBP=uid('P'); FBP=uid('P'); RBP=uid('P')
    
    swift_files = []
    assets_ref = None; sj_ref = None
    
    for root, dirs, files in os.walk(proj_path):
        dirs[:] = [d for d in dirs if d not in ['.xcassets','.git']]
        for f in sorted(files):
            full = os.path.join(root, f); rel = os.path.relpath(full, proj_path)
            if f.endswith('.swift'):
                swift_files.append(rel)
            elif f == 'Assets.xcassets': assets_ref = rel
            elif f == 'default_sources.json': sj_ref = rel
    
    ss_files = []
    ss_dir = os.path.join(proj_path, 'SwiftSoup')
    if os.path.isdir(ss_dir):
        for root, dirs, files in os.walk(ss_dir):
            for f in sorted(files):
                if f.endswith('.swift'):
                    ss_files.append(os.path.relpath(os.path.join(root,f), proj_path))
    
    total_swift = len(swift_files) + len(ss_files)
    print(f"App files: {len(swift_files)}, SwiftSoup: {len(ss_files)}, Total: {total_swift}")
    
    FR={}; BF={}; files_list=[]
    
    for sf in swift_files:
        fu=uid('f'); bu=uid('b')
        FR[fu]=f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {sf}; sourceTree = "<group>";'
        BF[bu]=f'isa = PBXBuildFile; fileRef = {fu};'
        files_list.append(bu)
    
    for sf in ss_files:
        fu=uid('f'); bu=uid('b')
        FR[fu]=f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {sf}; sourceTree = "<group>";'
        BF[bu]=f'isa = PBXBuildFile; fileRef = {fu};'
        files_list.append(bu)
    
    assets_bf = None
    if assets_ref:
        au=uid('f'); abu=uid('b')
        FR[au]=f'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {assets_ref}; sourceTree = "<group>";'
        BF[abu]=f'isa = PBXBuildFile; fileRef = {au};'
        assets_bf = abu
    
    resources_list = [assets_bf] if assets_bf else []
    
    sju = None
    if sj_ref:
        sju=uid('f')
        FR[sju]=f'isa = PBXFileReference; lastKnownFileType = text.json; path = {sj_ref}; sourceTree = "<group>";'
    
    PR=uid('F')
    FR[PR]=f'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {name}.app; sourceTree = BUILT_PRODUCTS_DIR;'
    
    def build_settings(cfg='Debug'):
        opts = '-Onone' if cfg == 'Debug' else '-O'
        return (
            f'CODE_SIGN_IDENTITY = -; '
            f'CODE_SIGNING_ALLOWED = NO; '
            f'CURRENT_PROJECT_VERSION = 1; '
            f'GENERATE_INFOPLIST_FILE = YES; '
            f'INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; '
            f'INFOPLIST_KEY_UILaunchScreen_Generation = YES; '
            f'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; '
            f'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait"; '
            f'IPHONEOS_DEPLOYMENT_TARGET = 16.0; '
            f'MARKETING_VERSION = 1.0.0; '
            f'PRODUCT_BUNDLE_IDENTIFIER = com.bookreader.app; '
            f'PRODUCT_NAME = "$(TARGET_NAME)"; '
            f'SWIFT_EMIT_LOC_STRINGS = YES; '
            f'SWIFT_OPTIMIZATION_LEVEL = {opts}; '
            f'SWIFT_VERSION = 5.9; '
            f'TARGETED_DEVICE_FAMILY = "1,2";'
        )
    
    def write_obj(f, oid, content):
        f.write(f'\t\t{oid} = {{ {content} }};\n')
    
    def write_dict(f, oid, d):
        parts = [f'isa = {d["isa"]}']
        for k, v in d.items():
            if k == 'isa': continue
            if isinstance(v, str):
                parts.append(f'{k} = {v};')
            elif isinstance(v, list):
                items = ' '.join(v)
                parts.append(f'{k} = ({items});')
        f.write(f'\t\t{oid} = {{' + ' '.join(parts) + '};\n')
    
    xpdir = os.path.join(proj_path, f'{name}.xcodeproj')
    os.makedirs(xpdir, exist_ok=True)
    
    with open(os.path.join(xpdir, 'project.pbxproj'), 'w') as f:
        f.write('// !$*UTF8*$!\n')
        f.write('{\n')
        f.write('\tarchiveVersion = 1;\n')
        f.write('\tclasses = {\n')
        f.write('\t};\n')
        f.write('\tobjectVersion = 56;\n')
        f.write('\tobjects = {\n')
        
        for oid, content in BF.items():
            write_obj(f, oid, content)
        for oid, content in FR.items():
            write_obj(f, oid, content)
        
        write_dict(f, uid('P'), {
            'isa': 'PBXProject',
            'attributes': '{"BuildIndependentTargetsInParallel":1,"LastSwiftUpdateCheck":1500,"LastUpgradeCheck":1500,"SwiftABIVersion":7,"TARGETED_DEVICE_FAMILY":"1,2"}',
            'buildConfigurationList': P_BCL,
            'compatibilityVersion': '"Xcode 14.0"',
            'developmentRegion': '"en"',
            'hasScannedForEncodings': 0,
            'knownRegions': '["en","Base"]',
            'mainGroup': MG,
            'productRefGroup': PG,
            'projectDirPath': '""',
            'projectRoot': '""',
            'targets': f'({T})',
        })
        
        write_dict(f, MG, {
            'isa': 'PBXGroup',
            'children': ' '.join(list(FR.keys())),
            'sourceTree': '"<group>"',
        })
        
        write_dict(f, PG, {
            'isa': 'PBXGroup',
            'children': f'({PR})',
            'name': '"Products"',
            'sourceTree': '"<group>"',
        })
        
        write_dict(f, T, {
            'isa': 'PBXNativeTarget',
            'buildConfigurationList': T_BCL,
            'buildPhases': f'({SBP} {FBP} {RBP})',
            'buildRules': '()',
            'dependencies': '()',
            'name': f'"{name}"',
            'productName': f'"{name}"',
            'productReference': PR,
            'productType': '"com.apple.product-type.application"',
        })
        
        write_dict(f, SBP, {
            'isa': 'PBXSourcesBuildPhase',
            'buildActionMask': 2147483647,
            'files': ' '.join(files_list),
            'runOnlyForDeploymentPostprocessing': 0,
        })
        
        write_dict(f, FBP, {
            'isa': 'PBXFrameworksBuildPhase',
            'buildActionMask': 2147483647,
            'files': '()',
            'runOnlyForDeploymentPostprocessing': 0,
        })
        
        write_dict(f, RBP, {
            'isa': 'PBXResourcesBuildPhase',
            'buildActionMask': 2147483647,
            'files': ' '.join([x for x in resources_list if x]) if resources_list else '()',
            'runOnlyForDeploymentPostprocessing': 0,
        })
        
        write_dict(f, P_BCL, {
            'isa': 'XCConfigurationList',
            'buildConfigurations': f'({P_DBG} {P_REL})',
            'defaultConfigurationIsVisible': 0,
            'defaultConfigurationName': '"Release"',
        })
        
        write_dict(f, P_DBG, {
            'isa': 'XCBuildConfiguration',
            'buildSettings': f'"{build_settings("Debug")}"',
            'name': '"Debug"',
        })
        
        write_dict(f, P_REL, {
            'isa': 'XCBuildConfiguration',
            'buildSettings': f'"{build_settings("Release")}"',
            'name': '"Release"',
        })
        
        write_dict(f, T_BCL, {
            'isa': 'XCConfigurationList',
            'buildConfigurations': f'({T_DBG} {T_REL})',
            'defaultConfigurationIsVisible': 0,
            'defaultConfigurationName': '"Release"',
        })
        
        write_dict(f, T_DBG, {
            'isa': 'XCBuildConfiguration',
            'name': '"Debug"',
        })
        
        write_dict(f, T_REL, {
            'isa': 'XCBuildConfiguration',
            'name': '"Release"',
        })
        
        f.write('\t};\n')
        f.write(f'\trootObject = {uid("P")} /* Project object */;\n')
        f.write('}\n')
    
    print(f'Generated: {xpdir}/project.pbxproj')
    
    scheme_dir = os.path.join(xpdir, 'xcshareddata', 'xcschemes')
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, f'{name}.xcscheme')
    with open(scheme_path, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<Scheme LastUpgradeVersion="1500" version="1.7">\n')
        f.write('<BuildAction parallelizeBuilders="YES" buildImplicitDependencies="YES" buildArchitectures="Automatic">\n')
        f.write('<BuildActionEntries>\n')
        f.write(f'<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">\n')
        f.write(f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/>\n')
        f.write('</BuildActionEntry>\n')
        f.write('</BuildActionEntries>\n')
        f.write('</BuildAction>\n')
        f.write('<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>\n')
        f.write(f'<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">\n')
        f.write(f'<BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/></BuildableProductRunnable>\n')
        f.write('</LaunchAction>\n')
        f.write(f'<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">\n')
        f.write(f'<BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/></BuildableProductRunnable>\n')
        f.write('</ProfileAction>\n')
        f.write('<AnalyzeAction buildConfiguration="Debug"></AnalyzeAction>\n')
        f.write('<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"></ArchiveAction>\n')
        f.write('</Scheme>\n')
    print(f'Generated: {scheme_path}')
    return True

if __name__=='__main__':
    sys.exit(0 if main() else 1)
