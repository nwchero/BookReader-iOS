#!/usr/bin/env python3
"""Generate minimal valid Xcode project for BookReader iOS app (pbxproj + xcscheme)."""

import os, sys, uuid

def uid():
    return str(uuid.uuid4()).replace('-','').upper()[:24]

def main():
    proj_path = "BookReader"
    proj_name = "BookReader"
    
    P = uid(); G = uid(); PG = uid(); T = uid()
    BCL = uid(); DBG = uid(); REL = uid(); PR = uid()
    SBP = uid(); FBP = uid(); RBP = uid()
    
    swift_files = []
    assets_ref = None
    sources_json_ref = None
    
    for root, dirs, files in os.walk(proj_path):
        dirs[:] = [d for d in dirs if d not in ['.xcassets', '.git']]
        for f in sorted(files):
            full = os.path.join(root, f)
            rel = os.path.relpath(full, proj_path)
            if f.endswith('.swift'):
                swift_files.append(rel)
            elif f == 'Assets.xcassets':
                assets_ref = rel
            elif f == 'default_sources.json':
                sources_json_ref = rel
    
    print(f"Found {len(swift_files)} Swift files")
    for sf in swift_files: print(f"  {sf}")
    
    frefs = {}; bfiles = {}; children = []
    
    for sf in swift_files:
        fu = uid(); bu = uid()
        frefs[fu] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'sourcecode.swift', 'path': sf, 'sourceTree': '<group>'}
        bfiles[bu] = {'isa': 'PBXBuildFile', 'fileRef': fu}
        children.append(fu)
    
    au = uid(); abu = uid()
    if assets_ref:
        frefs[au] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'folder.assetcatalog', 'path': assets_ref, 'sourceTree': '<group>'}
        bfiles[abu] = {'isa': 'PBXBuildFile', 'fileRef': au}
        children.append(au)
    
    sj = uid()
    if sources_json_ref:
        frefs[sj] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'text.json', 'path': sources_json_ref, 'sourceTree': '<group>'}
        children.append(sj)
    
    frefs[PR] = {'isa': 'PBXFileReference', 'explicitFileType': 'wrapper.application', 'includeInIndex': 0, 'path': f'{proj_name}.app', 'sourceTree': 'BUILT_PRODUCTS_DIR'}
    
    def bs():
        return {
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
            'CODE_SIGN_IDENTITY': '-', 'CODE_SIGNING_ALLOWED': 'NO',
            'DEVELOPMENT_TEAM': '', 'ENABLE_USER_SCRIPT_SANDBOXING': 'NO',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
            'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad': 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone': 'UIInterfaceOrientationPortrait',
            'IPHONEOS_DEPLOYMENT_TARGET': '16.0',
            'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/Frameworks',
            'MARKETING_VERSION': '1.0.0', 'PRODUCT_BUNDLE_IDENTIFIER': 'com.bookreader.app',
            'PRODUCT_NAME': '$(TARGET_NAME)', 'SWIFT_EMIT_LOC_STRINGS': 'YES',
            'SWIFT_VERSION': '5.9', 'TARGETED_DEVICE_FAMILY': '1,2',
        }
    
    objects = {
        P: {'isa': 'PBXProject', 'buildConfigurationList': BCL, 'compatibilityVersion': 'Xcode 14.0', 'developmentRegion': 'en', 'hasScannedForEncodings': 0, 'knownRegions': ['en', 'Base'], 'mainGroup': G, 'productRefGroup': PG, 'projectDirPath': '', 'projectRoot': '', 'targets': [T]},
        G: {'isa': 'PBXGroup', 'children': children, 'sourceTree': '<group>'},
        PG: {'isa': 'PBXGroup', 'children': [PR], 'name': 'Products', 'sourceTree': '<group>'},
        T: {'isa': 'PBXNativeTarget', 'buildConfigurationList': BCL, 'buildPhases': [SBP, FBP, RBP], 'buildRules': [], 'dependencies': [], 'name': proj_name, 'productName': proj_name, 'productReference': PR, 'productType': 'com.apple.product-type.application'},
        SBP: {'isa': 'PBXSourcesBuildPhase', 'buildActionMask': 2147483647, 'files': list(bfiles.keys()), 'runOnlyForDeploymentPostprocessing': 0},
        FBP: {'isa': 'PBXFrameworksBuildPhase', 'buildActionMask': 2147483647, 'files': [], 'runOnlyForDeploymentPostprocessing': 0},
        RBP: {'isa': 'PBXResourcesBuildPhase', 'buildActionMask': 2147483647, 'files': [abu] if assets_ref else [], 'runOnlyForDeploymentPostprocessing': 0},
        BCL: {'isa': 'XCConfigurationList', 'buildConfigurations': [DBG, REL], 'defaultConfigurationIsVisible': 0, 'defaultConfigurationName': 'Release'},
        DBG: {'isa': 'XCBuildConfiguration', 'buildSettings': bs(), 'name': 'Debug'},
        REL: {'isa': 'XCBuildConfiguration', 'buildSettings': bs(), 'name': 'Release'},
        **frefs, **bfiles
    }
    
    xcodeproj_dir = os.path.join(proj_path, f'{proj_name}.xcodeproj')
    os.makedirs(xcodeproj_dir, exist_ok=True)
    
    # Write pbxproj
    pbx_path = os.path.join(xcodeproj_dir, 'project.pbxproj')
    with open(pbx_path, 'w') as f:
        f.write('// !$*UTF8*$!\n{\n')
        f.write('\tarchiveVersion = 1;\n\tclasses = {\n\t};\n')
        f.write('\tobjectVersion = 56;\n\tobjects = {\n')
        for oid, oval in objects.items():
            f.write(f'\t\t{oid} = {{\n'); wd(f, oval, 3); f.write('\t\t}};\n')
        f.write('\t};\n')
        f.write(f'\trootObject = {P};\n}}\n')
    print(f'Generated: {pbx_path}')
    
    # Write .xcscheme
    scheme_dir = os.path.join(xcodeproj_dir, 'xcshareddata', 'xcschemes')
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, f'{proj_name}.xcscheme')
    with open(scheme_path, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<Scheme\n   LastUpgradeVersion = "1500"\n   version = "1.7">\n')
        f.write('   <BuildAction\n      parallelizeBuilders = "YES"\n      buildImplicitDependencies = "YES"\n      buildArchitectures = "Automatic">\n')
        f.write('      <BuildActionEntries>\n')
        f.write(f'         <BuildActionEntry\n            buildForTesting = "YES"\n            buildForRunning = "YES"\n            buildForProfiling = "YES"\n            buildForArchiving = "YES"\n            buildForAnalyzing = "YES">\n')
        f.write(f'            <BuildableReference\n               BuildableIdentifier = "primary"\n               BlueprintIdentifier = "{T}"\n               BuildableName = "{proj_name}.app"\n               BlueprintName = "{proj_name}"\n               ReferencedContainer = "container:{proj_name}.xcodeproj">\n')
        f.write('            </BuildableReference>\n         </BuildActionEntry>\n      </BuildActionEntries>\n   </BuildAction>\n')
        f.write('   <TestAction\n      buildConfiguration = "Debug"\n      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n      shouldUseLaunchSchemeArgsEnv = "YES">\n')
        f.write('      <Testables>\n      </Testables>\n   </TestAction>\n')
        f.write('   <LaunchAction\n      buildConfiguration = "Debug"\n      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n      launchStyle = "0"\n      useCustomWorkingDirectory = "NO"\n      ignoresPersistentStateOnLaunch = "NO"\n      debugDocumentVersioning = "YES"\n      debugServiceExtension = "internal"\n      allowLocationSimulation = "YES">\n')
        f.write(f'      <BuildableProductRunnable\n         runnableDebuggingMode = "0">\n')
        f.write(f'            <BuildableReference\n               BuildableIdentifier = "primary"\n               BlueprintIdentifier = "{T}"\n               BuildableName = "{proj_name}.app"\n               BlueprintName = "{proj_name}"\n               ReferencedContainer = "container:{proj_name}.xcodeproj">\n')
        f.write('            </BuildableReference>\n         </BuildableProductRunnable>\n   </LaunchAction>\n')
        f.write('   <ProfileAction\n      buildConfiguration = "Release"\n      shouldUseLaunchSchemeArgsEnv = "YES"\n      savedToolIdentifier = ""\n      useCustomWorkingDirectory = "NO"\n      debugDocumentVersioning = "YES">\n')
        f.write(f'      <BuildableProductRunnable\n         runnableDebuggingMode = "0">\n')
        f.write(f'            <BuildableReference\n               BuildableIdentifier = "primary"\n               BlueprintIdentifier = "{T}"\n               BuildableName = "{proj_name}.app"\n               BlueprintName = "{proj_name}"\n               ReferencedContainer = "container:{proj_name}.xcodeproj">\n')
        f.write('            </BuildableReference>\n         </BuildableProductRunnable>\n   </ProfileAction>\n')
        f.write('   <AnalyzeAction\n      buildConfiguration = "Debug">\n   </AnalyzeAction>\n')
        f.write('   <ArchiveAction\n      buildConfiguration = "Release"\n      revealArchiveInOrganizer = "YES">\n   </ArchiveAction>\n')
        f.write('</Scheme>\n')
    print(f'Generated: {scheme_path}')
    return True

def wd(f, d, indent):
    for k, v in d.items():
        pad = '\t' * indent
        if isinstance(v, str):
            q = k in ('name','path','productType','lastKnownFileType','explicitFileType','fileRef','sourceTree')
            f.write(f'{pad}{k} = "{v}" if q else f"{pad}{k} = {v}";\n')
        elif isinstance(v, list):
            f.write(f'{pad}{k} = (\n')
            for item in v:
                if isinstance(item, str):
                    q2 = k in ('name','children','files') or item.startswith('$') or '/' in item or ' ' in item
                    f.write(f'{pad}\t"{item}",\n' if q2 else f'{pad}\t{item},\n')
            f.write(f'{pad});\n')
        elif isinstance(v, dict):
            f.write(f'{pad}{k} = {{\n'); wd(f, v, indent+1); f.write(f'{pad}}};\n')

if __name__ == '__main__':
    sys.exit(0 if main() else 1)
