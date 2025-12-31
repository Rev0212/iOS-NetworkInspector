# NetworkInspector

NetworkInspector is a lightweight in-app network inspection tool for iOS.
It intercepts `URLSession` traffic and provides a built-in UI to inspect
requests, responses, headers, status codes, timing, and payloads.

This tool is intended **strictly for DEBUG builds**.

---

## Features

- Intercepts all HTTP/HTTPS requests using `URLProtocol`
- Captures request & response headers, body, status code, and timing
- In-memory log storage with size limits
- Built-in inspector UI (list → detail → tabs)
- Pretty-printed JSON responses
- Floating overlay button (does not interfere with app UI)
- Works with UIKit and SwiftUI apps

---

## Installation (Swift Package Manager)

Add the package using Xcode: 

File → Add Packages → Paste repository URL

## Usage

Enable the inspector in **DEBUG** builds only:

```swift
#if DEBUG
NetworkInspector.enable()
NetworkInspector.enableFloatingButton()
#endif

A floating 📡 button will appear on screen.
Tap it to open the network inspector UI.
