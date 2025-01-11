# FastSh

FastSh is a macOS application that helps you quickly generate shell commands using AI. It provides a convenient floating command input window that can be triggered with a global hotkey.

## Features

- 🚀 Quick command generation using OpenAI's API
- ⌨️ Global hotkey (Option + Space) to show/hide the command input
- 📋 Automatic command copying to clipboard
- 🔔 Native macOS notifications
- ⚙️ Configurable OpenAI API settings
- 🎨 Clean, native macOS UI with transparency effects

## Requirements

- macOS 15.1 or later
- OpenAI API key

## Installation

1. Download the latest release of FastSh
2. Move the app to your Applications folder
3. Launch FastSh
4. Configure your OpenAI API key in the Settings

## Usage

1. Press `Option + Space` to bring up the command input window
2. Type your command request in natural language
3. Press `Enter` to generate the command
4. The generated command will be automatically copied to your clipboard
5. A notification will appear confirming the command has been copied

## Configuration

Access the settings through the menu bar icon:

1. Click on the terminal icon in the menu bar
2. Select "Settings..."
3. Enter your OpenAI API key
4. (Optional) Modify the API base URL if using a different endpoint

## Development

FastSh is built using:

- SwiftUI for the user interface
- AppKit for native macOS integration
- Combine for reactive programming
- OpenAI's API for command generation

## Security

- API keys are stored securely in the system keychain
- All communication with OpenAI is done over HTTPS
- The application runs as a standard user process

## Version

Current version: 1.0.0

## License

[Your license information here]

## Author

Created by Onur Ravli
