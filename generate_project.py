#!/usr/bin/env python3
"""Generate a minimal valid Xcode project.pbxproj for BookReader iOS app."""

import os, sys, uuid

def uid():
    return str(uuid.uuid4()).replace('-','').upper()[:24]

def main():
    proj_path = "BookReader"
    proj_name = "BookReader"
    
    P = uid()
    G = uid()
    PG = uid()
    T = uid()
    BCL = uid()
    DBG = uid()
    REL = uid()
    PR = uid()
    SBP = uid()
    FBP = uid()
    RBP = uid()
    
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
    
    frefs = {}
    bfiles = {}
    children = []
    
    for sf in swift_files:
        fu = uid()
        bu = uid()
        frefs[fu] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'sourcecode.swift', 'path': sf, 'sourceTree': '<group>'}
        bfiles[bu] = {'isa': 'PBXBuildFile', 'fileRef': fu}
        children.append(fu)
    
    au = uid()
    abu = uid()
    if assets_ref:
        frefs[au] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'folder.assetcatalog', 'path': assets_ref, 'sourceTree': '<group>'}
        bfiles[abu] = {'isa': 'PBXBuildFile', 'fileRef': au}
        children.append(au)
    
    sj = uid()
    if sources_json_ref:
        frefs[sj] = {'isa': 'PBXFileReference', 'lastKnownFileType': 'text.json', 'path': sources_json_ref, 'sourceTree': '<group>'}
        children.append(sj)
    
    frefs[PR] = {
        'isa': 'PBXFileReference',
        'explicitFileType': 'wrapper.application',
        'includeInIndex': 0,
        'path': f'{proj_name}.app',
        'sourceTree': 'BUILT_PRODUCTS_DIR'
    }
    
    def build_settings():
        return {
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
            'CODE_SIGN_IDENTITY': '-',
            'CODE_SIGNING_ALLOWED': 'NO',
            'DEVELOPMENT_TEAM': '',
            'ENABLE_USER_SCRIPT_SANDBOXING': 'NO',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
            'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad': 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone': 'UIInterfaceOrientationPortrait',
            'IPHONEOS_DEPLOYMENT_TARGET': '16.0',
            'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/Frameworks',
            'MARKETING_VERSION': '1.0.0',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.bookreader.app',
            'PRODUCT_NAME': '$(TARGET_NAME)',
            'SWIFT_EMIT_LOC_STRINGS': 'YES',
            'SWIFT_VERSION': '5.9',
            'TARGETED_DEVICE_FAMILY': '1,2',
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
        DBG: {'isa': 'XCBuildConfiguration', 'buildSettings': build_settings(), 'name': 'Debug'},
        REL: {'isa': 'XCBuildConfiguration', 'buildSettings': build_settings(), 'name': 'Release'},
        **frefs, **bfiles
    }
    
    xcodeproj_dir = os.path.join(proj_path, f'{proj_name}.xcodeproj')
    os.makedirs(xcodeproj_dir, exist_ok=True)
    pbx_path = os.path.join(xcodeproj_dir, 'project.pbxproj')
    
    with open(pbx_path, 'w') as f:
        f.write('// !$*UTF8*$!\n')
        f.write('{\n')
        f.write('\tarchiveVersion = 1;\n')
        f.write('\tclasses = {\n\t};\n')
        f.write('\tobjectVersion = 56;\n')
        f.write('\tobjects = {\n')
        for obj_id, obj_val in objects.items():
            f.write(f'\t\t{obj_id} = {{\n')
            wdict(f, obj_val, 3)
            f.write('\t\t}};\n')
        f.write('\t};\n')
        f.write(f'\trootObject = {P};\n')
        f.write('}\n')
    
    print(f'Generated: {pbx_path}')
    return True

def wdict(f, d, indent):
    for k, v in d.items():
        pad = '\t' * indent
        if isinstance(v, str):
            if k in ('name','path','productType','lastKnownFileType','explicitFileType','fileRef','sourceTree'):
                f.write(f'{pad}{k} = "{v}";\n')
            else:
                f.write(f'{pad}{k} = {v};\n')
        elif isinstance(v, list):
            f.write(f'{pad}{k} = (\n')
            for item in v:
                if isinstance(item, str):
                    q = (k in ('name','children','files') or item.startswith('$') or '/' in item or ' ' in item)
                    f.write(f'{pad}\t{"'" + item + "'" if q else item},\n')
            f.write(f'{pad});\n')
        elif isinstance(v, dict):
            f.write(f'{pad}{k} = {{\n')
            wdict(f, v, indent+1)
            f.write(f'{pad}}};\n')

if __name__ == '__main__':
    sys.exit(0 if main() else 1)
