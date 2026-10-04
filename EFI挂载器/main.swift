import Cocoa

print("=== MAIN START ===")

let app = NSApplication.shared
let delegate = AppDelegate()

print("NSApplication created")

app.delegate = delegate
app.setActivationPolicy(.regular)

print("=== DELEGATE SET ===")

app.run()
