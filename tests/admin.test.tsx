import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter as Router, Routes, Route, useNavigate, Outlet } from 'react-router-dom'; // Keep Router for Navigation tests
import Navigation from '../src/components/Navigation';
import AdminDashboard from '../src/pages/AdminDashboard';
import { useAuth } from '../src/firebase'; // Mock this import
import App from '../src/App';
import AdminRoute from '../src/components/AdminRoute'; // Import AdminRoute for direct testing

// Explicitly mock firebase for this test file
jest.mock('../src/firebase', () => ({
  useAuth: jest.fn(),
  auth: {},
  app: {},
  analytics: {},
  initializeApp: jest.fn(),
  getAnalytics: jest.fn(),
  getAuth: jest.fn(),
  sendPasswordResetEmail: jest.fn(),
}));

// Mock react-router-dom to control useNavigate for App component tests
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}));

// Mock the Layout component as it's a wrapper
jest.mock('../src/Layout', () => ({ children }: { children: React.ReactNode }) => (
  <div data-testid="layout">{children}</div>
));

// Mock the LoginPage to avoid rendering the actual login page component
jest.mock('../src/pages/LoginPage', () => () => <div data-testid="login-page-mock">Login Page Placeholder or similar</div>);

// Mock AdminDashboard when testing redirects through AdminRoute to prevent actual rendering
jest.mock('../src/pages/AdminDashboard', () => () => <div data-testid="admin-dashboard-mock">Admin Dashboard</div>);

describe('Admin Functionality Frontend Tests', () => {
  let mockNavigate: jest.Mock;

  beforeEach(() => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: null,
      userToken: null,
      loading: false,
    });
    // Mock useNavigate for App component
    mockNavigate = jest.fn();
    (useNavigate as jest.Mock<any, any>).mockReturnValue(mockNavigate);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // Test Admin Dashboard link visibility in Navigation
  test('Admin Dashboard link is visible to admin users in navigation', () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: { role: 'admin' },
      userToken: 'fake-admin-token',
      loading: false,
    });
    render(
      <Router> {/* Use BrowserRouter for simple component rendering */}
        <Navigation />
      </Router>
    );
    expect(screen.getAllByText('Admin Dashboard').length).toBeGreaterThan(0);
  });

  test('Admin Dashboard link is not visible to non-admin users in navigation', () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: { role: 'user' },
      userToken: 'fake-user-token',
      loading: false,
    });
    render(
      <Router>
        <Navigation />
      </Router>
    );
    expect(screen.queryByText('Admin Dashboard')).not.toBeInTheDocument();
  });

  test('Admin Dashboard link is not visible to unauthenticated users in navigation', () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: null,
      userToken: null,
      loading: false,
    });
    render(
      <Router>
        <Navigation />
      </Router>
    );
    expect(screen.queryByText('Admin Dashboard')).not.toBeInTheDocument();
  });

  // Test AdminRoute behavior directly for accessibility
  test('AdminRoute renders AdminDashboard for admin users', async () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: { id: 1, email: 'admin@example.com', username: 'admin', role: 'admin', subscription_status: 'premium' },
      userToken: 'fake-admin-token',
      loading: false,
    });
    // Mock fetch for AdminDashboard content
    jest.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve([
        { id: 1, username: 'admin', email: 'admin@example.com', role: 'admin', subscription_status: 'premium' },
      ]),
    } as Response);

    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route path="/admin" element={<AdminRoute />} >
            <Route index element={<AdminDashboard />} />
          </Route>
          <Route path="/login" element={<div data-testid="login-page-mock">Login Page Placeholder or similar</div>} />
        </Routes>
      </MemoryRouter>
    );
    
    // AdminRoute should render the Outlet (AdminDashboard)
    expect(await screen.findByTestId('admin-dashboard-mock')).toBeInTheDocument();
  });

  test('AdminRoute redirects non-admin users to login', async () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: { role: 'user' },
      userToken: 'fake-user-token',
      loading: false,
    });
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route path="/admin" element={<AdminRoute />} >
            <Route index element={<AdminDashboard />} />
          </Route>
          <Route path="/login" element={<div data-testid="login-page-mock">Login Page Placeholder or similar</div>} />
        </Routes>
      </MemoryRouter>
    );
    await waitFor(() => {
      // AdminRoute should navigate to /login
      expect(screen.getByText('Login Page Placeholder or similar')).toBeInTheDocument();
    });
  });

  test('AdminRoute redirects unauthenticated users to login', async () => {
    (useAuth as jest.Mock<any, any>).mockReturnValue({
      currentUser: null,
      userToken: null,
      loading: false,
    });
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route path="/admin" element={<AdminRoute />} >
            <Route index element={<AdminDashboard />} />
          </Route>
          <Route path="/login" element={<div data-testid="login-page-mock">Login Page Placeholder or similar</div>} />
        </Routes>
      </MemoryRouter>
    );
    await waitFor(() => {
      // AdminRoute should navigate to /login
      expect(screen.getByText('Login Page Placeholder or similar')).toBeInTheDocument();
    });
  });
});