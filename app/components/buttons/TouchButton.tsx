import React from 'react';

export function TouchButton({ children, className, ...props }: { children: React.ReactNode, className?: string } & React.ComponentPropsWithoutRef<'button'>) {
  return (
    <button
      {...props}
      className={`
        min-h-[44px]
        min-w-[44px]
        px-4 py-3
        rounded-lg
        transition-all
        active:scale-95
        select-none
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
      className="bg-[#00A65A] text-white font-bold text-lg flex items-center justify-center space-x-2"
    >
      <span>Pay with</span>
      <span className="text-xl">M-PESA</span>
      <span>• KES {amount.toLocaleString()}</span>
    </TouchButton>
  );
}
