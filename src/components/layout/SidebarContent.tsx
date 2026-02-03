export default function SidebarContent() {
  return (
    <div className="p-4">
      <h2 className="text-xl font-semibold mb-4">Sidebar Menu</h2>
      <ul>
        <li className="mb-2"><a href="#" className="text-gray-700 hover:text-primary">Dashboard</a></li>
        <li className="mb-2"><a href="#" className="text-gray-700 hover:text-primary">My Listings</a></li>
        <li className="mb-2"><a href="#" className="text-gray-700 hover:text-primary">Messages</a></li>
        <li className="mb-2"><a href="#" className="text-gray-700 hover:text-primary">Settings</a></li>
      </ul>
    </div>
  );
}
