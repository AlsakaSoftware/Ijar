export interface Property {
  id: string;
  address: string;
  price: string;
  bedrooms: number;
  bathrooms: number;
  agentPhone?: string;
  agentName?: string;
  propertyUrl: string;
  rightmoveId?: string;
}

export interface CallRequest {
  properties: Property[];
  userId?: string;
  notificationEmail?: string;
}

export interface BlandCallResponse {
  call_id: string;
  status: string;
  message?: string;
}

export interface BlandWebhookPayload {
  call_id: string;
  phone_number: string;
  to: string;
  from: string;
  call_length: number;
  transcript: string;
  summary: string;
  recording_url?: string;
  end_reason: string;
  error_message?: string;
  variables?: Record<string, any>;
}

export interface CallResult {
  callId: string;
  propertyId: string;
  propertyAddress: string;
  agentPhone: string;
  status: 'completed' | 'failed' | 'no-answer' | 'busy';
  duration: number;
  summary: string;
  transcript: string;
  recordingUrl?: string;
  viewingSlots?: string[];
  propertyAvailable?: boolean;
  timestamp: Date;
}