import React from 'react';

export default function PricingPage() {
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
      buttonText: 'Start Free',
      highlight: false,
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
      buttonText: 'Go Pro',
      highlight: true,
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
      buttonText: 'Get Premium',
      highlight: false,
    },
  ];

  return (
    <div className="py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <h1 className="text-4xl font-extrabold text-text-dark mb-6 text-center">Flexible Pricing Plans</h1>
      <p className="text-lg text-text-DEFAULT leading-relaxed text-center mb-12">
        Choose the plan that best fits your trading needs. Upgrade, downgrade, or cancel anytime.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {pricingPlans.map((plan) => (
          <div
            key={plan.name}
            className={"relative flex flex-col p-8 bg-white shadow-lg rounded-lg " + (plan.highlight ? 'border-2 border-primary-dark' : 'border border-neutral-200')}
          >
            {plan.highlight && (
              <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary-dark text-white text-xs font-semibold px-3 py-1 rounded-full uppercase tracking-wide">
                Most Popular
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
                plan.highlight
                  ? 'bg-primary-dark hover:bg-primary-light text-white'
                  : 'bg-neutral-100 text-primary-dark hover:bg-neutral-200'
              )}
            >
              {plan.buttonText}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
