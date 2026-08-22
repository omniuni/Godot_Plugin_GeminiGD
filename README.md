# Gemini GD: Google Gemini for Godot Engine

Gemini GD is an unofficial Godot Engine editor plugin that brings Google Gemini directly into your development workflow.
It enables context-aware chat, automated project context scanning, code review, script explanations,
and direct code application within the Godot 4 editor.

---

## Features

- **Context-Aware Chat**: Automatically includes active scripts, open scenes, and related project files based on your queries.
- **Autonomous Tool Use**: Enables Gemini to dynamically inspect project structure, check syntax and linting, and reference installed addons during multi-turn reasoning.
- **Editor Integration**: Docks seamlessly into the Godot editor layout and adds context menu items to scripts for instant explanations of entire scripts or specific functions.
- **Direct Code Application**: AI-generated code snippets can be reviewed and applied directly into your project files.
- **Configurable Models & Thinking Levels**: Easily switch between available Gemini Flash models and configure thinking levels via Project Settings or the plugin's settings tab.
- **Resource Management**: Attach project resources easily via the integrated picker or drag-and-drop support.

---

## Installation

1. Download or clone this repository.
2. Place the `AI_Gemini_GD` folder into your Godot project's `addons/` directory, ensuring the final path is `res://addons/AI_Gemini_GD/`.
3. Open your project in the Godot Editor.
4. Navigate to **Project → Project Settings → Plugins** and enable **"Gemini GD"**.

---

## Configuration

Before using the assistant, you must configure your Google Gemini API key:

1. Open the **Settings** tab inside the Gemini GD dock.
2. Alternatively, navigate to **Project Settings → gemini_gd → gemini_configuration → api_key** and enter your valid API key.
3. (Optional) Adjust model parameters, temperature, and thinking levels to suit your development style.

---

## Tool Use and Built-in Tools

Gemini GD supports multi-turn tool calling, allowing the model to autonomously gather context, inspect files, and verify syntax while formulating an answer.

### Available Tools

| Tool Name | Identifier | Cost | Description |
| :--- | :--- | :---: | :--- |
| **Project Structure** | `project_structure` | 1 | Recursively scans and returns the directory hierarchy and file listing within `res://`. Requires a file extension filter (e.g. `gd`, `tscn`) or an empty string `""` to list all project files. |
| **Check Syntax and Lint** | `check_syntax` | 2 | Checks syntax integrity and common lint warnings for specified files and/or files matching text search terms across GDScript, JSON, and scene/resource headers. |
| **Addons Directory** | `addons_directory` | 2 | Discovers and inspects installed plugins in `res://addons/`. Returns `plugin.cfg` metadata in overview mode, or searches inside addon files for reference and documentation. |

### Safeguards

To ensure reliable, safe, and cost-effective execution, the tool system includes several built-in safeguards:

- **Configurable Tool Allowance**: Each query has a strict tool budget (default 30 units). Each tool call deducts its defined cost from the remaining allowance. Tool execution stops immediately if the allowance is exhausted.
- **Continuous Budget Tracking and Warnings**: On every turn, the assistant is informed of its remaining allowance. Progressive warnings are dispatched when the allowance drops to 1/3 and 1/5, instructing the model to wrap up tool usage and formulate its final answer.
- **Loop and Duplicate Call Prevention**: The system automatically detects and blocks consecutive tool calls that repeat the same tool name with identical arguments, preventing infinite polling loops.
- **Parameter Validation**: Tool arguments are validated against strict schema rules prior to execution. Missing or malformed parameters are rejected with explanatory feedback.
- **Read-Only Inspection**: Built-in tools operate in read-only mode to analyze and inspect the project, ensuring no unintended file modifications occur during tool execution.

---

## Usage Notes

- **Open the Dock**: Find the Gemini GD dock inside your Godot editor layout.
- **Prompting**: Type your query, attach relevant resources using the resource picker, and hit Send.
- **Quick Actions**: Right-click inside any script editor to access quick utility options like explaining selected functions or code reviews.
- **Treating Addons as Project Files**:
  - By default, the `res://addons/` directory is treated as third-party dependencies and excluded from project file searches, context scans, and syntax checks to keep model context focused on your game code.
  - When working on plugin development or when you want Gemini to treat addons as editable project code, enable **"Treat Addons as Project"** under **Project Settings → gemini_gd → advanced → treat_addons_as_project**.
  - When this option is disabled, Gemini can still read addon metadata and documentation via the read-only `addons_directory` tool.

---

## Requirements

- Godot Engine 4.3 or higher (compatible with Godot 4.x).
- A valid Google Gemini API Key.

---

## License

This project is open-source. See the repository for license details.
