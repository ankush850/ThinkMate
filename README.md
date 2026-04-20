# 🧠 ThinkMate – Your Offline AI Study Companion

ThinkMate is a premium, **100% on-device** AI learning assistant designed to transform your PDF documents into interactive study sessions. Unlike traditional AI tools, ThinkMate processes everything—from logic to voice—locally on your hardware for ultimate privacy and zero-latency offline learning.


---

## ✨ Key Features

### 📄 Smart Document Processing
- **Local PDF Indexing**: Upload your study materials once. ThinkMate extracts and chunks the text locally, allowing the AI to "read" and reference your specific documents during study sessions.
- **History Management**: Keep track of all your materials in a sleek history list. Delete or clear the entire cache with a single tap.

### 🗣️ "Talk About It" – Voice Interaction
- **Hands-Free Conversation**: A seamless, continuous voice interface. No need to press the mic for every turn—just talk, and the AI will listen, process, and reply.
- **Resilient Speech-to-Text**: High-accuracy local STT (Whisper-based) optimized for 16kHz mono audio.

### 🧩 Concept Simplifier
- **Step-by-Step Breakdown**: Stuck on a difficult chapter? ThinkMate breaks down complex concepts from your material into simple, numbered steps with clear analogies.
- **Context-Aware**: Explanations are strictly grounded in your provided document to ensure accuracy.

### 📝 Interactive Quiz Mode
- **Structured Learning**: The AI generates multiple-choice questions (MCQs) mapped directly to your material.
- **Real-Time Grading**: Get instant feedback on your answers.
- **Detailed Explanations**: Once revealed, the AI provides a full explanation of why an answer is correct.

---

## 🔒 Privacy & Offline First
- **Zero Internet Requirement**: Once the initial models are downloaded, ThinkMate functions entirely without a data connection.
- **Data Sovereignty**: Your PDFs and conversations never leave your device. We use local model storage for the LLM (Llama-3.2-1B-Instruct), STT (Whisper), and TTS engines.

---

## 📥 Downloads

Download the latest release for your Android device below:

> [!IMPORTANT]
> Since ThinkMate runs AI models locally, your device should have at least 4GB of RAM (8GB+ recommended) for the best experience.

| Version | Format | Link |
| :--- | :--- | :--- |
| **ThinkMate v1.0.0 (Latest)** | APK | [**Download APK**](https://github.com/omhujband/ThinkMate/releases/download/v1.0.0/ThinkMate.apk) |

---

## 🚀 Getting Started

1. **Install the APK** on your Android device.
2. **Onboarding**: Open the app and follow the splash screen prompts to download the required AI models (approx. 1-2GB total).
3. **Upload**: Tap the "Upload Material" button on the home screen and select a PDF.
4. **Learn**: Tap your document and choose a study module!

---

## 🛠️ Tech Stack
- **Framework**: [Flutter](https://flutter.dev)
- **AI Core**: [RunAnywhere](https://pub.dev/packages/runanywhere) (Llama-3.2, Whisper, Mimic TTS)
- **Animations**: `flutter_animate`
- **State Management**: `provider`
- **Storage**: `path_provider` & local cache

