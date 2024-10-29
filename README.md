```bash
v .
./macos-app-bundler # to generate a config.json
```

Edit config.json:

```json
{
	"exe_name":	"MyApp",
	"app_name":	"MyApp",
	"icon_file":	"logo.png",
	"code_sign_cert_name":	"Developer ID Application: Your Name (Team ID)",
	"executable_path":	"/path/to/binary"
}
```

Run macos-app-bundler again

```bash
./macos-app-bundler

/code/users.app has been generated successfully.
```
