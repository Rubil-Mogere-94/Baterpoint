'use client';

import { useState } from 'react';

export default function CreateListingForm() {
  const [tradeType, setTradeType] = useState<'barter' | 'cash' | 'mixed'>('mixed');
  
  return (
    <div className="max-w-4xl mx-auto p-4">
      {/* Trade Type Selector - Different layout for mobile/desktop */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-4">Trade Type</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {(['barter', 'cash', 'mixed'] as const).map((type) => (
            <button
              key={type}
              type="button"
              className={`
                p-4 rounded-lg border-2 transition-all
                ${tradeType === type 
                  ? 'border-primary bg-green-50' 
                  : 'border-gray-300 hover:border-green-300'}
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
              <div className="text-sm text-gray-600 mt-1 text-center">
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
            <label className="block font-medium mb-2">Title</label>
            <input 
              type="text"
              className="w-full p-3 border rounded-lg"
              placeholder="e.g., Samsung Galaxy S21"
            />
          </div>
          
          {/* Price - Conditionally shown */}
          {tradeType !== 'barter' && (
            <div>
              <label className="block font-medium mb-2">
                Cash Price (KES)
              </label>
              <div className="relative">
                <span className="absolute left-3 top-3 text-gray-500">KES</span>
                <input 
                  type="number"
                  className="w-full pl-12 p-3 border rounded-lg"
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
              <label className="block font-medium mb-2">
                What do you want in exchange?
              </label>
              <textarea 
                className="w-full p-3 border rounded-lg h-32"
                placeholder="List listings you want to trade for..."
              />
            </div>
          )}
          
          {/* Category Selector */}
          <div>
            <label className="block font-medium mb-2">Category</label>
            <select className="w-full p-3 border rounded-lg">
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
      <div className="mt-8">
        <button
          type="submit"
          className="w-full md:w-auto md:px-12 bg-primary text-white py-4 rounded-lg font-semibold hover:bg-green-700 transition"
        >
          Create Listing
        </button>
      </div>
    </div>
  );
}
