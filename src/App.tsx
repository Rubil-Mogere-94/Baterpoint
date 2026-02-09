import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Layout from './Layout';
import Home from './pages/Home';
import Browse from './pages/Browse';
import HowItWorks from './pages/HowItWorks';
import Pricing from './pages/Pricing';
import ListingDetails from './pages/ListingDetails';
import UserProfile from './pages/UserProfile';
import Trade from './pages/Trade';
import CreateListing from './pages/CreateListing';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import PrivateRoute from './components/PrivateRoute';
import AdminRoute from './components/AdminRoute';
import AdminDashboard from './pages/AdminDashboard';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route element={<PrivateRoute />}>
          <Route
            path="/*"
            element={
              <Layout>
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/browse" element={<Browse />} />
                  <Route path="/how-it-works" element={<HowItWorks />} />
                  <Route path="/pricing" element={<Pricing />} />
                  <Route path="/listing/:id" element={<ListingDetails />} />
                  <Route path="/profile" element={<UserProfile />} />
                  <Route path="/trade/:id" element={<Trade />} />
                  <Route path="/create-listing" element={<CreateListing />} />
                </Routes>
              </Layout>
            }
          />
        </Route>
        <Route element={<AdminRoute />}>
          <Route path="/admin" element={<Layout><AdminDashboard /></Layout>} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
