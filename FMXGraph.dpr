program FMXGraph;

uses
  System.StartUpCopy,
  FMX.Forms,
  View.Main in 'test\View.Main.pas' {Form1},
  Graph.FMX.GraphControl in 'source\Graph.FMX.GraphControl.pas',
  Graph in 'source\Graph.pas',
  Graph.Simulation in 'source\Graph.Simulation.pas',
  Graph.Simulation.Forces in 'source\Graph.Simulation.Forces.pas',
  Common.Generics.QuadTree in 'source\Common.Generics.QuadTree.pas',
  FastGeo in 'source\FastGeo.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
