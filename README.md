**NetworkInspector**

NetworkInspector is a lightweight, in-app network inspection tool for iOS apps.
It intercepts URLSession traffic and provides a built-in UI to inspect HTTP requests and responses in real time.

DEBUG builds only. Do not ship this tool in production.

**What It Does (Precisely)** :

NetworkInspector works by registering a custom URLProtocol that observes network traffic initiated through URLSession.

• Request method, URL, headers, and body
• Response headers, status code, and body
• Request timing and duration
• Base URL grouping for easier filtering

All logs are stored in memory only (no disk persistence).

**Features:**

• Intercepts HTTP/HTTPS traffic using URLProtocol
• Intercept all requests or only selected base URLs
• Captures request and response headers and bodies
• Captures status codes and timing information
• In-memory log storage with size limits
• Built-in inspector UI (List → Detail → Tabs)
• Pretty-printed JSON responses
• Share requests as cURL commands
• Floating overlay button that does not block app interaction
• Works with UIKit and SwiftUI

**Installation (Swift Package Manager)**

• Open Xcode
• Go to File → Add Packages
• Paste https://github.com/Rev0212/iOS-NetworkInspector
• Add the package to your app target

**Usage**
Enable the inspector in DEBUG builds to intercept all requests:

#if DEBUG
NetworkInspector.LeapInspector.enable()
NetworkInspector.LeapInspector.enableFloatingButton()
#endif

To intercept only specific base URLs:

#if DEBUG
NetworkInspector.enable(baseURLs: ["https://my-api.com", "https://my-base-api.com"])
NetworkInspector.enableFloatingButton()
#endif


**Inspector UI**
• Floating button opens the inspector
• Browse requests in a list view
• Inspect headers, body, response, and timing
• Share as cURL or delete logs
• Overlay does not interfere with app UI

**Important Notes**

• DEBUG builds only
• Works only with URLSession
• Logs cleared on app restart
• Intended strictly as a developer debugging tool
