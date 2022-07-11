unit test.Graph;

interface

uses
    DUnitX.TestFramework
  , System.Generics.Collections
  , Common.Generics.Graph
  ;

type
  [TestFixture]
  TTestGraphs = class
  private
    class function GetUndirectedGraph: TGraph<integer>; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

class function TTestGraphs.GetUndirectedGraph: TGraph<integer>;
begin
  var Verticies := TList<TVertex<integer>>.Create;
  var v1 := TVertex<integer>.Create(1);
  var v2 := TVertex<integer>.Create(2);
  var v3 := TVertex<integer>.Create(3);
  var v4 := TVertex<integer>.Create(4);
  var v5 := TVertex<integer>.Create(5);
  var v6 := TVertex<integer>.Create(6);
  var v7 := TVertex<integer>.Create(7);
  var v8 := TVertex<integer>.Create(8);

  Verticies.Add(v1);
  Verticies.Add(v2);
  Verticies.Add(v3);
  Verticies.Add(v4);
  Verticies.Add(v5);
  Verticies.Add(v6);
  Verticies.Add(v7);
  Verticies.Add(v8);

  var Edges := TList<TEdge<integer>>.Create;
  var e1_2 := TEdge<integer>.Create(7,  v1, v2);
  var e1_3 := TEdge<integer>.Create(9,  v1, v3);
  var e1_6 := TEdge<integer>.Create(14, v1, v6);
  var e2_3 := TEdge<integer>.Create(10, v2, v3);
  var e2_4 := TEdge<integer>.Create(15, v2, v4);
  var e3_4 := TEdge<integer>.Create(11, v3, v4);
  var e3_6 := TEdge<integer>.Create(2,  v3, v6);
  var e5_6 := TEdge<integer>.Create(9,  v5, v6);
  var e4_5 := TEdge<integer>.Create(6,  v4, v5);
  var e1_7 := TEdge<integer>.Create(1,  v1, v7);
  var e1_8 := TEdge<integer>.Create(1,  v1, v8);

  Edges.add(e1_2);
  Edges.add(e1_3);
  Edges.add(e1_6);
  Edges.add(e2_3);
  Edges.add(e2_4);
  Edges.add(e3_4);
  Edges.add(e3_6);
  Edges.add(e5_6);
  Edges.add(e4_5);
  Edges.add(e1_7);
  Edges.add(e1_8);


  result := TGraph<integer>.Create(Verticies, Edges);
end;

procedure TTestGraphs.Setup;
begin
end;

procedure TTestGraphs.TearDown;
begin
end;

procedure TTestGraphs.Test1;
begin
end;

procedure TTestGraphs.Test2(const AValue1 : Integer;const AValue2 : Integer);
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGraphs);

end.
