# Gemini GD: Google Gemini for Godot Engine

Gemini GD is an unofficial Godot Engine editor plugin that brings Google Gemini directly into your development workflow.
It enables context-aware chat, automated project context scanning, code review, script explanations,
and direct code application within the Godot 4 editor.

---

## Features

- **Context-Aware Chat**: Automatically includes active scripts, open scenes, and related project files based on your queries.
- **Editor Integration**: Docks seamlessly into the Godot editor layout and adds context menu items to scripts for instant explanations of entire scripts or specific functions.
- **Direct Code Application**: AI-generated code snippets can be reviewed and applied directly into your project files.
- **Configurable Models & Thinking Levels**: Easily switch between available Gemini Flash models and configure thinking levels via Project Settings or the plugin's settings tab.
- **Resource Management**: Attach project resources easily via the integrated picker or drag-and-drop support.

---

## Installation

1. Download or clone this repository.
2. Place the `AI_Gemini_GD` folder into your Godot project's `addons/` directory, ensuring the final path is `res://addons/AI_Gemini_GD/`.
3. Open your project in the Godot Editor.
4. Navigate to **Project -> Project Settings -> Plugins** and enable **"Gemini GD"**.

---

## Configuration

Before using the assistant, you must configure your Google Gemini API key:

1. Open the **Settings** tab inside the Gemini GD dock.
2. Alternatively, navigate to **Project Settings -> gemini_gd -> gemini_configuration -> api_key** and enter your valid API key.
3. (Optional) Adjust model parameters, temperature, and thinking levels to suit your development style.

---

## Usage

- **Open the Dock**: Find the Gemini GD dock inside your Godot editor layout.
- **Prompting**: Type your query, attach relevant resources using the resource picker, and hit Send.
- **Quick Actions**: Right-click inside any script editor to access quick utility options like explaining selected functions or code reviews.

---

## Requirements

- Godot Engine 4.3 or higher (compatible with 4.7.2-stable).
- A valid Google Gemini API Key.

---

## License

This project is open-source. See the repository for license details.
