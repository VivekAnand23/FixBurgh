/**
 * Service category groups, a copy of the `service_categories` Remote Config
 * default (firebase/remoteconfig.template.json). A test keeps them in step.
 */
export interface ServiceCategory {
  id: string;
  label: string;
  synonyms: string[];
}

export interface ServiceGroup {
  id: string;
  label: string;
  approvalCheck: string;
  categories: ServiceCategory[];
}

export const SERVICE_GROUPS: ServiceGroup[] = [
  {
    "id": "home_repair",
    "label": "Home repair",
    "approvalCheck": "Pennsylvania contractor registration (HIC) and insurance",
    "categories": [
      {
        "id": "plumbing",
        "label": "Plumbing",
        "synonyms": [
          "plumber",
          "leak",
          "leaking",
          "leaky",
          "tap",
          "faucet",
          "drain",
          "clog",
          "clogged",
          "pipe",
          "pipes",
          "toilet",
          "sink",
          "shower",
          "water heater",
          "sewer",
          "drip",
          "dripping"
        ]
      },
      {
        "id": "electrical",
        "label": "Electrical",
        "synonyms": [
          "electrician",
          "outlet",
          "socket",
          "breaker",
          "fuse",
          "wiring",
          "light",
          "lights",
          "switch",
          "power",
          "sparking",
          "fixture"
        ]
      },
      {
        "id": "hvac",
        "label": "HVAC",
        "synonyms": [
          "heating",
          "furnace",
          "boiler",
          "air conditioning",
          "ac",
          "a/c",
          "heat pump",
          "thermostat",
          "vent",
          "duct",
          "no heat",
          "cooling"
        ]
      },
      {
        "id": "appliance_repair",
        "label": "Appliance repair",
        "synonyms": [
          "washer",
          "dryer",
          "dishwasher",
          "fridge",
          "refrigerator",
          "oven",
          "stove",
          "microwave",
          "freezer",
          "appliance"
        ]
      },
      {
        "id": "carpentry",
        "label": "Carpentry",
        "synonyms": [
          "carpenter",
          "wood",
          "door",
          "cabinet",
          "shelf",
          "shelves",
          "deck",
          "trim",
          "frame",
          "floorboard"
        ]
      },
      {
        "id": "painting",
        "label": "Painting",
        "synonyms": [
          "painter",
          "paint",
          "repaint",
          "wall",
          "walls",
          "ceiling",
          "stain",
          "primer"
        ]
      },
      {
        "id": "roofing_and_gutters",
        "label": "Roofing and gutters",
        "synonyms": [
          "roof",
          "roofer",
          "shingle",
          "shingles",
          "gutter",
          "gutters",
          "downspout",
          "roof leak",
          "flashing"
        ]
      },
      {
        "id": "locksmith",
        "label": "Locksmith",
        "synonyms": [
          "lock",
          "locks",
          "key",
          "keys",
          "locked out",
          "deadbolt",
          "rekey"
        ]
      },
      {
        "id": "handyman",
        "label": "Handyman",
        "synonyms": [
          "fix",
          "repair",
          "mount",
          "hang",
          "assemble",
          "odd jobs",
          "tv mount",
          "furniture assembly",
          "caulk"
        ]
      }
    ]
  },
  {
    "id": "home_care",
    "label": "Home care",
    "approvalCheck": "Insurance",
    "categories": [
      {
        "id": "house_cleaning",
        "label": "House cleaning",
        "synonyms": [
          "cleaner",
          "cleaning",
          "clean",
          "maid",
          "deep clean",
          "move-out clean"
        ]
      },
      {
        "id": "pest_control",
        "label": "Pest control",
        "synonyms": [
          "pest",
          "mice",
          "mouse",
          "rats",
          "rat",
          "ants",
          "roaches",
          "cockroach",
          "bed bugs",
          "termites",
          "wasps",
          "exterminator"
        ]
      },
      {
        "id": "lawn_and_garden",
        "label": "Lawn and garden",
        "synonyms": [
          "lawn",
          "grass",
          "mow",
          "mowing",
          "garden",
          "gardener",
          "yard",
          "hedge",
          "weeds",
          "landscaping",
          "leaves"
        ]
      },
      {
        "id": "snow_removal",
        "label": "Snow removal",
        "synonyms": [
          "snow",
          "shovel",
          "shoveling",
          "plow",
          "plowing",
          "ice",
          "salt",
          "driveway"
        ]
      },
      {
        "id": "moving_help",
        "label": "Moving help",
        "synonyms": [
          "move",
          "moving",
          "movers",
          "boxes",
          "lift",
          "heavy",
          "furniture"
        ]
      },
      {
        "id": "junk_removal",
        "label": "Junk removal",
        "synonyms": [
          "junk",
          "haul",
          "hauling",
          "trash",
          "dump",
          "old furniture",
          "clean out",
          "debris"
        ]
      }
    ]
  },
  {
    "id": "personal_care",
    "label": "Personal care",
    "approvalCheck": "Background check, plus Pennsylvania child abuse clearances for anyone caring for children",
    "categories": [
      {
        "id": "babysitting",
        "label": "Babysitting",
        "synonyms": [
          "babysitter",
          "sitter",
          "child",
          "children",
          "kids",
          "kid",
          "childcare",
          "date night"
        ]
      },
      {
        "id": "nanny",
        "label": "Nanny",
        "synonyms": [
          "nanny",
          "childcare",
          "full-time",
          "after school",
          "au pair"
        ]
      },
      {
        "id": "elder_care_and_companionship",
        "label": "Elder care and companionship",
        "synonyms": [
          "elder",
          "senior",
          "elderly",
          "companion",
          "companionship",
          "caregiver",
          "aging parent"
        ]
      },
      {
        "id": "pet_sitting",
        "label": "Pet sitting",
        "synonyms": [
          "pet sitter",
          "pet",
          "pets",
          "cat",
          "cats",
          "dog sitting",
          "feed",
          "boarding",
          "house sit"
        ]
      },
      {
        "id": "dog_walking",
        "label": "Dog walking",
        "synonyms": [
          "dog walker",
          "walk",
          "walks",
          "dog",
          "dogs",
          "puppy"
        ]
      },
      {
        "id": "pet_grooming",
        "label": "Pet grooming",
        "synonyms": [
          "groom",
          "grooming",
          "groomer",
          "bath",
          "nail trim",
          "haircut dog"
        ]
      },
      {
        "id": "tutoring",
        "label": "Tutoring",
        "synonyms": [
          "tutor",
          "homework",
          "math",
          "reading",
          "sat",
          "lessons",
          "test prep",
          "school"
        ]
      }
    ]
  },
  {
    "id": "everyday_help",
    "label": "Everyday help",
    "approvalCheck": "None beyond ID",
    "categories": [
      {
        "id": "errands_and_grocery_runs",
        "label": "Errands and grocery runs",
        "synonyms": [
          "errand",
          "errands",
          "grocery",
          "groceries",
          "shopping",
          "pickup",
          "pharmacy",
          "delivery"
        ]
      },
      {
        "id": "meal_prep",
        "label": "Meal prep",
        "synonyms": [
          "meal",
          "meals",
          "cook",
          "cooking",
          "chef",
          "dinner",
          "food prep"
        ]
      },
      {
        "id": "tech_help",
        "label": "Tech help",
        "synonyms": [
          "computer",
          "laptop",
          "wifi",
          "wi-fi",
          "internet",
          "router",
          "printer",
          "phone",
          "tv setup",
          "tech"
        ]
      },
      {
        "id": "car_wash_and_detailing",
        "label": "Car wash and detailing",
        "synonyms": [
          "car",
          "car wash",
          "detail",
          "detailing",
          "vacuum car",
          "auto"
        ]
      }
    ]
  }
];

/** Categories that need a recorded background check before going live. */
export const BACKGROUND_CHECK_GROUP = 'personal_care';

/** Care for children: also needs the Pennsylvania child abuse clearances. */
export const CHILD_CARE_CATEGORIES = ['babysitting', 'nanny', 'tutoring'];

export const categoryById = (id: string) =>
  SERVICE_GROUPS.flatMap((g) => g.categories.map((c) => ({ ...c, group: g.id }))).find((c) => c.id === id);
