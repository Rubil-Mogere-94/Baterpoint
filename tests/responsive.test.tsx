import { render, screen } from '@testing-library/react';
import Navigation from '../app/components/Navigation.js'; // Adjust path if necessary

describe('Responsive Design', () => {
  let originalInnerWidth: number;

  beforeAll(() => {
    originalInnerWidth = window.innerWidth;
  });

  afterEach(() => {
    // Restore original window.innerWidth after each test
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: originalInnerWidth,
    });
  });

  test('Shows mobile menu button on small screens', () => {
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 375, // iPhone width
    });
    
    render(<Navigation />);
    expect(screen.getByLabelText('Menu')).toBeInTheDocument();
  });
  
  test('Shows desktop navigation on large screens', () => {
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 1200,
    });
    
    render(<Navigation />);
    // Assuming "Browse Listings" is a unique text for desktop navigation
    expect(screen.getByText('Browse Listings')).toBeInTheDocument();
  });
});
