// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBOl4GVyM2RsClvkoEnzgLQ3M9LgR4W4rI",
  authDomain: "barter-point-3c7a5.firebaseapp.com",
  projectId: "barter-point-3c7a5",
  storageBucket: "barter-point-3c7a5.firebasestorage.app",
  messagingSenderId: "65392254562",
  appId: "1:65392254562:web:9ffc85587a2637d217fb3b",
  measurementId: "G-EGPD18S3X1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);

export { app, analytics, auth };
