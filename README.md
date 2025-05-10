# Ollama UI App for macOS

![Ollama UI App preview image](ollama_preview.png)

Welcome to the Ollama UI App for macOS! This application provides a native and intuitive SwiftUI-based user interface to interact with your local Ollama instance. Chat with your favorite large language models directly from your Mac.

## ✨ Features

*   **Model Selection:** Easily view and select from your available Ollama models.
*   **Chat Interface:** Clean and user-friendly chat interface for conversing with models.
*   **Markdown Support:** Renders model responses in Markdown for better readability.
*   **Native macOS Experience:** Built with SwiftUI for a responsive and integrated feel.
*   **Automatic Model Detection:** Detects available models from your running Ollama instance.

## 🛠️ Built With

*   SwiftUI - For the user interface.
*   MarkdownUI - For rendering Markdown content.

## 🚀 Getting Started

### Prerequisites

To fully utilize the capabilities of this app, you'll need to have Ollama installed and running on your system.

1.  **Install Ollama:**
    If you haven't already, download and install Ollama from the official website or via Homebrew:
    ```bash
    brew install ollama
    ```
2.  **Verify Ollama Installation:**
    ```bash
    ollama --version
    ```
3.  **Run Ollama:**
    Ensure the Ollama service is running. You can start it by typing the following in your Terminal:
    ```bash
    ollama serve
    ```
    Or, if you have the Ollama macOS application, ensure it is running.
4.  **Pull a Model (Optional but Recommended):**
    If you don't have any models yet, pull one using the Ollama CLI:
    ```bash
    ollama pull llama3 # Or any other model you prefer, e.g., mistral, gemma
    ```

### Installation & Running the App

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/OllamaUIApp.git # Replace with your repo URL
    cd OllamaUIApp
    ```
2.  **Open in Xcode:**
    Open the `OllamaUIApp.xcodeproj` file in Xcode (Version X.Y or later recommended).
3.  **Build and Run:**
    Select a target simulator or your Mac and click the "Run" button.

## 📖 Usage

1.  Ensure your Ollama service is running in the background.
2.  Launch the Ollama UI App.
3.  The app will attempt to load available models from your Ollama instance.
4.  Select a model from the dropdown menu.
5.  Type your message in the input field and press Enter or click the "Send" button.
6.  Converse with the model!

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## 📧 Contact

Minyoung Yoo - yoo@minyoungyoo.com

Project Link: https://github.com/hellotunamayo/Ollama-UI-App *(Replace with your repo URL)*

## 🙏 Acknowledgements

*   Ollama Team
*   Contributors to libraries used

Enjoy using the Ollama UI App! 😊
