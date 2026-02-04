import Navigation from "@/components/Navigation";

export default function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-neutral-50 font-sans text-text-DEFAULT antialiased">
      <Navigation />
      <main className="mx-auto px-4 sm:px-6 lg:px-8 max-w-7xl flex-grow">
        {children}
      </main>
    </div>
  );
}
