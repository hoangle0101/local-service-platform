// Dispute types matching backend responses

export interface Dispute {
  id: string;
  bookingId: string;
  reporterId: string;
  reason: string;
  description: string | null;
  status: 'open' | 'under_review' | 'resolved' | 'closed';
  resolution: 'customer_favor' | 'provider_favor' | 'split' | null;
  refundAmount: string | number | null;
  adminNotes: string | null;
  resolvedById: string | null;
  resolvedAt: string | null;
  booking: {
    id: string;
    scheduledAt: string;
    actualPrice: string | number;
    service: {
      id: number;
      name: string;
    } | null;
    customer: {
      id: string;
      phone: string;
      profile: {
        fullName: string;
      } | null;
    };
    provider: {
      id: string;
      displayName: string;
    };
  };
  reporter: {
    id: string;
    phone: string;
    email: string | null;
    profile: {
      fullName: string;
    } | null;
  };
  resolvedBy: {
    id: string;
    email: string;
    profile: {
      fullName: string;
    } | null;
  } | null;
  createdAt: string;
  updatedAt: string;
}

export interface ResolveDisputeInput {
  resolution: 'customer_favor' | 'provider_favor' | 'split';
  refundAmount?: number;
  notes?: string;
}
