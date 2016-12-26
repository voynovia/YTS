source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '10.12'
use_frameworks!

target 'YTS' do
    pod 'Alamofire', '~> 4.0'
    pod 'Kanna', '~> 2.1.0'
    pod 'RealmSwift', '~> 2.1'
    pod 'Swifter', '~> 1.3.2'
end

post_install do |installer|
  Dir.glob(installer.sandbox.target_support_files_root + "Pods-*/*.sh").each do |script|
    flag_name = File.basename(script, ".sh") + "-Installation-Flag"
    folder = "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
    file = File.join(folder, flag_name)
    content = File.read(script)
    content.gsub!(/set -e/, "set -e\nKG_FILE=\"#{file}\"\nif [ -f \"$KG_FILE\" ]; then exit 0; fi\nmkdir -p \"#{folder}\"\ntouch \"$KG_FILE\"")
    File.write(script, content)
  end
end
