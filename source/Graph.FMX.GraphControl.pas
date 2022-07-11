unit Graph.FMX.GraphControl;

interface
uses
    System.Types
  , System.Classes
  , System.UITypes
  , System.SysUtils
  , System.Generics.Collections
  , System.Math.Vectors
  , System.Diagnostics
  , FMX.Controls
  , FMX.Graphics
  , FMX.Layouts
  , FMX.Types
  , FMX.Forms
  , Graph
  , Graph.Simulation
  , Graph.Simulation.Forces
  , Common.Generics.QuadTree
  ;

type
  TGraphControl = class;
  TGraphicSettings = class;

  TCoordOrigin = (CoordControl, CoordCenter);

  TOnDrawEdge         = procedure(const Edge: TEdge; const ACanvas: TCanvas; GraphicSettings: TGraphicSettings; var Handled: boolean) of object;
  TOnDrawVertex       = procedure(const Vertex: TVertex; const ACanvas: TCanvas; GraphicSettings: TGraphicSettings; var Handled: boolean) of object;
  TVertexEvent            = procedure(const Vertex: TVertex) of object;
  TVertexMouseEvent       = procedure(const Vertex: TVertex; Button: TMouseButton; Shift: TShiftState; X, Y: single) of object;
  TVertexMouseMoveEvent   = procedure(const Vertex: TVertex; Shift: TShiftState; X, Y: single; IsPressed: boolean) of object;
  TVertexMouseWheelEvent  = procedure(const Vertex: TVertex; Shift: TShiftState; WheelDelta: Integer) of object;
  TGraphControl = class(TControl)
  private
    FScrolBox: TScrollBox;
    FContent:  TScaledLayout;
    FCoordOrigin: TCoordOrigin;
    FOffsetCenter: TPointF;

    FGraph: TGraph;
    FSimulation: TGraphSimulation;

    FSettingsVertex:          TGraphicSettings;
    FSettingsVertexSelected:  TGraphicSettings;
    FSettingsEdge:            TGraphicSettings;

    FRadiusFind: single;
    FOnSimulation: TGraphSimulationEvent;

    FOnDrawEdge:    TOnDrawEdge;
    FOnDrawVertex:  TOnDrawVertex;

    FOnVertexMouseUp:     TVertexMouseEvent;
    FOnVertexMouseDown:   TVertexMouseEvent;
    FOnVertexMouseMove:   TVertexMouseMoveEvent;
    FOnVertexMouseWheel:  TVertexMouseWheelEvent;
    FOnVertexClick:       TVertexEvent;
    FOnVertexDblClick:    TVertexEvent;

    FVertexUnderMouse: TVertex;
    FVertexMoved: boolean;

    FIsDblClick: boolean;

    procedure DoOnSimulation(Event: TSimulationEvent);

    procedure SetGraph(const Value: TGraph);
    procedure SetCoordOrigin(const Value: TCoordOrigin);
    procedure SetSettingsEdge(const Value: TGraphicSettings);
    procedure SetSettingsVertex(const Value: TGraphicSettings);
    procedure SetSettingsVertexSelected(const Value: TGraphicSettings);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;

    procedure DoVertexMouseUp(const Vertex: TVertex; Button: TMouseButton; Shift: TShiftState; X,Y: single);
    procedure DoVertexMouseDown(const Vertex: TVertex; Button: TMouseButton; Shift: TShiftState; X,Y: single);
    procedure DoVertexMouseMove(const Vertex: TVertex; Shift: TShiftState; X,Y: single; IsPressed: boolean);
    procedure DoVertexMouseWheel(const Vertex: TVertex; Shift: TShiftState; WheelDelta: Integer);
    procedure DoVertexClick(const Vertex: TVertex);
    procedure DoVertexDblClick(const Vertex: TVertex);
  protected
    procedure DoContentResized(Sender: TObject);
    procedure DoCalcContentBounds(Sender: TObject; var ContentBounds: TRectF);

    procedure PaintContent(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure DrawEdge(const Edge: TEdge; const ACanvas: TCanvas); virtual;
    procedure DrawVertex(Vertex: TVertex; ACanvas: TCanvas); virtual;

    procedure DrawVertexCircle(const Vertex: TVertex; const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
    procedure DrawVertexPolygon(const Vertex: TVertex; const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
    procedure DrawVertexText(const Vertex: TVertex; const ACanvas: TCanvas; TextSettings: TTextSettings);

    procedure DrawEdgeLine(const Edge: TEdge; const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
    procedure DrawEdgeArc(const Edge: TEdge; const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
    procedure DrawEdgeText(const Edge: TEdge; const ACanvas: TCanvas; TextSettings: TTextSettings);

    procedure DrawRotatedText(ACanvas: TCanvas; const P: TPointF; DegAngle: single; const Text: string; TextSettings: TTextSettings);

    procedure DrawArrow(P1, P2: TPointF; Size: Single; ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
  protected
    procedure SetVertexUnderMouse(ContentMousePosition: TPointF);
    procedure MoveVertexUnderMouse(NewPosition: TPointF);
    procedure AfterMoveVertexUnderMouse(Shift: TShiftState);
    procedure PreFixedVertexUnderMouse;
    procedure FixedVertexUnderMouse;
    procedure SelectVertexUnderMouse;

    procedure ScaleContent(WheelDelta: single);
    procedure MoveContent(LocalMousePosition: TPointF);

    procedure CalcGraphRect(Vertices: TEnumerable<TVertex>; out Rect: TRectF; IsInfinity: boolean = true);

    function PointContent(LocalPoint: TPointF): TPointF;
  protected
    //Утилиты
    const PI2       =  6.283185307179586476925286766559000;
    const PIDiv180  =  0.017453292519943295769236907684886;
    const _180DivPI = 57.295779513082320876798154814105000;

    const Clockwise            = -1;
    const CounterClockwise     = +1;

    procedure GetLineEdge(const Edge: TEdge; out P1,P2: TPointF; out IsBidi: boolean);
    procedure ClipLineEdge(const Edge: TEdge; out P1, P2: TPointF);
    procedure ClipLineCircle(CenterPoint: TPointF; Radius: Single; var P1, P2: TPointF);
    procedure ClipLinePolygon(Polygon: TPolygon; var P1, P2: TPointF);

    procedure GetParallelLine(Offset: single; P1,P2: TPointF; out L1,L2: TPointF);

    function Centroid(P1, P2: TPointF): TPointF;
    function VertexAngle(x1,y1,x2,y2,x3,y3: double): double;
    function OrientedVertexAngle(const P1,P2,P3: TPointF; const Orient : Integer = Clockwise): double;

    function MinPoint(const Point1,Point2: TPointF): TPointF;
    function MaxPoint(const Point1,Point2: TPointF): TPointF;
    function ProjectPoint(const Src, Dst: TPointF; Dist: double): TPointF;

    function IsEqual(const Val1,Val2: double):Boolean;
    function NotEqual(const Val1,Val2: double):Boolean;
    function Orientation(const P1,P2,P: TPointF): Integer;
    function IntersectionPoint(const P1, P2, P3, P4: TPointF): TPointF;
    procedure InflatePolygon(var Polygon: TPolygon; Delta: single);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    ///<summary>
    /// Исходный граф, который будет отображаться.
    ///</summary>
    property Graph: TGraph read FGraph write SetGraph;

    ///<summary>
    /// Класс симуляции графа.
    ///</summary>
    property Simulation: TGraphSimulation read FSimulation;

    ///<summary>
    /// Начало координат.
    ///</summary>
    property CoordinateOrigin: TCoordOrigin read FCoordOrigin write SetCoordOrigin;

    ///<summary>
    /// Настройки отрисовки вершины
    ///</summary>
    property SettingsVertex: TGraphicSettings read FSettingsVertex write SetSettingsVertex;
    ///<summary>
    /// Настройки отрисовки выбранной вершины
    ///</summary>
    property SettingsVertexSelected: TGraphicSettings read FSettingsVertexSelected write SetSettingsVertexSelected;

    ///<summary>
    /// Настройки отрисовки ребра
    ///</summary>
    property SettingsEdge: TGraphicSettings read FSettingsEdge write SetSettingsEdge;

    ///<summary>
    /// Радиус нахождения вершины относительно позиции мышки.
    ///</summary>
    property RadiusFind: single read FRadiusFind write FRadiusFind;

    property OnSimulation: TGraphSimulationEvent read FOnSimulation write FOnSimulation;

    property OnDrawEdge:    TOnDrawEdge read FOnDrawEdge write FOnDrawEdge;
    property OnDrawVertex:  TOnDrawVertex read FOnDrawVertex write FOnDrawVertex;

    property OnVertexMouseUp:     TVertexMouseEvent read FOnVertexMouseUp write FOnVertexMouseUp;
    property OnVertexMouseDown:   TVertexMouseEvent read FOnVertexMouseDown write FOnVertexMouseDown;
    property OnVertexMouseMove:   TVertexMouseMoveEvent read FOnVertexMouseMove write FOnVertexMouseMove;
    property OnVertexMouseWheel:  TVertexMouseWheelEvent read FOnVertexMouseWheel write FOnVertexMouseWheel;
    property OnVertexClick:       TVertexEvent read FOnVertexClick write FOnVertexClick;
    property OnVertexDblClick:    TVertexEvent read FOnVertexDblClick write FOnVertexDblClick;
  end;

  TGraphicSettings = class(TPersistent)
  private
    FFill:    TBrush;
    FStroke:  TStrokeBrush;
    FText:    TTextSettings;
    procedure SetFill(const Value: TBrush);
    procedure SetStroke(const Value: TStrokeBrush);
    procedure SetText(const Value: TTextSettings);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    property Fill: TBrush read FFill write SetFill;
    property Stroke: TStrokeBrush read FStroke write SetStroke;
    property Text: TTextSettings read FText write SetText;
  end;

implementation

uses
    System.Math
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

{ TFMXGraph }

procedure TGraphControl.AfterMoveVertexUnderMouse(Shift: TShiftState);
begin
  if assigned(FVertexUnderMouse) then begin
    if not (ssAlt in Shift) and assigned(FVertexUnderMouse)
      then FVertexUnderMouse.IsFixed := false
      else FVertexUnderMouse.IsFixed := true;

    FSimulation.Alpha := 1;
    FSimulation.Restart;

    FVertexMoved := false;
  end;
end;

procedure TGraphControl.CalcGraphRect(Vertices: TEnumerable<TVertex>; out Rect: TRectF; IsInfinity: boolean);
begin
  if IsInfinity then begin
    Rect.Left   :=  Infinity;
    Rect.Top    :=  Infinity;
    Rect.Right  := -Infinity;
    Rect.Bottom := -Infinity;
  end;

  for var Vertex in Vertices do begin
    Rect.Left   := min(Rect.Left,   Vertex.Position.X + Vertex.Velocity.X);
    Rect.Top    := min(Rect.Top,    Vertex.Position.Y + Vertex.Velocity.Y);
    Rect.Right  := max(Rect.Right,  Vertex.Position.X + Vertex.Velocity.X);
    Rect.Bottom := max(Rect.Bottom, Vertex.Position.Y + Vertex.Velocity.Y);
  end;
end;

function TGraphControl.Centroid(P1, P2: TPointF): TPointF;
begin
  result := P1 + P2 * 0.5;
end;

procedure TGraphControl.ClipLineCircle(CenterPoint: TPointF; Radius: Single; var P1, P2: TPointF);

  function FindLineCircleIntersections(CenterPoint: TPointF; Radius: single; AP1, AP2: TPointF; out IP1, IP2: TPointF): integer;
  begin
    var d := AP2 - AP1;
    var A := sqr(d.X) + sqr(d.Y);
    var B := 2 * (d.X * (AP1.X - CenterPoint.X) + d.Y * (AP1.Y - CenterPoint.Y));
    var C := sqr(AP1.X - CenterPoint.X) + sqr(AP1.Y - CenterPoint.Y) - sqr(Radius);

    var det := sqr(B) - 4 * A * C;
    if (A <= 0.0000001) or (det < 0) then begin
      // No real solutions.
      IP1 := TPointF.Create(NaN, Nan);
      result := 0;
    end else
    if det = 0 then begin
      // One solution.
      var t := -B / (2*A);
      IP1 := AP1 + t * d;
      IP2 := TPointF.Create(NaN, NaN);
      result := 1;
    end else begin
      //Two Solutions.
      var t := (-B + sqrt(det)) / (2*A);
      IP1 := AP1 + t * d;

      t := (-B - sqrt(det)) / (2*A);
      IP2 := AP1 + t * d;
      result := 2;
    end;

  end;

begin
  var IP1 := TPointF.Zero;
  var IP2 := TPointF.Zero;
  var Intersections := FindLineCircleIntersections(CenterPoint, Radius, P1, P2, IP1, IP2);

  var P := TPointF.Zero;
  if Intersections = 1 then begin
    P := IP1;
  end else begin
    var dist1 := IP1.Distance(P1);
    var dist2 := IP2.Distance(P1);
    if dist1 < dist2
      then P := IP1
      else P := IP2;
  end;
  P2 := P;
end;

procedure TGraphControl.ClipLinePolygon(Polygon: TPolygon; var P1,
  P2: TPointF);

  function Orientation(const P1, P2, P: TPointF): Integer;
  var
    Orin : double;
  begin
    (* Determinant of the 3 points *)
    Orin := (P2.X - P1.X) * (P.Y - P1.Y) - (P.X - P1.X) * (P2.Y - P1.Y);

    if Orin > 0.0 then
      Result := -1          (* Orientaion is to the left-hand side  *)
    else if Orin < 0.0 then
      Result := 1           (* Orientaion is to the right-hand side *)
    else
      Result := 0;          (* Orientaion is neutral aka collinear  *)
  end;

  function SimpleIntersect(const P1, P2, P3, P4: TPointF): Boolean;
  begin
    Result := (
               ((Orientation(P1,P2,P3) * Orientation(P1,P2,P4)) <= 0) and
               ((Orientation(P3,P4,P1) * Orientation(P3,P4,P2)) <= 0)
              );
  end;

  procedure IntersectionPoint(const P1, P2, L1, L2: TPointF; out AResult: TPointF);
  var
    Ratio : double;
    dx1   : double;
    dx2   : double;
    dx3   : double;
    dy1   : double;
    dy2   : double;
    dy3   : double;
  begin
    dx1 := P2.X - P1.X;
    dx2 := L2.X - L1.X;
    dx3 := P1.X - L1.X;

    dy1 := P2.Y - P1.Y;
    dy2 := P1.Y - L1.Y;
    dy3 := L2.Y - L1.Y;

    Ratio := dx1 * dy3 - dy1 * dx2;

    if NotEqual(Ratio, 0.0) then
    begin
      Ratio := (dy2 * dx2 - dx3 * dy3) / Ratio;
      AResult.X := P1.X + Ratio * dx1;
      AResult.Y := P1.Y + Ratio * dy1;
    end
    else
    begin
      //if Collinear(x1,y1,x2,y2,x3,y3) then
      if IsEqual((dx1 * -dy2),(-dx3 * dy1)) then
      begin
        AResult := L1;
      end
      else
      begin
        AResult := L2;
      end;
    end;
  end;

begin
  assert(Length(Polygon) > 2, 'This is not Polygon.');

  for var I := 0 to Length(Polygon)-2 do begin
    if not SimpleIntersect(P1, P2, Polygon[I], Polygon[I+1]) then continue;
    IntersectionPoint(P1, P2, Polygon[I], Polygon[I+1], P2);
  end;

    if not SimpleIntersect(P1, P2, Polygon[High(Polygon)], Polygon[0]) then exit;
    IntersectionPoint(P1, P2, Polygon[High(Polygon)], Polygon[0], P2);
end;

constructor TGraphControl.Create(AOwner: TComponent);
begin
  inherited;
  FGraph      := nil;
  FSimulation := TGraphSimulation.Create;
  FSimulation.OnEvent := DoOnSimulation;

  FVertexUnderMouse := nil;

  FSettingsVertex         := TGraphicSettings.Create;
  FSettingsVertexSelected := TGraphicSettings.Create;
  FSettingsEdge           := TGraphicSettings.Create;

  with FSettingsVertex do begin
    Fill.Kind     := TBrushKind.Solid;
    Fill.Color    := TAlphaColors.White;
    Stroke.Kind   := TBrushKind.Solid;
    Stroke.Color  := TAlphaColors.Red;
    Stroke.Thickness := 2;

    Text.HorzAlign := TTextAlign.Center;
    Text.VertAlign := TTextAlign.Center;
    Text.Font.Size := 11;
    Text.WordWrap  := true;
  end;

  with FSettingsVertexSelected do begin
    Fill.Kind     := TBrushKind.Solid;
    Fill.Color    := TAlphaColors.Khaki;
    Stroke.Kind   := TBrushKind.Solid;
    Stroke.Color  := TAlphaColors.Red;

    Text.HorzAlign := TTextAlign.Center;
    Text.VertAlign := TTextAlign.Center;
    Text.Font.Size := 11;
    Text.WordWrap  := true;
  end;

  with FSettingsEdge do begin
    Fill.Kind     := TBrushKind.Solid;
    Fill.Color    := TAlphaColors.Black;
    Stroke.Kind   := TBrushKind.Solid;
    Stroke.Color  := TAlphaColors.Black;

    Text.HorzAlign := TTextAlign.Center;
    Text.VertAlign := TTextAlign.Center;
    Text.Font.Size := 11;
    Text.WordWrap  := true;
  end;

  FRadiusFind     := 30;
  FVertexMoved    := false;

  FScrolBox         := TScrollBox.Create(self);
  FScrolBox.Parent  := self;
  FScrolBox.Align   := TAlignLayout.Client;
  FScrolBox.HitTest := false;
  FScrolBox.OnCalcContentBounds := DoCalcContentBounds;

  FContent            := TScaledLayout.Create(self);
  FContent.Parent     := FScrolBox.Content;
  FContent.Size.Size  := TSizeF.Create(100,100);
  FContent.OnPaint    := PaintContent;
  FContent.OnResized  := DoContentResized;
  FContent.HitTest    := false;

  CoordinateOrigin    := TCoordOrigin.CoordCenter;
  FIsDblClick         := false;
end;

destructor TGraphControl.Destroy;
begin
  FSimulation.Free;
  FGraph := nil;

  FSettingsVertex.Free;
  FSettingsVertexSelected.Free;
  FSettingsEdge.Free;
  inherited;
end;

procedure TGraphControl.DoContentResized(Sender: TObject);
begin
  if FCoordOrigin = TCoordOrigin.CoordControl
    then FOffsetCenter := TPointF.Zero
    else FOffsetCenter := FContent.LocalRect.CenterPoint;
end;

procedure TGraphControl.DoVertexClick(const Vertex: TVertex);
begin
  if assigned(FOnVertexClick) then
    FOnVertexClick(Vertex);
end;

procedure TGraphControl.DoVertexDblClick(const Vertex: TVertex);
begin
  if assigned(FOnVertexDblClick) then
    FOnVertexDblClick(Vertex);
end;

procedure TGraphControl.DoVertexMouseDown(const Vertex: TVertex;
  Button: TMouseButton; Shift: TShiftState; X,Y: single);
begin
  if assigned(FOnVertexMouseDown) then
    FOnVertexMouseDown(Vertex, Button, Shift, X, Y);
end;

procedure TGraphControl.DoVertexMouseMove(const Vertex: TVertex;
  Shift: TShiftState; X, Y: single; IsPressed: boolean);
begin
  if assigned(FOnVertexMouseMove) then
    FOnVertexMouseMove(Vertex, Shift, X, Y, IsPressed);
end;

procedure TGraphControl.DoVertexMouseUp(const Vertex: TVertex;
  Button: TMouseButton; Shift: TShiftState; X,Y: single);
begin
  if assigned(FOnVertexMouseUp) then
    FOnVertexMouseUp(Vertex, Button, Shift, X, Y);
end;

procedure TGraphControl.DoVertexMouseWheel(const Vertex: TVertex;
  Shift: TShiftState; WheelDelta: Integer);
begin
  if assigned(FOnVertexMouseWheel) then
    FOnVertexMouseWheel(Vertex, Shift, WheelDelta);
end;

procedure TGraphControl.DoCalcContentBounds(Sender: TObject;
  var ContentBounds: TRectF);
begin
  if (Graph = nil) or (Graph.Vertices.Count = 0) then exit;

  ContentBounds.Width  := FContent.ChildrenRect.Width;
  ContentBounds.Height := FContent.ChildrenRect.Height;
end;

procedure TGraphControl.PaintContent(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);

  {$REGION 'Paint QuadTree'}

  procedure DrawQuadTree;
  begin
    var Rect := TRectF.Empty;
    CalcGraphRect(FGraph.Vertices, Rect);

    var QT := TQuadTree<TVertex>.Create(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    try
      for var Vertex in FGraph.Vertices do begin
        var p := Vertex.Position;
        if p.X.IsNan or p.Y.IsNan then continue;

        QT.SetValue(p.X, p.Y, Vertex);
      end;

      Canvas.Stroke.Color     := TAlphaColors.Lime;
      Canvas.Stroke.Thickness := 1;
      Canvas.Stroke.Kind      := TBrushKind.Solid;

      QT.Visit(QT.RootNode,
        function(QuadTree: TQuadTree<TVertex>; Node: TNode<TVertex>): boolean
        begin
          Canvas.DrawRect(TRectF.Create(TPointF.Create(Node.X, Node.Y), Node.W, Node.H), 1);
          result := false;
        end
      )

    finally
      QT.Free;
    end;
  end;

  {$ENDREGION}

begin
//  Canvas.ClearRect(ARect, TAlphaColors.Aquamarine);
  if FGraph = nil then exit;

  var SaveMatrix := Canvas.Matrix;
  var Matrix := TMatrix.CreateTranslation(FOffsetCenter.X, FOffsetCenter.Y);
  Canvas.MultiplyMatrix(Matrix);

  for var Edge in FGraph.Edges do
    DrawEdge(Edge, Canvas);

  for var Vertex in FGraph.Vertices do
    DrawVertex(Vertex, Canvas);

  Canvas.SetMatrix(SaveMatrix);

  //Отображение Квадратного дерева - для наглядности и отладки
//  DrawQuadTree;
end;

function TGraphControl.PointContent(LocalPoint: TPointF): TPointF;
begin
  result := FContent.AbsoluteToLocal(LocalToAbsolute(LocalPoint)) - FOffsetCenter;
end;

procedure TGraphControl.DrawArrow(P1, P2: TPointF; Size: Single; ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
begin
  var Angle := 180*ArcTan2(p2.y-p1.y,p2.x-p1.x)/pi;
  var P3 := TPointF.Create(P2.X+(Size*cos(pi*(Angle+150)/180)), P2.y+(Size*sin(pi*(Angle+150)/180)));
  var P4 := TPointF.Create(P2.X+(Size*cos(pi*(Angle-150)/180)), P2.y+(Size*sin(pi*(Angle-150)/180)));


  var SavedFill   := TBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  var SavedStroke := TStrokeBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  SavedFill.Assign(ACanvas.Fill);
  SavedStroke.Assign(ACanvas.Stroke);
  try
    ACanvas.Fill.Assign(Fill);
    ACanvas.Stroke.Assign(Stroke);

    ACanvas.FillPolygon([P2, P3, P4], 1);
    ACanvas.DrawPolygon([P2, P3, P4], 1);
  finally
    ACanvas.Fill.Assign(SavedFill);
    ACanvas.Stroke.Assign(SavedStroke);
    FreeAndNil(SavedFill);
    FreeAndNil(SavedStroke);
  end;
end;

procedure TGraphControl.DrawEdge(const Edge: TEdge; const ACanvas: TCanvas);
begin
  var LSettings := TGraphicSettings.Create;
  try
    LSettings.Assign(FSettingsEdge);

    var IsHandled := false;
    if assigned(FOnDrawEdge) then begin
      FOnDrawEdge(Edge, ACanvas, LSettings, IsHandled);
      if IsHandled then exit;
    end;

    DrawEdgeLine(Edge, ACanvas, LSettings.Fill, LSettings.Stroke);
    DrawEdgeText(Edge, ACanvas, LSettings.Text);
  finally
    FreeAndNil(LSettings);
  end;
end;

procedure TGraphControl.DrawEdgeArc(const Edge: TEdge; const ACanvas: TCanvas;
  Fill: TBrush; Stroke: TStrokeBrush);
begin
{ TODO : Отображение ребра как дуги }
//  var P1 := Edge.VertexFrom.Position;
//  var P2 := Edge.VertexTo.Position;
//  ClipLineEdge(Edge, P1, P2);
//  var CenterPoint := Centroid(P1, P2);
//  var AP := CenterPoint + TPointF.Create(10, 0);
//  var StartAngle := OrientedVertexAngle(AP, CenterPoint, P1);
//  var SweepAngle := OrientedVertexAngle(AP, CenterPoint, P2);
//
//  var SavedStroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Alpha);
//  SavedStroke.Assign(ACanvas.Stroke);
//  try
//    ACanvas.Stroke.Assign(FEdgeStroke);
//    ACanvas.DrawArc(CenterPoint, TPointF.Create(P1.Distance(P2)/2, P1.Distance(P2)/2), StartAngle, SweepAngle, 1);
//    if FGraph.GraphType = TGraphType.Directed then
//      DrawArrow(P1, P2, 10, ACanvas, Fill, Stroke);
//  finally
//    ACanvas.Stroke.Assign(SavedStroke);
//    FreeAndNil(SavedStroke);
//  end;
end;

procedure TGraphControl.DrawEdgeLine(const Edge: TEdge;
  const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
const ArrowSize = 8;
begin
  var P1, P2: TPointF;
  var IsBidi := false;
  GetLineEdge(Edge, P1, P2, IsBidi);

  var SavedStroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Alpha);
  SavedStroke.Assign(ACanvas.Stroke);
  try
    ACanvas.Stroke.Assign(Stroke);

    if FGraph.GraphType = TGraphType.Directed then begin
      // Направленное ребро рисуется со стрелкой от P1 в P2.
      // Чтобы стрелка имела острый наконечник - нужно саму линию рисовать чуть короче со стороны P2.
      var P2Arrow := ProjectPoint(P1, P2, P1.Distance(P2) - ArrowSize/2);

      //А чтобы начало линии было обрезано вершиной - удлиняем со стороны P1.
      P1 := ProjectPoint(P1, P2, -1);

      ACanvas.DrawLine(P1, P2Arrow, 1);

      //Магическая корректировка расположения стрелки, чобы как можно точнее была к границам вершины.
      if IsBidi and Supports(Edge.VertexTo, IVertexCircle)
        then P2 := ProjectPoint(P1, P2, P1.Distance(P2)-0.5)
        else P2 := ProjectPoint(P1, P2, P1.Distance(P2)-1);

      DrawArrow(P1, P2, ArrowSize, ACanvas, Fill, Stroke);
    end else begin
      ACanvas.DrawLine(P1, P2, 1);
    end;
  finally
    ACanvas.Stroke.Assign(SavedStroke);
    FreeAndNil(SavedStroke);
  end;
end;

procedure TGraphControl.DrawEdgeText(const Edge: TEdge; const ACanvas: TCanvas;
  TextSettings: TTextSettings);
begin
  if Edge.Text.Trim.IsEmpty then exit;

  var P1, P2: TPointF;
  var IsBidi := false;
  GetLineEdge(Edge, P1, P2, IsBidi);
  GetParallelLine(-10, P1, P2, P1, P2);
  var Angle := OrientedVertexAngle(TPointF.Create(P2.X, P1.Y), P1, P2, CounterClockwise);

  var LineWidth := P1.Distance(P2);
  var Offset := (LineWidth / 2);

  var P := ProjectPoint(MinPoint(P1, P2), MaxPoint(P1, P2), Offset);

  DrawRotatedText(ACanvas, P, Angle, Edge.Text, TextSettings);
end;

procedure TGraphControl.DrawRotatedText(ACanvas: TCanvas; const P: TPointF;
  DegAngle: single; const Text: string; TextSettings: TTextSettings);
var
  R: TRectF;
  SaveMatrix: TMatrix;
  Matrix: TMatrix;
begin
  var SavedFont := TFont.Create;
  var SavedFill := TBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  SavedFont.Assign(ACanvas.Font);
  SavedFill.Assign(ACanvas.Fill);
  try
    Canvas.Font.Assign(TextSettings.Font);
    Canvas.Fill.Color := TextSettings.FontColor;
    Canvas.Fill.Kind  := TBrushKind.Solid;

    //Текст центрируется относительно точки P.
    var W := ACanvas.TextWidth(Text);
    var H := ACanvas.TextHeight(Text);
    case TextSettings.HorzAlign of
      TTextAlign.Center:   R.Left := -W / 2;
      TTextAlign.Leading:  R.Left := 0;
      TTextAlign.Trailing: R.Left := -W;
    end;
    R.Width := W;
    case TextSettings.VertAlign of
      TTextAlign.Center:   R.Top := -H / 2;
      TTextAlign.Leading:  R.Top := 0;
      TTextAlign.Trailing: R.Top := -H;
    end;
    R.Height := H;

    SaveMatrix := Canvas.Matrix;

    Matrix := TMatrix.CreateRotation(DegToRad(DegAngle));
    Matrix.m31 := P.X;
    Matrix.m32 := P.Y;
    ACanvas.MultiplyMatrix(Matrix);
    ACanvas.FillText(R, Text, False, 1, [], TextSettings.HorzAlign, TextSettings.VertAlign);
    ACanvas.SetMatrix(SaveMatrix);

  finally
    ACanvas.Font.Assign(SavedFont);
    ACanvas.Fill.Assign(SavedFill);
    FreeAndNil(SavedFont);
    FreeAndNil(SavedFill);
  end;
end;

procedure TGraphControl.DrawVertex(Vertex: TVertex; ACanvas: TCanvas);
begin
  var LSettings := TGraphicSettings.Create;
  try
    if Vertex.IsSelected
      then LSettings.Assign(FSettingsVertexSelected)
      else LSettings.Assign(FSettingsVertex);

    var IsHandled := false;
    if assigned(FOnDrawVertex) then begin
      FOnDrawVertex(Vertex, ACanvas, LSettings, IsHandled);
      if IsHandled then exit;
    end;

    if Supports(Vertex, IVertexCircle) then begin
      DrawVertexCircle(Vertex, ACanvas, LSettings.Fill, LSettings.Stroke);
    end else begin
      DrawVertexPolygon(Vertex, ACanvas, LSettings.Fill, LSettings.Stroke);
    end;

    DrawVertexText(Vertex, ACanvas, LSettings.Text);
  finally
    FreeAndNil(LSettings);
  end;
end;

procedure TGraphControl.DrawVertexCircle(const Vertex: TVertex;
  const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
begin
  var Radius := (Vertex as IVertexCircle).Radius;

  var LRect := TRectF.Create(0, 0, Radius * 2, Radius * 2);
  LRect.SetLocation(Vertex.Position - TPointF.Create(Radius, Radius));

  ACanvas.FillEllipse(LRect, 1, Fill);
  LRect.Inflate(-Stroke.Thickness * 0.5, -Stroke.Thickness * 0.5);
  ACanvas.DrawEllipse(LRect, 1, Stroke);
end;

procedure TGraphControl.DrawVertexPolygon(const Vertex: TVertex;
  const ACanvas: TCanvas; Fill: TBrush; Stroke: TStrokeBrush);
const Thickness = 2; ArrowSize = 10;

begin
  var SavedFill := TBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  var SavedStroke := TStrokeBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  SavedFill.Assign(ACanvas.Fill);
  SavedStroke.Assign(ACanvas.Stroke);
  try
    var Polygon := (Vertex as IVertexPolygon).Polygon;

    InflatePolygon(Polygon, -Stroke.Thickness * 0.5);

    ACanvas.Fill.Assign(Fill);
    ACanvas.Stroke.Assign(Stroke);

    ACanvas.FillPolygon(Polygon, 1);
    ACanvas.DrawPolygon(Polygon, 1);
  finally
    ACanvas.Fill.Assign(SavedFill);
    ACanvas.Stroke.Assign(SavedStroke);
    FreeAndNil(SavedFill);
    FreeAndNil(SavedStroke);
  end;
end;

procedure TGraphControl.DrawVertexText(const Vertex: tVertex;
  const ACanvas: TCanvas; TextSettings: TTextSettings);

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
  var TextRect: TRectF;

  if Supports(Vertex, IVertexCircle) then begin
    var Radius := (Vertex as IVertexCircle).Radius;
    TextRect := TRectF.Create(Vertex.Position - TPointF.Create(Radius,Radius), Radius * 2, Radius * 2);
  end else begin
    var Polygon := (Vertex as IVertexPolygon).Polygon;
    TextRect := GetPolygonRect(Polygon);
  end;

  var SavedFill := TBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  var SavedFont := TFont.Create;
  SavedFill.Assign(ACanvas.Fill);
  SavedFont.Assign(ACanvas.Font);
  try
    ACanvas.Fill.Color := TextSettings.FontColor;
    ACanvas.Fill.Kind  := TBrushKind.Solid;
    ACanvas.Font.Assign(TextSettings.Font);

    ACanvas.FillText(TextRect, Vertex.Text, TextSettings.WordWrap, 1, [], TextSettings.HorzAlign, TextSettings.VertAlign);
  finally
    ACanvas.Fill.Assign(SavedFill);
    ACanvas.Font.Assign(SavedFont);
    FreeAndNil(SavedFill);
    FreeAndNil(SavedFont);
  end;
end;

procedure TGraphControl.FixedVertexUnderMouse;
begin
  if assigned(FVertexUnderMouse) then begin
    FVertexUnderMouse.IsFixed := not FVertexUnderMouse.IsFixed;

    FSimulation.Alpha := 1;
    FSimulation.Restart;
  end;
end;

procedure TGraphControl.GetLineEdge(const Edge: TEdge; out P1, P2: TPointF; out IsBidi: boolean);

  function ContainsBidirectional(AEdge: TEdge): boolean;
  begin
    for var Item in AEdge.VertexFrom.EdgesAsFrom do begin
      if Item.VertexFrom = AEdge.VertexTo then
        exit(true);
    end;
    result := false;
  end;

begin
  P1 := Edge.VertexFrom.Position;
  P2 := Edge.VertexTo.Position;

  IsBidi := ContainsBidirectional(Edge);
  if IsBidi then begin
    GetParallelLine(-5, P1, P2, P1, P2);
  end;

  ClipLineEdge(Edge, P1, P2);
end;

procedure TGraphControl.GetParallelLine(Offset: single; P1, P2: TPointF; out L1,
  L2: TPointF);
begin
  var dx := P1.X - P2.X;
  var dy := P1.Y - P2.Y;
  var Length := sqrt(sqr(dx) + sqr(dy));

  L1.X := P1.X - offset * dy/Length;
  L1.Y := P1.Y + offset * dx/Length;

  L2.X := P2.X - offset * dy/Length;
  L2.Y := P2.Y + offset * dx/Length;
end;

procedure TGraphControl.ClipLineEdge(const Edge: TEdge; out P1, P2: TPointF);
begin
  if Supports(Edge.VertexFrom, IVertexCircle) then begin
    var Radius := (Edge.VertexFrom as IVertexCircle).Radius;
    ClipLineCircle(P1, Radius, P2, P1);
  end else begin
    var Polygon := (Edge.VertexFrom as IVertexPolygon).Polygon;
    ClipLinePolygon(Polygon, P2, P1);
  end;

  if Supports(Edge.VertexTo, IVertexCircle) then begin
    var Radius := (Edge.VertexTo as IVertexCircle).Radius;
    ClipLineCircle(P2, Radius, P1, P2);
  end else begin
    var Polygon := (Edge.VertexTo as IVertexPolygon).Polygon;
    ClipLinePolygon(Polygon, P1, P2);
  end;
end;

procedure TGraphControl.InflatePolygon(var Polygon: TPolygon; Delta: single);
begin
  var NewPolygon: TPolygon;
  SetLength(NewPolygon, Length(Polygon));

  for var I := 0 to Length(Polygon)-1 do begin
    var L1, L2: TPointF;

    if I <> Length(Polygon)-1
      then GetParallelLine(Delta, Polygon[I], Polygon[I+1], L1, L2)
      else GetParallelLine(Delta, Polygon[I], Polygon[0], L1, L2);

    if I = 0 then begin
      NewPolygon[I]   := L1;
      NewPolygon[I+1] := L2;
    end else
    if I <> Length(Polygon)-1 then begin
     var P := IntersectionPoint(NewPolygon[I-1], NewPolygon[I], L1, L2);
     NewPolygon[I]    := P;
     NewPolygon[I+1]  := L2;
    end else begin
      var P := IntersectionPoint(NewPolygon[I-1], NewPolygon[I], L1, L2);
      NewPolygon[I]    := P;

      P := IntersectionPoint(NewPolygon[0], NewPolygon[1], L1, L2);
      NewPolygon[0]  := P;
    end;
  end;

  Polygon := NewPolygon;
end;

function TGraphControl.IntersectionPoint(const P1, P2, P3,
  P4: TPointF): TPointF;
var
  Ratio : Double;
  dx1   : Double;
  dx2   : Double;
  dx3   : Double;
  dy1   : Double;
  dy2   : Double;
  dy3   : Double;
begin
  dx1 := P2.X - P1.X;
  dx2 := P4.X - P3.X;
  dx3 := P1.X - P3.X;

  dy1 := P2.Y - P1.Y;
  dy2 := P1.Y - P3.Y;
  dy3 := P4.Y - P3.Y;

  Ratio := dx1 * dy3 - dy1 * dx2;

  if NotEqual(Ratio, 0.0) then
  begin
    Ratio := (dy2 * dx2 - dx3 * dy3) / Ratio;
    Result.X := P1.X + Ratio * dx1;
    Result.Y := P1.Y + Ratio * dy1;
  end
  else
  begin
    if IsEqual((dx1 * -dy2),(-dx3 * dy1)) then
    begin
      Result := P3;
    end
    else
    begin
      Result := P4;
    end;
  end;
end;

function TGraphControl.IsEqual(const Val1, Val2: double): Boolean;
const Epsilon_Medium    = 1.0E-12;
var
  Diff : double;
begin
  Diff := Val1 - Val2;
  Assert(((-Epsilon_Medium <= Diff) and (Diff <= Epsilon_Medium)) = (Abs(Diff) <= Epsilon_Medium),'Error - Illogical error in equality check. (IsEqual)');
  Result := ((-Epsilon_Medium <= Diff) and (Diff <= Epsilon_Medium));
end;

function TGraphControl.MaxPoint(const Point1, Point2: TPointF): TPointF;
begin
       if Point1.x > Point2.x then Result := Point1
  else if Point2.x > Point1.x then Result := Point2
  else if Point1.y > Point2.y then Result := Point1
  else                             Result := Point2;
end;

function TGraphControl.MinPoint(const Point1, Point2: TPointF): TPointF;
begin
       if Point1.x < Point2.x then Result := Point1
  else if Point2.x < Point1.x then Result := Point2
  else if Point1.y < Point2.y then Result := Point1
  else                             Result := Point2;
end;

procedure TGraphControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  var P := PointContent(TPointF.Create(X, Y));

  if assigned(FVertexUnderMouse) then begin
    FIsDblClick := DoubleClick;

    DoVertexMouseDown(FVertexUnderMouse, Button, Shift, P.X, P.Y);
    exit;
  end;
end;

procedure TGraphControl.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;

  if FGraph <> nil then begin
    var P := PointContent(TPointF.Create(X, Y));

    //Перемещение полотна графа
    if Pressed and (ssLeft in Shift) and (ssCtrl in Shift) then begin
      MoveContent(TPointF.Create(X, Y));
    end else
    //Перемещение Вершины
    if Pressed and (ssLeft in Shift) then begin
      MoveVertexUnderMouse(P);
    end;

    //Ищем Вершину под мышкой
    if not Pressed then begin
      SetVertexUnderMouse(P);
      PreFixedVertexUnderMouse;
    end;


    if assigned(FVertexUnderMouse) then begin
      DoVertexMouseMove(FVertexUnderMouse, Shift, P.X, P.Y, Pressed);
    end;
  end;
end;

procedure TGraphControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  var P := PointContent(TPointF.Create(X, Y));

  if FVertexMoved then begin
    AfterMoveVertexUnderMouse(Shift);
  end else begin
    if (Shift = [ssAlt]) then begin
      FixedVertexUnderMouse;
    end;

    if (Shift = [ssShift]) then begin
      SelectVertexUnderMouse;
    end;
  end;

  if assigned(FVertexUnderMouse) then
    FVertexUnderMouse.IsPreFixed := false;

  if assigned(FVertexUnderMouse) then begin
    if FIsDblClick then begin
      DoVertexDblClick(FVertexUnderMouse);
    end else begin
      DoVertexClick(FVertexUnderMouse);
    end;

    DoVertexMouseUp(FVertexUnderMouse, Button, Shift, P.X, P.Y);
  end;
end;

procedure TGraphControl.MouseWheel(Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
begin
  inherited;
  if shift = [ssCtrl] then begin
    ScaleContent(WheelDelta);
  end;

  if assigned(FVertexUnderMouse) then begin
    DoVertexMouseWheel(FVertexUnderMouse, Shift, WheelDelta);
  end;
end;

procedure TGraphControl.MoveContent(LocalMousePosition: TPointF);
{$J+}
const
  SavedMousePos: TPointF = (X: Infinity; Y: Infinity);
  OldPressedPosition: TPointF = (X: Infinity; Y: Infinity);
begin
  if (OldPressedPosition.X = Infinity) or (OldPressedPosition <> PressedPosition) then begin
    SavedMousePos      := LocalToAbsolute(PressedPosition);
    OldPressedPosition := PressedPosition;
  end;

  var DeltaX := ifthen(LocalMousePosition.X > SavedMousePos.X,
                       abs(LocalMousePosition.X-SavedMousePos.X),
                       abs(LocalMousePosition.X-SavedMousePos.X)*-1);
  var DeltaY := ifthen(LocalMousePosition.Y > SavedMousePos.Y,
                      abs(LocalMousePosition.Y-SavedMousePos.Y),
                      abs(LocalMousePosition.Y-SavedMousePos.Y)*-1);

  FScrolBox.ScrollBy(DeltaX, DeltaY);
  SavedMousePos := LocalMousePosition;
end;

procedure TGraphControl.MoveVertexUnderMouse(NewPosition: TPointF);
begin
  if assigned(FVertexUnderMouse) then begin
    FVertexUnderMouse.Position := NewPosition;
    FVertexUnderMouse.IsPreFixed := true;
    FSimulation.Alpha := 1;
    FSimulation.Restart;

    FVertexMoved := true;
  end;
end;

function TGraphControl.NotEqual(const Val1, Val2: double): Boolean;
const Epsilon_Medium    = 1.0E-12;
var
  Diff : double;
begin
  Diff := Val1 - Val2;
  Assert(((-Epsilon_Medium > Diff) or (Diff > Epsilon_Medium)) = (Abs(Val1 - Val2) > Epsilon_Medium),'Error - Illogical error in equality check. (NotEqual)');
  Result := ((-Epsilon_Medium > Diff) or (Diff > Epsilon_Medium));
end;

procedure TGraphControl.DoOnSimulation(Event: TSimulationEvent);
begin
  if Event = TSimulationEvent.EventStart then begin
    FSimulation.InitialCenter := TPointF.Zero;
    exit;
  end;

  if assigned(FGraph) then begin
    var NewRect := TRectF.Empty;
    CalcGraphRect(Graph.Vertices, NewRect);
    NewRect.Inflate(100,100);
    FContent.Size.Size := NewRect.Size;
  end;

  if assigned(FOnSimulation) then
    FOnSimulation(Event);

  FScrolBox.Content.Repaint;
end;

function TGraphControl.Orientation(const P1, P2, P: TPointF): Integer;
begin
  (* Determinant of the 3 points *)
  var Orin := (P2.X - P1.X) * (P.Y - P1.Y) - (P.X - P1.X) * (P2.Y - P1.Y);

  if Orin > 0.0 then
    Result := -1          (* Orientaion is to the left-hand side  *)
  else if Orin < 0.0 then
    Result := 1         (* Orientaion is to the right-hand side *)
  else
    Result := 0; (* Orientaion is neutral aka collinear  *)
end;

function TGraphControl.OrientedVertexAngle(const P1, P2, P3: TPointF;
  const Orient: Integer): double;
begin
  Result := VertexAngle(P1.X,P1.Y, P2.X,P2.Y, P3.X,P3.Y);
  if Orientation(P1, P2, P3) <> Orient then
    Result := 360.0 - Result;
end;

procedure TGraphControl.PreFixedVertexUnderMouse;
{$J+}
  const V: TVertex = nil;
  const IsPreFixed: boolean = false;
begin
  if V <> FVertexUnderMouse then begin
    if assigned(V) then
      V.IsPreFixed := false;

    V := FVertexUnderMouse;
    if Assigned(V) then
      V.IsPreFixed := true;
  end;
end;

function TGraphControl.ProjectPoint(const Src, Dst: TPointF; Dist: double): TPointF;
begin
 var  DistRatio := Dist / Src.Distance(Dst);
 Result.X := Src.X + DistRatio * (Dst.X - Src.X);
 Result.Y := Src.Y + DistRatio * (Dst.Y - Src.Y);
end;

procedure TGraphControl.ScaleContent(WheelDelta: single);
begin
  var BeforeZoomCenter := FContent.ScreenToLocal(Screen.MousePos);
  var LocalZoomCenter  := ScreenToLocal(Screen.MousePos);

  var OldScale := FContent.Scale.X;
  var NewScale: single;
  if WheelDelta >= 0 then NewScale := OldScale * (1 + (WheelDelta / 120)/5)
                     else NewScale := OldScale / (1 - (WheelDelta / 120)/5);

  FContent.BeginUpdate;
  FContent.Scale.X := NewScale;
  FContent.Scale.Y := NewScale;
  FContent.RecalcSize;
  FContent.EndUpdate;

  var AfterZoomCenter := ScreenToLocal(FContent.LocalToScreen(BeforeZoomCenter));
  FScrolBox.ViewportPosition := FScrolBox.ViewportPosition + (AfterZoomCenter - LocalZoomCenter);
end;

procedure TGraphControl.SelectVertexUnderMouse;
begin
  if assigned(FVertexUnderMouse) then begin
    FVertexUnderMouse.IsSelected := not FVertexUnderMouse.IsSelected;
    FVertexUnderMouse.IsFixed    := true;

    FSimulation.Alpha := 1;
    FSimulation.Restart;
  end;
end;

procedure TGraphControl.SetCoordOrigin(const Value: TCoordOrigin);
begin
  FCoordOrigin := Value;

  if FCoordOrigin = TCoordOrigin.CoordControl
    then FContent.Align := TAlignLayout.Client
    else FContent.Align := TAlignLayout.Center;
end;

procedure TGraphControl.SetGraph(const Value: TGraph);
begin
  FGraph := Value;
  FSimulation.Graph := FGraph;
  FSimulation.InitialCenter := FContent.AbsoluteToLocal(LocalToAbsolute(LocalRect.CenterPoint))
end;

procedure TGraphControl.SetSettingsEdge(const Value: TGraphicSettings);
begin
  FSettingsEdge.Assign(Value);
end;

procedure TGraphControl.SetSettingsVertex(const Value: TGraphicSettings);
begin
  FSettingsVertex.Assign(Value);
end;

procedure TGraphControl.SetSettingsVertexSelected(
  const Value: TGraphicSettings);
begin
  FSettingsVertexSelected.Assign(Value);
end;

procedure TGraphControl.SetVertexUnderMouse(ContentMousePosition: TPointF);

  function GetQuadTree: TQuadTree<TVertex>;
  begin
    var RectG: TRectF;
    CalcGraphRect(Graph.Vertices, RectG);

    result := TQuadTree<TVertex>.Create(RectG.Left, RectG.Top, RectG.Right, RectG.Bottom);
    for var Vertex in FGraph.Vertices do begin
      var p := Vertex.Position;
      result.SetValue(p.X, p.Y, Vertex);
    end;
  end;

begin
  var QuadTree := GetQuadTree;
  try
    var Node := QuadTree.Find(QuadTree.RootNode, ContentMousePosition.X, ContentMousePosition.Y, FRadiusFind);
    if assigned(Node) then begin
      var Vertex := Node.Point.Value;
      FVertexUnderMouse := Vertex;
    end else begin
      FVertexUnderMouse := nil;
    end;
  finally
    FreeAndNil(QuadTree);
  end;
end;

function TGraphControl.VertexAngle(x1, y1, x2, y2, x3, y3: double): double;
var
  Dist      : double;
  InputTerm : double;
begin
 (*
    Using the cosine identity:
    cosA = (b^2 + c^2 - a^2) / (2*b*c)
    A    = Cos'((b^2 + c^2 - a^2) / (2*b*c))

    Where:

    a,b and c : are edges in the triangle
    A         : is the angle at the vertex opposite edge 'a'
                aka the edge defined by the vertex <x1y1-x2y2-x3y3>

 *)
  (* Quantify coordinates *)
  x1   := x1 - x2;
  x3   := x3 - x2;
  y1   := y1 - y2;
  y3   := y3 - y2;

  (* Calculate Ley Distance *)
  Dist := (x1 * x1 + y1 * y1) * (x3 * x3 + y3 * y3);

  if IsEqual(Dist,0.0) then
    Result := 0.0
  else
  begin
    InputTerm := (x1 * x3 + y1 * y3) / sqrt(Dist);
    if IsEqual(InputTerm,1.0) then
      Result := 0.0
    else if IsEqual(InputTerm,-1.0) then
      Result := 180.0
    else
      Result := ArcCos(InputTerm) * _180DivPI
  end;
end;

{$REGION 'TGraphicSettings'}

procedure TGraphicSettings.Assign(Source: TPersistent);
begin
  if Source is TGraphicSettings then begin
    FFill.Assign(TGraphicSettings(Source).FFill);
    FStroke.Assign(TGraphicSettings(Source).FStroke);
    FText.Assign(TGraphicSettings(Source).FText);
  end else
    inherited;
end;

constructor TGraphicSettings.Create;
begin
  FFill     := TBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  FStroke   := TStrokeBrush.Create(TBrushKind.None, TAlphaColors.Alpha);
  FText     := TTextSettings.Create(nil);
end;

destructor TGraphicSettings.Destroy;
begin
  FFill.Free;
  FStroke.Free;
  FText.Free;
  inherited;
end;

procedure TGraphicSettings.SetFill(const Value: TBrush);
begin
  FFill.Assign(Value);
end;

procedure TGraphicSettings.SetStroke(const Value: TStrokeBrush);
begin
  FStroke.Assign(Value);
end;

procedure TGraphicSettings.SetText(const Value: TTextSettings);
begin
  FText.Assign(Value);
end;

{$ENDREGION}

end.
