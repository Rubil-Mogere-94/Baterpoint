'use client';

import { useState, useEffect } from 'react';

interface NavigatorWithConnection extends Navigator {
  connection?: {
    effectiveType?: '2g' | '3g' | '4g' | 'slow-2g' | '2g' | 'full-wifi';
    saveData?: boolean;
  };
}

export default function NetworkAwareImage({ src, alt, ...props }: { src: string, alt: string } & React.ComponentPropsWithoutRef<'img'>) {
  const [useLowQuality, setUseLowQuality] = useState(false);
  
  useEffect(() => {
    // Check if user is on slow network
    const checkNetwork = async () => {
      if ('connection' in navigator) {
        const connection = (navigator as NavigatorWithConnection).connection;
        if (connection?.effectiveType === '2g' || connection?.saveData === true) {
          setUseLowQuality(true);
        }
      }
      
      // Also check screen size - mobile might want lower quality
      if (typeof window !== 'undefined' && window.innerWidth <= 768) {
        setUseLowQuality(true);
      }
    };
    
    checkNetwork();
  }, []);
  
  // For Kenyan users with data limits
  const imageSrc = useLowQuality 
    ? `${src}?w=400&q=30`  // Lower quality, smaller size
    : `${src}?w=800&q=80`; // Higher quality
  
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={imageSrc}
      alt={alt}
      loading="lazy"  // Native lazy loading
      decoding="async"
      {...props}
    />
  );
}
