# OpenPanel Swift SDK

The OpenPanel Swift SDK allows you to integrate OpenPanel analytics into your iOS, macOS, tvOS, and watchOS applications.

## Features

- Easy-to-use API for tracking events and user properties
- Automatic collection of app states
- Support for custom event properties
- Shared instance for easy access throughout your app

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 12.0+
- Swift 5.3+

## Installation

### Swift Package Manager

You can add OpenPanel to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Add Packages...**
2. Enter `https://github.com/Openpanel-dev/swift-sdk` into the package repository URL text field
3. Click **Add Package**

Alternatively, if you have a `Package.swift` file, you can add OpenPanel as a dependency:

```swift
dependencies: [
    .package(url: "https://github.com/Openpanel-dev/swift-sdk")
]
```

## Usage

### Initialization

First, import the SDK in your Swift file:

```swift
import OpenPanel
```

Then, initialize the OpenPanel SDK with your client ID:

```swift
OpenPanel.initialize(options: .init(
    clientId: "YOUR_CLIENT_ID",
    clientSecret: "YOUR_CLIENT_SECRET"
))
```

### Tracking Events

To track an event:

```swift
OpenPanel.track(name: "Button Clicked", properties: ["button_id": "submit_form"])
```

### Identifying Users

To identify a user:

```swift
OpenPanel.identify(payload: IdentifyPayload(
    profileId: "user123",
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    properties: ["subscription": "premium"]
))
```

### Setting Global Properties

To set properties that will be sent with every event:

```swift
OpenPanel.setGlobalProperties([
    "app_version": "1.0.2",
    "environment": "production"
])
```

### Creating Aliases

To create an alias for a user:

```swift
OpenPanel.alias(payload: AliasPayload(profileId: "user123", alias: "u123"))
```

### Incrementing Properties

To increment a numeric property:

```swift
OpenPanel.increment(payload: IncrementPayload(profileId: "user123", property: "login_count"))
```

### Decrementing Properties

To decrement a numeric property:

```swift
OpenPanel.decrement(payload: DecrementPayload(profileId: "user123", property: "credits_remaining"))
```

## Advanced Usage

### Disabling Tracking

You can temporarily disable tracking during initialization:

```swift
OpenPanel.initialize(options: .init(
    clientId: "YOUR_CLIENT_ID",
    clientSecret: "YOUR_CLIENT_SECRET",
    disabled: true
))
```

### Custom Event Filtering

You can set up custom event filtering during initialization:

```swift
OpenPanel.initialize(options: .init(
    clientId: "YOUR_CLIENT_ID",
    clientSecret: "YOUR_CLIENT_SECRET",
    filter: { payload in
        // Your custom filtering logic here
        return true // or false to filter out the event
    }
))
```

## Thread Safety

The OpenPanel SDK is designed to be thread-safe. You can call its methods from any thread without additional synchronization.

## Automatic Tracking

The SDK automatically tracks app lifecycle events (`app_opened` and `app_closed`) if `automaticTracking` is set to `true` during initialization.