# macLlama: Native macOS GUI for Ollama

![macLlama preview image](macllama_logo.png)

Welcome to **macLlama**! This macOS application, built with SwiftUI, provides a user-friendly interface for interacting with Ollama. Recent updates include the ability to start the Ollama server directly from the app and various UI enhancements.

## System Requirements

*   **Operating System:** macOS 14.0 Sonoma or later.
*   **Processor:** Apple Silicon (e.g., M1, M2, M3, M4 series).
*   **Memory (RAM):** Varies based on the Ollama models you plan to use. Larger models require more RAM. Refer to the official [Ollama documentation](https://github.com/ollama/ollama/blob/main/docs/faq.md#what-are-the-system-requirements-to-run-ollama) for specific recommendations.
*   **Ollama Installation:** A working installation of Ollama is required.

## Getting Started

### Prerequisites

Before using macLlama, you're going to need to install Ollama:

1.  **Install Homebrew (if needed):**

    Open Terminal (`/Applications/Utilities/Terminal`) and run:

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

2.  **Install Ollama:**

    In Terminal, run:

    ```bash
    brew install ollama
    ```

3.  **Verify Installation:**

    ```bash
    ollama --version
    ```

### Installation & Running the App

1.  **Download the Application:**

    *   Go to the [Releases Page](https://github.com/hellotunamayo/macLlama/releases) of this repository.
    *   Download the latest `macLlama.app.zip` file from the Assets section.

2.  **Install:**

    *   Unzip the downloaded file.
    *   Drag the `macLlama.app` file to your `/Applications` folder.

3.  **Run the App:**

    Open `macLlama` from your Applications folder.

### Running the Ollama Server

macLlama can help you start the Ollama server. Alternatively, you can start it manually:

*   **From the App:** Look for a button or menu option to start the server.
*   **Manually:**

    ```bash
    ollama serve
    ```

### Installing Ollama Models

Before chatting, you need to download models for Ollama.

*   **Via macLlama:** Go to the `Settings > Model Management` tab, enter a model name(or location), and click "Pull".

*   **Via Terminal:**

    ```bash
    ollama pull <model_name>
    ```

    Example:

    ```bash
    ollama pull llama3:8b-instruct
    ```

    Find available models on the [Ollama Library](https://ollama.com/library).

## Usage

1.  Launch macLlama.
2.  The app will attempt to load available models.
3.  Select a model from the dropdown menu.
4.  Type your message and press Enter or click the "Send" button.(or `command + return` to send)

## Chat History (v1.0.5 - Build 2)

macLlama securely stores your chat conversations locally using SwiftData.

**Viewing / Managing Chat History:**

*   **Menu:** `Window > Chat History`.

**Resetting Chat History (Advanced - Use with Caution):**

If you encounter issues with chat history, you can manually manage the SwiftData storage. This is an advanced operation and should only be attempted if you understand the potential consequences.

**To reset your chat history:**

1.  Navigate to: `~/Library/Application Support/`
2.  Delete the following files:
    *   `default.store`
    *   `default.store-shm`
    *   `default.store-wal`

**WARNING:** Deleting these files will remove *all* SwiftData storage for macLlama and may impact other applications using SwiftData. Back up your local storage before attempting this.

## Contributing

Contributions are welcome!  Fork the project, create a feature branch, commit your changes, push to the branch, and open a pull request.

## License

Distributed under the Apache 2.0 License. See `LICENSE.txt` for more information.

## Frameworks & Libraries

*   **SwiftUI:**  macLlama is built using SwiftUI for a modern user interface.
*   **MarkdownUI:** We utilize the [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) library to render chat messages in Markdown.

## Contact

*   Project Discussions: [https://github.com/hellotunamayo/macLlama/discussions](https://github.com/hellotunamayo/macLlama/discussions)
*   Project Link: [https://github.com/hellotunamayo/macLlama](https://github.com/hellotunamayo/macLlama)

## Acknowledgements

*   Ollama Team
*   Contributors to libraries used

Enjoy using macLlama! 😊