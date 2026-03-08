# TransportSense: AI-Powered Transport Emission Analytics

TransportSense is a comprehensive web-based platform designed to analyze, visualize, and forecast global transport emissions. Built for peak performance, it features a blazingly fast Haskell backend using the Scotty framework and a dynamic, zero-dependency vanilla JS frontend. 

The project allows users to seamlessly upload transport emission datasets, view complex analytics through interactive charts, forecast future emissions using linear regression, and chat with an integrated AI regarding the transport data.

---

## 🚀 Key Features

1. **Global Dashboard & Visualizations**
   - High-performance data parsing and rendering for emission data spanning 196 countries.
   - Beautiful, interactive charts powered by **Chart.js** (Modal Share, CO₂ Trends, Green Scores).
   - Dynamic dark/light mode with a modern glassmorphism aesthetic.

2. **Custom Dataset Importing**
   - Import your own `.json` format transport data through a simple drag-and-drop interface.
   - Instantly generates localized mini-dashboards for the imported data.

3. **Future AI Forecasting**
   - **Linear Regression Prediction:** A custom mathematical engine instantly forecasts metric trends (CO₂ per Capita, Green Scores, and Motorisation rates) up to 2035.
   - Calculates projected percentage improvements and tracks goal margins.

4. **Integrated AI Assistant (Groq Llama 3)**
   - Chat directly with your dataset! Powered by the ultra-fast **Llama 3.1 LLM via the Groq API**.
   - **Context-Grounded:** The AI is secretly fed a compressed payload of the currently loaded dataset under the hood, ensuring it answers specific questions based *only* on the actual tabular transport data without hallucinating external knowledge.

5. **Advanced Emission Calculator**
   - Design custom transport modal splits using interactive sliders.
   - Predict total annual CO₂ footprints for entire city populations.
   - Export actionable intelligence as formatted PDF reports or localized CSV datasets.

---

## 💻 Tech Stack

- **Frontend**
  - **HTML, CSS, JS:** A fully custom, responsive, framework-less UI layout for completely unrestricted control over animations, glass overlays, and component styling.
  - **Chart.js:** Robust client-side data visualization.

- **Backend**
  - **Haskell:** Strict, functional, and purely mathematically evaluated language backend.
  - **Scotty Framework:** A lightweight, rapid web framework serving the frontend and automatically discovering/routing JSON datasets from the `static/` directory to dynamic endpoints.

- **Version Control & DevOps**
  - **Git & GitHub:** Full source control management and collaboration.
  - **Docker:** Fully containerized setup ensuring identical development, testing, and production environments without dependency skew.
  - **Railway:** Frictionless, automated CI/CD deployment platform directly pulling from GitHub via the Docker container for instantly live URL links.

---

## ⚙️ Local Setup Instructions

### Prerequisites
- Install **Haskell Tool Stack** (`stack`)
- Install **Docker** (optional, if you wish to run the containerized build locally)

### Option 1: Running Directly via Stack
1. Clone the repository and navigate into the project directory:
   ```bash
   git clone <repository-url>
   cd scotty-web
   ```
2. Build the Haskell dependencies:
   ```bash
   stack build
   ```
3. Run the web server:
   ```bash
   stack run
   ```
4. Once running, open your web browser and navigate to:
   ```
   http://localhost:3000/dashboard.html
   ```

### Option 2: Running via Docker
1. Ensure the Docker daemon is running.
2. Build the Docker image from the root directory:
   ```bash
   docker build -t transportsense .
   ```
3. Run the container and map port 3000:
   ```bash
   docker run -p 3000:3000 transportsense
   ```

---

## 🌐 Deployment (Railway)

TransportSense is natively designed to be deployed seamlessly on **Railway.app** using the included `Dockerfile`.

1. Push your latest code containing the `Dockerfile` to your GitHub repository.
2. Log into Railway and create a **New Project > Deploy from GitHub repo**.
3. Select your repository branching to `main`.
4. Railway will automatically detect the Dockerfile, build the Haskell binary within an isolated environment, and spin up an externally facing URL. 
   *(Note: Ensure your Railway service exposes Port `3000`)* 

---

## 🤖 Configuring the AI Assistant

Because the AI Chatbot runs securely via the client's local browser, it requires a free **Groq API key**:
1. Visit the [Groq Console API Keys page](https://console.groq.com/keys).
2. Create a free account (no credit card required) and generate an API key (`gsk_...`).
3. Open the live TransportSense Dashboard, navigate to the **AI Prediction** tab on the sidebar.
4. Click **⚙️ Setup API** in the Chatbot panel, paste your key, and click Save.
5. The API key is securely saved in your local storage. The AI Assistant will instantly begin analyzing your dashboard data!
