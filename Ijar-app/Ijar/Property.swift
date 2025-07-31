import Foundation

struct Property: Identifiable {
    let id = UUID()
    let images: [String]
    let price: String
    let bedrooms: Int
    let bathrooms: Int
    let address: String
    let area: String
    
    static let mockProperties: [Property] = [
        Property(
            images: [
                "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800&q=80",
                "https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&q=80",
                "https://images.unsplash.com/photo-1560185009-5bf9f2849dbe?w=800&q=80",
                "https://images.unsplash.com/photo-1560185008-b033106af5c3?w=800&q=80"
            ],
            price: "£2,500/month",
            bedrooms: 3,
            bathrooms: 2,
            address: "123 Canary Wharf",
            area: "London E14"
        ),
        Property(
            images: [
                "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80",
                "https://images.unsplash.com/photo-1516156008625-3a9d6067fab5?w=800&q=80",
                "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80"
            ],
            price: "£3,200/month",
            bedrooms: 4,
            bathrooms: 3,
            address: "45 Royal Docks",
            area: "London E16"
        ),
        Property(
            images: [
                "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80",
                "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80",
                "https://images.unsplash.com/photo-1600607687644-aac4c3eac7f4?w=800&q=80",
                "https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=800&q=80",
                "https://images.unsplash.com/photo-1600607688969-a5bfcd646154?w=800&q=80"
            ],
            price: "£1,800/month",
            bedrooms: 2,
            bathrooms: 1,
            address: "78 Mile End Road",
            area: "London E1"
        ),
        Property(
            images: [
                "https://images.unsplash.com/photo-1567496898669-ee935f5f647a?w=800&q=80",
                "https://images.unsplash.com/photo-1574180045827-681f8a1a9622?w=800&q=80"
            ],
            price: "£4,500/month",
            bedrooms: 5,
            bathrooms: 3,
            address: "12 St Katharine Docks",
            area: "London E1W"
        ),
        Property(
            images: [
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80",
                "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80",
                "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80",
                "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80"
            ],
            price: "£2,100/month",
            bedrooms: 2,
            bathrooms: 2,
            address: "89 Stratford High Street",
            area: "London E15"
        )
    ]
}