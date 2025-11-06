class SparePartFilterOptions {
  // Brands
  static const List<String> brands = [
    'Honda',
    'Toyota', 
    'Nissan',
    'Mazda',
    'Mitsubishi',
    'Ford',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Hyundai',
    'Kia',
  ];

  // Models by Brand
  static const Map<String, List<String>> modelsByBrand = {
    'Honda': [
      'Civic',
      'Accord', 
      'CR-V',
      'HR-V',
      'City',
      'Jazz',
      'Pilot',
      'Odyssey',
    ],
    'Toyota': [
      'Corolla',
      'Camry',
      'RAV4',
      'Hilux',
      'Innova',
      'Fortuner',
      'Yaris',
      'Vios',
      'Prius',
    ],
    'Nissan': [
      'Almera',
      'Sentra',
      'Altima',
      'X-Trail',
      'Navara',
      'Teana',
      'Cefiro',
      'Maxima',
    ],
    'Mazda': [
      'Mazda2',
      'Mazda3',
      'Mazda6',
      'CX-3',
      'CX-5',
      'CX-9',
      'BT-50',
    ],
    'Mitsubishi': [
      'Lancer',
      'Outlander',
      'Pajero',
      'Triton',
      'ASX',
      'Mirage',
    ],
    'Ford': [
      'Focus',
      'Fiesta',
      'Mustang',
      'Explorer',
      'Ranger',
      'EcoSport',
      'Everest',
    ],
    'BMW': [
      '1 Series',
      '3 Series',
      '5 Series',
      '7 Series',
      'X1',
      'X3',
      'X5',
      'X6',
    ],
    'Mercedes-Benz': [
      'A-Class',
      'C-Class',
      'E-Class',
      'S-Class',
      'GLA',
      'GLC',
      'GLE',
      'G-Class',
    ],
    'Audi': [
      'A3',
      'A4',
      'A6',
      'A8',
      'Q3',
      'Q5',
      'Q7',
      'TT',
    ],
    'Volkswagen': [
      'Golf',
      'Jetta',
      'Passat',
      'Tiguan',
      'Touareg',
      'Polo',
    ],
    'Hyundai': [
      'Elantra',
      'Sonata',
      'Tucson',
      'Santa Fe',
      'i10',
      'i20',
      'i30',
    ],
    'Kia': [
      'Forte',
      'Optima',
      'Sportage',
      'Sorento',
      'Picanto',
      'Rio',
      'Stinger',
    ],
  };

  // Product Categories
  static const List<String> categories = [
    'Engine Parts',
    'Brake System',
    'Suspension',
    'Transmission',
    'Electrical',
    'Cooling System',
    'Exhaust System',
    'Air Intake',
    'Fuel System',
    'Body Parts',
    'Interior',
    'Lighting',
    'Filters',
    'Belts & Chains',
    'Gaskets & Seals',
    'Sensors',
    'Wheels & Tires',
    'Tools & Equipment',
  ];

  // Sub-categories for specific parts
  static const Map<String, List<String>> subCategories = {
    'Engine Parts': [
      'Pistons',
      'Cylinder Head',
      'Valves',
      'Camshaft',
      'Crankshaft',
      'Engine Mounts',
      'Timing Belt',
      'Spark Plugs',
    ],
    'Brake System': [
      'Brake Pads',
      'Brake Discs',
      'Brake Fluid',
      'Brake Calipers',
      'Brake Lines',
      'Master Cylinder',
      'Brake Shoes',
    ],
    'Suspension': [
      'Shock Absorbers',
      'Struts',
      'Springs',
      'Stabilizer Link',
      'Control Arms',
      'Ball Joints',
      'Bushings',
    ],
    'Electrical': [
      'Battery',
      'Alternator',
      'Starter Motor',
      'Wiring Harness',
      'Fuses',
      'Relays',
      'ECU',
    ],
    'Filters': [
      'Oil Filter',
      'Air Filter',
      'Fuel Filter',
      'Cabin Filter',
      'Transmission Filter',
    ],
  };

  // Position Options
  static const List<String> positions = [
    'Front',
    'Rear',
    'Left',
    'Right',
    'Front Left',
    'Front Right', 
    'Rear Left',
    'Rear Right',
    'Center',
    'Both',
    'All',
  ];

  // Warehouse Options
  static const List<String> warehouses = [
    'A',
    'B', 
    'C',
    'D',
  ];

  // Rack Options (01-20)
  static List<String> get racks {
    return List.generate(20, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  // Section Options (01-50)
  static List<String> get sections {
    return List.generate(50, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  // Utility Methods
  static List<String> getModelsForBrand(String brand) {
    return modelsByBrand[brand] ?? [];
  }

  static List<String> getSubCategoriesForCategory(String category) {
    return subCategories[category] ?? [];
  }

  static List<String> getAllModels() {
    return modelsByBrand.values.expand((models) => models).toList()..sort();
  }

  static bool isValidBrandModelCombination(String brand, String model) {
    return modelsByBrand[brand]?.contains(model) ?? false;
  }

  // Get all unique values
  static List<String> getAllBrands() => List.from(brands)..sort();
  static List<String> getAllCategories() => List.from(categories)..sort();
  static List<String> getAllPositions() => List.from(positions)..sort();
  static List<String> getAllWarehouses() => List.from(warehouses)..sort();
  static List<String> getAllRacks() => racks;
  static List<String> getAllSections() => sections;
}