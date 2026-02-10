import { useState, useEffect } from 'react';
import { auth } from '../../firebase'; // Import the auth object from firebase.ts
import { User } from 'firebase/auth'; // Import User type if needed

interface AuthState {
  currentUser: User | null;
  loading: boolean;
  userToken?: string | null; // Optional, if you need to store the token
}

export function useAuth() {
  const [authState, setAuthState] = useState<AuthState>({
    currentUser: null,
    loading: true,
    userToken: null,
  });

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (user) => {
      let userToken: string | null = null;
      if (user) {
        // Optionally get the ID token
        userToken = await user.getIdToken();
      }
      setAuthState({
        currentUser: user,
        loading: false,
        userToken: userToken,
      });
    });

    // Cleanup subscription on unmount
    return () => unsubscribe();
  }, []);

  return authState;
}