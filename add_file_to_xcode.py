#!/usr/bin/env python3
"""
Script to add WorkoutSessionView.swift to the Xcode project
"""
import os
import re

def add_file_to_xcode_project():
    project_file = "FitCoreWatch.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print("Project file not found!")
        return False
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate unique IDs (simplified approach)
    file_ref_id = "A1234567890ABCDEF123458A"
    build_file_id = "A1234567890ABCDEF1234589"
    
    # Add to PBXBuildFile section
    build_file_entry = f'\t\t{file_ref_id} /* WorkoutSessionView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {build_file_id} /* WorkoutSessionView.swift */; }};'
    
    # Find the end of PBXBuildFile section
    build_file_pattern = r'(\s+A1234567890ABCDEF1234586 /\* Date\+Extensions\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = A1234567890ABCDEF1234585 /\* Date\+Extensions\.swift \*/; \};\n)(/\* End PBXBuildFile section \*/)'
    
    if re.search(build_file_pattern, content):
        content = re.sub(build_file_pattern, f'\\1{build_file_entry}\n\\2', content)
    else:
        print("Could not find Date+Extensions.swift entry to add after")
        return False
    
    # Add to PBXFileReference section
    file_ref_entry = f'\t\t{build_file_id} /* WorkoutSessionView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WorkoutSessionView.swift; sourceTree = "<group>"; }};'
    
    file_ref_pattern = r'(\s+A1234567890ABCDEF1234585 /\* Date\+Extensions\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = "Date\+Extensions\.swift"; sourceTree = "<group>"; \};\n)(/\* End PBXFileReference section \*/)'
    
    if re.search(file_ref_pattern, content):
        content = re.sub(file_ref_pattern, f'\\1{file_ref_entry}\n\\2', content)
    else:
        print("Could not find Date+Extensions.swift file reference to add after")
        return False
    
    # Add to group children
    group_pattern = r'(\s+A1234567890ABCDEF1234568 /\* ContentView\.swift \*/,\n)(\s+A1234567890ABCDEF123456F /\* WorkoutView\.swift \*/,)'
    
    if re.search(group_pattern, content):
        content = re.sub(group_pattern, f'\\1\\t\t\t{build_file_id} /* WorkoutSessionView.swift */,\n\\2', content)
    else:
        print("Could not find ContentView.swift in group to add after")
        return False
    
    # Add to sources build phase
    sources_pattern = r'(\s+A1234567890ABCDEF1234569 /\* ContentView\.swift in Sources \*/,\n)(\s+A1234567890ABCDEF1234567 /\* FitCoreWatchApp\.swift in Sources \*/,)'
    
    if re.search(sources_pattern, content):
        content = re.sub(sources_pattern, f'\\1\\t\t\t{file_ref_id} /* WorkoutSessionView.swift in Sources */,\n\\2', content)
    else:
        print("Could not find ContentView.swift in sources to add after")
        return False
    
    # Write the updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added WorkoutSessionView.swift to Xcode project!")
    return True

if __name__ == "__main__":
    add_file_to_xcode_project()
