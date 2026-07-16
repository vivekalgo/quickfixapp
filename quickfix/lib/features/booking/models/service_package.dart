class ServicePackage {
  final String id;
  final String title;
  final String categoryId;
  final String subCategory;
  final double rating;
  final int reviewsCount;
  final double price;
  final double originalPrice;
  final String durationText;
  final List<String> bulletPoints;
  final String imageUrl;

  const ServicePackage({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.subCategory,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    required this.originalPrice,
    required this.durationText,
    required this.bulletPoints,
    required this.imageUrl,
  });
}

const List<ServicePackage> packageDatabase = [
  // Cleaning
  ServicePackage(
    id: 'c_sofa_3',
    title: '3-Seater Sofa Dry Cleaning',
    categoryId: 'cleaning',
    subCategory: 'Sofa Cleaning',
    rating: 4.8,
    reviewsCount: 8400,
    price: 499,
    originalPrice: 699,
    durationText: '45 mins',
    bulletPoints: [
      'Deep vacuuming of sofa seats & cushions',
      'Specialized foam wash & shampoo scrub',
      'Stain removal treatment & extraction',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
  ),
  ServicePackage(
    id: 'c_sofa_5',
    title: '5-Seater Sofa Dry Cleaning',
    categoryId: 'cleaning',
    subCategory: 'Sofa Cleaning',
    rating: 4.9,
    reviewsCount: 12000,
    price: 799,
    originalPrice: 1199,
    durationText: '1 hr 15 mins',
    bulletPoints: [
      'Complete 5 seat deep foam scrub',
      'Extraction of dirt, mud, and stains',
      'Deodorizing spray for fresh aroma',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=500',
  ),
  ServicePackage(
    id: 'c_kit_standard',
    title: 'Standard Kitchen Cleaning',
    categoryId: 'cleaning',
    subCategory: 'Kitchen Cleaning',
    rating: 4.6,
    reviewsCount: 4100,
    price: 1199,
    originalPrice: 1599,
    durationText: '2 hrs 30 mins',
    bulletPoints: [
      'Chimney degreasing & exterior wipe',
      'Countertop, sink & tiles scrubbing',
      'Gas stove, burner & knobs polish',
    ],
    imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500',
  ),

  // Plumbing
  ServicePackage(
    id: 'p_tap_install',
    title: 'Tap Installation / Replacement',
    categoryId: 'plumbing',
    subCategory: 'Tap Repairs',
    rating: 4.5,
    reviewsCount: 1500,
    price: 149,
    originalPrice: 249,
    durationText: '20 mins',
    bulletPoints: [
      'Installation of new kitchen/bathroom tap',
      'Leakage check & Teflon taping',
      'Includes 30 days post-service warranty',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
  ),
  ServicePackage(
    id: 'p_leak_pipe',
    title: 'Pipe Leakage Repair',
    categoryId: 'plumbing',
    subCategory: 'Leaks Repair',
    rating: 4.7,
    reviewsCount: 3100,
    price: 299,
    originalPrice: 399,
    durationText: '40 mins',
    bulletPoints: [
      'Localization of pipeline leakages',
      'Replacement of pipes/joints (materials extra)',
      'Pressure testing for durability',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
  ),

  // Electrician
  ServicePackage(
    id: 'e_fan_mount',
    title: 'Ceiling Fan Installation',
    categoryId: 'electrician',
    subCategory: 'Fans & Lights',
    rating: 4.7,
    reviewsCount: 6300,
    price: 129,
    originalPrice: 199,
    durationText: '30 mins',
    bulletPoints: [
      'Unboxing, rod attachment & mounting',
      'Wiring connection & speed checks',
      'Applies to standard ceilings',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
  ),
  ServicePackage(
    id: 'e_switch_board',
    title: 'Switchboard Installation',
    categoryId: 'electrician',
    subCategory: 'Switchboard',
    rating: 4.8,
    reviewsCount: 4200,
    price: 199,
    originalPrice: 299,
    durationText: '35 mins',
    bulletPoints: [
      'Wiring audit & modular plate mounting',
      'Connections for up to 8 switches & sockets',
      'Includes safety earthing validation',
    ],
    imageUrl:
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
  ),
];
