 # Ollama UI App

![Ollama UI App preview image](ollama_preview.png) <!-- Consider updating this preview image if UI improvements are significant -->

Welcome to the Ollama UI App! This macOS application, built with SwiftUI, offers a user-friendly interface for interacting with Ollama. We've recently added features to **start the Ollama server directly from the app** and made several **UI improvements** for a smoother experience.

## Prerequisites

To use this app, you'll first need to install Ollama.

### 1. Install Homebrew (if you don't have it)

Homebrew is a package manager for macOS that simplifies software installation.

1.  Open your Terminal (you can find it in `/Applications/Utilities/`).
2.  Run the following command:
    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

### 2. Install Ollama CLI

Once Homebrew is installed, you can install Ollama.

1.  In Terminal, run:
    ```bash
    brew install ollama
    ```
2.  Verify the installation:
    ```bash
    ollama --version
    ```
    You should see the installed Ollama CLI version.

## Getting Started

### 1. Running the Ollama Server

The Ollama UI App can now help you start the Ollama server. Alternatively, you can start it manually.

*   **From the App:** Look for an option within the Ollama UI App to start the server.
*   **Manually (via Terminal):**
    ```bash
    ollama serve
    ```
    (You might also see `ollama start` used in older documentation, but `ollama serve` is common).

### 2. Installing Ollama Models

Before you can chat, you need to download models for Ollama to use. You can do this via the Terminal.

```bash
ollama pull <model_name>
```
For example, to download the Llama 3 8B instruct model, you would run:
```bash
ollama pull llama3:8b-instruct
```
You can find a list of available models on the [Ollama Library](https://ollama.com/library).

## Using the Ollama UI App

Once the Ollama server is running and you have at least one model installed, you can launch and use the Ollama UI App to interact with your local large language models.

## Contributing

Once the Ollama CLI is running, you can use the Ollama UI App without any issues. I am very glad to see that you are interested in contributing to this open-source app! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

For any questions or further assistance, feel free to reach out to us at [yoo@minyoungyoo.com](mailto:yoo@minyoungyoo.com). Enjoy using the Ollama UI App! 😊
