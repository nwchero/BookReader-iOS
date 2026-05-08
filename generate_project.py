#!/usr/bin/env python3
"""Generate a complete valid Xcode project for BookReader iOS app."""

import os, sys, uuid, json

def uid(s=''):
    return str(uuid.uuid4()).replace('-','').upper()[:24] + s

def main():
    proj_path = "BookReader"
    name = "BookReader"
    
    P=uid('P'); MG=uid('G'); PG=uid('G'); T=uid('T')
    P_BCL=uid('C'); P_DBG=uid('C'); P_REL=uid('C')
    T_BCL=uid('C'); T_DBG=uid('C'); T_REL=uid('C')
    PR=uid('F'); SBP=uid('P'); FBP=uid('P'); RBP=uid('P')
    CS=uid('G')  # Compile sources group
    
    swift_files = []
    assets_ref = None; sj_ref = None
    ss_group_uid = uid('G')
    
    for root, dirs, files in os.walk(proj_path):
        dirs[:] = [d for d in dirs if d not in ['.xcassets','.git']]
        for f in sorted(files):
            full = os.path.join(root, f); rel = os.path.relpath(full, proj_path)
            if f.endswith('.swift'):
                if rel.startswith('SwiftSoup/'):
                    continue  # handled separately
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
    
    FR={}  # PBXFileReference
    BF={}  # PBXBuildFile
    children=[]
    
    for sf in swift_files:
        fu=uid('f'); bu=uid('b')
        FR[fu]={ 'isa':'PBXFileReference', 'lastKnownFileType':'sourcecode.swift', 'path':sf, 'sourceTree':'<group>' }
        BF[bu]={ 'isa':'PBXBuildFile', 'fileRef':fu }
        children.append(fu)
    
    ss_children=[]
    for sf in ss_files:
        fu=uid('f'); bu=uid('b')
        FR[fu]={ 'isa':'PBXFileReference', 'lastKnownFileType':'sourcecode.swift', 'path':sf, 'sourceTree':'<group>' }
        BF[bu]={ 'isa':'PBXBuildFile', 'fileRef':fu }
        ss_children.append(fu)
    
    au=uid('f'); abu=uid('b')
    if assets_ref:
        FR[au]={ 'isa':'PBXFileReference', 'lastKnownFileType':'folder.assetcatalog', 'path':assets_ref, 'sourceTree':'<group>' }
        BF[abu]={ 'isa':'PBXBuildFile', 'fileRef':au }
        children.append(au)
    
    sju=uid('f')
    if sj_ref:
        FR[sju]={ 'isa':'PBXFileReference', 'lastKnownFileType':'text.json', 'path':sj_ref, 'sourceTree':'<group>' }
        children.append(sju)
    
    FR[PR]={ 'isa':'PBXFileReference', 'explicitFileType':'wrapper.application', 'includeInIndex':0, 'path':f'{name}.app', 'sourceTree':'BUILT_PRODUCTS_DIR' }
    
    def common_settings():
        return {
            'CODE_SIGN_IDENTITY':'-',
            'CODE_SIGNING_ALLOWED':'NO',
            'CURRENT_PROJECT_VERSION':'1',
            'GENERATE_INFOPLIST_FILE':'YES',
            'INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES',
            'INFOPLIST_KEY_UILaunchScreen_Generation':'YES',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone':'UIInterfaceOrientationPortrait',
            'IPHONEOS_DEPLOYMENT_TARGET':'16.0',
            'MARKETING_VERSION':'1.0.0',
            'PRODUCT_BUNDLE_IDENTIFIER':'com.bookreader.app',
            'PRODUCT_NAME':'$(TARGET_NAME)',
            'SWIFT_EMIT_LOC_STRINGS':'YES',
            'SWIFT_VERSION':'5.9',
            'TARGETED_DEVICE_FAMILY':'1,2',
        }
    
    def debug_settings():
        s = common_settings()
        s.update({ 'SWIFT_OPTIMIZATION_LEVEL':'-Onone' })
        return s
    
    def release_settings():
        s = common_settings()
        s.update({ 'SWIFT_OPTIMIZATION_LEVEL':'-O' })
        return s
    
    objects = {
        P: {
            'isa':'PBXProject',
            'buildConfigurationList':P_BCL,
            'compatibilityVersion':'Xcode 14.0',
            'developmentRegion':'en',
            'hasScannedForEncodings':0,
            'knownRegions':['en','Base'],
            'mainGroup':MG,
            'productRefGroup':PG,
            'projectDirPath':'',
            'projectRoot':'',
            'targets':[T]
        },
        MG: {
            'isa':'PBXGroup',
            'children':children + ([ss_group_uid] if ss_children else []),
            'sourceTree':'<group>'
        },
        PG: { 'isa':'PBXGroup','children':[PR],'name':'Products','sourceTree':'<group>' },
        T: {
            'isa':'PBXNativeTarget',
            'buildConfigurationList':T_BCL,
            'buildPhases':[SBP,FBP,RBP],
            'buildRules':[],
            'dependencies':[],
            'name':name,
            'productName':name,
            'productReference':PR,
            'productType':'com.apple.product-type.application'
        },
        SBP: { 'isa':'PBXSourcesBuildPhase','buildActionMask':2147483647,'files':list(BF.keys()),'runOnlyForDeploymentPostprocessing':0 },
        FBP: { 'isa':'PBXFrameworksBuildPhase','buildActionMask':2147483647,'files':[],'runOnlyForDeploymentPostprocessing':0 },
        RBP: { 'isa':'PBXResourcesBuildPhase','buildActionMask':2147483647,'files':[abu] if assets_ref else [],'runOnlyForDeploymentPostprocessing':0 },
        P_BCL: { 'isa':'XCConfigurationList','buildConfigurations':[P_DBG,P_REL],'defaultConfigurationIsVisible':0,'defaultConfigurationName':'Release' },
        P_DBG: { 'isa':'XCBuildConfiguration','buildSettings':common_settings(),'name':'Debug' },
        P_REL: { 'isa':'XCBuildConfiguration','buildSettings':common_settings(),'name':'Release' },
        T_BCL: { 'isa':'XCConfigurationList','buildConfigurations':[T_DBG,T_REL],'defaultConfigurationIsVisible':0,'defaultConfigurationName':'Release' },
        T_DBG: { 'isa':'XCBuildConfiguration','buildSettings':debug_settings(),'name':'Debug' },
        T_REL: { 'isa':'XCBuildConfiguration','buildSettings':release_settings(),'name':'Release' },
        **FR, **BF
    }
    
    if ss_children:
        objects[ss_group_uid] = { 'isa':'PBXGroup','children':ss_children,'name':'SwiftSoup','sourceTree':'<group>' }
    
    xpdir = os.path.join(proj_path, f'{name}.xcodeproj')
    os.makedirs(xpdir, exist_ok=True)
    
    with open(os.path.join(xpdir, 'project.pbxproj'), 'w') as f:
        f.write('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n')
        
        ids_sorted = sorted(objects.keys())
        for oid in ids_sorted:
            obj = objects[oid]
            if obj is None: continue
            f.write(f'\t\t{oid} = {{\n')
            w(f, obj, 3)
            f.write('\t\t}};\n')
        
        f.write('\t};\n')
        f.write(f'\trootObject = {P};\n')
        f.write('}\n')
    
    print(f'Generated: {xpdir}/project.pbxproj')
    
    scheme_dir = os.path.join(xpdir, 'xcshareddata', 'xcschemes')
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, f'{name}.xcscheme')
    with open(scheme_path, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Scheme LastUpgradeVersion="1500" version="1.7">')
        f.write('<BuildAction parallelizeBuilders="YES" buildImplicitDependencies="YES" buildArchitectures="Automatic"><BuildActionEntries>')
        f.write(f'<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/></BuildableEntry>')
        f.write('</BuildActionEntries></BuildAction>')
        f.write('<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>')
        f.write(f'<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/></BuildableProductRunnable></LaunchAction>')
        f.write(f'<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{T}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:{name}.xcodeproj"/></BuildableProductRunnable></ProfileAction>')
        f.write('<AnalyzeAction buildConfiguration="Debug"></AnalyzeAction><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"></ArchiveAction></Scheme>')
    print(f'Generated: {scheme_path}')
    return True

def w(f, d, indent):
    for k, v in d.items():
        p='\t'*indent
        if isinstance(v, str):
            q=k in ('name','path','productType','lastKnownFileType','explicitFileType','fileRef','sourceTree')
            f.write(f'{p}{k} = "{v}";\n' if q else f'{p}{k} = {v};\n')
        elif isinstance(v, list):
            f.write(f'{p}{k} = (\n')
            for i in v:
                if isinstance(i, str):
                    sq=k in ('name','children','files') or '$' in i or '/' in i or ' ' in i or '.' in i
                    f'{p}\t"{i}",\n' if sq else f'{p}\t{i},\n'
            f.write(f'{p});\n')
        elif isinstance(v, dict):
            f.write(f'{p}{k} = {{\n'); w(f,v,indent+1); f.write(f'{p}}};\n')

if __name__=='__main__':
    sys.exit(0 if main() else 1)
