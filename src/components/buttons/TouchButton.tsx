import React from 'react';

export function TouchButton({ children, className, ...props }: { children: React.ReactNode, className?: string } & React.ComponentPropsWithoutRef<'button'>) {
  return (
    <button
      {...props}
      className={`
        min-h-[44px]
        min-w-[44px]
        px-4 py-3
        bg-primary hover:bg-primary-dark text-white font-medium
        rounded-lg
        transition-all
        active:scale-95
        select-none
        focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-light
        ${className || ''}
      `}
    >
      {children}
    </button>
  );
}

export function MPesaButton({ amount, onClick }: { amount: number, onClick: () => void }) {
  return (
    <TouchButton
      onClick={onClick}
      className="bg-[#00A65A] hover:bg-[#008F4C] text-white font-bold text-lg flex items-center justify-center space-x-2 focus:ring-[#00A65A]"
    >
      <span>Pay with</span>
      <span className="text-xl">M-PESA</span>
      <span>• KES {amount.toLocaleString()}</span>
    </TouchButton>
  );
}
