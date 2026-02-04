'use client';

import { useState } from 'react';
import { TouchButton } from '../buttons/TouchButton';

export default function CreateListingForm() {
  const [tradeType, setTradeType] = useState<'barter' | 'cash' | 'mixed'>('mixed');
  
  const inputClassNames = "w-full p-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary placeholder-neutral-400 text-neutral-800";

  return (
    <div className="max-w-4xl mx-auto p-4 bg-white shadow-lg rounded-lg">
      <h2 className="text-2xl font-bold text-neutral-800 mb-6">Create New Listing</h2>
      
      {/* Trade Type Selector - Different layout for mobile/desktop */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold text-neutral-700 mb-4">Trade Type</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {(['barter', 'cash', 'mixed'] as const).map((type) => (
            <button
              key={type}
              type="button"
              className={`
                p-4 rounded-lg border-2 transition-all duration-200
                ${tradeType === type 
                  ? 'border-primary-dark bg-primary-light text-white shadow-md' 
                  : 'border-neutral-300 hover:border-primary-light bg-neutral-50 text-neutral-700 hover:text-primary-dark'}
                flex flex-col items-center justify-center
                h-24 sm:h-32
              `}
              onClick={() => setTradeType(type)}
            >
              <div className="text-2xl mb-2">
                {type === 'barter' && '🔄'}
                {type === 'cash' && '💰'}
                {type === 'mixed' && '🔀'}
              </div>
              <div className="font-semibold capitalize">{type}</div>
              <div className="text-sm mt-1 text-center">
                {type === 'barter' && 'Trade listings only'}
                {type === 'cash' && 'Sell for cash only'}
                {type === 'mixed' && 'Cash + listings'}
              </div>
            </button>
          ))}
        </div>
      </div>
      
      {/* Form Grid - Responsive layout */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Left Column */}
        <div className="space-y-6">
          {/* Title - Full width on mobile, half on desktop */}
          <div className="col-span-full md:col-span-1">
            <label className="block font-medium text-neutral-700 mb-2">Title</label>
            <input 
              type="text"
              className={inputClassNames}
              placeholder="e.g., Samsung Galaxy S21"
            />
          </div>
          
          {/* Price - Conditionally shown */}
          {tradeType !== 'barter' && (
            <div>
              <label className="block font-medium text-neutral-700 mb-2">
                Cash Price (KES)
              </label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-500">KES</span>
                <input 
                  type="number"
                  className={"pl-12 " + inputClassNames}
                  placeholder="5000"
                />
              </div>
            </div>
          )}
        </div>
        
        {/* Right Column */}
        <div className="space-y-6">
          {/* Wanted Items - Conditionally shown */}
          {tradeType !== 'cash' && (
            <div>
              <label className="block font-medium text-neutral-700 mb-2">
                What do you want in exchange?
              </label>
              <textarea 
                className={"h-32 " + inputClassNames}
                placeholder="List listings you want to trade for..."
              />
            </div>
          )}
          
          {/* Category Selector */}
          <div>
            <label className="block font-medium text-neutral-700 mb-2">Category</label>
            <select className={inputClassNames}>
              <option value="">Select category</option>
              <option value="electronics">Electronics</option>
              <option value="phones">Phones & Tablets</option>
              <option value="agriculture">Agriculture</option>
              <option value="services">Services</option>
            </select>
          </div>
        </div>
      </div>
      
      {/* Submit Button - Full width on mobile, auto on desktop */}
      <div className="mt-8 text-right">
        <TouchButton
          type="submit"
          className="w-full md:w-auto"
        >
          Create Listing
        </TouchButton>
      </div>
    </div>
  );
}
