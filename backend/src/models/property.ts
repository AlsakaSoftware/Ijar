import { RightmoveProperty } from '../scraper-types';

export interface LiveSearchProperty {
  id: string;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area: string;
  rightmoveUrl: string;
  agentPhone: string | null;
  agentName: string | null;
  branchName: string | null;
  latitude: number | null;
  longitude: number | null;
}

export function transformProperty(property: RightmoveProperty): LiveSearchProperty {
  const price = property.price?.displayPrices?.[0]?.displayPrice ||
                property.price?.displayPrice ||
                'Price on request';

  const addressParts = property.displayAddress.split(',');
  const area = addressParts.length > 1
    ? addressParts[addressParts.length - 1].trim()
    : '';

  const images = property.images?.map(img => img.srcUrl || img.url).filter(Boolean) || [];

  return {
    id: property.id.toString(),
    images,
    price,
    bedrooms: property.bedrooms || 0,
    bathrooms: property.bathrooms || 0,
    address: property.displayAddress,
    area,
    rightmoveUrl: `https://www.rightmove.co.uk${property.propertyUrl}`,
    agentPhone: property.customer?.contactTelephone || null,
    agentName: property.customer?.brandTradingName || null,
    branchName: property.customer?.branchName || null,
    latitude: property.location?.latitude || null,
    longitude: property.location?.longitude || null
  };
}
