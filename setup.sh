#!/bin/bash

# FitCore Watch App Setup Script
# This script sets up the development environment for the FitCore Watch app

echo "🚀 Setting up FitCore Watch App..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "FitCoreWatch.xcodeproj/project.pbxproj" ]; then
    echo "❌ Please run this script from the fitcore-watch directory."
    exit 1
fi

echo "✅ Xcode found"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "FitCoreWatch/Models"
mkdir -p "FitCoreWatch/Extension"
mkdir -p "FitCoreWatch/Shared"
mkdir -p "FitCoreWatch/Shared/Extensions"
mkdir -p "FitCoreWatch/Preview Content"

echo "✅ Directories created"

# Set up Git repository
if [ ! -d ".git" ]; then
    echo "🔧 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: FitCore Watch App"
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << EOF
# Xcode
.DS_Store
*/build/*
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.moved-aside
*.xccheckout
*.xcscmblueprint

# Build
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# CocoaPods
Pods/
*.podspec

# Carthage
Carthage/Build

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
iOSInjectionProject/
EOF

echo "✅ .gitignore created"

# Create development documentation
echo "📚 Creating development documentation..."
cat > DEVELOPMENT.md << EOF
# FitCore Watch App Development

## Getting Started

1. Open \`FitCoreWatch.xcodeproj\` in Xcode
2. Select your Apple Watch simulator or device
3. Build and run the project (⌘+R)

## Project Structure

- \`FitCoreWatch/\` - Main watch app target
- \`FitCoreWatch/Extension/\` - Watch extension code
- \`FitCoreWatch/Shared/\` - Shared code and models
- \`FitCoreWatch/Preview Content/\` - SwiftUI preview assets

## Key Features

- Workout tracking with sets, reps, and weights
- Rest timer with haptic feedback
- Heart rate monitoring via HealthKit
- Music control during workouts
- Always On Display support
- WatchConnectivity for iPhone sync

## Development Notes

- Built with SwiftUI for modern, declarative UI
- Uses HealthKit for health data integration
- Implements WatchConnectivity for iPhone communication
- Follows Apple's Human Interface Guidelines for watchOS

## Testing

- Test on both 40mm and 44mm Apple Watch sizes
- Test with Always On Display enabled/disabled
- Test workout scenarios with and without iPhone nearby
- Test haptic feedback and notifications

## Deployment

1. Configure signing in Xcode
2. Set bundle identifier to match your team
3. Build for release
4. Archive and upload to App Store Connect
EOF

echo "✅ Development documentation created"

# Create build script
echo "🔨 Creating build script..."
cat > build.sh << 'EOF'
#!/bin/bash

# FitCore Watch App Build Script

echo "🔨 Building FitCore Watch App..."

# Clean build
echo "🧹 Cleaning build..."
xcodebuild clean -project FitCoreWatch.xcodeproj -scheme FitCoreWatch

# Build for simulator
echo "📱 Building for simulator..."
xcodebuild build -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Build complete!"
EOF

chmod +x build.sh

echo "✅ Build script created"

# Create test script
echo "🧪 Creating test script..."
cat > test.sh << 'EOF'
#!/bin/bash

# FitCore Watch App Test Script

echo "🧪 Running FitCore Watch App tests..."

# Run unit tests
echo "🔬 Running unit tests..."
xcodebuild test -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Some tests failed!"
    exit 1
fi

echo "🎉 Testing complete!"
EOF

chmod +x test.sh

echo "✅ Test script created"

# Create deployment script
echo "🚀 Creating deployment script..."
cat > deploy.sh << 'EOF'
#!/bin/bash

# FitCore Watch App Deployment Script

echo "🚀 Deploying FitCore Watch App..."

# Check if we're in release mode
if [ "$1" != "release" ]; then
    echo "⚠️  This will deploy to App Store Connect. Use 'deploy.sh release' to confirm."
    exit 1
fi

# Archive the app
echo "📦 Archiving app..."
xcodebuild archive -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'generic/platform=watchOS' -archivePath FitCoreWatch.xcarchive

if [ $? -eq 0 ]; then
    echo "✅ Archive successful!"
else
    echo "❌ Archive failed!"
    exit 1
fi

# Export for App Store
echo "📤 Exporting for App Store..."
xcodebuild -exportArchive -archivePath FitCoreWatch.xcarchive -exportPath Export -exportOptionsPlist ExportOptions.plist

if [ $? -eq 0 ]; then
    echo "✅ Export successful!"
    echo "📱 Upload to App Store Connect using Xcode or Transporter"
else
    echo "❌ Export failed!"
    exit 1
fi

echo "🎉 Deployment complete!"
EOF

chmod +x deploy.sh

echo "✅ Deployment script created"

# Create ExportOptions.plist
echo "📋 Creating export options..."
cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ Export options created"

# Final setup
echo "🎯 Final setup..."

# Make scripts executable
chmod +x setup.sh

echo "✅ Setup complete!"
echo ""
echo "🎉 FitCore Watch App is ready for development!"
echo ""
echo "Next steps:"
echo "1. Open FitCoreWatch.xcodeproj in Xcode"
echo "2. Configure your team and bundle identifier"
echo "3. Select your Apple Watch simulator or device"
echo "4. Build and run the project (⌘+R)"
echo ""
echo "For more information, see DEVELOPMENT.md"
echo ""
echo "Happy coding! 🚀"

