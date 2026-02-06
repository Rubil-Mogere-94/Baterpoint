import { auth } from '../../firebase';
import { useAuthState } from 'react-firebase-hooks/auth';

export default function UserProfile() {
  const [user] = useAuthState(auth);

  const displayName = user?.displayName || user?.email || 'Guest';
  const initials = displayName ? displayName.charAt(0).toUpperCase() + displayName.charAt(1).toUpperCase() : 'GU';

  return (
    <a href="#" className="flex items-center space-x-2 p-1 rounded-md hover:bg-primary-light transition-colors duration-200">
      <div className="h-8 w-8 rounded-full bg-neutral-300 flex items-center justify-center text-neutral-700 font-medium text-sm">{initials}</div>
      <div className="hidden md:block">
        <div className="font-medium text-white">{displayName}</div>
        <div className="text-sm text-neutral-300">View Profile</div>
      </div>
    </a>
  );
}
