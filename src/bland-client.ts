import axios from 'axios';
import { Property, BlandCallResponse } from './types';

export class BlandClient {
  private apiKey: string;
  private phoneNumber: string;
  private webhookUrl: string;

  constructor(apiKey: string, phoneNumber: string, webhookUrl: string) {
    this.apiKey = apiKey;
    this.phoneNumber = phoneNumber;
    this.webhookUrl = webhookUrl;
  }

  async callProperty(property: Property): Promise<BlandCallResponse> {
    const prompt = this.generatePrompt(property);
    
    try {
      const response = await axios.post<BlandCallResponse>(
        'https://api.bland.ai/v1/calls',
        {
          phone_number: property.agentPhone,
          from: this.phoneNumber,
          task: prompt,
          first_sentence: "Hi, I'm calling about your property listing on Rightmove - is it still available?",
          wait_for_greeting: true,
          voice: "matt", // British accent
          max_duration: 180, // 3 minutes
          webhook: this.webhookUrl,
          metadata: {
            property_id: property.id,
            property_address: property.address,
            property_url: property.propertyUrl
          }
        },
        {
          headers: {
            'Authorization': this.apiKey,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error('Bland API error:', error.response?.data);
        throw new Error(error.response?.data?.message || 'Failed to initiate call');
      }
      throw error;
    }
  }

  private generatePrompt(property: Property): string {
    return `You're calling about the property at ${property.address} listed for ${property.price}.
    
    Your objectives:
    1. Confirm if the property is still available for rent
    2. Ask about viewing availability this week and next week
    3. Get 2-3 specific viewing time slots (with dates and times)
    4. Ask if there have been many applications/interest
    5. Ask about move-in date availability
    
    Important instructions:
    - Be professional, friendly, and concise
    - If asked who you represent, say you're calling on behalf of a client interested in viewing
    - Try to get specific dates and times for viewings, not just "anytime"
    - If they need to check availability, ask if they can text the viewing times to your number
    - Thank them for their time at the end
    
    Property details:
    - Address: ${property.address}
    - Price: ${property.price}
    - Bedrooms: ${property.bedrooms}
    - Link: https://rightmove.co.uk${property.propertyUrl}`;
  }
}