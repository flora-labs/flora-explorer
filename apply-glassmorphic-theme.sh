#!/bin/bash

echo "=== APPLYING GLASSMORPHIC ICE THEME TO FLORA EXPLORER ==="
echo

# Backup the original index.vue
echo "1. Backing up original dashboard..."
cp src/modules/[chain]/index.vue src/modules/[chain]/index-original.vue

# Copy the glassmorphic version
echo "2. Applying glassmorphic theme..."
cp src/modules/[chain]/index-glassmorphic.vue src/modules/[chain]/index.vue

# Update the main style.css to include ice theme
echo "3. Adding glassmorphic CSS to main styles..."
cat >> src/style.css << 'EOF'

/* Flora Ice - Glassmorphic Theme */
:root {
  /* Ice-inspired color palette */
  --ice-primary: #e3f2fd;
  --ice-secondary: #bbdefb;
  --ice-accent: #64b5f6;
  --ice-deep: #1976d2;
  --frost-white: rgba(255, 255, 255, 0.95);
  --glacier-blue: #e1f5fe;
  --arctic-cyan: #00e5ff;
  --crystal-purple: #7c4dff;
  
  /* Glassmorphic properties */
  --glass-bg: rgba(255, 255, 255, 0.05);
  --glass-border: rgba(255, 255, 255, 0.18);
  --glass-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
  --glass-blur: blur(12px);
  
  /* Dark mode adjustments */
  --dark-bg: #0a0f1c;
  --dark-surface: rgba(13, 27, 42, 0.7);
  --dark-glass: rgba(255, 255, 255, 0.03);
}

/* Glassmorphic card mixin */
.glass-card {
  background: var(--glass-bg);
  backdrop-filter: var(--glass-blur);
  -webkit-backdrop-filter: var(--glass-blur);
  border-radius: 20px;
  border: 1px solid var(--glass-border);
  box-shadow: var(--glass-shadow);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.glass-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 40px 0 rgba(31, 38, 135, 0.45);
  border-color: rgba(255, 255, 255, 0.3);
}

/* Ice crystal background pattern */
.ice-background {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: -1;
  background: 
    radial-gradient(ellipse at top left, rgba(100, 181, 246, 0.1) 0%, transparent 50%),
    radial-gradient(ellipse at bottom right, rgba(124, 77, 255, 0.1) 0%, transparent 50%),
    linear-gradient(135deg, #0a0f1c 0%, #162447 100%);
}

.ice-background::before {
  content: '';
  position: absolute;
  width: 100%;
  height: 100%;
  background-image: 
    radial-gradient(circle at 20% 50%, rgba(0, 229, 255, 0.1) 0%, transparent 50%),
    radial-gradient(circle at 80% 80%, rgba(100, 181, 246, 0.08) 0%, transparent 50%),
    radial-gradient(circle at 40% 20%, rgba(255, 255, 255, 0.05) 0%, transparent 50%);
  animation: float 20s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  33% { transform: translateY(-10px) rotate(1deg); }
  66% { transform: translateY(5px) rotate(-1deg); }
}

/* Statistic cards with ice effect */
.stat-card {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.02) 100%);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 24px;
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.stat-card::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.1) 0%, transparent 70%);
  transform: rotate(45deg);
  transition: all 0.5s ease;
  opacity: 0;
}

.stat-card:hover::before {
  opacity: 1;
  transform: rotate(45deg) translateY(-20px);
}

.stat-card-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--ice-accent) 0%, var(--crystal-purple) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  box-shadow: 0 4px 20px rgba(100, 181, 246, 0.3);
}

.stat-card-value {
  font-size: 32px;
  font-weight: 700;
  background: linear-gradient(135deg, #ffffff 0%, var(--ice-secondary) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 8px;
}

.stat-card-label {
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

/* Frosted glass buttons */
.glass-button {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  padding: 12px 32px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  color: white;
  cursor: pointer;
}

.glass-button::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
  transition: left 0.5s ease;
}

.glass-button:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(100, 181, 246, 0.3);
}

.glass-button:hover::before {
  left: 100%;
}

/* Primary action buttons with gradient */
.btn-swap {
  background: linear-gradient(135deg, #7c4dff 0%, #536dfe 100%);
  border: none;
}

.btn-send {
  background: linear-gradient(135deg, #00e5ff 0%, #00acc1 100%);
  border: none;
}

.btn-delegate {
  background: linear-gradient(135deg, #64b5f6 0%, #1976d2 100%);
  border: none;
}

/* Wallet section glassmorphism */
.wallet-section {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.01) 100%);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  padding: 32px;
  position: relative;
}

.wallet-balance-item {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  padding: 20px;
  transition: all 0.3s ease;
}

.wallet-balance-item:hover {
  background: rgba(255, 255, 255, 0.05);
  border-color: rgba(255, 255, 255, 0.1);
}
EOF

echo "4. Updating tailwind classes for dark theme..."
# Update base body background
sed -i.bak 's/bg-base-100/bg-[#0a0f1c]/g' src/App.vue

echo
echo "✅ GLASSMORPHIC ICE THEME APPLIED!"
echo
echo "Next steps:"
echo "1. Restart the development server: npm run dev"
echo "2. Visit http://localhost:5173/flora-testnet"
echo "3. Enjoy the new ice-crystal glassmorphic design!"
echo
echo "To revert:"
echo "cp src/modules/[chain]/index-original.vue src/modules/[chain]/index.vue"