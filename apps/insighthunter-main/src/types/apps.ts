export type Tier = 'lite' | 'standard' | 'pro' | 'enterprise';

export interface AppDefinition {
  slug:        string;
  name:        string;
  description: string;
  icon:        string;           // emoji or SVG path
  href:        string;           // dashboard route
  featurePage: string;           // marketing route
  tier:        Tier;
  available:   boolean;
  comingSoon?: boolean;
}

export interface PricingTier {
  id:          Tier;
  name:        string;
  price:       number | null;    // null = contact sales
  priceLabel:  string;
  description: string;
  features:    string[];
  cta:         string;
  ctaHref:     string;
  highlighted: boolean;
}
