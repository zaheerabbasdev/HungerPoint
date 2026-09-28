import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router';
import '@fontsource-variable/geist';
import '@fontsource-variable/geist-mono';
import './index.css';
import App from './App';
import { AuthProvider } from './context/AuthContext';
import { BranchProvider } from './context/BranchContext';
import { CartProvider } from './context/CartContext';

// BASE_URL comes from Vite's `base` (see vite.config.ts), so routes keep
// working when the app is hosted in a subfolder such as /hungerpoint/.
const basename = import.meta.env.BASE_URL.replace(/\/$/, '') || '/';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter basename={basename}>
      <AuthProvider>
        <BranchProvider>
          <CartProvider>
            <App />
          </CartProvider>
        </BranchProvider>
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
);
