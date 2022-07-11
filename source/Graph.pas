unit Graph;

interface
uses
    System.Types
  , System.Math.Vectors
  , System.Generics.Collections
  ;

type
  TGraph  = class;
  TVertex = class;
  TEdge   = class;

  TVertexCircle   = class;
  TVertexPolygon  = class;
  TVertexRhomb    = class;


  TGraphType = (Directed, Undirected);

  TGraph = class
  private
    FGraphType: TGraphType;
    FVertices:  TList<TVertex>;
    FEdges:     TList<TEdge>;

    procedure DoOnNotifyEdges(Sender: TObject; const Item: TEdge; Action: TCollectionNotification);
  public
    constructor Create; overload;
    constructor Create(GraphType: TGraphType); overload;
    destructor Destroy; override;

    property GraphType: TGraphType read FGraphType;
    property Vertices: TList<TVertex> read FVertices;
    property Edges: TList<TEdge> read FEdges;
  end;


  ///Объект, поддерживающий нтерфесы без ARC
  TSupportInterface = class(TObject, IInterface)
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  TDataObject = class abstract(TSupportInterface)
  strict private
    FData: TDictionary<string, string>;

    function GetData(const DataName: string): string;
    procedure SetData(const DataName, Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    property Data[const DataName: string]: string read GetData write SetData;
  end;

  TVertex = class abstract(TDataObject)
  private
    FEdgesAsTo:   TList<TEdge>;
    FEdgesAsFrom: TList<TEdge>;

    FIsFixed: boolean;
    FIsPreFixed: boolean;
    FIsSelected: boolean;
    procedure SetIsFixed(const Value: boolean);
    procedure SetIsPreFixed(const Value: boolean);
  public
    Idx: integer;
    ///Координаты текущего положения Вершины
    Position: TPointF;
    ///Координаты предыдущего положения Вершины
    PositionPrev: TPointF;
    ///Координаты зафиксированного положения Вершины
    PositionFixed: TPointF;
    ///Вектор скорости Вершины
    Velocity: TPointF;
    ///Отображаемый текст
    Text: string;

    constructor Create;
    destructor Destroy; override;

    property IsPreFixed: boolean read FIsPreFixed write SetIsPreFixed;
    ///Указывает заблокировано ли положение Вершины
    property IsFixed: boolean read FIsFixed write SetIsFixed;
    property IsSelected: boolean read FIsSelected write FIsSelected;
    property Edges:       TList<TEdge> read FEdgesAsTo;
    property EdgesAsFrom: TList<TEdge> read FEdgesAsFrom;

    function RadiusCollide: single; virtual; abstract;
  end;

  TEdge = class(TDataObject)
  private
    FVertexFrom: TVertex;
    FVertexTo: TVertex;
  public
    Idx: integer;
    Text: string;
    constructor Create(VertexFrom, VertexTo: TVertex);
    destructor Destroy; override;

    property VertexFrom:  TVertex read FVertexFrom;
    property VertexTo:    TVertex read FVertexTo;
  end;

  IVertexCircle = interface
    ['{DEFE4953-3BAB-4DE2-926D-4E3B41C72A3E}']
    function GetRadius: single;
    procedure setRadius(Value: single);

    property Radius: single read GetRadius write SetRadius;
  end;

  TVertexCircle = class(TVertex, IVertexCircle)
  strict private
    FRadius: single;
    function GetProps: IVertexCircle;

    function GetRadius: single;
    procedure SetRadius(Value: single);
  public
    constructor Create; overload;
    constructor Create(Radius: single); overload;
    property Props: IVertexCircle read GetProps;

    function RadiusCollide: single; override;
  end;

   IVertexPolygon = interface
    ['{99A33EA3-10CB-47D1-87D9-A53FE43308B6}']
    function GetTemplatePolygon: TPolygon;
    procedure SetTemplatePolygon(Value: TPolygon);
    function GetPolygon: TPolygon;
    function GetRadius: single;

    property TemplatePolygon: TPolygon read GetTemplatePolygon write SetTemplatePolygon;
    property Polygon: TPolygon read GetPolygon;
    property Radius: single read GetRadius;
  end;

  TVertexPolygonBase = class abstract (TVertex, IVertexPolygon)
  strict private
    FTemplatePolygon: TPolygon;
  protected
    function GetTemplatePolygon: TPolygon;
    procedure SetTemplatePolygon(Value: TPolygon);
    function GetPolygon: TPolygon;
    function GetRadius: single;
  public
    constructor Create;

    function RadiusCollide: single; override;
  end;

  TVertexPolygon = class(TVertexPolygonBase)
  strict private
    function GetProps: IVertexPolygon;
  public
    property Props: IVertexPolygon read GetProps;
  end;

  IVertexRhomb = interface
  ['{CD4553FA-2500-4C4D-952F-6419404DD6E5}']
    function GetDiagonalH: single;
    procedure SetDiagonalH(Value: single);
    function GetDiagonalV: single;
    procedure SetDiagonalV(Value: single);

    property DiagonalH: single read GetDiagonalH write SetDiagonalH;
    property DiagonalV: single read GetDiagonalV write SetDiagonalV;
  end;

  TVertexRhomb = class(TVertexPolygon, IVertexRhomb)
  strict private
    function GetDiagonalH: single;
    procedure SetDiagonalH(Value: single);
    function GetDiagonalV: single;
    procedure SetDiagonalV(Value: single);

    function GetProps: IVertexRhomb;
  public
    constructor Create; overload;
    constructor Create(DiagonalH, DiagonalV: single); overload;
    property Props: IVertexRhomb read GetProps;
  end;

  IVertexRect = interface(IVertexPolygon)
  ['{28F1E480-141B-4EEF-B1B8-CF8B40460E3B}']
    function GetPolygon: TPolygon;
    function GetHeight: single;
    procedure SetHeight(Value: single);
    function GetWidth: single;
    procedure SetWidth(Value: single);

    property Height: single read GetHeight write SetHeight;
    property Width: single read GetWidth write SetWidth;
    property Polygon: TPolygon read GetPolygon;
  end;

  TVertexRect = class(TVertexPolygon, IVertexRect)
  strict private
    function GetHeight: single;
    procedure SetHeight(Value: single);
    function GetWidth: single;
    procedure SetWidth(Value: single);

    function GetProps: IVertexRect;
  public
    constructor Create; overload;
    constructor Create(Width, Height: single); overload;
    property Props: IVertexRect read GetProps;
  end;

implementation

uses
    System.SysUtils
  ;

function HighestPoint(const APoints: TPolygon): TPointF;
var
  i : Integer;
begin
  if Length(APoints) = 0 then Exit;
  Result := APoints[0];
  for i := 1 to Length(APoints) - 1 do
    if APoints[i].y > Result.y then
    Result := APoints[i];
end;

function LowestPoint(const APoints: TPolygon): TPointF;
var
  i : Integer;
begin
  if Length(APoints) = 0 then Exit;
  Result := APoints[0];
  for i := 1 to Length(APoints) - 1 do
    if APoints[i].y < Result.y then
      Result := APoints[i];
end;

function MostLeftPoint(const APoints: TPolygon): TPointF;
var
  i : Integer;
begin
  if Length(APoints) = 0 then Exit;
  Result := APoints[0];
  for i := 1 to Length(APoints) - 1 do
   if APoints[i].x < Result.x then
     Result := APoints[i];
end;

function MostRightPoint(const APoints: TPolygon): TPointF;
var
  i : Integer;
begin
  if Length(APoints) = 0 then Exit;
  Result := APoints[0];
  for i := 1 to Length(APoints) - 1 do
    if APoints[i].x > Result.x then
      Result := APoints[i];
end;


{ TVertex }

constructor TVertex.Create;
begin
  inherited Create;

  Idx           := -1;
  Position.X    := Single.NaN;
  Position.Y    := Single.NaN;
  Velocity.X    := Single.NaN;
  Velocity.Y    := Single.NaN;
  FEdgesAsTo    := TList<TEdge>.Create;
  FEdgesAsFrom  := TList<TEdge>.Create;
  FIsFixed      := false;
  FIsPreFixed   := false;
  FIsSelected   := false;
end;

destructor TVertex.Destroy;
begin
  FEdgesAsTo.Free;
  FEdgesAsFrom.Free;
  inherited;
end;


procedure TVertex.SetIsFixed(const Value: boolean);
begin
  FIsFixed := Value;
  PositionFixed := Position;
end;

procedure TVertex.SetIsPreFixed(const Value: boolean);
begin
  FIsPreFixed := Value;
  PositionFixed := Position;
end;

{ TGraph }

constructor TGraph.Create(GraphType: TGraphType);
begin
  FGraphType := GraphType;
  FVertices  := TObjectList<TVertex>.Create;
  FEdges     := TObjectList<TEdge>.Create;

  FEdges.OnNotify := DoOnNotifyEdges;
end;

constructor TGraph.Create;
begin
  Create(TGraphType.Undirected);
end;

destructor TGraph.Destroy;
begin
  FEdges.Free;
  FVertices.Free;
  inherited;
end;

procedure TGraph.DoOnNotifyEdges(Sender: TObject; const Item: TEdge;
  Action: TCollectionNotification);
begin
  if not FVertices.Contains(Item.VertexFrom) then
    FVertices.Add(Item.VertexFrom);
  if not FVertices.Contains(Item.VertexTo) then
    FVertices.Add(Item.VertexTo);

  case Action of
    cnAdded:      begin
                    Item.VertexFrom.Edges.Add(Item);
                    Item.VertexTo.EdgesAsFrom.Add(Item);
                  end;
    cnExtracted,
    cnDeleting,
    cnRemoved:    begin
                    Item.VertexFrom.Edges.Remove(Item);
                    Item.VertexTo.EdgesAsFrom.Remove(Item);
                  end;
  end;
end;

{ TEdge }

constructor TEdge.Create(VertexFrom, VertexTo: TVertex);
begin
  Assert(VertexFrom <> nil, 'VertexFrom не может быть пустым.');
  Assert(VertexTo   <> nil, 'VertexTo не может быть пустым.');

  inherited Create;

  FVertexFrom := VertexFrom;
  FVertexTo   := VertexTo;
end;

destructor TEdge.Destroy;
begin
  FVertexFrom := nil;
  FVertexTo   := nil;

  inherited;
end;

{ TDataObject }

constructor TDataObject.Create;
begin
  FData := TDictionary<string, string>.Create;
end;

destructor TDataObject.Destroy;
begin
  FData.Free;
  inherited;
end;

function TDataObject.GetData(const DataName: string): string;
begin
  if not FData.TryGetValue(DataName, result) then
    result := string.Empty;
end;

procedure TDataObject.SetData(const DataName, Value: string);
begin
  FData.AddOrSetValue(DataName, Value);
end;

{ TVertexCircle }

constructor TVertexCircle.Create;
begin
  Create(30);
end;

constructor TVertexCircle.Create(Radius: single);
begin
  inherited Create;
  FRadius := Radius;
end;

function TVertexCircle.GetProps: IVertexCircle;
begin
  result := self;
end;

function TVertexCircle.GetRadius: single;
begin
  result := FRadius;
end;

function TVertexCircle.RadiusCollide: single;
begin
  result := FRadius + 5;
end;

procedure TVertexCircle.SetRadius(Value: single);
begin
  assert(Value > 0, 'Value must be greater than zero.');
  FRadius := Value;
end;

{ TVertexPolygon }

function TVertexPolygon.GetProps: IVertexPolygon;
begin
  result := self;
end;

{ TVertexPolygonBase }

constructor TVertexPolygonBase.Create;
begin
  inherited Create;
  FTemplatePolygon := [];
end;

function TVertexPolygonBase.GetPolygon: TPolygon;
begin
  for var P in FTemplatePolygon do
    result := result + [P + Self.Position];
end;

function TVertexPolygonBase.GetRadius: single;
  function GetPolygonRect(Polygon: TPolygon): TRectF;
  begin
    var LPoint := MostLeftPoint(Polygon);
    var RPoint := MostRightPoint(Polygon);
    var UPoint := HighestPoint(Polygon);
    var DPoint := LowestPoint(Polygon);


    var TopLeft     := TPointF.Create(LPoint.X, DPoint.Y);
    var BottomRight := TPointF.Create(RPoint.X, UPoint.Y);

    result := TRectF.Create(TopLeft, BottomRight);
  end;
begin
  var Rect := GetPolygonRect(FTemplatePolygon);

  result := sqrt(sqr(Rect.Width) + sqr(Rect.Height));
end;

function TVertexPolygonBase.GetTemplatePolygon: TPolygon;
begin
  result := FTemplatePolygon;
end;

function TVertexPolygonBase.RadiusCollide: single;
begin
  result := GetRadius;
end;

procedure TVertexPolygonBase.SetTemplatePolygon(Value: TPolygon);
begin
  FTemplatePolygon := value;
end;

{ TVertexRhomb }

constructor TVertexRhomb.Create;
begin
  Create(30,30);
end;

constructor TVertexRhomb.Create(DiagonalH, DiagonalV: single);
begin
  inherited Create;
  SetTemplatePolygon([TPointF.Create(0,-DiagonalV/2), TPointF.Create(DiagonalH/2,0), TPointF.Create(0,DiagonalV/2), TPointF.Create(-DiagonalH/2,0)]);
end;

function TVertexRhomb.GetDiagonalH: single;
begin
  var Pgon := GetTemplatePolygon;
  result := Pgon[3].Distance(Pgon[1]);
end;

function TVertexRhomb.GetDiagonalV: single;
begin
  var Pgon := GetTemplatePolygon;
  result := Pgon[0].Distance(Pgon[2]);
end;

function TVertexRhomb.GetProps: IVertexRhomb;
begin
  result := Self;
end;

procedure TVertexRhomb.SetDiagonalH(Value: single);
begin
  var Pgon := GetTemplatePolygon;
  SetTemplatePolygon([Pgon[0], TPointF.Create(Value/2, 0), Pgon[2], TPointF.Create(-(Value/2),0)]);
end;

procedure TVertexRhomb.SetDiagonalV(Value: single);
begin
  var Pgon := GetTemplatePolygon;
  SetTemplatePolygon([TPointF.Create(0,-(Value/2)), Pgon[1], TPointF.Create(0,Value/2), Pgon[3]]);
end;

{ TVertexRect }

constructor TVertexRect.Create;
begin
  Create(30,30);
end;

constructor TVertexRect.Create(Width, Height: single);
begin
  inherited Create;
  SetTemplatePolygon([TPointF.Create(-Width/2,-Width/2), TPointF.Create(Width/2,-Width/2), TPointF.Create(Width/2,Width/2), TPointF.Create(-Width/2,Width/2)]);
end;

function TVertexRect.GetHeight: single;
begin
  var Pgon := GetTemplatePolygon;
  result := Pgon[0].Distance(Pgon[1]);
end;

function TVertexRect.GetProps: IVertexRect;
begin
  result := self;
end;

function TVertexRect.GetWidth: single;
begin
  var Pgon := GetTemplatePolygon;
  result := Pgon[0].Distance(Pgon[3]);
end;

procedure TVertexRect.SetHeight(Value: single);
begin
  var Pgon := GetTemplatePolygon;
  SetTemplatePolygon([TPointF.Create(Pgon[0].X, -(Value/2)), TPointF.Create(Pgon[1].X, -(Value/2)),
                      TPointF.Create(Pgon[2].X, Value/2),       TPointF.Create(Pgon[3].X,Value/2)]);
end;

procedure TVertexRect.SetWidth(Value: single);
begin
  var Pgon := GetTemplatePolygon;
  SetTemplatePolygon([TPointF.Create(-(Value/2), Pgon[0].Y), TPointF.Create(Value/2, Pgon[1].Y),
                      TPointF.Create(Value/2, Pgon[2].Y),    TPointF.Create(-(Value/2),Pgon[3].Y)]);
end;

{ TVertexSupportInterface }

function TSupportInterface.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TSupportInterface._AddRef: Integer;
begin
  result := -1;
end;

function TSupportInterface._Release: Integer;
begin
  result := -1;
end;

end.
