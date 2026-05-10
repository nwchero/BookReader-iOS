#!/usr/bin/env python3
"""Generate a complete valid Xcode project for BookReader iOS app."""

import os, sys, uuid

def uid(s=''):
    return str(uuid.uuid4()).replace('-','').upper()[:24] + s

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
        FR[fu]={'isa':'PBXFileReference','lastKnownFileType':'sourcecode.swift','path':sf,'sourceTree':'<group>'}
        BF[bu]={'isa':'PBXBuildFile','fileRef':fu}
        files_list.append(bu)
    
    for sf in ss_files:
        fu=uid('f'); bu=uid('b')
        FR[fu]={'isa':'PBXFileReference','lastKnownFileType':'sourcecode.swift','path':sf,'sourceTree':'<group>'}
        BF[bu]={'isa':'PBXBuildFile','fileRef':fu}
        files_list.append(bu)
    
    assets_fu = None
    if assets_ref:
        au=uid('f'); abu=uid('b')
        FR[au]={'isa':'PBXFileReference','lastKnownFileType':'folder.assetcatalog','path':assets_ref,'sourceTree':'<group>'}
        BF[abu]={'isa':'PBXBuildFile','fileRef':au}
        files_list.append(abu)
    
    if sj_ref:
        sju=uid('f')
        FR[sju]={'isa':'PBXFileReference','lastKnownFileType':'text.json','path':sj_ref,'sourceTree':'<group>'}
    
    PR=uid('F')
    FR[PR]={'isa':'PBXFileReference','explicitFileType':'wrapper.application','includeInIndex':0,'path':f'{name}.app','sourceTree':'BUILT_PRODUCTS_DIR'}
    
    def fmt_val(v):
        if isinstance(v, bool):
            return 'YES' if v else 'NO'
        if isinstance(v, int):
            return str(v)
        if isinstance(v, list):
            return '(' + ' '.join(v) + ')'
        return f'"{v}"'
    
    def fmt_obj(d, indent=3):
        parts = []
        for k, v in d.items():
            parts.append(f'{k} = {fmt_val(v)};')
        return '\n' + '\t'*indent + ('\n\t'*indent).join(parts) + ';\n' + '\t'*(indent-1)
    
    xpdir = os.path.join(proj_path, f'{name}.xcodeproj')
    os.makedirs(xpdir, exist_ok=True)
    
    with open(os.path.join(xpdir, 'project.pbxproj'), 'w') as f:
        f.write('// !$*UTF8*$!\n')
        f.write('{\n')
        f.write('\tarchiveVersion = 1;\n')
        f.write('\tclasses = {\n')
        f.write('\t};\n')
        f.write('\tobjectVersion = 56;\n')
        f.write('\tobjects = (\n')
        
        all_objs = {}
        all_objs.update(BF)
        all_objs.update(FR)
        
        for oid, obj in all_objs.items():
            s = fmt_obj(obj)
            f.write(f'\t\t{oid} /* Object */ = {{{s}}};\n')
        
        all_children = list(FR.keys())
        
        proj = {
            'isa':'PBXProject',
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
            'targets': f'<{T}>',
        }
        s = fmt_obj(proj)
        f.write(f'\t\t{P} /* Project object */ = {{{s}}};\n')
        
        main_group = {
            'isa':'PBXGroup',
            'children': '(' + ' '.join(all_children) + ')',
            'sourceTree': '"<group>"',
        }
        s = fmt_obj(main_group)
        f.write(f'\t\t{MG} = {{{s}}};\n')
        
        prod_group = {
            'isa':'PBXGroup',
            'children': f'(<{PR}>)',
            'name': '"Products"',
            'sourceTree': '"<group>"',
        }
        s = fmt_obj(prod_group)
        f.write(f'\t\t{PG} = {{{s}}};\n')
        
        native_target = {
            'isa':'PBXNativeTarget',
            'buildConfigurationList': T_BCL,
            'buildPhases': f'(<{SBP}> <{FBP}> <{RBP}>)',
            'buildRules': '()',
            'dependencies': '()',
            'name': f'"{name}"',
            'productName': f'"{name}"',
            'productReference': f'<{PR}>',
            'productType': '"com.apple.product-type.application"',
        }
        s = fmt_obj(native_target)
        f.write(f'\t\t{T} = {{{s}}};\n')
        
        sources_phase = {
            'isa':'PBXSourcesBuildPhase',
            'buildActionMask': 2147483647,
            'files': '(' + ' '.join([f'<{x}>' for x in files_list]) + ')',
            'runOnlyForDeploymentPostprocessing': 0,
        }
        s = fmt_obj(sources_phase)
        f.write(f'\t\t{SBP} = {{{s}}};\n')
        
        frameworks_phase = {
            'isa':'PBXFrameworksBuildPhase',
            'buildActionMask': 2147483647,
            'files': '()',
            'runOnlyForDeploymentPostprocessing': 0,
        }
        s = fmt_obj(frameworks_phase)
        f.write(f'\t\t{FBP} = {{{s}}};\n')
        
        resources_phase = {
            'isa':'PBXResourcesBuildPhase',
            'buildActionMask': 2147483647,
            'files': '()',
            'runOnlyForDeploymentPostprocessing': 0,
        }
        s = fmt_obj(resources_phase)
        f.write(f'\t\t{RBP} = {{{s}}};\n')
        
        proj_bcl = {
            'isa':'XCConfigurationList',
            'buildConfigurations': f'(<{P_DBG}> <{P_REL}>)',
            'defaultConfigurationIsVisible': 0,
            'defaultConfigurationName': '"Release"',
        }
        s = fmt_obj(proj_bcl)
        f.write(f'\t\t{P_BCL} = {{{s}}};\n')
        
        proj_dbg = {
            'isa':'XCBuildConfiguration',
            'name': '"Debug"',
        }
        s = fmt_obj(proj_dbg)
        f.write(f'\t\t{P_DBG} = {{{s}}};\n')
        
        proj_rel = {
            'isa':'XCBuildConfiguration',
            'name': '"Release"',
        }
        s = fmt_obj(proj_rel)
        f.write(f'\t\t{P_REL} = {{{s}}};\n')
        
        target_bcl = {
            'isa':'XCConfigurationList',
            'buildConfigurations': f'(<{T_DBG}> <{T_REL}>)',
            'defaultConfigurationIsVisible': 0,
            'defaultConfigurationName': '"Release"',
        }
        s = fmt_obj(target_bcl)
        f.write(f'\t\t{T_BCL} = {{{s}}};\n')
        
        target_dbg = {
            'isa':'XCBuildConfiguration',
            'name': '"Debug"',
        }
        s = fmt_obj(target_dbg)
        f.write(f'\t\t{T_DBG} = {{{s}}};\n')
        
        target_rel = {
            'isa':'XCBuildConfiguration',
            'name': '"Release"',
        }
        s = fmt_obj(target_rel)
        f.write(f'\t\t{T_REL} = {{{s}}};\n')
        
        f.write('\t);\n')
        f.write(f'\trootObject = {P} /* Project object */;\n')
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
