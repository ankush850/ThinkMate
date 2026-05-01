# ThinkMate – Offline AI Study Companion

<p align="center">
  <img src="https://github.com/ankush850/ThinkMate/blob/c830eccb5180ecff67d63e48ac705c9d954c41ee/ThinkMate.png" width="180"/>
</p>

<p align="center">
  <b>Talk to your PDFs. Learn faster.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-brightgreen?logo=android"/>
  <img src="https://img.shields.io/badge/Framework-Flutter-blue?logo=flutter"/>
  <img src="https://img.shields.io/badge/LLM-Llama--3.2-orange"/>
  <img src="https://img.shields.io/badge/STT-Whisper-green"/>
  <img src="https://img.shields.io/badge/Runtime-RunAnywhere-purple"/>
  <img src="https://img.shields.io/badge/Mode-100%25%20Offline-red"/>
</p>

---

##  Overview

**ThinkMate** is a fully offline AI-powered study assistant designed to run entirely on-device.  
It transforms static PDFs into **interactive, conversational learning experiences** using embedded AI models.

Unlike cloud-based systems, ThinkMate ensures:

-  Full data privacy  
-  Real-time responses  
-  Zero dependency on internet connectivity  

---

## 📥 Download

> ⚠️ Requires Android device with minimum 4GB RAM

| Version | Format | Link |
| :--- | :--- | :--- |
| **ThinkMate v1.0.0 (Latest)** | APK | [![Download APK](https://img.shields.io/badge/Download-APK-blue?logo=android&style=for-the-badge)](https://github.com/omhujband/ThinkMate/releases/download/v1.0.0/ThinkMate.apk) |

---


##  Motivation

Traditional AI learning tools suffer from:

- Dependence on cloud APIs  
- Privacy concerns with sensitive study material  
- Poor personalization for user-provided documents  
- Latency in real-time interaction  

**ThinkMate addresses these limitations by deploying a complete AI pipeline locally.**

---

##  Core Capabilities

###  Document Intelligence
- Local PDF parsing and semantic chunking  
- Context-aware retrieval system  
- Persistent on-device document memory  

---

###  Voice-Driven Interaction
- Continuous conversation mode  
- Whisper-based offline speech recognition  
- Real-time conversational feedback  

---

###  Concept Simplification
- Structured breakdown of complex ideas  
- Step-by-step reasoning  
- Analogy-driven explanations  

---

###  Adaptive Quiz Engine
- Auto-generated MCQs from source material  
- Instant grading and feedback  
- Explanation-first learning approach  

---

## 🛠️ Tech Stack

| Layer | Technology |
|------|-----------|
| Frontend | Flutter |
| AI Runtime | RunAnywhere |
| LLM | Llama 3.2 |
| Speech-to-Text | Whisper |
| Text-to-Speech | Mimic |
| State Management | Provider |
| Storage | Local Cache |

---
##  System Architecture
```mermaid
flowchart LR

%% Layers
subgraph UI["UI"]
A[Chat / Voice / Quiz]
end

subgraph APP["App Layer"]
B[Session + State]
end

subgraph CORE["AI Core"]
C[Input Router]
D[Context + Prompt]
E[Response Formatter]
end

subgraph MODELS["Models"]
F[Llama LLM]
G[Whisper STT]
H[TTS]
end

subgraph DATA["Data"]
I[PDF + Index]
end

%% Flow
A --> B --> C
C --> G
C --> D
D --> I
D --> F
F --> E
E --> H
E --> A
```

## PDF Processing Pipeline

``` mermaid
flowchart LR

A[PDF Upload] --> B[Text Extraction]

B --> C[Cleaning & Normalization]

C --> D[Chunking Engine]

D --> E[Metadata Tagging]

E --> F[Index Storage]

F --> G[Ready for Retrieval]
```
## Voice Interaction Loop (Real-Time)

```mermaid
sequenceDiagram
participant User
participant Mic
participant STT as Whisper STT
participant Core
participant LLM
participant TTS

User->>Mic: Speak
Mic->>STT: Audio Stream
STT->>Core: Transcribed Text
Core->>LLM: Context + Prompt
LLM->>Core: Response
Core->>TTS: Convert to Speech
TTS->>User: Audio Output
```


## Runtime Execution Model
Single-device orchestration
Async processing across:
Audio pipeline
LLM inference
UI rendering
Memory-aware execution:
Chunked inference
Cached embeddings
No external API dependency

##  Key Design Principles
1. On-Device First
All computation happens locally:
Eliminates latency
Guarantees privacy

2. Modular AI Pipeline
Each component is isolated:
STT, LLM, TTS are independent
Easy to upgrade models

3. Context-Grounded AI
No hallucination-prone open responses
Strict document-based answering

4. Streaming Interaction (Planned)
Real-time token streaming
Continuous voice loop


## 🚀 Why This Architecture Stands Out

Most projects:

Use APIs
Have shallow pipelines
Lack real orchestration

ThinkMate instead implements:

Full offline AI stack
Multi-model coordination
Real-time voice + reasoning loop
Embedded document intelligence

---
