// tests/__mocks__/firebase.ts
import { jest } from '@jest/globals';

export const useAuth = jest.fn(() => ({
  currentUser: null,
  userToken: null,
  loading: false,
}));

export const auth = {};
export const app = {};
export const analytics = {};
export const initializeApp = jest.fn();
export const getAnalytics = jest.fn();
export const getAuth = jest.fn();
export const sendPasswordResetEmail = jest.fn();
