# BarterPoint Africa

![BarterPoint Africa Banner](https://via.placeholder.com/1200x300/00A65A/FFFFFF?text=BarterPoint+Africa) <!-- Placeholder banner image -->

BarterPoint Africa is a cutting-edge web application designed to revolutionize trade in the Kenyan market. Optimized for seamless performance across all devices—mobile phones, tablets, and desktops—our platform connects users for efficient bartering and selling of goods and services. We are committed to delivering an exceptional user experience, prioritizing performance, and integrating features specifically tailored to the unique needs of Kenyan users.

## ✨ Features

### Core Functionality
-   **Responsive Navigation:** Intuitive navigation experience that gracefully adapts from desktop to mobile interfaces, ensuring ease of use regardless of screen size.
-   **Dynamic Listing Grid:** Listings are displayed in an optimized grid layout that intelligently adjusts to provide the best viewing experience on any device.
-   **Adaptive Listing Forms:** A smart "Create Listing" form that changes its layout and available options based on the user's device and selected trade type (barter, cash, or mixed).
-   **Intelligent Sidebar/Drawer:** A persistent sidebar on desktop transforms into a user-friendly, slide-out drawer on mobile for efficient space utilization.
-   **Real-time Trade Chat:** A responsive chat interface designed for smooth communication between traders, featuring mobile-specific quick reply options for fast interactions.

### Kenyan Market Optimizations
-   **Touch-Friendly Design:** All interactive elements meet a minimum touch target size of 44px, ensuring comfortable and accurate interactions on touchscreens.
-   **Network-Aware Image Loading:** Optimizes data usage by dynamically serving lower-quality images on slower networks (2G, data-saver mode) or smaller screens, crucial for varying connectivity conditions.
-   **Offline-First Capabilities:** Enhanced reliability in areas with intermittent internet access through mechanisms that store pending actions locally and synchronize with the server when connectivity is restored.

## 🚀 Getting Started

Follow these steps to set up and run BarterPoint Africa locally.

### Prerequisites

-   Node.js (LTS version recommended)
-   Python 3.8+
-   `npm` or `yarn` for frontend package management
-   `pip` for backend package management

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/barterpoint-africa.git # Replace with actual repo URL
cd barterpoint-africa
```

### 2. Frontend Setup

Install frontend dependencies:

```bash
npm install
```

### 3. Backend Setup

Navigate to the `backend` directory, create a Python virtual environment, and install dependencies:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows, use `.\venv\Scripts\activate`
pip install -r requirements.txt
cd .. # Return to project root
```

### 4. Run the Application

Start both the frontend and backend servers concurrently:

```bash
npm run dev:all
```

-   The frontend will be accessible at `http://localhost:3000`.
-   The backend API will be running on `http://localhost:8000`.

## 🏗️ Project Structure

```
.
├── app/                    # Next.js 14 App Router (Frontend)
│   ├── components/         # Reusable React components
│   ├── lib/                # Utility functions, hooks, API clients
│   ├── styles/             # Global styles and Tailwind CSS imports
│   └── ...                 # Other Next.js specific files (pages, layout)
├── backend/                # Python FastAPI API
│   ├── main.py             # FastAPI application entry point
│   ├── requirements.txt    # Python dependencies
│   └── venv/               # Python virtual environment
├── public/                 # Static assets (images, manifest, service worker)
├── tailwind.config.ts      # Tailwind CSS configuration
├── next.config.ts          # Next.js configuration
├── package.json            # Frontend dependencies and scripts
├── tsconfig.json           # TypeScript configuration
└── README.md               # Project README
```

## 🛠️ Technologies Used

### Frontend
-   **React:** A declarative, component-based JavaScript library for building user interfaces.
-   **TypeScript:** A superset of JavaScript that adds static types, enhancing code quality and maintainability.
-   **Next.js 14 (App Router):** A React framework enabling server-side rendering (SSR), static site generation (SSG), and API routes for powerful web applications.
-   **Tailwind CSS:** A utility-first CSS framework for rapidly building custom designs.

### Backend
-   **Python:** A versatile high-level programming language.
-   **FastAPI:** A modern, fast (high-performance) web framework for building APIs with Python 3.7+ based on standard Python type hints.

### Database & Other (Planned)
-   **PostgreSQL:** Robust relational database.
-   **Redis:** In-memory data structure store, used as a cache and message broker.
-   **Vercel:** Platform for frontend deployment.
-   **Railway/Digital Ocean:** Platforms for backend deployment.

## ⚙️ Configuration & Optimization

### Tailwind CSS Configuration (`tailwind.config.ts`)
Our Tailwind configuration includes custom breakpoints and a brand color palette (`primary`: M-Pesa green, `secondary`: Kenyan orange) to align with local design preferences and common device sizes in Kenya.

```javascript
// Example from tailwind.config.ts
module.exports = {
  // ...
  theme: {
    screens: {
      'xs': '320px', 'sm': '480px', 'md': '768px',
      'lg': '1024px', 'xl': '1280px', '2xl': '1536px',
    },
    extend: {
      colors: {
        'primary': '#00A65A',  /* M-Pesa green */
        'secondary': '#FF9900', /* Kenyan orange */
      },
    },
  },
  // ...
}
```

### Next.js Performance Enhancements (`next.config.ts`)
The `next.config.ts` file is configured for optimal performance:
-   **Image Optimization:** Defined `deviceSizes` and `imageSizes` for efficient image delivery.
-   **Compression:** `compress: true` for GZIP compression.
-   **Experimental Features:** `optimizeCss` and `scrollRestoration` enabled for enhanced user experience.
-   **SVG Handling:** Webpack configured to use `@svgr/webpack` for importing SVGs as React components.

### Progressive Web App (PWA) Support
BarterPoint Africa is designed as a PWA, offering an app-like experience directly from the web browser. This is enabled via:
-   **Web App Manifest (`public/manifest.json`):** Defines app metadata, icons, and display properties for "Add to Home Screen" functionality.
-   **Service Worker (`public/sw.js`):** Basic service worker for caching assets, enabling offline access and faster subsequent loads.

## ✅ Testing

We employ a multi-faceted testing approach to ensure reliability and responsiveness:

-   **Responsive Design Testing:** Thorough validation across a matrix of devices and emulators (iOS Safari, Android Chrome, various desktop browsers).
-   **Network Condition Testing:** Evaluation under simulated slow 3G networks using browser developer tools.
-   **User Interaction Testing:** Extensive testing of touch interactions, PWA installation, and offline functionality.
-   **Breakpoint Visual Debugging:** Use of specific CSS media queries for visual debugging of breakpoints during development.

## 💡 Future Enhancements & Roadmap

We plan to expand BarterPoint Africa with the following features:

-   **M-Pesa Integration:** Seamless and responsive payment flows for M-Pesa transactions.
-   **Multilingual Support:** Introduction of Swahili/English language toggling.
-   **Location-Based Services:** Optimized use of mobile GPS for location-aware features.
-   **SMS Fallback:** Notification system with SMS fallback for critical updates.
-   **WhatsApp Sharing:** Direct integration for sharing listings and app content via WhatsApp.

## 👋 Contributing

We welcome contributions! Please see our `CONTRIBUTING.md` (to be created) for guidelines on how to contribute to BarterPoint Africa.

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the `LICENSE` file for details. (License file to be created)

---

Developed with ❤️ for the Kenyan market.
