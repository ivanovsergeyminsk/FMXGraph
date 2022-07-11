unit View.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.ListBox, FMX.Edit,

  System.Generics.Collections,
  Graph.FMX.GraphControl, Graph, Graph.Simulation, Graph.Simulation.Forces
  ;

type
  TGraphRecord = record
    Value1: integer;
    Value2: string;

    constructor New(V1: integer; V2: string);
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    Layout1: TLayout;
    Layout2: TLayout;
    Rectangle1: TRectangle;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FGraphControl: TGraphControl;
    FGraph: TGraph;

    procedure GetTest1Graph(var Graph: TGraph);
    procedure GetTest1Simulation(Simulation: TGraphSimulation);

    procedure VertexMove(const Vertex: TVertex; Shift: TShiftState; X,Y: single; IsPressed: boolean);
    procedure VertexDraw(const Vertex: TVertex; const ACanvas: TCanvas; GraphicSettings: TGraphicSettings; var Handled: boolean);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  System.Math,
  System.Math.Vectors;

procedure TForm1.Button1Click(Sender: TObject);
begin
  GetTest1Simulation(FGraphControl.Simulation);
  GetTest1Graph(FGraph);

  FGraphControl.Graph := FGraph;
  FGraphControl.Simulation.Restart;

//  if assigned(FGraph) then begin
//    for var Vertex in FGraph.Vertices do begin
//      var VertextGraphic := Vertex as IVertexGraphic;
//      VertextGraphic.Position := TPointF.Create(random(trunc(FGraphControl.Width)), random(trunc(FGraphControl.Height)));
//    end;
//
//    var Alg := TForceDirected(FGraphControl.StackingAlgorithm);
//    Alg.LengthIdeal       := EditLen.Text.ToDouble;
//    Alg.ImpulsiveForceMax := EditImpulseMax.Text.ToDouble;
//    Alg.RForce            := EditForceR.Text.ToDouble;
//    Alg.AForce            := EditForceA.Text.ToDouble;
//
//    Alg.Recalc;
//  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGraph := TGraph.Create(TGraphType.Directed);

  FGraphControl := TGraphControl.Create(self);
  FGraphControl.Parent  := Layout1;
  FGraphControl.Visible := true;
  FGraphControl.Align   := TAlignLayout.Client;
  FGraphControl.Simulation.Stop;
  FGraphControl.Simulation.InitialRadius := 5;
  FGraphControl.Simulation.Alpha := 5;
  FGraphControl.OnVertexMouseMove := VertexMove;
  FGraphControl.OnDrawVertex      := VertexDraw;
//  FGraphControl.CoordinateOrigin := TCoordOrigin.CoordControl;

//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//  FGraph.Vertices.Add(TVertex.Create);
//
//  for var I := 1 to 150 do
//    FGraph.Vertices.Add(TVertex.Create);
//
//  for var I := 0 to FGraph.Vertices.Count div 4 do begin
//    FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[Random(FGraph.Vertices.Count-1)], FGraph.Vertices.Items[Random(FGraph.Vertices.Count-1)]));
//  end;
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[5]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[6]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[7]));
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[1]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[2]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[3]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0], FGraph.Vertices.Items[4]));
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1], FGraph.Vertices.Items[0]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1], FGraph.Vertices.Items[2]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1], FGraph.Vertices.Items[3]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1], FGraph.Vertices.Items[4]));
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2], FGraph.Vertices.Items[0]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2], FGraph.Vertices.Items[1]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2], FGraph.Vertices.Items[3]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2], FGraph.Vertices.Items[4]));
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3], FGraph.Vertices.Items[0]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3], FGraph.Vertices.Items[1]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3], FGraph.Vertices.Items[2]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3], FGraph.Vertices.Items[4]));
//
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4], FGraph.Vertices.Items[0]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4], FGraph.Vertices.Items[1]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4], FGraph.Vertices.Items[2]));
//  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4], FGraph.Vertices.Items[3]));


//  FGraphControl.Graph   := FGraph;
//
//  var F1 := TForceCenter.Create(1, FGraphControl.LocalRect.CenterPoint);
//
//  var F2 := TForceLink.Create;
//  F2.Iterations := 2;
//  F2.Strength   := 0.001;
//  F2.Distance   := 50;
//
//  var F3 := TForceRadial.Create(0.1, 400, FGraphControl.LocalRect.CenterPoint);
//  var F4 := TForceCollide.Create(0.001, 10, 2);
//  var F5 := TForceManyBody.Create;//(-100, 50, 70, 0.9);
//
////  F5.Strength := -70;
////
//  F3.Strength := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
//                 begin
//                  if Vertex.Edges.Count > 0
//                    then result := 0.5
//                    else result := 0;
//                 end;
//
////  F4.Radius := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
////               begin
////                 result := -0.5;
////               end;
//
//
////  var FX := TForceX.Create(0.002, 0);
////  var FY := TForceY.Create(0.002, 0);
//
//
//  FGraphControl.Simulation.Force[TForces.ForceCenterName] := F1;
//  FGraphControl.Simulation.Force[TForces.ForceLinkName]   := F2;
//  FGraphControl.Simulation.Force[TForces.ForceRadial]     := F3;
//  FGraphControl.Simulation.Force[TForces.ForceCollide]    := F4;
//  FGraphControl.Simulation.Force[TForces.ForceManyBody]   := F5;
//
////  FGraphControl.Simulation.Force['x'] := FX;
////  FGraphControl.Simulation.Force['y'] := FY;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FGraph.Free;
end;

procedure TForm1.GetTest1Graph(var Graph: TGraph);
begin
  Graph.Edges.Clear;
  Graph.Vertices.Clear;

  for var I := 0 to 4 do begin
    FGraph.Vertices.Add(TVertexCircle.Create);
    FGraph.Vertices.Last.Text := I.ToString;
  end;

  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0],  FGraph.Vertices.Items[1]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1],  FGraph.Vertices.Items[2]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2],  FGraph.Vertices.Items[3]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3],  FGraph.Vertices.Items[4]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4],  FGraph.Vertices.Items[0]));
//
  for var I := 5 to 19 do begin
    FGraph.Vertices.Add(TVertexRhomb.Create);
    FGraph.Vertices.Last.Text := I.ToString;
  end;
//
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0],  FGraph.Vertices.Items[5]));
  FGraph.Edges.Last.Text := 'Туды';
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0],  FGraph.Vertices.Items[6]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[0],  FGraph.Vertices.Items[7]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[5],  FGraph.Vertices.Items[0]));
  FGraph.Edges.Last.Text := 'Сюды';
//
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1],  FGraph.Vertices.Items[8]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1],  FGraph.Vertices.Items[9]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[1],  FGraph.Vertices.Items[10]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2],  FGraph.Vertices.Items[11]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2],  FGraph.Vertices.Items[12]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[2],  FGraph.Vertices.Items[13]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3],  FGraph.Vertices.Items[12]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3],  FGraph.Vertices.Items[13]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[3],  FGraph.Vertices.Items[14]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4],  FGraph.Vertices.Items[15]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4],  FGraph.Vertices.Items[16]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4],  FGraph.Vertices.Items[17]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[4],  FGraph.Vertices.Items[18]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[19],  FGraph.Vertices.Items[2]));
  FGraph.Edges.Last.Text := 'Обратно';
//
  for var I := 20 to 30 do begin
    FGraph.Vertices.Add(TVertexRect.Create);
    FGraph.Vertices.Last.Text := I.ToString;
  end;
//
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[5],  FGraph.Vertices.Items[20]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[5],  FGraph.Vertices.Items[21]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[5],  FGraph.Vertices.Items[22]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[6],  FGraph.Vertices.Items[23]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[6],  FGraph.Vertices.Items[24]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[7],  FGraph.Vertices.Items[25]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[8],  FGraph.Vertices.Items[26]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[8],  FGraph.Vertices.Items[27]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[8],  FGraph.Vertices.Items[28]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[9],  FGraph.Vertices.Items[29]));
  FGraph.Edges.Add(TEdge.Create(FGraph.Vertices.Items[9],  FGraph.Vertices.Items[30]));
//
//
  for var I := 0 to 99 do begin
    if I mod 3 = 0 then begin
      FGraph.Vertices.Add(TVertexRect.Create)
    end else begin
      if Odd(I)
        then FGraph.Vertices.Add(TVertexCircle.Create)
        else FGraph.Vertices.Add(TVertexRhomb.Create);
    end;

    FGraph.Vertices.Last.Text := I.ToString;
  end;
end;

procedure TForm1.GetTest1Simulation(Simulation: TGraphSimulation);
begin
  Simulation.Stop;
  Simulation.Graph := nil;
  Simulation.Alpha := 1;

  Simulation.Force['F1'] := nil;
  Simulation.Force['F2'] := nil;
  Simulation.Force['F3'] := nil;
  Simulation.Force['F4'] := nil;
  Simulation.Force['F5'] := nil;
  Simulation.Force[TForces.ForceCenterName] := nil;

  var F1 := TForceLink.Create;
  var F2 := TForceManyBody.Create;
  var F3 := TForceX.Create;
  var F4 := TForceY.Create;
  var F5 := TForceCollide.Create;

  F1.Distance := 100;
  F2.Theta    := 0.01;
  F2.Strength :=
    function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
    begin
      if (Vertex.Edges.Count > 0) or (Vertex.EdgesAsFrom.Count > 0) then begin
        result := -1000;
      end else
        result := -100;

    end;

  F3.X := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
          begin
            if (Vertex.Edges.Count = 0) and (Vertex.EdgesAsFrom.Count = 0) then
              result := 0 + 350
            else
              result := 0 - 250;

          end;

  F4.Y := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
          begin
            if (Vertex.Edges.Count = 0) and (Vertex.EdgesAsFrom.Count = 0) then begin
              if Vertex is TVertexCircle then
                result := 0 - 250
              else if Vertex is TVertexRect then
                result := 0
              else
                result := 0 + 250;
            end else begin
              result := 0
            end;
          end;

  F5.Radius := 40;

  Simulation.Force['F1'] := F1;
  Simulation.Force['F2'] := F2;
  Simulation.Force['F3'] := F3;
  Simulation.Force['F4'] := F4;
  Simulation.Force['F5'] := F5;
end;

procedure TForm1.VertexDraw(const Vertex: TVertex; const ACanvas: TCanvas;
  GraphicSettings: TGraphicSettings; var Handled: boolean);
begin
//  Vertex.Text := Vertex.Position.X.ToString+' : '+Vertex.Position.Y.ToString;
end;

procedure TForm1.VertexMove(const Vertex: TVertex; Shift: TShiftState; X,Y: single; IsPressed: boolean);
begin
  if IsPressed then begin
    if (Vertex.Edges.Count = 0) and (Vertex.EdgesAsFrom.Count = 0) then begin

      var FX := FGraphControl.Simulation.Force['F3'] as TForceX;
      var FY := FGraphControl.Simulation.Force['F4'] as TForceY;

      var VertexType := Vertex.ClassType;
      FX.X := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
              begin
                if (Vertex.Edges.Count = 0) and (Vertex.EdgesAsFrom.Count = 0) then begin
                  if (Vertex.ClassType = VertexType)
                    then result := X
                    else result := FX.Xs[Idx];
                end else begin
                  result := FX.Xs[Idx];
                end

              end;

      FY.Y := function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
              begin
                if (Vertex.Edges.Count = 0) and (Vertex.EdgesAsFrom.Count = 0) then begin
                  if (Vertex.ClassType = VertexType)
                    then result := Y
                    else result := FY.Ys[Idx];
                end else begin
                  result := FY.Ys[Idx]
                end;
              end;

      FGraphControl.Simulation.Alpha := 1;
      FGraphControl.Simulation.Restart;
    end;
  end;
end;

{ TGraphRecord }

constructor TGraphRecord.New(V1: integer; V2: string);
begin
  Value1 := V1;
  Value2 := V2;
end;

initialization
  ReportMemoryLeaksOnShutdown := true;

end.
