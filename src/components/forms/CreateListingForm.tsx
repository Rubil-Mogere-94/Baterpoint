'use client';

import { useState } from 'react';
import { TouchButton } from '../buttons/TouchButton';
import { notification } from 'antd'; // Import Ant Design notification

interface FormErrors {
  title?: string;
  price?: string;
  category?: string;
  image?: string;
  general?: string;
}

export default function CreateListingForm() {
  const [tradeType, setTradeType] = useState<'barter' | 'cash' | 'mixed'>('mixed');
  const [title, setTitle] = useState('');
  const [price, setPrice] = useState<number | ''>('');
  const [wantedItems, setWantedItems] = useState('');
  const [category, setCategory] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);

  const [errors, setErrors] = useState<FormErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [api, contextHolder] = notification.useNotification(); // Ant Design notification hook

  const inputClassNames = "w-full p-3 border border-neutral-200 rounded-lg focus:ring-2 focus:ring-primary-dark focus:border-primary-dark placeholder-neutral-400 text-neutral-800 transition-all duration-200";

  const validate = (): FormErrors => {
    const newErrors: FormErrors = {};
    if (!title) newErrors.title = 'Title is required.';
    if (!category) newErrors.category = 'Category is required.';
    if (tradeType !== 'barter' && (!price || price <= 0)) {
      newErrors.price = 'A valid price is required for this trade type.';
    }
    if (!imageFile) newErrors.image = 'An image is required.';

    return newErrors;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});
    setIsSubmitting(true);

    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      setIsSubmitting(false);
      return;
    }

    const formData = new FormData();
    formData.append('title', title);
    formData.append('category', category);
    formData.append('tradeType', tradeType);
    if (tradeType !== 'barter' && price) {
      formData.append('cashPrice', price.toString());
    }
    if (tradeType !== 'cash') {
      formData.append('exchange', wantedItems);
    }
    if (imageFile) {
      formData.append('image', imageFile);
    }
    formData.append('description', ''); 

    const token = localStorage.getItem('access_token');
    const headers: HeadersInit = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const response = await fetch('http://localhost:8000/listings/', {
        method: 'POST',
        headers: headers,
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to create listing');
      }

      await response.json();
      
      api.success({
        message: 'Listing Created',
        description: 'Your new listing has been created successfully!',
        placement: 'topRight',
      });
      // Reset form on success
      setTitle('');
      setPrice('');
      setWantedItems('');
      setCategory('');
      setImageFile(null);
      setTradeType('mixed');

    } catch (error: any) {
      api.error({
        message: 'Error Creating Listing',
        description: error.message || 'An unexpected error occurred.',
        placement: 'topRight',
      });
      setErrors({ general: error.message || 'An unexpected error occurred.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-4 bg-white shadow-xl rounded-lg border border-neutral-100">
      {contextHolder} {/* Ant Design notification context holder */}
      <h2 className="text-2xl font-bold text-neutral-800 mb-6">Create New Listing</h2>
      
      <form onSubmit={handleSubmit} noValidate>
        {/* General Error Message */}
        {errors.general && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
            <strong className="font-bold">Error: </strong>
            <span className="block sm:inline">{errors.general}</span>
          </div>
        )}

        {/* Trade Type Selector */}
        <div className="mb-8">
          <h3 className="text-lg font-semibold text-neutral-700 mb-4">Trade Type</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            {(['barter', 'cash', 'mixed'] as const).map((type) => (
              <button
                key={type}
                type="button"
                className={`p-4 rounded-lg border-2 transition-all duration-200 ${tradeType === type ? 'border-primary-dark bg-primary text-white shadow-lg' : 'border-neutral-200 hover:border-primary hover:bg-primary-50 hover:text-primary-dark'} flex flex-col items-center justify-center h-24 sm:h-32`}
                onClick={() => setTradeType(type)}
              >
                <div className="text-2xl mb-2">{type === 'barter' ? '🔄' : type === 'cash' ? '💰' : '🔀'}</div>
                <div className="font-semibold capitalize">{type}</div>
                <div className="text-sm mt-1 text-center">
                  {type === 'barter' ? 'Trade listings only' : type === 'cash' ? 'Sell for cash only' : 'Cash + listings'}
                </div>
              </button>
            ))}
          </div>
        </div>
        
        {/* Form Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Left Column */}
          <div className="space-y-6">
            <div>
              <label htmlFor="title" className="block font-medium text-neutral-700 mb-2">Title</label>
              <input type="text" id="title" className={inputClassNames} placeholder="e.g., Samsung Galaxy S21" value={title} onChange={(e) => setTitle(e.target.value)} required />
              {errors.title && <p className="text-red-500 text-sm mt-1">{errors.title}</p>}
            </div>
            
            {tradeType !== 'barter' && (
              <div>
                <label htmlFor="price" className="block font-medium text-neutral-700 mb-2">Cash Price (KES)</label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-500">KES</span>
                  <input type="number" id="price" className={"pl-12 " + inputClassNames} placeholder="5000" value={price} onChange={(e) => setPrice(Number(e.target.value))} />
                </div>
                {errors.price && <p className="text-red-500 text-sm mt-1">{errors.price}</p>}
              </div>
            )}

            <div>
              <label htmlFor="image" className="block font-medium text-neutral-700 mb-2">Image</label>
              <input type="file" id="image" accept="image/png, image/jpeg, image/webp" className={`${inputClassNames} p-0 file:mr-4 file:py-3 file:px-4 file:rounded-l-lg file:border-0 file:bg-neutral-100 file:text-neutral-700 hover:file:bg-neutral-200`} onChange={(e) => setImageFile(e.target.files ? e.target.files[0] : null)} required />
              {errors.image && <p className="text-red-500 text-sm mt-1">{errors.image}</p>}
            </div>
          </div>
          
          {/* Right Column */}
          <div className="space-y-6">
            {tradeType !== 'cash' && (
              <div>
                <label htmlFor="wantedItems" className="block font-medium text-neutral-700 mb-2">What do you want in exchange?</label>
                <textarea id="wantedItems" className={"h-32 " + inputClassNames} placeholder="List listings you want to trade for..." value={wantedItems} onChange={(e) => setWantedItems(e.target.value)} />
              </div>
            )}
            
            <div>
              <label htmlFor="category" className="block font-medium text-neutral-700 mb-2">Category</label>
              <select id="category" className={inputClassNames} value={category} onChange={(e) => setCategory(e.target.value)} required>
                <option value="">Select category</option>
                <option value="electronics">Electronics</option>
                <option value="phones">Phones & Tablets</option>
                <option value="agriculture">Agriculture</option>
                <option value="services">Services</option>
              </select>
              {errors.category && <p className="text-red-500 text-sm mt-1">{errors.category}</p>}
            </div>
          </div>
        </div>
        
        {/* Submit Button */}
        <div className="mt-8 text-right">
          <TouchButton type="submit" className="w-full md:w-auto bg-primary-dark hover:bg-primary-dark-dark text-white font-bold py-2 px-6 rounded-lg transition-colors duration-200 disabled:bg-neutral-400" disabled={isSubmitting}>
            {isSubmitting ? (
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : 'Create Listing'}
          </TouchButton>
        </div>
      </form>
    </div>
  );
}