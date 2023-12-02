{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2023 Christoph Schneider                                 }
{  Schneider Infosystems AG, Switzerland                                       }
{  https://github.com/SchneiderInfosystems/FB4D                                }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

unit FB4D.Configuration;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  System.JSON, System.JSON.Types,
  System.Net.HttpClient,
  System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces;

type
  /// <summary>
  /// The interface IFirebaseConfiguration provides a class factory for
  /// accessing all interfaces to the Firebase services.
  /// </summary>
  TFirebaseConfiguration = class(TInterfacedObject, IFirebaseConfiguration)
  private
    fApiKey: string;
    fProjectID: string;
    fBucket: string;
    fFirebaseURL: string;
    fServerRegion: string;
    fAuth: IFirebaseAuthentication;
    fRealTimeDB: IRealTimeDB;
    fDatabase: TDictionary<string, IFirestoreDatabase>;
    fStorage: IFirebaseStorage;
    fFunctions: IFirebaseFunctions;
    fVisionML: IVisionML;
  public
    /// <summary>
    /// The first constructor requires all secrets of the Firebase project as
    /// ApiKey and Project ID and when using the Storage also the storage Bucket
    /// and for accessing the Firebase RT-DB the FirebaseURL as parameters.
    /// </summary>
    constructor Create(const ApiKey, ProjectID: string;
      const Bucket: string = ''; const FirebaseURL: string = '';
      const ServerRegion: string = cRegionUSCent1); overload;

    destructor Destroy; override;

    /// <summary>
    /// The second constructor parses the google-services.json file that shall
    /// be loaded from the Firebase Console after adding an App in the project
    /// settings.
    /// </summary>
    constructor Create(const GoogleServicesFile: string); overload;

    /// <summary>
    /// Define Bucket after creation but before access to Storage
    /// </summary>
    procedure SetBucket(const Bucket: string);

    /// <summary>
    /// Define FirebaseURL after creation but before access to RealTimeDB
    /// </summary>
    procedure SetFirebaseURL(const FirebaseURL: string);

    /// <summary>
    /// Define Server Region after creation but before access to Functions
    /// </summary>
    procedure SetServerRegion(const ServerRegion: string);

    function ProjectID: string;
    function ServerRegion: string;
    function Auth: IFirebaseAuthentication;
    function RealTimeDB: IRealTimeDB;
    function Database(
      const DatabaseID: string = cDefaultDatabaseID): IFirestoreDatabase;
    function Storage: IFirebaseStorage;
    function Functions: IFirebaseFunctions;
    function VisionML: IVisionML;
    class function GetLibVersionInfo: string;
    class function GetLibLicenseInfo: string;
  end;

implementation

uses
  System.IOUtils,
  FB4D.Authentication, FB4D.RealTimeDB, FB4D.Firestore, FB4D.Storage,
  FB4D.Functions, FB4D.VisionML;

{$I FB4DVersion.inc}

{ TFirebaseConfiguration }

constructor TFirebaseConfiguration.Create(const ApiKey, ProjectID,
  Bucket, FirebaseURL, ServerRegion: string);
begin
  fApiKey := ApiKey;
  fProjectID := ProjectID;
  fBucket := Bucket;
  fServerRegion := ServerRegion;
  if FirebaseURL.IsEmpty then
    fFirebaseURL := Format(GOOGLE_FIREBASE, [fProjectID])
  else
    fFirebaseURL := FirebaseURL;
  fDatabase := TDictionary<string, IFirestoreDatabase>.Create;
end;

constructor TFirebaseConfiguration.Create(const GoogleServicesFile: string);
var
  JsonObj, ProjInfo: TJSONValue;
  Client, ApiKey: TJSONArray;
begin
  if not FileExists(GoogleServicesFile) then
    raise EFirebaseConfiguration.CreateFmt(
      'Open the Firebase Console and store the google-services.json here: %s',
      [ExpandFileName(GoogleServicesFile)]);
  JsonObj := TJSONObject.ParseJSONValue(TFile.ReadAllText(GoogleServicesFile));
  try
    ProjInfo := JsonObj.GetValue<TJSONObject>('project_info');
    Assert(assigned(ProjInfo), '"project_info" missing in Google-Services.json');
    fProjectID := ProjInfo.GetValue<string>('project_id');
    fFirebaseURL := ProjInfo.GetValue<string>('firebase_url');
    fBucket := ProjInfo.GetValue<string>('storage_bucket');
    Client := JsonObj.GetValue<TJSONArray>('client');
    Assert(assigned(Client), '"client" missing in Google-Services.json');
    Assert(Client.Count > 0, '"client" array empty in Google-Services.json');
    ApiKey := Client.Items[0].GetValue<TJSONArray>('api_key');
    Assert(assigned(ApiKey), '"api_key" missing in Google-Services.json');
    Assert(ApiKey.Count > 0, '"api_key" array empty in Google-Services.json');
    fApiKey := ApiKey.Items[0].GetValue<string>('current_key');
  finally
    JsonObj.Free;
  end;
  fServerRegion := cRegionUSCent1; // Region is missing in google-services.json
  fDatabase := TDictionary<string, IFirestoreDatabase>.Create;
end;

destructor TFirebaseConfiguration.Destroy;
begin
  fDatabase.Free;
  inherited;
end;

procedure TFirebaseConfiguration.SetBucket(const Bucket: string);
begin
  fBucket := Bucket;
end;

procedure TFirebaseConfiguration.SetFirebaseURL(const FirebaseURL: string);
begin
  fFirebaseURL := FirebaseURL;
end;

procedure TFirebaseConfiguration.SetServerRegion(const ServerRegion: string);
begin
  fServerRegion := ServerRegion;
end;

function TFirebaseConfiguration.Auth: IFirebaseAuthentication;
begin
  Assert(not fApiKey.IsEmpty, 'ApiKey is required for Authentication');
  if not assigned(fAuth) then
    fAuth := TFirebaseAuthentication.Create(fApiKey);
  result := fAuth;
end;

function TFirebaseConfiguration.RealTimeDB: IRealTimeDB;
begin
  Assert(not fProjectID.IsEmpty, 'ProjectID is required for RealTimeDB');
  if not assigned(fRealTimeDB) then
    fRealTimeDB := TRealTimeDB.CreateByURL(fFirebaseURL, Auth);
  result := fRealTimeDB;
end;

function TFirebaseConfiguration.Database(
  const DatabaseID: string): IFirestoreDatabase;
begin
  Assert(not fProjectID.IsEmpty, 'ProjectID is required for Firestore');
  Assert(not DatabaseID.IsEmpty, 'DatabaseID is required for Firestore');
  if not fDatabase.TryGetValue(DatabaseID, result) then
  begin
    result := TFirestoreDatabase.Create(fProjectID, Auth, DatabaseID);
    fDatabase.Add(DatabaseID, result);
  end;
end;

function TFirebaseConfiguration.Storage: IFirebaseStorage;
begin
  Assert(not fBucket.IsEmpty, 'Bucket is required for Storage');
  if not assigned(fStorage) then
    fStorage := TFirebaseStorage.Create(fBucket, Auth);
  result := fStorage;
end;

function TFirebaseConfiguration.Functions: IFirebaseFunctions;
begin
  Assert(not fProjectID.IsEmpty, 'ProjectID is required for Functions');
  if not assigned(fFunctions) then
    fFunctions := TFirebaseFunctions.Create(fProjectID, Auth, fServerRegion);
  result := fFunctions;
end;

function TFirebaseConfiguration.VisionML: IVisionML;
begin
  Assert(not fProjectID.IsEmpty, 'ProjectID is required for VisionML');
  Assert(not fApiKey.IsEmpty, 'ApiKey is required for VisionML');
  if not assigned(fVisionML) then
    fVisionML := TVisionML.Create(fProjectID, fAPIKey, Auth);
  result := fVisionML;
end;

function TFirebaseConfiguration.ProjectID: string;
begin
  result := fProjectID;
end;

function TFirebaseConfiguration.ServerRegion: string;
begin
  result := fServerRegion;
end;

class function TFirebaseConfiguration.GetLibLicenseInfo: string;
begin
  result := 'Apache 2.0 License © Schneider Infosystems Ltd';
end;

class function TFirebaseConfiguration.GetLibVersionInfo: string;
begin
  result := Format('FB4D V%d.%d.%d.%d',
    [cLibMajorVersion, cLibMinorVersion, cLibReleaseVersion, cLibBuildVersion]);
end;

end.
