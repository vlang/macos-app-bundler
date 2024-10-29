import os
import json

struct Config {
	exe_name            string
	app_name            string
	icon_file           string
	code_sign_cert_name string
	executable_path     string
}

fn main() {
	// Read configuration
	config := read_config('config.json') or {
		println('config.json not found. Creating a default config.json...')
		config := default_config()
		write_default_config('config.json', config) or {
			eprintln('Failed to create default config.json: ${err}')
			return
		}
		println('Default config.json created. Please review and modify it as needed.')
		return
	}

	// Create app bundle
	create_app_bundle(config) or {
		eprintln('Failed to create app bundle: ${err}')
		return
	}

	// Process icon
	process_icon(config) or {
		eprintln('Failed to process icon: ${err}')
		return
	}

	// Create Info.plist
	create_info_plist(config) or {
		eprintln('Failed to create Info.plist: ${err}')
		return
	}

	println('${config.executable_path}.app has been generated successfully.')

	// Code sign app
	code_sign_app(config) or {
		eprintln('Failed to code sign app: ${err}')
		return
	}

	println('App bundle created and signed successfully.')
}

fn default_config() Config {
	return Config{
		exe_name:            'MyApp'
		app_name:            'MyApp'
		icon_file:           'logo.png'
		code_sign_cert_name: 'Developer ID Application: Your Name (Team ID)'
		executable_path:     '/path/to/executable'
	}
}

// Write default config to config.json
fn write_default_config(path string, config Config) ! {
	// Serialize Config struct to JSON with indentation for readability
	json_content := json.encode_pretty(config) // or {
	// return error('Failed to serialize default config to JSON: $err')
	//}

	// Write JSON to file
	os.write_file(path, json_content) or { return error('Failed to write to ${path}: ${err}') }
}

// Read configuration from config.json
fn read_config(path string) !Config {
	content := os.read_file(path)!
	config := json.decode(Config, content)!
	return config
}

// Create the app bundle directory structure and copy the executable
fn create_app_bundle(config Config) ! {
	// Create app bundle directories
	// app_bundle_path :=  os.join_path(config.app_path, '${config.app_name}.app')
	app_bundle_path := config.executable_path + '.app'
	contents_path := os.join_path(app_bundle_path, 'Contents')
	macos_path := os.join_path(contents_path, 'MacOS')
	resources_path := os.join_path(contents_path, 'Resources')

	os.mkdir_all(macos_path)!
	os.mkdir_all(resources_path)!

	// Copy executable to MacOS
	dest_executable := os.join_path(macos_path, config.exe_name)
	os.cp(config.executable_path, dest_executable)!
	os.chmod(dest_executable, 0o755)!
}

// Process icon using sips and iconutil
fn process_icon(config Config) ! {
	// Create iconset directory
	iconset_dir := 'MyIcon.iconset'
	os.mkdir(iconset_dir)!

	// Define sizes and filenames
	sizes := [
		{
			'size':     '16'
			'filename': 'icon_16x16.png'
		},
		{
			'size':     '32'
			'filename': 'icon_16x16@2x.png'
		},
		{
			'size':     '32'
			'filename': 'icon_32x32.png'
		},
		{
			'size':     '64'
			'filename': 'icon_32x32@2x.png'
		},
		{
			'size':     '128'
			'filename': 'icon_128x128.png'
		},
		{
			'size':     '256'
			'filename': 'icon_128x128@2x.png'
		},
		{
			'size':     '256'
			'filename': 'icon_256x256.png'
		},
		{
			'size':     '512'
			'filename': 'icon_256x256@2x.png'
		},
		{
			'size':     '512'
			'filename': 'icon_512x512.png'
		},
	]

	for s in sizes {
		size := s['size']
		filename := s['filename']
		cmd := 'sips -z ${size} ${size} "${config.icon_file}" --out "${iconset_dir}/${filename}"'
		res := os.execute(cmd)
		if res.exit_code != 0 {
			return error('Failed to execute command: ${cmd}')
		}
	}

	// Copy original icon for 512x512@2x.png
	dest_icon := os.join_path(iconset_dir, 'icon_512x512@2x.png')
	os.cp(config.icon_file, dest_icon)!

	// Generate icns file
	icns_file := '${config.exe_name}.icns'
	cmd_iconutil := 'iconutil -c icns ${iconset_dir} -o ${icns_file}'
	res := os.execute(cmd_iconutil)
	if res.exit_code != 0 {
		return error('Failed to execute command: ${cmd_iconutil}')
	}

	// Copy icns to Resources
	resources_path := os.join_path('${config.executable_path}.app', 'Contents', 'Resources')
	icns_dest := os.join_path(resources_path, icns_file)
	os.cp(icns_file, icns_dest)!

	// Clean up iconset directory
	os.rmdir_all(iconset_dir)!
	os.rm(icns_file)!
}

// Create Info.plist with appropriate fields
fn create_info_plist(config Config) ! {
	// vfmt off
	plist_content := '<?xml version="1.0" encoding="UTF-8"?>\n' +
	'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ' +
	'"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' +
	'<plist version="1.0">\n' +
	'<dict>\n' +
	'	<key>CFBundleExecutable</key>\n' +
	'	<string>${config.exe_name}</string>\n' +
	'	<key>CFBundleIconFile</key>\n' +
	'	<string>${config.exe_name}</string>\n' +
	'	<key>CFBundleIdentifier</key>\n' +
	'	<string>${config.exe_name}</string>\n' +
	'	<key>CFBundleName</key>\n' +
	'	<string>${config.exe_name}</string>\n' +
	'	<key>CFBundlePackageType</key>\n' +
	'	<string>APPL</string>\n' +
	'	<key>CFBundleURLTypes</key>\n' +
	'        <array>\n' +
	'          <dict>\n' +
	'            <key>CFBundleURLName</key>\n' +
	'            <string>${config.exe_name} URL</string>\n' +
	'	        <key>CFBundleURLSchemes</key>\n' +
	'		        <array>\n' +
	'			        <string>${config.exe_name}</string>\n' +
	'		        </array>\n' +
	'	        </dict>\n' +
	'	    </array>\n' +
	'	<key>LSMinimumSystemVersion</key>\n' +
	'	<string>10.7.0</string>\n' +
	'	<key>LSUIElement</key>\n' +
	'	<string>1</string>\n' +
	'	<key>NSHighResolutionCapable</key>\n' +
	'	<true/>\n' +
	'</dict>\n' +
	'</plist>\n'
	// vfmt on

	// Write to Info.plist
	info_plist_path := os.join_path('${config.executable_path}.app', 'Contents', 'Info.plist')
	os.write_file(info_plist_path, plist_content)!
}

// Code sign the app
fn code_sign_app(config Config) ! {
	app_bundle_path := config.executable_path + '.app'
	res := os.execute('codesign -s "${config.code_sign_cert_name}" -v ${app_bundle_path}')
	if res.exit_code != 0 {
		return error('Failed to code sign app: ${res.output}')
	}
}
