unit Graph.Simulation;
{
 Этот модуль  реализует численный интегратор Velocity Verlet для
 симуляции физических сил на частицах. Симуляция упрощена: она предполагает
 постоянный единичный шаг времени Δt = 1 для каждого шага и постоянную
 единичную массу m = 1 для всех частиц. В результате сила F, действующая на
 частицу, эквивалентна постоянному ускорению a за интервал времени Δt и
 может быть смоделирована просто путем добавления к скорости частицы, которая
 затем добавляется к положению частицы.
}

interface

uses
    System.Generics.Collections
  , System.Types
  , System.SysUtils
  , System.Math
  , System.Math.Vectors
  , FMX.Types
  , Graph
  ;

type
  TGraphSimulation = class;
  TForce           = class;

  TSimulationEvent      = (EventStart, EventTick, EventEnd);
  TGraphSimulationEvent = procedure(Event: TSimulationEvent) of object;

  TGraphSimulation = class sealed
  private
    FInitialCenter: TPointF;
    FInitialRadius: double;
    FInitialAngle : double;

  private
    FGraph: TGraph;

    FAlpha        : double;
    FAlphaMin     : double;
    FAlphaDecay   : double;
    FAlphaTarget  : double;
    FVelocityDecay: double;
    FRandom       : TFunc<Extended>;

    FForces: TDictionary<string, TForce>;

    FSimulationEvent: TGraphSimulationEvent;
    FTimer          : TTimer;

    procedure Step(Sender: TObject);
    procedure DoEvent(Event: TSimulationEvent);

    procedure InitializeVertices;
    function InitializeForce(Force: TForce): TForce;

    procedure SetGraph(Value: TGraph);
    function GetVelocityDecay: double;
    procedure SetVelocityDecay(Value: double);
    procedure SetRandom(Value: TFunc<Extended>);
    function GetForce(ForceName: string): TForce;
    procedure SetForce(ForceName: string; Value: TForce);
    procedure SetInitialCenter(const Value: TPointF);
    procedure SetAlpha(const Value: double);
    procedure SetAlphaMin(const Value: double);
    procedure SetAlphaDecay(const Value: double);
    procedure SetAlphaTarget(const Value: double);

  public
    constructor Create;
    destructor Destroy; override;

    ///  Перезапускает внутренний таймер симуляции.
    ///  В сочетании с AlphaTarget или Alpha этот метод можно использовать для
    ///  "разогрева" симуляции во время взаимодействия, например, при перетаскивания
    ///  Вершины, или для возобновления симуляции после временной паузы (Stop).
    procedure Restart;

    ///  Останавливает внутренний таймер симуляции.
    ///  Этот метод полезен для запуска симуляции вручную (Tick)
    procedure Stop;

    ///  Вручную выполняет симуляцию на указанное кол-во итераций.
    ///  Для каждой итерации метод увеличиваеи текущее значение Alpha на
    ///  (AlphaTarget - Alpha) * AlphaDecay;
    ///  затем вызывает каждую зарегистрированную силу (Forces), передавая ей
    ///  новое значение Alpha;
    ///  затем уменьшает Velocity каждой Вершины на Velocity*VelocityDecay;
    ///  и наконец, увеличивает положение каждого узна на Velocity.
    ///
    ///  Этот метод не отправляет события. События отправляются только внутринним
    ///  таймером, когда симуляция запущена методом Restart. Натуральное число тиков
    ///  при запуске симуляции равно |log(AlphaMin)/log(1-AlphaDecay)| и по умолчанию
    ///  составляет значение 300.
    ///
    ///  Этот метод можно использовать в ссочетании с методом Stop для статического
    ///  вычисления развертки графа.
    procedure Tick(Iterations: integer = 1);

    ///  Исходный граф для которого будет выполнятся симуляция.
    ///  Если граф изменен, например, когда узлы добавляются или удаляются из сомуляции,
    ///  необходимо снова присвоить граф, чтобы уведомить сомуляцию и связанные силы об
    ///  изменении.
    property Graph: TGraph read FGraph write SetGraph;

    ///  Alpha примерно аналогична температуре при симуляции отжига.
    ///  Со временем он уменьшается по мере "остывания" симуляции.
    ///  Когда Alpha достигает AlphaMin, симуляция останавливается.
    ///
    ///  Принимаемое значние в диапазоне [0..1].
    ///  По умолчанию значение равно 1.
    property Alpha: double read FAlpha write SetAlpha;

    ///  Внутренний таймер симуляции останавливается, когда текущее значение
    ///  Alpha меньше значения AlphaMin.
    ///
    ///  Принимаемое значение в диапазоне [0..1].
    ///  По умолчанию значение равно 0.001.
    property AlphaMin: double read FAlphaMin write SetAlphaMin;

    ///  AlphaDecay определяет, как быстро текущая Alpha интерполируеися в направлении
    ///  желаемой AlphaTarget.
    ///  Более высокие скорости затухания приводят к тому, что симуляция стабилизируется
    ///  быстрее, но рискует застрять в локальном минимуме.
    ///  Более низкние значения приводят к тому, что симуляция выполняется дольше,
    ///  но обычно сходится к лучшей разрвертке.
    ///  Чтобы симуляция продолжалась вечно при текущей Alpha, установите AlphaDecay
    ///  равной 0. В качестве альтернативы установите AlphaTarget больше AlphaMin.
    ///
    ///  Принимаемое значение в диапазоне [0..1].
    ///  По умолчанию значение равно ~ 0.0228.
    property AlphaDecay: double read FAlphaDecay write SetAlphaDecay;

    ///  AlphaTarget определяет к какому значению стремится Alpha при интерполяции.
    ///
    ///  Принимаемое значение в диапазоне [0..1].
    ///  По умолчанию значение равно 0.
    property AlphaTarget: double read FAlphaTarget write SetAlphaTarget;

    ///  Коэффициент затухания скорости.
    ///  Коэффициент затухания сродни атмосферному трению. После приложения любых сил
    ///  во время выполнения Tick значение Velocity каждого узла умножается на 1-VelocityDecay.
    ///  Как и при меньшей AlphaDecay, меньшее значение VelocityDecay может выдать
    ///  лучшее решение, но есть риск численной нестабильности и коллебаний.
    ///
    ///  Принимаемое значение в диапазоне [0..1].
    ///  По умолчанию значение равно 0.4.
    property VelocityDecay: double read GetVelocityDecay write SetVelocityDecay;

    ///  Список сил по уникальному названию (не регистрозависимый).
    ///
    ///  Чтобы добавить силу в симуляцию вы можете написать так:
    ///  Simulation.Force['Link'] := TForceLink.Create;
    ///
    ///  Чтобы удалить силу вы можете написать так:
    ///  Simulation.Force['Link'] := nil;
    ///
    ///  Если силы с таким название не существует, вернет значение nil.
    ///
    ///  TGraphSimulation сам уничтожает экземпляры сил.
    property Force[ForceName: string]: TForce read GetForce write SetForce;

    ///  Функция генерации случайных чисел в диапазоне от 0 (включительно) до 1 (исключительно).
    ///  Вы можете задать свою функцию.
    property RandomSource: TFunc<Extended> read FRandom write SetRandom;

    property InitialRadius: double read FInitialRadius write FInitialRadius;
    property InitialAngle: double read FInitialAngle write FInitialAngle;
    property InitialCenter: TPointF read FInitialCenter write SetInitialCenter;

    ///  Поиск вершины в указанном радиусе указанной точки.
    ///  Если ничего не найдено возвращает nil.
    function Find(Point: TPointF; Radius: double = INFINITY): TVertex;

    ///  События симуляции. См. TSimulationEvent
    ///  События отправляются только внутренним таймером и предназначены для
    ///  интерактивного рендеринга симуляции.
    property OnEvent: TGraphSimulationEvent read FSimulationEvent write FSimulationEvent;
  end;

  ///  Базовый класс для сил симуляции.
  ///  Доступные силы см. Graph.Simulation.Forces
  TForce = class abstract
  protected
    FGraph : TGraph;
    FRandom: TFunc<Extended>;

    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); virtual;
    procedure Force(Alpha: double); virtual; abstract;

  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TForces = class
  const ForceCenterName = 'ForceCenter';

  const ForceLinkName = 'ForceLink';

  const ForceRadial = 'ForceRadial';

  const ForceCollide = 'ForceCollide';

  const ForceManyBody = 'ForceManyBody';

  const ForceX = 'ForceX';

  const ForceY = 'ForceY';
  end;

function Jiggle(Random: TFunc<Extended>): double;

implementation

{$REGION 'Jiggle'}


function Jiggle(Random: TFunc<Extended>): double;
begin
  result := (Random() - 0.5) * 1E-6;
end;
{$ENDREGION}

{$REGION 'TGraphSimulation'}

constructor TGraphSimulation.Create;
begin
  InitialRadius  := 10;
  InitialAngle   := Pi * (3 - sqrt(5));
  FInitialCenter := TPointF.Zero;

  FGraph := nil;

  FAlpha         := 0.0;
  FAlphaMin      := 0.001;
  FAlphaDecay    := 1 - Power(FAlphaMin, 1 / 300);
  FAlphaTarget   := 0;
  FVelocityDecay := 0.6;
  FRandom        := Random;

  FForces          := TObjectDictionary<string, TForce>.Create([doOwnsValues]);
  FTimer           := TTimer.Create(nil);
  FTimer.Enabled   := false;
  FTimer.OnTimer   := Step;
  FTimer.Interval  := 5;
  FSimulationEvent := nil;
end;

destructor TGraphSimulation.Destroy;
begin
  FTimer.Free;
  FForces.Free;
  inherited;
end;

procedure TGraphSimulation.DoEvent(Event: TSimulationEvent);
begin
  if assigned(FSimulationEvent) then
    FSimulationEvent(Event);
end;

function TGraphSimulation.Find(Point: TPointF; Radius: double): TVertex;
begin
  result := nil;
  if not Radius.IsInfinity then
    Radius := Radius * Radius;

  for var Vertex in FGraph.Vertices do
  begin
    var d   := Point - Vertex.Position;
    var d2  := d.X * d.X + d.Y * d.Y;

    if d2 < Radius then
    begin
      result := Vertex;
      Radius := d2;
    end;
  end;
end;

function TGraphSimulation.GetForce(ForceName: string): TForce;
begin
  if not FForces.TryGetValue(ForceName.ToLower, result) then
    result := nil;
end;

function TGraphSimulation.GetVelocityDecay: double;
begin
  result := 1 - FVelocityDecay;
end;

function TGraphSimulation.InitializeForce(Force: TForce): TForce;
begin
  Force.Initialize(FGraph, FRandom);
  result := Force;
end;

procedure TGraphSimulation.InitializeVertices;
begin
  if FGraph = nil then
    exit;

  var n := FGraph.Vertices.Count;
  for var I := 0 to n - 1 do
  begin
    var Vertex := FGraph.Vertices.Items[I];
    Vertex.Idx := I;
    if Vertex.IsFixed then
      Vertex.Position := Vertex.PositionFixed;

    if Vertex.Position.X.IsNan or Vertex.Position.Y.IsNan then
    begin
      var Radius := FInitialRadius * sqrt(0.5 + I);
      var Angle  := I * FInitialAngle;

      Vertex.Position.X := FInitialCenter.X + Radius * cos(Angle);
      Vertex.Position.Y := FInitialCenter.Y + Radius * sin(Angle);
    end;

    if Vertex.Velocity.X.IsNan or Vertex.Velocity.Y.IsNan then
    begin
      Vertex.Velocity := TPointF.Zero;
    end;
  end;
end;

procedure TGraphSimulation.Restart;
begin
  FTimer.Enabled := true;
  DoEvent(TSimulationEvent.EventStart);
end;

procedure TGraphSimulation.SetAlpha(const Value: double);
begin
  FAlpha := max(0.0, min(1, Value));
end;

procedure TGraphSimulation.SetAlphaDecay(const Value: double);
begin
  FAlphaDecay := max(0.0, min(1, Value));
end;

procedure TGraphSimulation.SetAlphaMin(const Value: double);
begin
  FAlphaMin := max(0.0, min(1, Value));
end;

procedure TGraphSimulation.SetAlphaTarget(const Value: double);
begin
  FAlphaTarget := max(0.0, min(1, Value));
end;

procedure TGraphSimulation.SetForce(ForceName: string; Value: TForce);
begin
  if Value = nil
  then
    FForces.Remove(ForceName.ToLower)
  else
    FForces.Add(ForceName.ToLower, InitializeForce(Value));
end;

procedure TGraphSimulation.SetGraph(Value: TGraph);
begin
  FGraph := Value;
  InitializeVertices;
  for var Force in FForces.Values do
  begin
    InitializeForce(Force);
  end;
end;

procedure TGraphSimulation.SetInitialCenter(const Value: TPointF);
begin
  FInitialCenter := Value;
  if not FTimer.Enabled then
    InitializeVertices;
end;

procedure TGraphSimulation.SetRandom(Value: TFunc<Extended>);
begin
  FRandom := Value;
  for var Force in FForces.Values do
  begin
    InitializeForce(Force);
  end;
end;

procedure TGraphSimulation.SetVelocityDecay(Value: double);
begin
  FVelocityDecay := 1 - Value;
end;

procedure TGraphSimulation.Step(Sender: TObject);
begin
  Tick;
  DoEvent(TSimulationEvent.EventTick);
  if FAlpha < FAlphaMin then
  begin
    FTimer.Enabled := false;
    DoEvent(TSimulationEvent.EventEnd);
  end;
end;

procedure TGraphSimulation.Stop;
begin
  FTimer.Enabled := false;
end;

procedure TGraphSimulation.Tick(Iterations: integer);
begin
  for var K := 0 to Iterations - 1 do
  begin
    FAlpha := FAlpha + (FAlphaTarget - FAlpha) * FAlphaDecay;

    for var Force in FForces.Values do
      Force.Force(FAlpha);

    if FGraph <> nil then
      for var Vertex in FGraph.Vertices do
      begin
        if Vertex.IsFixed or Vertex.IsPreFixed then
        begin
          Vertex.Position := Vertex.PositionFixed;
          Vertex.Velocity := TPointF.Zero;
        end
        else
        begin
          Vertex.Velocity := Vertex.Velocity * FVelocityDecay;
          Vertex.Position := Vertex.Position + Vertex.Velocity;
        end;
      end;
  end;
end;

{$ENDREGION}

{$REGION 'TForce'}


constructor TForce.Create;
begin
  FGraph  := nil;
  FRandom := nil;
end;

destructor TForce.Destroy;
begin
  FRandom := nil;
  FGraph  := nil;
  inherited;
end;

procedure TForce.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  FGraph  := Graph;
  FRandom := Random;
end;

{$ENDREGION}

end.
