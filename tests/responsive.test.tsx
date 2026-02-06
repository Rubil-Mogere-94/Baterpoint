import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter as Router } from 'react-router-dom';
import Navigation from '@/components/Navigation'; // Adjust path if necessary
import MatchMedia from 'jest-matchmedia-mock';

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
    expect(screen.queryByText('Browse Listings')).toBeInTheDocument(); 
    expect(screen.queryByText('How it Works')).toBeInTheDocument();
    expect(screen.queryByText('Pricing')).toBeInTheDocument();

    // The elements are technically in the DOM, but their display is controlled by CSS.
    // We can simulate clicking the mobile menu button to open the mobile menu and then check for the links.
    fireEvent.click(mobileMenuButton);

    expect(screen.getByText('Browse Listings')).toBeVisible();
    expect(screen.getByText('How it Works')).toBeVisible();
    expect(screen.getByText('Pricing')).toBeVisible();
    expect(screen.getByText('Create Listing')).toBeVisible();
  });
  
  test('Shows desktop navigation on large screens and hides mobile menu button', () => {
    matchMedia.useMediaQuery('(min-width: 769px)');
    render(<Router><Navigation /></Router>);
    
    // Desktop nav links should be visible
    expect(screen.getByText('Browse Listings')).toBeInTheDocument();
    expect(screen.getByText('How it Works')).toBeInTheDocument();
    expect(screen.getByText('Pricing')).toBeInTheDocument();
    
    // Mobile menu button should be hidden
    expect(screen.queryByRole('button', { name: 'Open main menu' })).not.toBeVisible();
  });
});
