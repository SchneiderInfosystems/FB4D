type
  // Workaround for geographical 2D coordinates from System.Sensors for Linux64
  TLocationDegrees = Double;
  TLocationCoord2D = record
    Latitude: TLocationDegrees;
    Longitude: TLocationDegrees;
    constructor Create(ALatitude, ALongitude: TLocationDegrees);
  end;
