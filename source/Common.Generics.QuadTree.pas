unit Common.Generics.QuadTree;

interface
uses
    System.SysUtils
  , System.Generics.Collections
  , System.Types
  ;

type
  TQuadTree<T> = class;
  TNode<T> = class;

  TNodeType = (Empty, Leaf, Pointer);

  TPoint<T> = record
  private
    FIsEmpty: boolean;
    procedure SetIsEmpty;
  public
    X: double;
    Y: double;
    Value: T;

    constructor Create(X,Y: double; Value: T);
    function CompareTo(Point: TPoint<T>): integer;

    property IsEmpty: boolean read FIsEmpty;
  end;

  EQuadTree = class(Exception);

  TQFunc<T> = reference to function(QuadTree: TQuadTree<T>; Node: TNode<T>): boolean;
  TQProc<T> = reference to procedure(QuadTree: TQuadTree<T>; Node: TNode<T>);

  TQuadTree<T> = class
  private
    FRoot: TNode<T>;
    FCount: integer;

    function Intersects(Left, Bottom, Right, Top: double; Node: TNode<T>): boolean;

    procedure Extend(X, Y: double);
    function Insert(Parent: TNode<T>; Point: TPoint<T>): boolean;
    procedure Split(Node: TNode<T>);
    procedure Balance(Node: TNode<T>);
    function GetQuadrantForPoint(Parent: TNode<T>; X,Y: double): TNode<T>;
    procedure SetPointForNode(Node: TNode<T>; Point: TPoint<T>);

    function TryTraverse(Node: TNode<T>; Func: TQFunc<T>): boolean;
    function TryVisit(Node: TNode<T>; Func: TQFunc<T>): boolean;

    function TryFindNeighbors(Node: TNode<T>; X, Y: double; Radius: single; var AResult: TNode<T>): boolean;

    function PointInCircle(P: TPointF; Center: TPointF; Radius: single): boolean;
  public
    constructor Create(MinX, MinY, MaxX, MaxY: double);
    destructor Destroy; override;

    property RootNode: TNode<T> read FRoot;
    property Count: integer read FCount;

    procedure SetValue(x,y: double; Value: T);
    function GetValue(x,y: double; Default: T): T;
    function TryGetValue(x,y: double; out AResult: T): boolean;
    function Remove(x,y: double): T;
    function Contains(x,y: double): boolean;
    function IsEmpty: boolean;
    procedure Clear;

    function Keys: TArray<TPoint<T>>;
    function Values: TArray<T>;

    function SearchIntersect(xMin, yMin, xMax, yMax: double): TArray<TPoint<T>>;
    function SearchWithin(xMin, yMin, xMax, yMax: double): TArray<TPoint<T>>;

    procedure Navigate(Node: TNode<T>; Func: TQProc<T>; xMin, yMin, xMax, yMax: double);
    function Clone: TQuadTree<T>;

    procedure Traverse(Node: TNode<T>; Func: TQFunc<T>); overload;
    procedure Traverse(Node: TNode<T>; Func: TQProc<T>); overload;

    procedure Visit(Node: TNode<T>; Func: TQFunc<T>); overload;
    procedure VisitAfter(Node: TNode<T>; Func: TQProc<T>); overload;
    function Find(Node: TNode<T>; X,Y: double; Radius: single = 0.0): TNode<T>;
  end;

  TNode<T> = class
  strict private
    Fx: double;
    Fy: double;
    Fw: double;
    Fh: double;
    FParent: TNode<T>;
    FNodeType: TNodeType;
    Fnw: TNode<T>;
    Fne: TNode<T>;
    Fsw: TNode<T>;
    Fse: TNode<T>;

    FData: TDictionary<string, string>;
    function GetData(DataName: string): string;
    procedure SetData(DataName: string; Value: string);
    function GetChildNode(Idx: integer): TNode<T>;
  public
    Point:  TPoint<T>;

    constructor Create(x,y,w,h: double; Parent: TNode<T>);
    destructor Destroy; override;

    property X: double read Fx write Fx;
    property Y: double read Fy write Fy;
    property W: double read Fw write Fw;
    property H: double read Fh write Fh;

    property Parent: TNode<T> read FParent write FParent;
//    property Point: TPoint<T> read FPoint write FPoint;
    property NodeType: TNodeType read FNodeType write FNodeType;

    property NW: TNode<T> read Fnw write Fnw;
    property NE: TNode<T> read Fne write Fne;
    property SW: TNode<T> read Fsw write Fsw;
    property SE: TNode<t> read Fse write Fse;

    property Nodes[Idx: integer]: TNode<T> read GetChildNode;
    property Data[DataName: string]: string read GetData write SetData;
  end;


implementation
uses
    System.Math
  ;

{ TPoint<T> }

function TPoint<T>.CompareTo(Point: TPoint<T>): integer;
begin
  if X < Point.X then exit(-1);
  if X > Point.X then exit(1);
  if Y < Point.Y then exit(-1);
  if Y > Point.Y then exit(1);

  result := 0;
end;

constructor TPoint<T>.Create(X, Y: double; Value: T);
begin
  self.X      := X;
  self.Y      := Y;
  Self.Value  := Value;
  FIsEmpty    := false;
end;

procedure TPoint<T>.SetIsEmpty;
begin
  FIsEmpty := true;
  X := 0;
  Y := 0;
end;

{ TQuadTree<T> }

procedure TQuadTree<T>.Balance(Node: TNode<T>);
begin
  case Node.NodeType of
    Empty:    ;
    Leaf:     begin
                if Node.Parent <> nil then
                  Balance(Node.Parent);
              end;
    Pointer:  begin
                var nw: TNode<T> := Node.NW;
                var ne: TNode<T> := Node.NE;
                var sw: TNode<T> := Node.SW;
                var se: TNode<T> := Node.SE;
                var FirstLeaf: TNode<T> := nil;

                // Look for the first non-empty child, if there is more than one then we
                // break as this node can't be balanced.
                if nw.NodeType <> TNodeType.Empty then
                  FirstLeaf := nw;

                if ne.NodeType <> TNodeType.Empty then begin
                  if FirstLeaf <> nil then exit;
                  FirstLeaf := ne;
                end;

                if sw.NodeType <> TNodeType.Empty then begin
                  if FirstLeaf <> nil then exit;
                  FirstLeaf := sw;
                end;

                if se.NodeType <> TNodeType.Empty then begin
                  if FirstLeaf <> nil then exit;
                  FirstLeaf := se;
                end;

                if FirstLeaf = nil then begin
                  // All child nodes are empty: so make this node empty.
                  Node.NodeType := TNodeType.Empty;
                  Node.NW := nil;
                  Node.NE := nil;
                  Node.SW := nil;
                  Node.SE := nil;
                end else if FirstLeaf.NodeType = TNodeType.Pointer then begin
                  // Only child was a pointer, therefore we can't rebalance.
                  exit;
                end else begin
                  // Only child was a leaf: so update node's point and make it a leaf.
                  Node.NodeType := TNodeType.Leaf;
                  Node.NW := nil;
                  Node.NE := nil;
                  Node.SW := nil;
                  Node.SE := nil;
                  Node.Point := FirstLeaf.Point;
                end;

                // Try and balance the parent as well.
                if Node.Parent <> nil then
                  Balance(Node.Parent);
              end;
  end;
end;

procedure TQuadTree<T>.Clear;
begin
  FreeAndNil(FRoot.NW);
  FreeAndNil(FRoot.NE);
  FreeAndNil(FRoot.SW);
  FreeAndNil(FRoot.SE);

  FRoot.Point.X := FRoot.X;
  FRoot.Point.Y := FRoot.Y;
  FRoot.NodeType := TNodeType.Empty;
  FCount := 0;
end;

function TQuadTree<T>.Clone: TQuadTree<T>;
var
  cln: TQuadTree<T>;
begin
  var x1 := FRoot.X;
  var y1 := FRoot.Y;
  var x2 := x1 + FRoot.W;
  var y2 := y1 + FRoot.H;

  cln := TQuadTree<T>.Create(x1,y1,x2,y2);
  // This is inefficient as the clone needs to recalculate the structure of the
  // tree, even though we know it already.  But this is easier and can be
  // optimized when/if needed.
  Traverse(FRoot,
    procedure(QuadTree: TQuadTree<T>; Node: TNode<T>)
    begin
      cln.SetValue(Node.Point.X, Node.Point.Y, Node.Point.Value);
    end
  );

  result := cln;
end;

function TQuadTree<T>.Contains(x, y: double): boolean;
begin
  var Node: TNode<T>;
  result := TryGetValue(x, y, Node);
end;

constructor TQuadTree<T>.Create(MinX, MinY, MaxX, MaxY: double);
begin
  FRoot := TNode<T>.Create(Floor(MinX), Floor(MinY), Ceil(MaxX) - Floor(MinX), Ceil(MaxY)-Floor(MinY), nil);
end;

destructor TQuadTree<T>.Destroy;
begin
  FreeAndNil(FRoot);
  inherited;
end;

procedure TQuadTree<T>.Extend(X, Y: double);
begin
  var NewRoot := TNode<T>.Create(FRoot.X, FRoot.Y, FRoot.W * 2, FRoot.H * 2, nil);

  if (x < FRoot.X) then NewRoot.X := FRoot.X-FRoot.W;
  if (y < FRoot.Y) then NewRoot.Y := FRoot.Y-FRoot.H;

  var nx   := NewRoot.X;
  var ny   := NewRoot.Y;
  var nhw  := NewRoot.W / 2;
  var nhh  := NewRoot.H / 2;

  var mx := NewRoot.X + NewRoot.W / 2;
  var my := NewRoot.Y + NewRoot.H / 2;

  if FRoot.X < mx then begin
    if FRoot.y < my then begin
      NewRoot.NW := FRoot;
      NewRoot.NE := TNode<T>.Create(nx+nhw, ny,     nhw, nhh, NewRoot);
      NewRoot.SW := TNode<T>.Create(nx,     ny+nhh, nhw, nhh, NewRoot);
      NewRoot.SE := TNode<T>.Create(nx+nhw, ny+nhh, nhw, nhh, NewRoot);
    end else begin
      NewRoot.NW := TNode<T>.Create(nx,     ny,     nhw, nhh, NewRoot);
      NewRoot.NE := TNode<T>.Create(nx+nhw, ny,     nhw, nhh, NewRoot);
      NewRoot.SW := FRoot;
      NewRoot.SE := TNode<T>.Create(nx+nhw, ny+nhh, nhw, nhh, NewRoot);
    end;
  end else begin
    if FRoot.y < my then begin
      NewRoot.NW := TNode<T>.Create(nx,     ny,     nhw, nhh, NewRoot);
      NewRoot.NE := FRoot;
      NewRoot.SW := TNode<T>.Create(nx,     ny+nhh, nhw, nhh, NewRoot);
      NewRoot.SE := TNode<T>.Create(nx+nhw, ny+nhh, nhw, nhh, NewRoot);
    end else begin
      NewRoot.NW := TNode<T>.Create(nx,     ny,     nhw, nhh, NewRoot);
      NewRoot.NE := TNode<T>.Create(nx+nhw, ny,     nhw, nhh, NewRoot);
      NewRoot.SW := TNode<T>.Create(nx,     ny+nhh, nhw, nhh, NewRoot);
      NewRoot.SE := FRoot;
    end;
  end;

  FRoot.Parent    := NewRoot;
  FRoot           := NewRoot;
  FRoot.NodeType  := TNodeType.Pointer;
end;

function TQuadTree<T>.Find(Node: TNode<T>; X, Y: double; Radius: single): TNode<T>;
begin
  result := nil;
  if Node = nil then exit;
  case Node.NodeType of
    Empty:    begin
                var Parent := Node;
                for var I := 1 to 3 do begin
                  if Parent.Parent = nil then exit;

                  Parent := Parent.Parent;
                  if TryFindNeighbors(Parent.NE, X, Y, Radius, result) then exit;
                  if TryFindNeighbors(Parent.SE, X, Y, Radius, result) then exit;
                  if TryFindNeighbors(Parent.SW, X, Y, Radius, result) then exit;
                  if TryFindNeighbors(Parent.NW, X, Y, Radius, result) then exit;
                end;
              end;
    Leaf:     begin
                if Radius = 0 then begin
                  if (Node.Point.X = X) and (Node.Point.Y = y) then
                    result := Node;
                end else begin
                  if PointInCircle(TPointF.Create(X,Y), TPointF.Create(Node.Point.X, Node.Point.Y), Radius) then begin
                    result := Node;
                  end else begin
                    var Parent := Node;
                    for var I := 1 to 3 do begin
                      if Parent.Parent = nil then exit;

                      Parent := Parent.Parent;
                      if TryFindNeighbors(Parent.NE, X, Y, Radius, result) then exit;
                      if TryFindNeighbors(Parent.SE, X, Y, Radius, result) then exit;
                      if TryFindNeighbors(Parent.SW, X, Y, Radius, result) then exit;
                      if TryFindNeighbors(Parent.NW, X, Y, Radius, result) then exit;
                    end;
                  end;
                end;
              end;
    Pointer:  begin
                result := Find(GetQuadrantForPoint(Node, x,y), x,y, Radius);
              end;
    else      raise EQuadTree.Create('Invalid NodeType');
  end;
end;

function TQuadTree<T>.GetQuadrantForPoint(Parent: TNode<T>; X,
  Y: double): TNode<T>;
begin
  var mx := Parent.X + Parent.W / 2;
  var my := Parent.Y + Parent.H / 2;

  if X < mx then begin
    if y < my
      then result := Parent.NW
      else result := Parent.SW;
  end else begin
    if y < my
      then result := Parent.NE
      else result := Parent.SE;
  end;

end;

function TQuadTree<T>.GetValue(x, y: double; Default: T): T;
begin
  var Node := Find(FRoot, x, y);
  if Node <> nil
    then result := Node.Point.Value
    else result := Default;
end;

function TQuadTree<T>.Insert(Parent: TNode<T>; Point: TPoint<T>): boolean;
begin
  result := false;
  case Parent.NodeType of
    Empty:    begin
                SetPointForNode(Parent, Point);
                result := true;
              end;
    Leaf:     begin
                if (Parent.Point.X = Point.X) and (Parent.Point.Y = Point.Y) then begin
                  SetPointForNode(Parent, Point);
                  result := false;
                end else begin
                  Split(Parent);
                  result := Insert(Parent, Point);
                end;
              end;
    Pointer:  begin
                result := Insert(GetQuadrantForPoint(Parent, Point.X, Point.Y), Point);
              end;
    else      raise EQuadTree.Create('Invalid NodeType in Parent.');
  end;
end;

function TQuadTree<T>.Intersects(Left, Bottom, Right, Top: double;
  Node: TNode<T>): boolean;
begin
  result := not ((Node.X > Right)  or
                 (Node.X + Node.W < Left) or
                 (Node.Y > Bottom) or
                 (Node.Y + Node.H < Top));
end;

function TQuadTree<T>.IsEmpty: boolean;
begin
  result := FRoot.NodeType = TNodeType.Empty;
end;

function TQuadTree<T>.Keys: TArray<TPoint<T>>;
var
  arr: TArray<TPoint<T>>;
begin
  Traverse(FRoot,
    procedure(QuadTree: TQuadTree<T>; Node: TNode<T>)
    begin
      arr := arr+[Node.Point];
    end
  );

  result := arr;
end;

procedure TQuadTree<T>.Navigate(Node: TNode<T>; Func: TQProc<T>; xMin, yMin,
  xMax, yMax: double);
begin
  case Node.NodeType of
    Leaf:     begin
                Func(Self, Node);
              end;
    Pointer:  begin
                if Intersects(xMin, yMax, xMax, yMin, Node.NE) then
                  Navigate(Node.NE, Func, xMin, yMin, xMax, yMax);
                if Intersects(xMin, yMax, xMax, yMin, Node.SE) then
                  Navigate(Node.SE, Func, xMin, yMin, xMax, yMax);
                if Intersects(xMin, yMax, xMax, yMin, Node.SW) then
                  Navigate(Node.SW, Func, xMin, yMin, xMax, yMax);
                if Intersects(xMin, yMax, xMax, yMin, Node.NW) then
                  Navigate(Node.NW, Func, xMin, yMin, xMax, yMax);
              end;
  end;
end;

function TQuadTree<T>.PointInCircle(P, Center: TPointF;
  Radius: single): boolean;
begin
    result := P.Distance(Center) <= Radius;
end;

function TQuadTree<T>.Remove(x, y: double): T;
begin
  var Node := Find(FRoot, x, y);
  if Node <> nil then begin
    result := Node.Point.Value;
    Node.Point.SetIsEmpty;
    Node.NodeType := TNodeType.Empty;
    Balance(Node);
    dec(FCount);
  end;
//  end else begin
//    result := nil;
//  end;
end;

function TQuadTree<T>.SearchIntersect(xMin, yMin, xMax, yMax: double): TArray<TPoint<T>>;
var
  arr: TArray<TPoint<T>>;
begin
  Navigate(FRoot,
    procedure(QuadTree: TQuadTree<T>; Node: TNode<T>)
    begin
      var Pt := Node.Point;
      if (Pt.X < xMin) or (Pt.X > xMax) or (Pt.Y < yMin) or (Pt.Y > yMax) then begin
        // Definitely not within the polygon!
      end else begin
        arr := arr+[Node.Point];
      end;

    end
  , xMin, yMin, xMax, yMax);

  result := Arr;
end;

function TQuadTree<T>.SearchWithin(xMin, yMin, xMax, yMax: double): TArray<TPoint<T>>;
var
  arr: TArray<TPoint<T>>;
begin
  Navigate(FRoot,
    procedure(QuadTree: TQuadTree<T>; Node: TNode<T>)
    begin
      var Pt := Node.Point;
      if (Pt.X > xMin) and (PT.X < xMax) and (Pt.Y > yMin) and (Pt.Y < yMax) then
        arr := arr+[Node.Point];
    end
  , xMin, yMin, xMax, yMax);

  result := arr;
end;

procedure TQuadTree<T>.SetPointForNode(Node: TNode<T>; Point: TPoint<T>);
begin
  if Node.NodeType = TNodeType.Pointer then
    raise EQuadTree.Create('Can not set point for node of type POINTER"');

  Node.NodeType := TNodeType.Leaf;
  Node.Point    := Point;
end;

procedure TQuadTree<T>.SetValue(x, y: double; Value: T);
begin
  if (x < FRoot.X) or (y < FRoot.Y) or (x > FRoot.X + FRoot.W) or (y > FRoot.Y + FRoot.H) then begin
    Extend(X, Y);
//    raise EQuadTree.Create(format('Out of bounds : (%f , %f)', [x, y]));
  end;

  if Insert(FRoot, TPoint<T>.Create(x,y, Value)) then
    inc(FCount);
end;

procedure TQuadTree<T>.Split(Node: TNode<T>);
begin
  var OldPoint := Node.Point;
  Node.Point.SetIsEmpty;

  Node.NodeType := TNodeType.Pointer;

  var x   := Node.X;
  var y   := Node.Y;
  var hw  := Node.W / 2;
  var hh  := Node.H / 2;

  Node.NW := TNode<T>.Create(x,    y,    hw, hh, Node);
  Node.NE := TNode<T>.Create(x+hw, y,    hw, hh, Node);
  Node.SW := TNode<T>.Create(x,    y+hh, hw, hh, Node);
  Node.SE := TNode<T>.Create(x+hw, y+hh, hw, hh, Node);

  Insert(Node, OldPoint);
end;

procedure TQuadTree<T>.Traverse(Node: TNode<T>; Func: TQFunc<T>);
begin
  TryTraverse(Node, Func);
end;

procedure TQuadTree<T>.Traverse(Node: TNode<T>; Func: TQProc<T>);
begin
  case Node.NodeType of
    Leaf:     begin
                Func(self, Node);
              end;
    Pointer:  begin
                Traverse(Node.NE, Func);
                Traverse(Node.SE, Func);
                Traverse(Node.SW, Func);
                Traverse(Node.NW, Func);
              end;
  end;
end;

function TQuadTree<T>.TryFindNeighbors(Node: TNode<T>; X, Y: double;
  Radius: single; var AResult: TNode<T>): boolean;
begin
  result  := false;
  AResult := nil;
  if Node = nil then exit;
  case Node.NodeType of
    Empty:    ;
    Leaf:     begin
                if PointInCircle(TPointF.Create(X,Y), TPointF.Create(Node.Point.X, Node.Point.Y), Radius) then begin
                  AResult := Node;
                  exit(true);
                end;
              end;
    Pointer:  begin
                if TryFindNeighbors(Node.NE, X, Y, Radius, AResult) then exit(true);
                if TryFindNeighbors(Node.SE, X, Y, Radius, AResult) then exit(true);
                if TryFindNeighbors(Node.SW, X, Y, Radius, AResult) then exit(true);
                if TryFindNeighbors(Node.NW, X, Y, Radius, AResult) then exit(true);
              end;
    else      raise EQuadTree.Create('Invalid NodeType');
  end;
end;

function TQuadTree<T>.TryGetValue(x, y: double; out AResult: T): boolean;
begin
  var Node := Find(FRoot, x, y);
  if Node <> nil then begin
    AResult := Node.Point.Value;
    exit(true);
  end;

  result := false;
end;

function TQuadTree<T>.TryTraverse(Node: TNode<T>; Func: TQFunc<T>): boolean;
begin
  result := false;
  case Node.NodeType of
    Leaf:     begin
                result := Func(self, Node);
              end;
    Pointer:  begin
                if TryTraverse(Node.NE, Func) then exit;
                if TryTraverse(Node.SE, Func) then exit;
                if TryTraverse(Node.SW, Func) then exit;
                if TryTraverse(Node.NW, Func) then exit;
              end;
  end;
end;

function TQuadTree<T>.TryVisit(Node: TNode<T>; Func: TQFunc<T>): boolean;
begin
  result := Func(self, Node);
  case Node.NodeType of
    Pointer:  begin
                if TryVisit(Node.NE, Func) then exit;
                if TryVisit(Node.SE, Func) then exit;
                if TryVisit(Node.SW, Func) then exit;
                if TryVisit(Node.NW, Func) then exit;
              end;
  end;
end;

function TQuadTree<T>.Values: TArray<T>;
var
  arr: TArray<T>;
begin
  Traverse(FRoot,
    procedure(QuadTree: TQuadTree<T>; Node: TNode<T>)
    begin
      arr := arr+[Node.Point.Value];
    end
  );

  result := arr;
end;

procedure TQuadTree<T>.VisitAfter(Node: TNode<T>; Func: TQProc<T>);
begin
  if Node = nil then exit;
  
  if Node.NodeType = TNodeType.Pointer then begin
    VisitAfter(Node.NE, Func);
    VisitAfter(Node.SE, Func);
    VisitAfter(Node.SW, Func);
    VisitAfter(Node.NW, Func);
  end;

  Func(self, Node);
end;

procedure TQuadTree<T>.Visit(Node: TNode<T>; Func: TQFunc<T>);
begin
  TryVisit(Node, Func);
end;

{ TNode<T> }

constructor TNode<T>.Create(x, y, w, h: double; Parent: TNode<T>);
begin
  Fx      := x;
  Fy      := y;
  Fw      := w;
  Fh      := h;
  FParent := Parent;
  FNodeType := TNodeType.Empty;
  FData := TDictionary<string, string>.Create;
end;

destructor TNode<T>.Destroy;
begin
  FreeAndNil(Fnw);
  FreeAndNil(Fne);
  FreeAndNil(Fsw);
  FreeAndNil(Fse);
  FParent := nil;
  FData.Free;
  inherited;
end;

function TNode<T>.GetChildNode(Idx: integer): TNode<T>;
begin
  assert(InRange(Idx, 0, 3), 'Out of range bounds 0..3');
  case Idx of
      0:  result := Fnw;
      1:  result := Fne;
      2:  result := Fsw;
    else  result := Fse;
  end;
end;

function TNode<T>.GetData(DataName: string): string;
begin
  if not FData.TryGetValue(DataName, result) then
    result := string.Empty;
end;

procedure TNode<T>.SetData(DataName, Value: string);
begin
  FData.AddOrSetValue(DataName, Value);
end;

end.
