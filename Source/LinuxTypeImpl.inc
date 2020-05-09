// Workaround because of missing System.Sensors for Linux
constructor TLocationCoord2D.Create(ALatitude, ALongitude: TLocationDegrees);
begin
  Latitude := ALatitude;
  Longitude := ALongitude;
end;
