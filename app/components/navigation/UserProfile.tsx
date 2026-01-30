export default function UserProfile() {
  return (
    <div className="flex items-center space-x-2">
      <div className="h-8 w-8 rounded-full bg-gray-300"></div>
      <div className="hidden md:block">
        <div className="font-semibold">John Doe</div>
        <div className="text-sm text-gray-500">View Profile</div>
      </div>
    </div>
  );
}
