import { RightmoveAPI } from '../api';
import { PropertyRepository } from '../repositories/propertyRepository';
import { PropertySearchParams, PropertyWithDetails } from '../types';
import { SearchBody, OnboardingSearchBody } from '../schemas/searchSchemas';
import { Property } from '../schemas/propertySchemas';

export class SearchService {
  constructor(
    private api: RightmoveAPI,
    private propertyRepo: PropertyRepository
  ) {}

  async searchProperties(body: SearchBody): Promise<{
    properties: any[];
    total: number;
    hasMore: boolean;
    page: number;
  }> {
    const params = this.buildSearchParams(body);
    const results = await this.api.searchProperties(params);

    return {
      properties: results.properties,
      total: results.total,
      hasMore: results.hasMore,
      page: results.page,
    };
  }

  async onboardingSearch(body: OnboardingSearchBody): Promise<{
    properties: Property[];
    total: number;
    saved: number;
  }> {
    const params = this.buildSearchParams(body);
    params.page = 1;

    const results = await this.api.searchProperties(params);
    if (results.properties.length === 0) {
      return { properties: [], total: 0, saved: 0 };
    }

    // Fetch HD details for top 10 properties
    const maxToProcess = Math.min(results.properties.length, 10);
    const propertiesWithDetails: PropertyWithDetails[] = [];

    for (let i = 0; i < maxToProcess; i++) {
      const property = results.properties[i];
      try {
        const details = await this.api.getPropertyDetails(property.identifier);
        const p = details.property;

        propertiesWithDetails.push({
          ...property,
          bathrooms: parseInt(p.analyticsInfo?.bathrooms || '0', 10),
          hdImages: p.photos?.map((photo: any) => photo.maxSizeUrl) || [],
        });

        await new Promise(resolve => setTimeout(resolve, 100));
      } catch {
        propertiesWithDetails.push({
          ...property,
          bathrooms: 0,
          hdImages: [],
        });
      }
    }

    // Save to database
    let savedCount = 0;
    for (const prop of propertiesWithDetails) {
      try {
        const dbProperty = this.mapToDbProperty(prop);
        await this.propertyRepo.upsertAndLinkToQuery(body.queryId, dbProperty);
        savedCount++;
      } catch (error) {
        console.error(`Failed to save property ${prop.identifier}:`, error);
      }
    }

    // Return formatted properties
    const responseProperties: Property[] = propertiesWithDetails.map(p => ({
      id: String(p.identifier),
      images: p.hdImages && p.hdImages.length > 0
        ? p.hdImages.slice(0, 10)
        : p.thumbnailPhotos?.map((photo: any) => photo.url) || [],
      price: p.displayPrices?.[0]?.displayPrice || `£${p.monthlyRent} pcm`,
      bedrooms: p.bedrooms || 0,
      bathrooms: p.bathrooms || 0,
      address: p.address,
      area: p.address.split(',').pop()?.trim() || '',
      rightmove_url: `https://www.rightmove.co.uk/properties/${p.identifier}`,
      agent_phone: p.branch?.contactTelephoneNumber || null,
      agent_name: p.branch?.brandName || null,
      branch_name: p.branch?.name || null,
      latitude: p.latitude || null,
      longitude: p.longitude || null,
    }));

    return {
      properties: responseProperties,
      total: results.total,
      saved: savedCount,
    };
  }

  async getPropertyDetails(propertyId: string): Promise<any> {
    const response = await this.api.getPropertyDetails(propertyId);
    const p = response.property;

    return {
      id: p.identifier,
      bedrooms: p.bedrooms,
      bathrooms: parseInt(p.analyticsInfo?.bathrooms || '0', 10),
      address: p.address,
      price: p.displayPrices?.[0]?.displayPrice || `£${p.price} pcm`,
      description: p.fullDescription || p.summary,
      propertyType: p.propertySubtype || p.analyticsInfo?.propertySubType,
      furnishType: p.letFurnishType,
      availableFrom: p.letDateAvailable,
      latitude: p.latitude,
      longitude: p.longitude,
      photos: p.photos?.map((photo: any) => photo.maxSizeUrl) || [],
      floorplans: p.floorplans?.map((fp: any) => fp.url) || [],
      features: p.features?.map((f: any) => f.featureDescription) || [],
      stations: p.stations?.map((s: any) => ({ name: s.station, distance: s.distance })) || [],
      agent: {
        name: p.branch?.brandName,
        branch: p.branch?.name,
        phone: p.telephoneNumber,
        address: p.branch?.address,
      },
    };
  }

  private buildSearchParams(body: SearchBody): PropertySearchParams {
    let furnishType: 'furnished' | 'unfurnished' | undefined;
    if (body.furnishType === 'furnished') furnishType = 'furnished';
    else if (body.furnishType === 'unfurnished') furnishType = 'unfurnished';

    return {
      latitude: body.latitude,
      longitude: body.longitude,
      minPrice: body.minPrice,
      maxPrice: body.maxPrice,
      minBedrooms: body.minBedrooms,
      maxBedrooms: body.maxBedrooms,
      minBathrooms: body.minBathrooms,
      maxBathrooms: body.maxBathrooms,
      radius: body.radius,
      furnishType,
      page: body.page || 1,
      pageSize: 25,
    };
  }

  private mapToDbProperty(property: PropertyWithDetails) {
    const addressParts = property.address.split(',');
    const area = addressParts.length > 1 ? addressParts[addressParts.length - 1].trim() : undefined;

    const allImages = property.hdImages && property.hdImages.length > 0
      ? property.hdImages
      : property.thumbnailPhotos?.map((p: any) => p.url) || [];

    return {
      rightmove_id: property.identifier,
      images: allImages.slice(0, 10),
      price: property.displayPrices?.[0]?.displayPrice || `£${property.monthlyRent} pcm`,
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      address: property.address,
      area,
      rightmove_url: `https://www.rightmove.co.uk/properties/${property.identifier}`,
      agent_phone: property.branch?.contactTelephoneNumber || undefined,
      agent_name: property.branch?.brandName || undefined,
      branch_name: property.branch?.name || undefined,
      latitude: property.latitude || undefined,
      longitude: property.longitude || undefined,
    };
  }
}
