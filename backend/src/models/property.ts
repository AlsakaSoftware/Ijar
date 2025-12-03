import { RightmoveProperty } from '../scraper-types';
import { RightmoveAPIProperty } from '../rightmove-api';

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
  summary?: string;
  propertyType?: string;
}

// Transform from scraper response (legacy)
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

// Transform from API response (new)
export function transformAPIProperty(property: RightmoveAPIProperty): LiveSearchProperty {
  const price = property.displayPrices?.[0]?.displayPrice ||
                `£${property.monthlyRent} pcm` ||
                'Price on request';

  const addressParts = property.address.split(',');
  const area = addressParts.length > 1
    ? addressParts[addressParts.length - 1].trim()
    : '';

  // Get images from thumbnailPhotos, upgrading to larger size
  const images = property.thumbnailPhotos?.map(photo => {
    // Replace max_656x437 with larger size for better quality
    return photo.url.replace('max_656x437', 'max_1024x682');
  }) || [];

  // If no thumbnailPhotos, use the main thumbnail
  if (images.length === 0 && property.photoLargeThumbnailUrl) {
    images.push(property.photoLargeThumbnailUrl.replace('max_656x437', 'max_1024x682'));
  }

  return {
    id: property.identifier.toString(),
    images,
    price,
    bedrooms: property.bedrooms || 0,
    bathrooms: 0, // API listing doesn't include bathrooms, will get from details
    address: property.address.trim(),
    area,
    rightmoveUrl: `https://www.rightmove.co.uk/properties/${property.identifier}`,
    agentPhone: property.branch?.contactTelephoneNumber || null,
    agentName: property.branch?.brandName || null,
    branchName: property.branch?.name || null,
    latitude: property.latitude || null,
    longitude: property.longitude || null,
    summary: property.summary || undefined,
    propertyType: property.propertyType || undefined
  };
}
