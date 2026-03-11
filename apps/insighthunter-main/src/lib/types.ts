export interface User {
    id: string;
    email: string;
    fullName: string;
    companyName: string;
    plan: string;
    subscriptionStatus: string;
    stripeCustomerId?: string;
    stripeSubscriptionId?: string;
    createdAt: number;
  }
  
  export interface PricingPlan {
    id: string;
    name: string;
    price: number;
    interval: 'month' | 'year' | 'one-time' | 'custom';
    stripePriceId?: string;
    description: string;
    features: string[];
    highlighted?: boolean;
    badge?: string;
    cta: string;
    tier: 'free' | 'standard' | 'pro' | 'enterprise';
  }
  
  export interface Addon {
    id: string;
    name: string;
    price: number;
    interval: 'month' | 'one-time';
    description: string;
    stripePriceId?: string;
  }
  
  export interface CartItem {
    id: string;
    name: string;
    price: number;
    interval: string;
    type: 'plan' | 'addon' | 'report';
    stripePriceId?: string;
  }
  
  export interface AppFeature {
    slug: string;
    name: string;
    tagline: string;
    description: string;
    icon: string;
    tier: string;
    features: string[];
    benefits: string[];
    screenshot?: string;
  }
  
  export interface SupportTicket {
    name: string;
    email: string;
    subject: string;
    message: string;
    priority: 'low' | 'normal' | 'high';
  }
  