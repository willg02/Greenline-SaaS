<template>
  <div class="landing-page">
    <header class="hero">
      <div class="container">
        <nav class="hero-nav">
          <div class="brand">🌿 Greenline</div>
          <div class="nav-links">
            <router-link to="/login" class="btn btn-outline">Login</router-link>
            <router-link to="/signup" class="btn btn-primary">Get Started Free</router-link>
          </div>
        </nav>

        <div class="hero-content">
          <h1 class="hero-title">
            Complete Business Suite for<br />
            <span class="highlight">Landscaping Professionals</span>
          </h1>
          <p class="hero-description">
            Manage quotes, track clients, and access a curated plant database—all in one platform. 
            Built for landscapers, installers, and garden centers.
          </p>
          <div class="hero-cta">
            <router-link to="/signup" class="btn btn-primary btn-lg">
              Start Free Trial
            </router-link>
            <a href="#features" class="btn btn-secondary btn-lg">
              Learn More
            </a>
          </div>
          <p class="hero-note">✓ 14-day free trial · No credit card required</p>
        </div>
      </div>
    </header>

    <section id="features" class="features">
      <div class="container">
        <h2 class="section-title">Everything You Need to Run Your Business</h2>
        
        <div class="features-grid">
          <div class="feature-card card">
            <div class="feature-icon">🌿</div>
            <h3>Plant Compendium</h3>
            <p>Browse 30+ curated native and ornamental plants with detailed care information and supplier links.</p>
          </div>

          <div class="feature-card card">
            <div class="feature-icon">💰</div>
            <h3>Quote Estimator</h3>
            <p>Generate professional landscaping quotes with itemized pricing for site prep, materials, and labor.</p>
          </div>

          <div class="feature-card card">
            <div class="feature-icon">👥</div>
            <h3>Client Management</h3>
            <p>Keep track of all your clients, their project history, and contact information in one place.</p>
          </div>

          <div class="feature-card card">
            <div class="feature-icon">📐</div>
            <h3>Material Calculator</h3>
            <p>Quick cubic yard calculations for soil, mulch, and compost. Get instant cost estimates.</p>
          </div>

          <div class="feature-card card">
            <div class="feature-icon">👨‍👩‍👧‍👦</div>
            <h3>Team Collaboration</h3>
            <p>Invite team members and manage projects together with role-based permissions.</p>
          </div>

          <div class="feature-card card">
            <div class="feature-icon">☁️</div>
            <h3>Cloud Sync</h3>
            <p>Access your data from anywhere. All quotes, clients, and projects synced in real-time.</p>
          </div>
        </div>
      </div>
    </section>

    <section class="pricing">
      <div class="container">
        <h2 class="section-title">Simple, Transparent Pricing</h2>
        
        <div class="pricing-grid">
          <div class="pricing-card card">
            <div class="tier-badge">Solo</div>
            <div class="price">
              <span class="amount">$29</span>
              <span class="period">/month</span>
            </div>
            <ul class="features-list">
              <li>✓ Unlimited quotes</li>
              <li>✓ 50 clients</li>
              <li>✓ Plant database access</li>
              <li>✓ Material calculator</li>
              <li>✓ Email support</li>
            </ul>
            <router-link to="/signup" class="btn btn-outline" style="width: 100%;">
              Start Free Trial
            </router-link>
          </div>

          <div class="pricing-card card featured">
            <div class="tier-badge popular">Team</div>
            <div class="price">
              <span class="amount">$79</span>
              <span class="period">/month</span>
            </div>
            <ul class="features-list">
              <li>✓ Everything in Solo</li>
              <li>✓ Unlimited clients</li>
              <li>✓ Up to 5 team members</li>
              <li>✓ Custom plant library</li>
              <li>✓ Priority support</li>
              <li>✓ Advanced reporting</li>
            </ul>
            <router-link to="/signup" class="btn btn-primary" style="width: 100%;">
              Start Free Trial
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <footer class="footer">
      <div class="container">
        <div class="footer-content">
          <div class="footer-brand">
            <div class="brand">🌿 Greenline</div>
            <p>Professional plant business management</p>
          </div>
          <div class="footer-links">
            <div class="link-column">
              <h4>Product</h4>
              <a href="#features">Features</a>
              <a href="#pricing">Pricing</a>
              <router-link to="/signup">Sign Up</router-link>
            </div>
            <div class="link-column">
              <h4>Support</h4>
              <a href="https://github.com/willg02/plant-business-suite" target="_blank">Documentation</a>
              <a href="mailto:support@greenline.example">Contact</a>
            </div>
          </div>
        </div>
        <div class="footer-bottom">
          <p>© 2025 Greenline. Professional plant installation & design services.</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
// Landing page - no script logic needed for now
</script>

<style scoped>
.landing-page {
  background-color: var(--color-white);
}

.hero {
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-light) 100%);
  color: var(--color-white);
  padding: 2rem 0 6rem;
}

.hero-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0 3rem;
}

.brand {
  font-size: 1.5rem;
  font-weight: 700;
}

.nav-links {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.hero-content {
  text-align: center;
  max-width: 800px;
  margin: 0 auto;
}

.hero-title {
  font-size: 3.5rem;
  line-height: 1.1;
  margin-bottom: 1.5rem;
  color: var(--color-white);
}

.highlight {
  color: var(--color-accent-light);
}

.hero-description {
  font-size: 1.25rem;
  margin-bottom: 2rem;
  color: rgba(255, 255, 255, 0.9);
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.hero-cta {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-bottom: 1rem;
}

.hero-note {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.875rem;
  margin-bottom: 0;
}

.features {
  padding: 6rem 0;
  background-color: var(--bg-secondary);
}

.section-title {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.feature-card {
  text-align: center;
  transition: transform var(--transition-base);
}

.feature-card:hover {
  transform: translateY(-4px);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  color: var(--text-primary);
  margin-bottom: 0.5rem;
}

.feature-card p {
  color: var(--text-secondary);
  margin-bottom: 0;
}

.pricing {
  padding: 6rem 0;
}

.pricing-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
  max-width: 800px;
  margin: 0 auto;
}

.pricing-card {
  text-align: center;
  position: relative;
  transition: transform var(--transition-base);
}

.pricing-card:hover {
  transform: translateY(-4px);
}

.pricing-card.featured {
  border: 2px solid var(--color-primary);
  box-shadow: var(--shadow-xl);
}

.tier-badge {
  display: inline-block;
  padding: 0.5rem 1rem;
  background-color: var(--color-gray-200);
  color: var(--text-secondary);
  border-radius: var(--border-radius);
  font-weight: 600;
  text-transform: uppercase;
  font-size: 0.875rem;
  margin-bottom: 1rem;
}

.tier-badge.popular {
  background-color: var(--color-primary);
  color: var(--color-white);
}

.price {
  margin-bottom: 2rem;
}

.amount {
  font-size: 3rem;
  font-weight: 700;
  color: var(--text-primary);
}

.period {
  color: var(--text-secondary);
  font-size: 1.125rem;
}

.features-list {
  list-style: none;
  padding: 0;
  margin-bottom: 2rem;
  text-align: left;
}

.features-list li {
  padding: 0.5rem 0;
  color: var(--text-secondary);
}

.footer {
  background-color: var(--color-gray-900);
  color: var(--color-white);
  padding: 3rem 0 2rem;
}

.footer-content {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 3rem;
  margin-bottom: 2rem;
}

.footer-brand p {
  color: var(--color-gray-400);
  margin-top: 0.5rem;
}

.footer-links {
  display: flex;
  gap: 3rem;
}

.link-column h4 {
  color: var(--color-white);
  margin-bottom: 1rem;
  font-size: 1rem;
}

.link-column a {
  display: block;
  color: var(--color-gray-400);
  text-decoration: none;
  margin-bottom: 0.5rem;
  transition: color var(--transition-fast);
}

.link-column a:hover {
  color: var(--color-white);
}

.footer-bottom {
  border-top: 1px solid var(--color-gray-800);
  padding-top: 2rem;
  text-align: center;
}

.footer-bottom p {
  color: var(--color-gray-500);
  margin: 0;
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.5rem;
  }

  .hero-description {
    font-size: 1.125rem;
  }

  .hero-cta {
    flex-direction: column;
  }

  .features-grid {
    grid-template-columns: 1fr;
  }

  .pricing-grid {
    grid-template-columns: 1fr;
  }

  .footer-content {
    grid-template-columns: 1fr;
  }
}
</style>
