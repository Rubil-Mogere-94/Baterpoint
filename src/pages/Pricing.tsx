import React, { useState } from 'react';
import { notification } from 'antd'; // Import Ant Design notification

export default function PricingPage() {
  const [api, contextHolder] = notification.useNotification(); // Ant Design notification hook

  // In a real application, currentUserPlan would likely come from an authenticated user's context or API fetch.
  // For demonstration, we'll use local state.
  const [currentUserPlan, setCurrentUserPlan] = useState('Basic'); // e.g., 'Basic', 'Pro', 'Premium'

  const pricingPlans = [
    {
      name: 'Basic',
      price: 'Free',
      features: [
        'Up to 5 active listings',
        'Standard search filters',
        'Direct messaging with traders',
        'Email support'
      ],
      buttonText: 'Current Plan', // Default, will be overridden
      highlight: false,
      isCurrent: false,
    },
    {
      name: 'Pro',
      price: 'KES 999/month',
      features: [
        'Unlimited active listings',
        'Advanced search filters',
        'Priority direct messaging',
        '24/7 Chat & Email support',
        'Featured listing opportunities'
      ],
      buttonText: 'Go Pro', // Default, will be overridden
      highlight: true,
      isCurrent: false,
    },
    {
      name: 'Premium',
      price: 'KES 2499/month',
      features: [
        'All Pro features',
        'Dedicated account manager',
        'Premium analytics & insights',
        'Early access to new features',
        'Branded profile'
      ],
      buttonText: 'Get Premium', // Default, will be overridden
      highlight: false,
      isCurrent: false,
    },
  ].map(plan => ({
    ...plan,
    isCurrent: plan.name === currentUserPlan,
    buttonText: plan.name === currentUserPlan 
      ? 'Current Plan' 
      : (
          (currentUserPlan === 'Basic' && (plan.name === 'Pro' || plan.name === 'Premium')) ||
          (currentUserPlan === 'Pro' && plan.name === 'Premium')
        )
        ? 'Upgrade'
        : 'Downgrade', // Assuming downgrading from Pro to Basic or Premium to Pro/Basic
  }));

  const handlePlanChange = (planName: string) => {
    // In a real application, this would trigger an API call to update the subscription
    console.log(`Attempting to change plan to: ${planName}`);
    setCurrentUserPlan(planName); // Simulate plan change
    api.success({
      message: 'Plan Changed',
      description: `Your plan has been successfully changed to ${planName} (simulated).`,
      placement: 'topRight',
    });
  };

  const handleCancelSubscription = () => {
    api.info({
      message: 'Cancellation Flow Initiated',
      description: 'You are now entering the simulated cancellation flow.',
      placement: 'topRight',
    });
    // In a real application, this would redirect to a cancellation page or open a modal
  };

  return (
    <div className="py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {contextHolder} {/* Ant Design notification context holder */}
      <h1 className="text-4xl font-extrabold text-text-dark mb-6 text-center">Flexible Pricing Plans</h1>
      <p className="text-lg text-text-DEFAULT leading-relaxed text-center mb-12">
        Choose the plan that best fits your trading needs. Upgrade, downgrade, or cancel anytime.
      </p>

      {/* Current Subscription Status Display */}
      <div className="bg-gradient-to-r from-primary-light to-primary-dark text-white p-6 rounded-lg shadow-xl mb-12 text-center">
        <h2 className="text-2xl font-bold mb-2">Your Current Plan: <span className="underline">{currentUserPlan}</span></h2>
        <p className="text-lg">
          Status: Active | Renews: {currentUserPlan === 'Basic' ? 'N/A' : 'March 8, 2027'} (Example)
        </p>
        <button 
          onClick={handleCancelSubscription}
          className="mt-4 px-6 py-2 bg-white text-primary-dark font-semibold rounded-lg hover:bg-neutral-100 transition-colors duration-200"
        >
          Manage / Cancel Subscription
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {pricingPlans.map((plan) => (
          <div
            key={plan.name}
            className={"relative flex flex-col p-8 bg-white shadow-lg rounded-lg " + (plan.isCurrent ? 'border-4 border-primary' : (plan.highlight ? 'border-2 border-primary-dark' : 'border border-neutral-200'))}
          >
            {plan.highlight && !plan.isCurrent && (
              <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary-dark text-white text-xs font-semibold px-3 py-1 rounded-full uppercase tracking-wide">
                Most Popular
              </div>
            )}
            {plan.isCurrent && (
              <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary text-white text-xs font-semibold px-3 py-1 rounded-full uppercase tracking-wide">
                Your Plan
              </div>
            )}
            <h2 className="text-3xl font-bold text-text-dark text-center mb-4">
              {plan.name}
            </h2>
            <p className="text-5xl font-extrabold text-text-dark text-center mb-6">
              {plan.price}
            </p>
            <ul className="flex-grow space-y-3 mb-8">
              {plan.features.map((feature, index) => (
                <li key={index} className="flex items-start text-text-DEFAULT">
                  <svg className="h-6 w-6 text-secondary mr-2 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span>{feature}</span>
                </li>
              ))}
            </ul>
            <button
              className={"w-full py-3 rounded-lg font-semibold transition-colors duration-200 " + (
                plan.isCurrent
                  ? 'bg-neutral-300 text-neutral-600 cursor-not-allowed'
                  : (plan.highlight
                      ? 'bg-primary-dark hover:bg-primary text-white'
                      : 'bg-neutral-100 text-primary-dark hover:bg-neutral-200')
              )}
              disabled={plan.isCurrent}
              onClick={() => handlePlanChange(plan.name)}
            >
              {plan.buttonText}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

