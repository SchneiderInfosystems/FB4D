## Database Aggregation Queries
_Supported since FB4D v???_

Firestore provides the ability to run server-side aggregation queries like `COUNT()`, `SUM()`, and `AVG()` directly on the server without having to transfer the documents to the client. This is especially useful for performing calculations efficiently over large collections.

FB4D supports both synchronous and asynchronous aggregation queries:
```pascal
/// Runs an asynchronous aggregation query (result via callback TOnAggregationResult)
procedure RunAggregationQuery(StructuredQuery: IStructuredQuery; const Aggregations: array of TAggregationField; OnResult: TOnAggregationResult; OnRequestError: TOnRequestError);

/// Runs a synchronous aggregation query and returns an IAggregationResult
function RunAggregationQuerySynchronous(StructuredQuery: IStructuredQuery; const Aggregations: array of TAggregationField): IAggregationResult;
```
> [!NOTE]
> `RunAggregationQuery` is accessible via `IFirestoreDatabase`. 

### Defining the Aggregations (`TAggregationField`)
You define one or more aggregations using the `TAggregationField` record. You can use its class factory functions:
* `TAggregationField.Count(const Alias: string = ''; CountUpTo: Int64 = 0)`
* `TAggregationField.Sum(const FieldPath: string; const Alias: string = '')`
* `TAggregationField.Avg(const FieldPath: string; const Alias: string = '')`

**Firestore limitations:** A single request may contain up to 5 aggregations.

### Querying the Result (`IAggregationResult`)

The `IAggregationResult` interface provides typed access to the result values returned by Firebase, addressed by their alias name.

```pascal
IAggregationResult = interface
  function GetCount(const Alias: string = 'field_1'): Int64;
  function GetDouble(const Alias: string): double;
  function GetInt64(const Alias: string): Int64;
  function HasField(const Alias: string): boolean;
  function ReadTime: TDateTime;
  function AliasNames: TArray<string>;
end;
```
> [!TIP]
> If you omitted the `Alias` string when defining your aggregation, Firestore automatically assigns consecutive aliases like `field_1`, `field_2`, etc.

### Example: Running a COUNT and SUM
```pascal
var
  Query: IStructuredQuery;
  AggResult: IAggregationResult;
begin
  Query := TStructuredQuery.CreateForCollection('invoices');
  
  AggResult := myFirestoreDb.RunAggregationQuerySynchronous(Query, [
    TAggregationField.Count('total_invoices'),
    TAggregationField.Sum('price', 'sum_price')
  ]);

  if Assigned(AggResult) then
  begin
    Writeln('Total count: ', AggResult.GetCount('total_invoices'));
    Writeln('Total sum: ', AggResult.GetDouble('sum_price'):0:2);
  end;
end;
```
