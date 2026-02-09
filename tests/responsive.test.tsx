import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter as Router } from 'react-router-dom';
import Navigation from '@/components/Navigation'; // Adjust path if necessary
import MatchMedia from 'jest-matchmedia-mock';

// Explicitly mock firebase for this test file
jest.mock('../src/firebase', () => ({
  useAuth: jest.fn(() => ({
    currentUser: null,
    userToken: null,
    loading: false,
  })),
  auth: {},
  app: {},
  analytics: {},
  initializeApp: jest.fn(),
  getAnalytics: jest.fn(),
  getAuth: jest.fn(),
  sendPasswordResetEmail: jest.fn(),
}));



let matchMedia: any;

describe('Responsive Design', () => {
  beforeAll(() => {
    matchMedia = new MatchMedia();
  });

  afterEach(() => {
    matchMedia.clear();
  });

  test('Shows mobile menu button on small screens and hides desktop nav links', () => {
    matchMedia.useMediaQuery('(max-width: 768px)');
    render(<Router><Navigation /></Router>);
    
    // Mobile menu button should be visible
    const mobileMenuButton = screen.getByRole('button', { name: 'Open main menu' });
    expect(mobileMenuButton).toBeInTheDocument();
    
    // Desktop nav links should be hidden (not in the document flow)
    expect(screen.queryAllByText('Browse Listings').length).toBeGreaterThanOrEqual(1); 
    expect(screen.queryAllByText('How it Works').length).toBeGreaterThanOrEqual(1);
    expect(screen.queryAllByText('Pricing').length).toBeGreaterThanOrEqual(1);

    // The elements are technically in the DOM, but their display is controlled by CSS.
    // We can simulate clicking the mobile menu button to open the mobile menu and then check for the links.
    fireEvent.click(mobileMenuButton);

    expect(screen.getAllByText('Browse Listings')[0]).toBeVisible();
    expect(screen.getAllByText('How it Works')[0]).toBeVisible();
    expect(screen.getAllByText('Pricing')[0]).toBeVisible();
    expect(screen.getAllByText('Create Listing')[0]).toBeVisible();
  });
  
  test('Shows desktop navigation on large screens and hides mobile menu button', () => {
    matchMedia.useMediaQuery('(min-width: 769px)');
    render(<Router><Navigation /></Router>);
    
    // Desktop nav links should be visible
    expect(screen.getAllByText('Browse Listings')[0]).toBeInTheDocument();
    expect(screen.getAllByText('How it Works')[0]).toBeInTheDocument();
    expect(screen.getAllByText('Pricing')[0]).toBeInTheDocument();
    
    // Mobile menu button should be hidden
    expect(screen.queryByRole('button', { name: 'Open main menu' })).not.toBeVisible();
  });
});
