export default function HowItWorksPage() {
  return (
    <div className="py-12 px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto">
      <h1 className="text-4xl font-extrabold text-text-dark mb-6 text-center">How It Works</h1>
      <p className="text-lg text-text-DEFAULT leading-relaxed text-center mb-8">
        Welcome to BarterPoint, the seamless platform for exchanging goods and services! Here's a quick guide on how to get started and make the most of your bartering experience.
      </p>

      <div className="space-y-10">
        <div className="flex flex-col md:flex-row items-center bg-white shadow-lg rounded-lg p-6">
          <div className="md:w-1/3 flex justify-center mb-4 md:mb-0">
            <div className="flex items-center justify-center h-20 w-20 rounded-full bg-primary-light text-white text-3xl font-bold">1</div>
          </div>
          <div className="md:w-2/3 md:pl-8 text-center md:text-left">
            <h2 className="text-2xl font-bold text-text-dark mb-2">Create Your Listing</h2>
            <p className="text-text-DEFAULT">
              Start by posting what you have to offer. Describe your item or service in detail, add clear photos, and specify if you're looking for a direct barter, cash, or a mixed deal. The more information, the better!
            </p>
          </div>
        </div>

        <div className="flex flex-col md:flex-row items-center bg-white shadow-lg rounded-lg p-6">
          <div className="md:w-1/3 flex justify-center mb-4 md:mb-0">
            <div className="flex items-center justify-center h-20 w-20 rounded-full bg-secondary text-white text-3xl font-bold">2</div>
          </div>
          <div className="md:w-2/3 md:pl-8 text-center md:text-left">
            <h2 className="text-2xl font-bold text-text-dark mb-2">Browse & Discover</h2>
            <p className="text-text-DEFAULT">
              Explore a wide variety of listings from other users. Use our intuitive search and filter options to find exactly what you need, whether it's an item, a service, or a unique bartering opportunity.
            </p>
          </div>
        </div>

        <div className="flex flex-col md:flex-row items-center bg-white shadow-lg rounded-lg p-6">
          <div className="md:w-1/3 flex justify-center mb-4 md:mb-0">
            <div className="flex items-center justify-center h-20 w-20 rounded-full bg-accent text-white text-3xl font-bold">3</div>
          </div>
          <div className="md:w-2/3 md:pl-8 text-center md:text-left">
            <h2 className="text-2xl font-bold text-text-dark mb-2">Propose a Trade</h2>
            <p className="text-text-DEFAULT">
              Found something you like? Send a trade proposal! You can suggest an item you have, offer cash, or a combination of both. Communicate directly with other users to negotiate the best deal.
            </p>
          </div>
        </div>

        <div className="flex flex-col md:flex-row items-center bg-white shadow-lg rounded-lg p-6">
          <div className="md:w-1/3 flex justify-center mb-4 md:mb-0">
            <div className="flex items-center justify-center h-20 w-20 rounded-full bg-primary text-white text-3xl font-bold">4</div>
          </div>
          <div className="md:w-2/3 md:pl-8 text-center md:text-left">
            <h2 className="text-2xl font-bold text-text-dark mb-2">Complete Your Exchange</h2>
            <p className="text-text-DEFAULT">
              Once you agree on a trade, arrange for the exchange of goods or services. Enjoy the benefits of bartering and the vibrant community at BarterPoint!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
