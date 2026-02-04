/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#3B82F6', // Blue-500
          light: '#60A5FA',  // Blue-400
          dark: '#2563EB',   // Blue-600
        },
        secondary: {
          DEFAULT: '#10B981', // Green-500
          light: '#34D399',  // Green-400
          dark: '#059669',   // Green-600
        },
        accent: {
          DEFAULT: '#F59E0B', // Amber-500
          light: '#FBBF24',  // Amber-400
          dark: '#D97706',   // Amber-600
        },
        neutral: {
          50: '#F9FAFB',     // Gray-50
          100: '#F3F4F6',    // Gray-100
          200: '#E5E7EB',    // Gray-200
          300: '#D1D5DB',    // Gray-300
          400: '#9CA3AF',    // Gray-400
          500: '#6B7280',    // Gray-500
          600: '#4B5563',    // Gray-600
          700: '#374151',    // Gray-700
          800: '#1F2937',    // Gray-800
          900: '#111827',    // Gray-900
        },
        text: {
          DEFAULT: '#374151', // Neutral-700
          light: '#6B7280',  // Neutral-500
          dark: '#1F2937',   // Neutral-800
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'], // Using Inter as a modern, clean sans-serif font
      },
    },
  },
  plugins: [],
}