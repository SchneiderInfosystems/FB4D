## Database Batch Get Queries
_Supported since FB4D v???_

Firestore provides the ability to retrieve multiple documents from the database in a single request using the `batchGet` API. This is significantly faster and more efficient than making multiple separate `GET` requests, especially when requesting a known set of documents.

FB4D supports both synchronous and asynchronous `batchGet` requests:
```pascal
/// Retrieves multiple documents in a single request asynchronously.
procedure BatchGet(const DocumentPaths: TRequestResourceParams; OnDocuments: TOnDocuments; OnRequestError: TOnRequestError); overload;

/// Retrieves multiple documents in a single request synchronously.
function BatchGetSynchronous(const DocumentPaths: TRequestResourceParams): IFirestoreDocuments; overload;
```
> [!NOTE]
> `BatchGet` and `BatchGetSynchronous` are accessible via `IFirestoreDatabase`. 

### Defining the Document Paths (`TRequestResourceParams`)
Both functions accept an array of document paths, defined via the `TRequestResourceParams` type (which resolves to `array of TRequestResourceParam`).
A single `TRequestResourceParam` is simply an array of strings representing the path to a document collections and its ID, for instance: `['users', 'user1']`.

Therefore, the `DocumentPaths` array expects a format like `[['collection1', 'doc1'], ['collection2', 'doc2']]`. FB4D internally resolves these paths to their fully qualified Firestore resource names.

### Example: Fetching Two Documents using BatchGet
```pascal
var
  DocPaths: TRequestResourceParams;
  Docs: IFirestoreDocuments;
  i: Integer;
begin
  SetLength(DocPaths, 2);
  DocPaths[0] := ['users', 'user1'];
  DocPaths[1] := ['config', 'settings'];
  
  // Synchronously fetch both documents
  Docs := myFirestoreDb.BatchGetSynchronous(DocPaths);

  if Assigned(Docs) then
  begin
    Writeln('Retrieved ', Docs.Count, ' documents.');
    for i := 0 to Docs.Count - 1 do
      Writeln('Found document: ', Docs.Document(i).DocumentName(False));
  end;
end;
```
> [!TIP]
> If a requested document does not exist, Firestore will omit it from the found documents list. Therefore, `Docs.Count` might be less than `Length(DocPaths)` if some documents are missing. FB4D safely ignores the missing ones and only parses the documents that map to the `found` node in the payload.
