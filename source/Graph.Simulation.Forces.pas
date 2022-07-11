unit Graph.Simulation.Forces;

{
 Сила-это просто метод, который изменяет положения (Position) или
 скорости (Velocity) Вершин;
 в этом контексте сила может применять классическую физическую силу, такую как
 электрический заряд или гравитация, или она может разрешить геометрическое
 ограничение, такое как удержание Вершин в ограничивающем прямоугольнике или
 удержание связанных Вершин на фиксированном расстоянии друг от друга.
 Например, простая сила позиционирования, которая перемещает вершины к
 началу координат (0,0), может быть реализована как:

 procedure Force(Alpha: double);
 begin
 var k := Alpha * 0.1;
 for Vertex in FGraph.Vertices do
 begin
 Vertex.Velocity.X := Vertex.Velocity.X * k;
 Vertex.Velocity.Y := Vertex.Velocity.Y * k;
 end;
 end;

 Силы обычно считывают текущее положение Вершины (TVertex.Position), а затем
 добавляет (или вычтает) скорость Вершины (TVertex.Velocity).
 Однако силы могут также “заглядывать вперед” к ожидаемой следующей позиции
 Вершины, TVertex.Position + TVertex.Velocity;
 это необходимо для разрешения геометрических ограничений через итеративную релаксацию.
 Силы могут также изменять положение напрямую, что иногда полезно, чтобы избежать
 добавления энергии к моделированию, например, при повторном центрировании симуляции
 в окне просмотра.

 Симуляция оыбчно составляет несколько сил по желанию. В данном модуле реализовано
 несклько сил, которые вы можете использовать.
 Или можете реализовать свои силы, наследуясь от Graph.Simulation.TForce

}

interface

uses
    System.Generics.Collections
  , System.Types
  , System.SysUtils
  , Graph
  , Graph.Simulation
  , Common.Generics.QuadTree
  ;

type
  TUserMethodE = reference to function(Edge: TEdge; Idx: integer; Edges: TEnumerable<TEdge>): double;
  TUserMethodV = reference to function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double;

  TValueOrFuncE = record
    class operator Implicit(a: double): TValueOrFuncE;
    class operator Implicit(a: TUserMethodE): TValueOrFuncE;

  strict private
    FFunc: TUserMethodE;

  public
    property Func: TUserMethodE read FFunc;
  end;

  TValueOrFuncV = record
    class operator Implicit(a: double): TValueOrFuncV;
    class operator Implicit(a: TUserMethodV): TValueOrFuncV;

  strict private
    FFunc: TUserMethodV;

  public
    property Func: TUserMethodV read FFunc;
  end;

  ///  Центрирующая сила переводит Вершины равномерно, так что среднее положение
  ///  всех Вершин (центр масс, если все Вершины имеют одинаковый вес)
  ///  находится в заданном положении CenterPoint. Эта сила изменяет положение
  ///  Вершин в каждой итерации; она не изменяет Velocity, так как это обычно
  ///  приводит к тому, что Вершины отклоняются и колеблются вокруг желаемого центра.
  ///  Эта сила помогает удерживать Вершины в центре окна просмотра и, в отличие
  ///  от силы позиционирования, не искажает их относительное положение.
  TForceCenter = class(TForce)
  protected
    FStrength   : double;
    FCenterPoint: TPointF;

    procedure SetCenterPoint(Value: TPointF);
    procedure SetStrength(Value: double);

  protected
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength: double; CenterPoint: TPointF); reintroduce; overload;

    ///  Координата центрирования
    ///
    ///  По умолчанию значение равно (X:0, Y:0).
    property CenterPoint: TPointF read FCenterPoint write SetCenterPoint;
    ///  Интенсивность центрирующеЙ силы.
    ///  Маленькая интенсивность, например 0.05, смягчает движения на интерактивным
    ///  графах, в которых новые Вершины входят или выходят из графа.
    ///
    ///  По умолчанию значение равно 1.
    property Strength: double read FStrength write SetStrength;
  end;

  ///  Сила связи толкает связанные Вершины вместе или врозь в зависимости от
  ///  желаемого расстояния связи. Интенсивность силы пропорциональна разнице
  ///  между расстоянием между связанными узлами и целевым расстоянием,
  ///  аналогично силе пружины.
  TForceLink = class(TForce)
  protected
    FStrength: TValueOrFuncE;
    FDistance: TValueOrFuncE;

    FStrengths : TArray<double>;
    FDistances : TArray<double>;
    FCount     : TArray<integer>;
    FBias      : TArray<double>;
    FIterations: integer;

    procedure SetStrength(Value: TValueOrFuncE);
    procedure SetDistance(Value: TValueOrFuncE);

    procedure Initialize; reintroduce; overload;
    procedure InitializeStrength;
    procedure InitializeDistance;

  private
    function GetDistances(EdgeIdx: integer): double;
    function GetStrengths(EdgeIdx: integer): double;

  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strenght, Distance: double; Iterations: integer); reintroduce; overload;

    ///  Текущее значение интенсивности для каждой связи.
    property Strengths[EdgeIdx: integer]: double read GetStrengths;

    ///  Текущее значение растояния для каждой связи.
    property Distances[EdgeIdx: integer]: double read GetDistances;

    ///  Кол-во итераций для релаксации.
    ///  Увеличение числа итераций значительно увеличивает жесткость ограничения
    ///  и полезно для сложных структур, таких как решетки, но также увеличивает
    ///  стоимость времени выполнения для оценки силы.
    ///
    ///  По умолчанию значение равно 1.
    property Iterations: integer read FIterations write FIterations;
    ///  Интернсивность силы связи.
    ///  Можно указать фиксированное значение или вычисляемую функцию.
    ///  Функция вызывается для каждой вершины в симуляции, а результат сохраняется внутри
    ///  класса, так что интенсивность каждой Вершины вычисляется только при инициализации силы
    ///  или при указании новой функции, а не при каждом применении силы.
    ///
    ///  По умолчанию значение равно 1 / min(FCount[Edge.VertexFrom.Idx], FCount[Edge.VertexTo.Idx])
    ///  Это значение по умолчанию было выбрано потому, что оно автоматически уменьшает
    ///  прочность связей, подключенных к Вершинам с большой связью, улучшая стабильность.
    property Strength: TValueOrFuncE read FStrength write SetStrength;
    ///  Желаемое растояние между связанными Вершинами.
    ///  Можно указать фиксированное значение или вычисляемую функцию.
    ///  Функция вызывается для каждой вершины в симуляции, а результат сохраняется внутри
    ///  класса, так что растояние каждой Вершины вычисляется только при инициализации силы
    ///  или при указании новой функции, а не при каждом применении силы.
    ///
    ///  По умолчанию значение равно 30.
    property Distance: TValueOrFuncE read FDistance write SetDistance;
  end;

  ///  Сила столкновения рассматривает Вершины как круги с заданным радиусом,
  ///  а не точки, и предотвращает перекрытие Вершин.
  ///  Более формально две Вершины a и b разделены так, что расстояние между a и b
  ///  составляет не менее radius(a) + radius(b). Чтобы уменьшить дрожание,
  ///  по умолчанию это “мягкое” ограничение с настраиваемой силой и количеством итераций.
  TForceCollide = class(TForce)
  protected const
    F_RADIUS = '_ForceCollide_radius';
  protected
    FIterations: integer;
    FStrength  : double;
    FRadius    : TValueOrFuncV;
    FRadii     : TArray<double>;

    procedure Initialize; reintroduce; overload;

    procedure SetIterations(Value: integer);
    procedure SetStrength(Value: double);
    procedure SetRadius(Value: TValueOrFuncV);

  private
    function GetRadiuses(VertexIdx: integer): double;

    procedure PrepareTree(QuadTree: TQuadTree<TVertex>; Node: TNode<TVertex>);
    procedure CalculateForces(Vertex: TVertex; QuadTree: TQuadTree<TVertex>);
  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength, Radius: double; Iterations: integer); reintroduce; overload;

    /// Текущие значения радиусов для каждой вершины.
    property Radiuses[VertexIdx: integer]: double read GetRadiuses;

    ///  Кол-во итераций для релаксации. (см. описание Strength)
    ///  Увеличение числа итераций значительно увеличивает жесткость ограничения
    ///  и позволяет избежать частичного перекрытия Вершин, но также увеличивает
    ///  затраты времени выполнения для оценки силы.
    ///  По умолчанию значение равно 1.
    property Iterations: integer read FIterations write SetIterations;

    ///  Интенсивность силы столкновения.
    ///  Перекрывающиеся Вершины разрешаются путем итеративной релаксации.
    ///  Для каждой вершины определяются другие Вершины, которые, как ожидается,
    ///  перекрываются на следующем тике (используя ожидаемые позиции:
    ///  TVertex.Position + TVertex. Velocity).
    ///  Затем Velocity Вершины изменяется, чтобы вытолкнуть Вершину из каждой
    ///  перекрывающеся Вершины. Изменение Velocity гасится интенсивностью силы,
    ///  так что разрешение одновременных перекрытий может быть смешано вместе,
    ///  чтобы найти стабильное решение.
    ///
    ///  Принимаемое значение в диапазоне [0..1].
    ///  По умолчанию значение равно 1.
    property Strength: double read FStrength write SetStrength;

    ///  Радиус столкновения.
    ///  Можно указать фиксированное значение или вычисляемую функцию.
    ///  Функция вызывается для каждой вершины в симуляции, а результат сохраняется внутри
    ///  класса, так что радиус каждой Вершины вычисляется только при инициализации силы
    ///  или при указании новой функции, а не при каждом применении силы.
    ///
    ///  По умолчанию занчение равно 1.
    property Radius: TValueOrFuncV read FRadius write SetRadius;
  end;

  ///  Сила многих тел (или n-тел) применяется взаимно между всеми Вершинами.
  ///  Его можно использовать для имитации гравитации (притяжения), если сила положительна,
  ///  или электростатического заряда (отталкивания), если сила отрицательна.
  ///  Эта реализация использует квадродеревья и приближение Барнса–Хата для
  ///  значительного повышения производительности; точность может быть
  ///  настроена с помощью параметра theta.

  ///  В отличие от ссылок, которые влияют только на две связанные Вершины,
  ///  сила заряда является глобальной: каждая Вершина влияет на любую другую Вершину,
  ///  даже если они находятся на несвязанных подграфах.
  TForceManyBody = class(TForce)
  protected const
    F_VALUE = '_ForceManyBody_value';

  protected
    FStrength    : TValueOrFuncV;
    FDistanceMin2: double;
    FDistanceMax2: double;
    FTheta2      : double;

    FStrengths: TArray<double>;

    procedure Initialize; reintroduce; overload;

    procedure SetStrength(Value: TValueOrFuncV);
    function GetDistanceMin: double;
    procedure SetDistanceMin(Value: double);
    function GetDistanceMax: double;
    procedure SetDistanceMax(Value: double);
    function GetTheta: double;
    procedure SetTheta(Value: double);

  private
    function GetStrengths(VertexIdx: integer): double;

    procedure AccumulateForces(QuadTree: TQuadTree<TVertex>; Node: TNode<TVertex>);
    procedure CalculateForces(Vertex: TVertex; QuadTree: TQuadTree<TVertex>; Alpha: double);
  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength, DistanceMin, DistanceMax, Theta: double); reintroduce; overload;

    /// Текущие значения интенсивности для каждой вершины.
    property Strengths[VertexIdx: integer]: double read GetStrengths;

    ///  Интенсивность силы.
    ///  Можно указать фиксированное значение или вычисляемую функцию.
    ///  Функция вызывается для каждой вершины в симуляции, а результат сохраняется внутри
    ///  класса, так что радиус каждой Вершины вычисляется только при инициализации силы
    ///  или при указании новой функции, а не при каждом применении силы.
    ///
    ///  Положительное значение заставляет Вершины притягиваться друг к другу,
    ///  подобно гравитации, в то время как отрицательное значение заставляет
    ///  Вершины отталкиваться друг от друга, подобно электростатическому заряду.
    ///
    ///  По умолчанию значение равно -30.
    property Strength: TValueOrFuncV read FStrength write SetStrength;

    ///  Критерий приближения Барнса-Хата.
    ///  Для ускорения вычислений эта сила реализует приближение Барнса–Хата,
    ///  которое принимает O(n log n) для каждого вычисления, где n - количество Вершин.
    ///  Для каждого вычисления квадродерево хранит текущие позиции Вершин;
    ///  затем для каждой Вершины вычисляется объединенная сила всех других Вершин
    ///  на данной Вершине. Для кластера Вершин, который находится далеко,
    ///  зарядовая сила может быть аппроксимирована, рассматривая кластер как
    ///  одну более крупную Вершину. Параметр theta определяет точность аппроксимации:
    ///  если отношение w / l ширины w ячейки квадродерева к расстоянию l от вершины
    ///  до центра масс ячейки меньше тета, все Вершины в данной ячейке рассматриваются
    ///  как одна Вершина, а не по отдельности.
    ///
    ///  Значение по умолчанию равно 0.9
    property Theta: double read GetTheta write SetTheta;

    ///  Минимальное расстояние между Вершинами над которыми рассматривается эта сила.
    ///  Минимальное расстояние устанавливает верхнюю границу интенсивности силы между
    ///  двумя соседними Вершинами, избегая нестабильности. В частности, он избегает
    ///  бесконечно сильной силы, если две вершины точно совпадают; в этом случае
    ///  направление силы является случайным.
    ///
    ///  Значение по умолчанию равно 1.
    property DistanceMin: double read GetDistanceMin write SetDistanceMin;

    ///  Максимальное расстояние между Вершинами, над которыми рассматривается эта сила.
    ///  Указание конечного максимального расстояние повышает производительность и создает
    ///  более локализованную компановку.
    ///
    ///  Значение по умолчанию равно бесконечности.
    property DistanceMax: double read GetDistanceMax write SetDistanceMax;

  end;

  {
   TForceX, TForceY - силы позиционирования по осям X и Y.
   Данные силы толкают узлы в желаемое положение по заданному измерению с настраиваемой силой.
   Strength силы  пропорциональна одномерному расстоянию между позицией узла и целевой позицией.
   Хотя эти силы можно испльзовать ждя позиционирования отдельных узлов, они предназначены
   главным образом для глобальных сил, которые применяются ко всем (или большенству) узлов.
  }

  ///  Позиционируюшая сила по оси X
  TForceX = class(TForce)
  protected
    Fx        : TValueOrFuncV;
    FStrength : TValueOrFuncV;
    FStrengths: TArray<double>;
    Fxz       : TArray<double>;

    procedure Initialize; reintroduce; overload;
    procedure SetStrength(Value: TValueOrFuncV);
    procedure SetX(Value: TValueOrFuncV);

  private
    function GetXs(VertexIdx: integer): double;

  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength, X: double); reintroduce; overload;

    ///  Текущее значение позиционирования по оси X для каждой вершины.
    property Xs[VertexIdx: integer]: double read GetXs;

    ///  Интенсивность силы.
    ///  Определяет, на сколько увеличить x-velocity узла: (x - vertex.x) * strength.
    ///  Принимает число или функцию.
    ///  Например, значение 0.1 указвает, что узел должен перемещаться на десятую часть пути
    ///  от своей текущей позиции по оси X до целевой позиции X при каждом тике симуляции.
    ///  Более высокие значения перемещают узлы быстрее к целевому положению, часто за счет
    ///  других сил или ограничений. Значение вне диапазона [0..1] не рекомендуются.
    ///
    ///  Strength-функция вызывается для каждого узла в симуляции, передавая узел и его индекс,
    ///  начинающийся с нуля. Полученное число затем сохраняется внутри, так что strength каждого узла
    ///  пересчитывается только при инициализации силы или когда этому свойству присваивается новое значение,
    ///  а не при каждом тике симуляции.
    property Strength: TValueOrFuncV read FStrength write SetStrength;

    ///  Значение позиционирования по оси X.
    ///  Принимает число или функцию.
    property X: TValueOrFuncV read Fx write SetX;
  end;

  ///  Позиционируюшая сила по оси Y
  TForceY = class(TForce)
  protected
    Fy        : TValueOrFuncV;
    FStrength : TValueOrFuncV;
    FStrengths: TArray<double>;
    Fyz       : TArray<double>;

    procedure Initialize; reintroduce; overload;

    procedure SetStrength(Value: TValueOrFuncV);
    procedure SetY(Value: TValueOrFuncV);

  private
    function GetYs(VertexIdx: integer): double;

  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength, Y: double); reintroduce; overload;

    ///  Текущее значение позиционирования по оси Y для каждой вершины.
    property Ys[VertexIdx: integer]: double read GetYs;

    ///  Интенсивность силы.
    ///  Определяет, на сколько увеличить y-velocity узла: (y - vertex.y) * strength.
    ///  Принимает число или функцию.
    ///  Например, значение 0.1 указвает, что узел должен перемещаться на десятую часть пути
    ///  от своей текущей позиции по оси Y до целевой позиции Y при каждом тике симуляции.
    ///  Более высокие значения перемещают узлы быстрее к целевому положению, часто за счет
    ///  других сил или ограничений. Значение вне диапазона [0..1] не рекомендуются.
    ///
    ///  Strength-функция вызывается для каждого узла в симуляции, передавая узел и его индекс,
    ///  начинающийся с нуля. Полученное число затем сохраняется внутри, так что strength каждого узла
    ///  пересчитывается только при инициализации силы или когда этому свойству присваивается новое значение,
    ///  а не при каждом тике симуляции.
    property Strength: TValueOrFuncV read FStrength write SetStrength;

    ///  Значение позиционирования по оси Y.
    ///  Принимает число или функцию.
    property Y: TValueOrFuncV read Fy write SetY;
  end;

  ///  Позиционирующая сила по направлению к окружности заданного радиуса с
  ///  центром в CenterPoint.
  TForceRadial = class(TForce)
  protected
    FCenterPoint: TPointF;
    FRadius     : TValueOrFuncV;
    FStrength   : TValueOrFuncV;

    FRadiuses : TArray<double>;
    FStrengths: TArray<double>;

    procedure Initialize; reintroduce; overload;

    procedure SetStrength(Value: TValueOrFuncV);
    procedure SetRadius(Value: TValueOrFuncV);

  private
    function GetRadiuses(VertexIdx: integer): double;
    function GetStrengths(VertexIdx: integer): double;

  protected
    procedure Initialize(Graph: TGraph; Random: TFunc<Extended>); overload; override;
    procedure Force(Alpha: double); override;

  public
    constructor Create; overload; override;
    constructor Create(Strength, Radius: double; CenterPoint: TPointF); reintroduce; overload;

    ///  Текущее значение радиуса для каждой вершины.
    property Radiuses[VertexIdx: integer]: double read GetRadiuses;
    ///  Текущее значение интенсивности для каждой вершины.
    property Strengths[VertexIdx: integer]: double read GetStrengths;

    ///  Интенсивность силы.
    ///  Интенсивность определяет, насколько увеличить Velocty Вершины.
    ///  Например, значение  0.1 указывает, что Вершина должна перемещаться на
    ///  десятую часть пути от своего текущего положения до ближайшей точки на
    ///  окружности с каждым вычислением.
    ///  Более высокие значения перемещают Вершины быстрее в целевую позицию,
    ///  часто за счет других сил или ограничений.
    ///  Значения вне диапазона [0..1] не рекомендуется.
    ///
    ///  Strength-функция вызывается для каждого узла в симуляции, передавая узел и его индекс,
    ///  начинающийся с нуля. Полученное число затем сохраняется внутри, так что strength каждого узла
    ///  пересчитывается только при инициализации силы или когда этому свойству присваивается новое значение,
    ///  а не при каждом тике симуляции.
    ///
    ///  По умолчанию значение равно  0.1
    property Strength: TValueOrFuncV read FStrength write SetStrength;
    ///  Радиус окружности.
    ///  Принимает число или функцию.
    property Radius: TValueOrFuncV read FRadius write SetRadius;
    ///  Центр окружности.
    ///  Принимает число или функцию.
    property CenterPoint: TPointF read FCenterPoint write FCenterPoint;
  end;

implementation

uses
    System.Math
  , System.Math.Vectors
  ;

{$REGION 'TForceCenter'}


constructor TForceCenter.Create;
begin
  Create(1, TPointF.Zero);
end;

constructor TForceCenter.Create(Strength: double; CenterPoint: TPointF);
begin
  inherited Create;
  FStrength    := Strength;
  FCenterPoint := CenterPoint;
end;

procedure TForceCenter.Force(Alpha: double);
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  var
  sp := TPointF.Zero;
  var
  n := FGraph.Vertices.Count;

  if FGraph <> nil then
  begin
    for var Vertex in FGraph.Vertices do
      sp := sp + Vertex.Position;

    sp := (sp / n - FCenterPoint) * FStrength;
    for var Vertex in FGraph.Vertices do
    begin
      Vertex.Position := Vertex.Position - sp;
    end;
  end;
end;

procedure TForceCenter.SetCenterPoint(Value: TPointF);
begin
  FCenterPoint := Value;
  Force(0);
end;

procedure TForceCenter.SetStrength(Value: double);
begin
  FStrength := Value;
  Force(0);
end;

{$ENDREGION}

{$REGION 'TForceCollide'}


procedure TForceCollide.CalculateForces(Vertex: TVertex;
  QuadTree: TQuadTree<TVertex>);
begin
  var
  ri := FRadii[Vertex.Idx];
  var
  ri2 := sqr(ri);
  var
  xi := Vertex.Position.X + Vertex.Velocity.X;
  var
  yi := Vertex.Position.Y + Vertex.Velocity.Y;

  QuadTree.Traverse(QuadTree.RootNode,
    function(QuadTree: TQuadTree<TVertex>; Node: TNode<TVertex>): boolean
    begin
      var
      rj := Node.Data[F_RADIUS].ToDouble;
      var
      r := ri + rj;

      if Node.NodeType = TNodeType.Leaf then
      begin
        var
        Data := Node.Point.Value;

        if Data.Idx > Vertex.Idx then
        begin
          var
          X := xi - Data.Position.X - Data.Velocity.X;
          var
          Y := yi - Data.Position.Y - Data.Velocity.Y;
          var
          l := sqr(X) + sqr(Y);
          if l < sqr(r) then
          begin
            if X = 0 then
            begin
              X := Jiggle(FRandom);
              l := l + sqr(X);
            end;

            if Y = 0 then
            begin
              Y := Jiggle(FRandom);
              l := l + sqr(Y);
            end;

            l := (r - sqrt(l)) / sqrt(l) * FStrength;

            X := X * l;
            Y := Y * l;
            rj := sqr(rj);
            r := rj / (ri2 + rj);
            Vertex.Velocity.X := Vertex.Velocity.X + X * r;
            Vertex.Velocity.Y := Vertex.Velocity.Y + Y * r;

            r := 1 - r;
            Data.Velocity.X := Data.Velocity.X - X * r;
            Data.Velocity.Y := Data.Velocity.Y - Y * r;
          end;
        end;
        exit(false);
      end;

      result := (Node.X > xi + r) or (Node.X + Node.w < xi - r) or
        (Node.Y > yi + r) or (Node.Y + Node.w < yi - r);
    end);
end;

constructor TForceCollide.Create(Strength, Radius: double; Iterations: integer);
begin
  inherited Create;
  FStrength   := Strength;
  FRadius     := Radius;
  FIterations := Iterations;
end;

constructor TForceCollide.Create;
begin
  Create(1, 10, 1);
end;

procedure TForceCollide.Force(Alpha: double);

  procedure CalcExtendQuadTree(Vertices: TEnumerable<TVertex>; out xMin, yMin, xMax, yMax: double);
  begin
    xMin := Infinity;
    yMin := Infinity;
    xMax := -Infinity;
    yMax := -Infinity;
    for var Vertex in Vertices do
    begin
      xMin := min(xMin, Vertex.Position.X + Vertex.Velocity.X);
      yMin := min(yMin, Vertex.Position.Y + Vertex.Velocity.Y);
      xMax := max(xMax, Vertex.Position.X + Vertex.Velocity.X);
      yMax := max(yMax, Vertex.Position.Y + Vertex.Velocity.Y);
    end;
    var
    w := xMax - xMin;
    var
    h := yMax - yMin;

    xMax := xMin + max(w, h);
    yMax := yMin + max(w, h);
    //    xMin := -1000000;
    //    yMin := -1000000;
    //    xMax := 1000000;
    //    yMax := 1000000;
  end;

  function QuadTree(Vertices: TEnumerable<TVertex>): TQuadTree<TVertex>;
  begin
    var xMin, yMin, xMax, yMax: double;
    CalcExtendQuadTree(FGraph.Vertices, xMin, yMin, xMax, yMax);

    result := TQuadTree<TVertex>.Create(xMin, yMin, xMax, yMax);
    for var Vertex in Vertices do
    begin
      var
      p := Vertex.Position + Vertex.Velocity;
      result.SetValue(p.X, p.Y, Vertex);
    end;
  end;

begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  for var K := 0 to FIterations - 1 do
  begin
    var
    Tree := QuadTree(FGraph.Vertices);
    try
      Tree.Traverse(Tree.RootNode, PrepareTree);

      for var Vertex in FGraph.Vertices do
        CalculateForces(Vertex, Tree);
    finally
      FreeAndNil(Tree);
    end;
  end;
end;

function TForceCollide.GetRadiuses(VertexIdx: integer): double;
begin
  result := FRadii[VertexIdx];
end;

procedure TForceCollide.Initialize;
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  SetLength(FRadii, FGraph.Vertices.Count);
  //  FillChar(FRadii[0], Length(FRadii) * SizeOf(FRadii[0]), 0);

  for var Vertex in FGraph.Vertices do
  begin
    FRadii[Vertex.Idx] := FRadius.Func(Vertex, Vertex.Idx, FGraph.Vertices);
  end;
end;

procedure TForceCollide.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

procedure TForceCollide.PrepareTree(QuadTree: TQuadTree<TVertex>;
  Node: TNode<TVertex>);
begin
  if Node.NodeType = TNodeType.Leaf then
  begin
    Node.Data[F_RADIUS] := FRadii[Node.Point.Value.Idx].ToString;
    exit;
  end;

  Node.Data[F_RADIUS] := double(0).ToString;

  for var I := 0 to 3 do
  begin
    var
    NChild := Node.Nodes[I];
    var r: integer;
    if TryStrToInt(NChild.Data[F_RADIUS], r) then
      if r > Node.Data[F_RADIUS].ToInteger then
        Node.Data[F_RADIUS] := NChild.Data[F_RADIUS];
  end;
end;

procedure TForceCollide.SetIterations(Value: integer);
begin
  FIterations := Value;
  Force(0);
end;

procedure TForceCollide.SetRadius(Value: TValueOrFuncV);
begin
  FRadius := Value;
  Initialize;
end;

procedure TForceCollide.SetStrength(Value: double);
begin
  FStrength := max(0, min(1, Value));
  Force(0);
end;

{$ENDREGION}

{$REGION 'TForceLink'}


procedure TForceLink.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

constructor TForceLink.Create;
begin
  Create(0, 30, 1);

  FStrength :=
      function(Edge: TEdge; Idx: integer; Edges: TEnumerable<TEdge>): double
    begin
      result := 1 / min(FCount[Edge.VertexFrom.Idx], FCount[Edge.VertexTo.Idx]);
    end;
end;

constructor TForceLink.Create(Strenght, Distance: double; Iterations: integer);
begin
  inherited Create;

  FIterations := Iterations;
  FStrength   := Strenght;
  FDistance   := Distance;
end;

procedure TForceLink.Force(Alpha: double);
begin
  for var K := 0 to FIterations - 1 do
  begin
    for var I := 0 to FGraph.Edges.Count - 1 do
    begin
      var
      Edge := FGraph.Edges[I];
      var
      Source := Edge.VertexFrom;
      var
      Target := Edge.VertexTo;

      var
      X := Target.Position.X + Target.Velocity.X - Source.Position.X - Source.Velocity.X;
      var
      Y := Target.Position.Y + Target.Velocity.Y - Source.Position.Y - Source.Velocity.Y;

      X := ifthen(InRange(X, -1_000_000, 1_000_000), X, Jiggle(FRandom));
      Y := ifthen(InRange(Y, -1_000_000, 1_000_000), Y, Jiggle(FRandom));

      var
      l := sqrt(X * X + Y * Y);
      l := (l - FDistances[I]) / l * Alpha * FStrengths[I];
      X := X * l;
      Y := Y * l;

      Target.Velocity.X := Target.Velocity.X - X * FBias[I];
      Target.Velocity.Y := Target.Velocity.Y - Y * FBias[I];
      Source.Velocity.X := Source.Velocity.X + X * (1 - FBias[I]);
      Source.Velocity.Y := Source.Velocity.Y + Y * (1 - FBias[I]);
    end;

  end;
end;

function TForceLink.GetDistances(EdgeIdx: integer): double;
begin
  result := FDistances[EdgeIdx];
end;

function TForceLink.GetStrengths(EdgeIdx: integer): double;
begin
  result := FStrengths[EdgeIdx];
end;

procedure TForceLink.Initialize;
begin
  if not assigned(FGraph) then
    exit;
  if FGraph.Edges.Count = 0 then
    exit;

  var
  n := FGraph.Vertices.Count;
  var
  m := FGraph.Edges.Count;

  SetLength(FCount, n);
  FillChar(FCount[0], Length(FCount) * SizeOf(FCount[0]), 0);
  for var I := 0 to m - 1 do
  begin
    var
    Edge     := FGraph.Edges.Items[I];
    Edge.Idx := I;

    FCount[Edge.VertexFrom.Idx] := (FCount[Edge.VertexFrom.Idx] or 0)+ 1;
    FCount[Edge.VertexTo.Idx]   := (FCount[Edge.VertexTo.Idx] or 0)+ 1;
  end;

  SetLength(FBias, m);
  FillChar(FBias[0], Length(FBias) * SizeOf(FBias[0]), 0);
  for var I := 0 to m - 1 do
  begin
    var
    Edge     := FGraph.Edges.Items[I];
    FBias[I] := FCount[Edge.VertexFrom.Idx] / (FCount[Edge.VertexFrom.Idx] + FCount[Edge.VertexTo.Idx]);
  end;

  SetLength(FStrengths, m);
  //  FillChar(FStrengths[0], Length(FStrengths) * SizeOf(FStrengths[0]), 0);
  InitializeStrength;

  SetLength(FDistances, m);
  //  FillChar(FDistances[0], Length(FDistances) * SizeOf(FDistances[0]), 0);
  InitializeDistance;
end;

procedure TForceLink.InitializeDistance;
begin
  if FGraph = nil then
    exit;

  for var Edge in FGraph.Edges do
    FDistances[Edge.Idx] := FDistance.Func(Edge, Edge.Idx, FGraph.Edges);
end;

procedure TForceLink.InitializeStrength;
begin
  if FGraph = nil then
    exit;

  for var Edge in FGraph.Edges do
    FStrengths[Edge.Idx] := FStrength.Func(Edge, Edge.Idx, FGraph.Edges);
end;

procedure TForceLink.SetDistance(Value: TValueOrFuncE);
begin
  FDistance := Value;
  InitializeDistance;
end;

procedure TForceLink.SetStrength(Value: TValueOrFuncE);
begin
  FStrength := Value;
end;

{$ENDREGION}

{$REGION 'TForceRadial'}


constructor TForceRadial.Create;
begin
  Create(0.1, 1, TPointF.Zero);
end;

constructor TForceRadial.Create(Strength, Radius: double; CenterPoint: TPointF);
begin
  inherited Create;
  FCenterPoint := CenterPoint;
  FStrength    := Strength;
  FRadius      := Radius;
end;

procedure TForceRadial.Force(Alpha: double);
begin
  if FGraph = nil then
    exit;

  for var Vertex in FGraph.Vertices do
  begin
    var
    D   := Vertex.Position - FCenterPoint;
    D.X := ifthen(InRange(D.X, -1_000_000, 1_000_000), D.X, 1E-6);
    D.Y := ifthen(InRange(D.Y, -1_000_000, 1_000_000), D.Y, 1E-6);

    var
    r := sqrt(sqr(D.X) + sqr(D.Y));
    var
    K := (FRadiuses[Vertex.Idx] - r) * FStrengths[Vertex.Idx] * Alpha / r;

    Vertex.Velocity := Vertex.Velocity + D * K;
  end;
end;

function TForceRadial.GetRadiuses(VertexIdx: integer): double;
begin
  result := FRadiuses[VertexIdx];
end;

function TForceRadial.GetStrengths(VertexIdx: integer): double;
begin
  result := FStrengths[VertexIdx];
end;

procedure TForceRadial.Initialize;
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  SetLength(FStrengths, FGraph.Vertices.Count);
  //  FillChar(FStrengths[0], Length(FStrengths) * SizeOf(FStrengths[0]), 0);

  SetLength(FRadiuses, FGraph.Vertices.Count);
  //  FillChar(FRadiuses[0], Length(FRadiuses) * SizeOf(FRadiuses[0]), 0);

  for var Vertex in FGraph.Vertices do
  begin
    FRadiuses[Vertex.Idx]  := FRadius.Func(Vertex, Vertex.Idx, FGraph.Vertices);
    FStrengths[Vertex.Idx] := FStrength.Func(Vertex, Vertex.Idx, FGraph.Vertices);
  end;
end;

procedure TForceRadial.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

procedure TForceRadial.SetRadius(Value: TValueOrFuncV);
begin
  FRadius := Value;
  Initialize;
end;

procedure TForceRadial.SetStrength(Value: TValueOrFuncV);
begin
  FStrength := Value;
  Initialize;
end;

{$ENDREGION}

{$REGION 'TForceX' }


constructor TForceX.Create;
begin
  Create(0.1, 0.0);
end;

constructor TForceX.Create(Strength, X: double);
begin
  inherited Create;
  FStrength := Strength;
  Fx        := X;
end;

procedure TForceX.Force(Alpha: double);
begin
  if FGraph = nil then
    exit;

  for var Vertex in FGraph.Vertices do
  begin
    Vertex.Velocity.X := Vertex.Velocity.X + (Fxz[Vertex.Idx] - Vertex.Position.X) * FStrengths[Vertex.Idx] * Alpha;
  end;
end;

function TForceX.GetXs(VertexIdx: integer): double;
begin
  result := Fxz[VertexIdx];
end;

procedure TForceX.Initialize;
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  SetLength(FStrengths, FGraph.Vertices.Count);
  //  FillChar(FStrengths[0], Length(FStrengths) * SizeOf(FStrengths[0]), 0);

  SetLength(Fxz, FGraph.Vertices.Count);
  //  FillChar(Fxz[0], Length(Fxz) * SizeOf(Fxz[0]), 0);

  for var Vertex in FGraph.Vertices do
  begin
    Fxz[Vertex.Idx]        := Fx.Func(Vertex, Vertex.Idx, FGraph.Vertices);
    FStrengths[Vertex.Idx] := ifthen(IsNan(Fxz[Vertex.Idx]), 0.0, FStrength.Func(Vertex, Vertex.Idx, FGraph.Vertices));
  end;
end;

procedure TForceX.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

procedure TForceX.SetStrength(Value: TValueOrFuncV);
begin
  FStrength := Value;
  Initialize;
end;

procedure TForceX.SetX(Value: TValueOrFuncV);
begin
  Fx := Value;
  Initialize;
end;

{$ENDREGION}

{$REGION 'TForceY' }


constructor TForceY.Create;
begin
  Create(0.1, 0.0);
end;

constructor TForceY.Create(Strength, Y: double);
begin
  inherited Create;

  FStrength := Strength;
  Fy        := Y;
end;

procedure TForceY.Force(Alpha: double);
begin
  if FGraph = nil then
    exit;

  for var Vertex in FGraph.Vertices do
  begin
    Vertex.Velocity.Y := Vertex.Velocity.Y + (Fyz[Vertex.Idx] - Vertex.Position.Y) * FStrengths[Vertex.Idx] * Alpha;
  end;
end;

function TForceY.GetYs(VertexIdx: integer): double;
begin
  result := Fyz[VertexIdx];
end;

procedure TForceY.Initialize;
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  SetLength(FStrengths, FGraph.Vertices.Count);
  //  FillChar(FStrengths[0], Length(FStrengths) * SizeOf(FStrengths[0]), 0);

  SetLength(Fyz, FGraph.Vertices.Count);
  //  FillChar(Fyz[0], Length(Fyz) * SizeOf(Fyz[0]), 0);

  for var Vertex in FGraph.Vertices do
  begin
    Fyz[Vertex.Idx]        := Fy.Func(Vertex, Vertex.Idx, FGraph.Vertices);
    FStrengths[Vertex.Idx] := ifthen(IsNan(Fyz[Vertex.Idx]), 0.0, FStrength.Func(Vertex, Vertex.Idx, FGraph.Vertices));
  end;
end;

procedure TForceY.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

procedure TForceY.SetStrength(Value: TValueOrFuncV);
begin
  FStrength := Value;
  Initialize;
end;

procedure TForceY.SetY(Value: TValueOrFuncV);
begin
  Fy := Value;
  Initialize;
end;

{$ENDREGION}

{$REGION 'TValueOrFunc'}


class operator TValueOrFuncE.Implicit(a: TUserMethodE): TValueOrFuncE;
begin
  result.FFunc := a;
end;

class operator TValueOrFuncE.Implicit(a: double): TValueOrFuncE;
begin
  result.FFunc :=
      function(Edge: TEdge; Idx: integer; Edges: TEnumerable<TEdge>): double
    begin
      result := a;
    end;
end;

{$ENDREGION}

{$REGION 'TValueOrFuncV' }


class operator TValueOrFuncV.Implicit(a: TUserMethodV): TValueOrFuncV;
begin
  result.FFunc := a;
end;

class operator TValueOrFuncV.Implicit(a: double): TValueOrFuncV;
begin
  result.FFunc :=
      function(Vertex: TVertex; Idx: integer; Vertices: TEnumerable<TVertex>): double
    begin
      result := a;
    end;
end;

{$ENDREGION}

{$REGION 'TForceManyBody' }

constructor TForceManyBody.Create;
begin
  Create(-30, 1, Infinity, sqrt(0.81));
end;

procedure TForceManyBody.AccumulateForces(QuadTree: TQuadTree<TVertex>;
  Node: TNode<TVertex>);
begin
  var
  Strength: double := 0.0;
  var
  weight: double := 0.0;
  var
  X := 0.0;
  var
  Y := 0.0;

  // For leaf nodes, accumulate forces from coincident quadrants.
  if Node.NodeType = TNodeType.Leaf then
  begin
    Node.Point.X := Node.Point.Value.Position.X;
    Node.Point.Y := Node.Point.Value.Position.Y;
    Strength := Strength + FStrengths[Node.Point.Value.Idx];

    // For internal nodes, accumulate forces from child quadrants.
  end
  else
    if Node.NodeType = TNodeType.Pointer then
  begin
    for var I := 0 to 3 do
    begin
      var
      q := Node.Nodes[I];
      var Value: double;
      if (q <> nil) and TryStrToFloat(q.Data[F_VALUE], Value) then
      begin
        var
        c := abs(Value);
        Strength := Strength + Value;
        weight := weight + c;
        X := X + c * q.Point.X;
        Y := Y + c * q.Point.Y;
      end;
    end;

    Node.Point.X := X / weight;
    Node.Point.Y := Y / weight;
  end
  else
  begin
    Node.Point.X := (Node.X + Node.w) / 2;
    Node.Point.Y := (Node.Y + Node.h) / 2;
  end;

  Node.Data[F_VALUE] := Strength.ToString;
end;

procedure TForceManyBody.CalculateForces(Vertex: TVertex; QuadTree: TQuadTree<TVertex>; Alpha: double);
begin
 QuadTree.Visit(QuadTree.RootNode,
    function(QuadTree: TQuadTree<TVertex>; Node: TNode<TVertex>): boolean
    begin
      if Node.Data[F_VALUE].IsEmpty then
        exit(true);

      var
      X := Node.Point.X - Vertex.Position.X;
      var
      Y := Node.Point.Y - Vertex.Position.Y;
      var
      w := Node.w;

      //          if x.IsNan then x := Jiggle(FRandom);
      //          if y.IsNan then y := Jiggle(FRandom);

      var
      l := sqr(X) + sqr(Y);

      // Apply the Barnes-Hut approximation if possible.
      // Limit forces for very close nodes; randomize direction if coincident.
      if (sqr(w) / FTheta2) < l then
      begin
        if l < FDistanceMax2 then
        begin
          if X = 0 then
          begin
            X := Jiggle(FRandom);
            l := l + sqr(X);
          end;
          if Y = 0 then
          begin
            Y := Jiggle(FRandom);
            l := l + sqr(Y);
          end;
          if l < FDistanceMin2 then
            l := sqrt(FDistanceMin2 * l);

          var
          _Value := Node.Data[F_VALUE].ToDouble;
          Vertex.Velocity.X := Vertex.Velocity.X + X * _Value * Alpha / l;
          Vertex.Velocity.Y := Vertex.Velocity.Y + Y * _Value * Alpha / l;
        end;
        exit(true);
        // Otherwise, process points directly.
      end
      else
        if (Node.NodeType <> TNodeType.Leaf) or (l >= FDistanceMax2) then
        exit(false);

      // Limit forces for very close nodes; randomize direction if coincident.
      if (Node.Point.Value <> Vertex) then
      begin
        if X = 0 then
        begin
          X := Jiggle(FRandom);
          l := l + sqr(X);
        end;
        if Y = 0 then
        begin
          Y := Jiggle(FRandom);
          l := l + sqr(Y);
        end;
        if l < FDistanceMin2 then
          l := sqrt(FDistanceMin2 * l);
      end;

      if Node.Point.Value <> Vertex then
      begin
        w := FStrengths[Node.Point.Value.Idx] * Alpha / l;
        Vertex.Velocity.X := Vertex.Velocity.X + X * w;
        Vertex.Velocity.Y := Vertex.Velocity.Y + Y * w;
      end;

      result := false;
    end
    );
end;

constructor TForceManyBody.Create(Strength, DistanceMin, DistanceMax,
  Theta: double);
begin
  inherited Create;

  FStrength     := Strength;
  FDistanceMin2 := DistanceMin;
  FDistanceMax2 := DistanceMax;
  FTheta2       := sqr(Theta);
end;

procedure TForceManyBody.Force(Alpha: double);

  procedure CalcExtendQuadTree(Vertices: TEnumerable<TVertex>; out xMin, yMin, xMax, yMax: double);
  begin
    xMin := Infinity;
    yMin := Infinity;
    xMax := -Infinity;
    yMax := -Infinity;
    for var Vertex in Vertices do
    begin
      xMin := min(xMin, Vertex.Position.X + Vertex.Velocity.X);
      yMin := min(yMin, Vertex.Position.Y + Vertex.Velocity.Y);
      xMax := max(xMax, Vertex.Position.X + Vertex.Velocity.X);
      yMax := max(yMax, Vertex.Position.Y + Vertex.Velocity.Y);
    end;
  end;

  function QuadTree(Vertices: TEnumerable<TVertex>): TQuadTree<TVertex>;
  begin
    var xMin, yMin, xMax, yMax: double;
    CalcExtendQuadTree(FGraph.Vertices, xMin, yMin, xMax, yMax);

    result := TQuadTree<TVertex>.Create(xMin, yMin, xMax, yMax);
    for var Vertex in Vertices do
    begin
      result.SetValue(Vertex.Position.X, Vertex.Position.Y, Vertex);
    end;
  end;

begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  var
  Tree := QuadTree(FGraph.Vertices);
  try
    Tree.VisitAfter(Tree.RootNode, AccumulateForces);

    for var Vertex in FGraph.Vertices do
      CalculateForces(Vertex, Tree, Alpha);

  finally
    FreeAndNil(Tree);
  end;
end;

function TForceManyBody.GetDistanceMax: double;
begin
  result := sqrt(FDistanceMax2);
end;

function TForceManyBody.GetDistanceMin: double;
begin
  result := sqrt(FDistanceMin2);
end;

function TForceManyBody.GetStrengths(VertexIdx: integer): double;
begin
  result := FStrengths[VertexIdx];
end;

function TForceManyBody.GetTheta: double;
begin
  result := sqrt(FTheta2);
end;

procedure TForceManyBody.Initialize(Graph: TGraph; Random: TFunc<Extended>);
begin
  inherited;
  Initialize;
end;

procedure TForceManyBody.Initialize;
begin
  if FGraph = nil then
    exit;
  if FGraph.Vertices.Count = 0 then
    exit;

  SetLength(FStrengths, FGraph.Vertices.Count);
  //  FillChar(FStrengths[0], Length(FStrengths) * SizeOf(FStrengths[0]), 0);

  for var Vertex in FGraph.Vertices do
  begin
    FStrengths[Vertex.Idx] := FStrength.Func(Vertex, Vertex.Idx, FGraph.Vertices);
  end;
end;

procedure TForceManyBody.SetDistanceMax(Value: double);
begin
  FDistanceMax2 := sqr(Value);
end;

procedure TForceManyBody.SetDistanceMin(Value: double);
begin
  FDistanceMin2 := sqr(Value);
end;

procedure TForceManyBody.SetStrength(Value: TValueOrFuncV);
begin
  FStrength := Value;
  Initialize;
end;

procedure TForceManyBody.SetTheta(Value: double);
begin
  FTheta2 := sqr(Value);
end;

{$ENDREGION}

end.
