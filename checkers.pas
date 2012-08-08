unit checkers;

interface

             


uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Math;

const
	// evaluation functions masks
  I_ZONE = $AA01800180018055;
  II_ZONE = $54024002402A00;
  III_ZONE = $2814280A0000;
  LEVELS : array [1..4] of Int64 = ($AA55, $AA550000,$AA5500000000,$AA55000000000000);

  //mask used to evaluate moves
  BORDER  = $AA01800180018055;
  LEFT = $AA54AA54AA54AA54;
  RIGHT = $2A552A552A552A55;
 	TOP  =   $AA00000000000000;
  BOTTOM = $55;

  // evaluation functions const
	K_VALUE = 30;
  P_VALUE = 15;
  II_ZONE_VALUE = 2;
  III_ZONE_VALUE = 5;
  BEST_LEVEL_VALUE =10;
  MEDIUM_LEVEL_VALUE = 5;
  WORST_LEVEL_VALUE = 3;
  PROTECT_VALUE = 30;

  //players
	WHITE = 1;
  BLACK = 2;

  //move directions
  N_LEFT = 1;
  N_RIGHT = 2;
  B_RIGHT = 3;
  B_LEFT = 4;
  // gameTypes
  PVC = 1;
  CVC = 2;
  PVP = 3;

  GAMEOVER = 1;
  DRAW = 2;
type
  TComputerThread = class(TThread)
  protected
  	procedure Execute; override;
  private
  	procedure UpdateGraphicss;
  public
  	constructor Create();
  end;
  
  TJumpArray = array of Int64;
	TPlayer = class
  	pieces : Int64;
    enemy : TPlayer;
    lastLine : Int64;
    color : Byte;
    function getPossibleMoves(mover : Int64):Int64; virtual;abstract;
    function getPossibleJumps(mover : Int64):Int64; virtual;abstract;
    function getMovers():Int64;virtual;abstract;
    function getJumpers():Int64;virtual;abstract;
    function getAllMovers():Int64;
    function doJump(src: Int64; dst:Int64):boolean;
    function Alfabeta(depth : integer; player : TPlayer; alfa,beta :integer; var bestMover: Int64; var bestMove: Int64; var bestJumpQueu:TJumpArray ):integer;
    function JumpsMiniMax(depth : integer; mover:Int64; player:TPlayer; alfa, beta : integer;var jumpsArray:TJumpArray; indeks:integer):integer;
    procedure getKingMovesAndJumps(mover : Int64; var moves : Int64; var jumps : Int64);
  	procedure doMove(src: Int64; dst:Int64);
    constructor Create(v_pieces, lastLine:Int64; v_enemy : TPlayer; v_color: Byte);
    destructor Destroy;
  end;
  TBlackPlayer = class(TPlayer)
  	function getPossibleMoves(mover : Int64):Int64; override;
  	function getPossibleJumps(mover : Int64):Int64; override;
    function getMovers():Int64;override;
    function getJumpers():Int64;override;
  end;
  TWhitePlayer = class(TPlayer)
    function getPossibleMoves(mover : Int64):Int64;override;
    function getPossibleJumps(mover : Int64):Int64;override;
    function getMovers():Int64;override;
    function getJumpers():Int64;override;
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    Board: TImage;
    Button2: TButton;
    Button3: TButton;
    Board2: TImage;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure BoardClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
  end;
   Coordinates = record
    	x : Integer;
      y : Integer;
    end;
  procedure resetBoard();
procedure clearAfterMove();
procedure updateGraphics();
procedure initGraphics();
procedure handleTouch(clickedTile : Int64);
procedure handleJump(dst : Int64);
procedure handleMove(dst : Int64);
procedure handlePossibles(piece : Int64);
function evaluate(player, enemy: TPlayer):integer;
function getKingsJumpers2(enemy :Int64; toCheck :Int64):Int64;
procedure getProtectValue(player, enemy:TPlayer; var pValue: integer; var eValue :integer);
procedure getLevelValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
procedure getZoneValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
procedure getPiecesValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
function getBitcount(bitboard: Int64):integer;
function getPieceToKill(src: Int64; dst : Int64; enemy : Int64):Int64;
function getMoveInRD(direction : integer; mover : Int64):Int64;
procedure getKingPossibleMovesAndJumps(mover : Int64; enemy : Int64;var moves : Int64; var jumps : Int64);
function getKingsJumpers(player: TPlayer):Int64;
function getKingsMovers(player:TPlayer):Int64;
function getSlideMoves(direction : integer; mover :Int64; dst : Int64; var nEnemy : Int64):Int64;
function getPossibleBackMoves(mover : Int64; enemy : Int64; requiredField : Int64):Int64;
function getPossibleNextMoves(mover : Int64; enemy : Int64; requiredField : Int64):Int64;
function getPossibleBackJumps(mover : Int64; enemy : Int64; requiredFiled : Int64):Int64;
function getPossibleNextJumps(mover : Int64; enemy : Int64; requiredFiled : Int64):Int64;
function getBackRight(mover :Int64):Int64;
function getBackLeft(mover :Int64):Int64;
function getNextRight(mover :Int64):Int64;
function getNextLeft(mover :Int64):Int64;
procedure handleGame(clickedTile : Int64);

var
  Form1: TForm1;
   possibleMoves : Int64 = 0;
   possibleJumps : Int64 = 0;
  oldClick : Int64 = 0;
  playerWhite, playerBlack : TPlayer;
  player : TPlayer;
  WP, BP, K, stillJumping : Int64;
  FULL_BOARD: Int64;
  CH_BOARD :Int64 = $AA55AA55AA55AA55;
  chessboard, blackpawn, whitepawn, whiteking, blackking, background,b_gameOver,b_normal : TBitmap;
  rects : array [0..63] of coordinates;
  maxDepth : Integer =10;
  gameType : integer = 0;
  isProcessing : boolean = false;
  ComputerThread : TComputerThread;
  gameState : integer = 0;
  sleepTime : longInt = 100;
implementation

{$R *.dfm}
// funkcje odpowiedzialne za obliczanie ruchow odpowiednio do zawodnika
procedure TPlayer.getKingMovesAndJumps(mover : Int64;var moves : Int64; var jumps : Int64);
begin
	getKingPossibleMovesAndJumps(mover, self.enemy.pieces,moves,jumps);
end;

constructor TPlayer.Create(v_pieces,lastLine :Int64; v_enemy : TPlayer; v_color :Byte);
begin
	self.pieces := v_pieces;
 	self.enemy := v_enemy;
  self.lastLine :=lastLine;
  self.color := v_color;
end;

destructor TPlayer.Destroy;
begin
	Inherited;
  self.Free;
end;

procedure TPlayer.doMove(src: Int64; dst:Int64);
begin
  if(dst AND self.lastLine<> 0) then
    	K := K OR dst;
  self.pieces := (self.pieces AND NOT src) OR dst;
  if K AND src <> 0 then
    	K := (K AND NOT src) OR dst;
end;


function TPlayer.doJump(src: Int64; dst:Int64):boolean;
var
moves, jumps,pieceToKill : Int64;
begin
	pieceToKill := getPieceToKill(src, dst, self.enemy.pieces);
  if(dst AND self.lastLine <> 0) then
  	K := K OR dst;
  self.pieces := (self.pieces AND NOT src) OR dst;
  self.enemy.pieces:= self.enemy.pieces AND NOT pieceToKill;
  K := K AND NOT pieceToKill;
  jumps:=0;
  if K AND src <> 0 then
    K := (K AND NOT src) OR dst;
  if(dst AND K <> 0) then
  	self.getKingMovesAndJumps(dst,moves, jumps);
  if((self.getPossibleJumps(dst)<>0) OR (jumps<>0)) then Result:=true else Result:=false;
  if (dst AND self.lastLine <> 0) AND (src AND NOT K <> 0) then Result:=false;
end;

function TBlackPlayer.getPossibleMoves(mover : Int64):Int64;
begin
	Result := getPossibleBackMoves(mover, self.enemy.pieces, NOT(self.pieces OR enemy.pieces));
end;

function TBlackPlayer.getMovers():Int64;
begin
	Result := getPossibleNextMoves(NOT(self.pieces OR self.enemy.pieces), self.enemy.pieces, self.pieces);
end;

function TBlackPlayer.getJumpers():Int64;
begin
	Result := getPossibleNextJumps(NOT(self.pieces OR self.enemy.pieces), self.enemy.pieces, self.pieces);
end;

function TBlackPlayer.getPossibleJumps(mover : Int64):Int64;
begin
	Result := getPossibleBackJumps(mover, self.enemy.pieces, NOT(self.pieces OR enemy.pieces));
end;

function TWhitePlayer.getPossibleMoves(mover : Int64):Int64;
begin
	Result := getPossibleNextMoves(mover, self.enemy.pieces, NOT(self.pieces OR enemy.pieces));
end;

function TWhitePlayer.getPossibleJumps(mover : Int64):Int64;
begin
	Result := getPossibleNextJumps(mover, self.enemy.pieces, NOT(self.pieces OR enemy.pieces));
end;

function TWhitePlayer.getMovers():Int64;
begin
	Result := getPossibleBackMoves(NOT(self.pieces OR self.enemy.pieces), self.enemy.pieces, self.pieces);
end;

function TWhitePlayer.getJumpers():Int64;
begin
	Result := getPossibleBackJumps(NOT(self.pieces OR self.enemy.pieces), self.enemy.pieces, self.pieces);
end;
function TPlayer.getAllMovers():Int64;
var
temp:Int64;
begin
	temp := self.getMovers() OR self.getJumpers() OR getKingsMovers(self) or getKingsJumpers(self);
  Result := temp;
end;
// AI

function TPlayer.JumpsMiniMax(depth : integer; mover:Int64; player:TPlayer; alfa, beta : integer;var jumpsArray:TJumpArray; indeks:integer):integer;
var
jumps,moves, jump,playerBefore, enemyBefore, kBefore,bestMover,bestMove:Int64;
bestJumpqueu : TJumpArray;
value, bestValue: integer;
begin
jumps := 0;
bestValue :=10000;
  if(mover AND K <>0) then
		player.getKingMovesAndJumps(mover,moves,jumps);
	jumps := jumps OR player.getPossibleJumps(mover);
  if(jumps = 0) then
  begin
  	Result:=self.Alfabeta(depth-1, player.enemy, alfa, beta,bestMover, bestMove, bestJumpqueu);
    exit;
  end
  else
	while(jumps<>0) do
  begin
  	jump := jumps AND NOT(jumps-1);
  	jumps := jumps AND (jumps-1);
    kBefore:=K;
    playerBefore:= player.pieces;
    enemyBefore:= player.enemy.pieces;
    player.doJump(mover, jump);
    if (jump AND player.lastLine <> 0) AND (mover AND NOT K <> 0) then
    	value := self.Alfabeta(depth-1, player.enemy, alfa, beta,bestMover, bestMove, bestJumpqueu)
    else
    	value := self.JumpsMiniMax(depth, jump, player,alfa, beta, jumpsArray, indeks+1);
    player.pieces:=playerBefore;
    player.enemy.pieces:=enemyBefore;
    K:=kBefore;
    if(value<bestValue) then
    begin
    	bestValue:=value;
    	if(High(jumpsArray)<indeks)then
      SetLength(jumpsArray,indeks);
      jumpsArray[indeks-1]:=jump;
    end;
  end;
  Result:=bestValue;
end;



function TPlayer.Alfabeta(depth : integer; player : TPlayer; alfa,beta :integer; var bestMover: Int64; var bestMove: Int64; var bestJumpQueu:TJumpArray ):integer;
var
value, bestValue, i : integer;
movers,current, move, moves, jumps,jumpers,playerBefore, enemyBefore, kBefore: Int64;
jumpsArray :TJumpArray;
begin
	if(self =player) then bestValue := -10000 else bestValue := 10000;
	if(depth =0)then
  begin
  	Result:=evaluate(self, self.enemy);
    exit;
  end;
  jumpers:=0;
  movers:=0;
  if(K AND player.pieces <>0 ) then
  begin
  	jumpers:=getKingsJumpers(player);
  	movers := getKingsMovers(player);
  end;
  jumpers := jumpers OR player.getJumpers();
  if jumpers = 0 then
  	movers := movers OR player.getMovers()
  else
  	movers:=0;
  if (movers = 0) AND (jumpers = 0) then
  begin
  	if self.pieces = 0 then Result := -9000
    else if self.enemy.pieces = 0 then Result:= 9000
    else Result := -1000;
    exit;
  end
  else
  begin
  while jumpers <> 0 do
  begin
  	current := jumpers AND NOT(jumpers-1);
    jumpers := jumpers AND (jumpers-1);
    value := self.JumpsMiniMax(depth, current, player,alfa, beta, jumpsArray,1);
    	if self <> player then
  		begin
    		if value < bestValue then
      	begin
      		bestValue := value;
      		beta := value;
    			if value < alfa then
        	begin
        		Result:=alfa;
        		exit;
      		end;
      	end;
    	end
    	else
    	begin
    		if bestValue < value then
      	begin
        	if depth = maxDepth then
        	begin
        		bestMover := current;
            setLength(bestJumpQueu, High(jumpsArray)+1);
            for i :=0 to High(jumpsArray)do
      			bestJumpQueu[i] := jumpsArray[i];
            setLength(jumpsArray, 0);
          	bestMove :=0;
        	end;
          bestValue := value;
          alfa := value;
          if value > beta then
          begin
          	Result:=beta;
          	exit;
          end;
      	end;
    	end;
  	end;
  while movers <> 0 do
  begin
  	current := movers AND NOT(movers-1);
    movers := movers AND (movers-1);
    moves :=0;
    if(current AND K <> 0) then
    	player.getKingMovesAndJumps(current, moves, jumps);
    moves := moves OR player.getPossibleMoves(current);
    while(moves<>0) do
    begin
   		move := moves AND NOT(moves-1);
    	moves := moves AND (moves-1);
    	kBefore:=K;
    	playerBefore:= player.pieces;
    	enemyBefore:= player.enemy.pieces;
    	player.doMove(current,move);
    	value :=  self.Alfabeta(depth-1, player.enemy, alfa,beta, bestMover,bestMove,bestJumpQueu);
    	player.pieces:=playerBefore;
    	player.enemy.pieces:=enemyBefore;
    	K:=kBefore;
    	if self <> player then
  		begin
    		if value < beta then
      	begin
      		bestValue := value;
      		beta := value;
    			if alfa >=beta then
        	begin
        		Result:=alfa;
        		exit;
      		end;
      	end;
    	end
    	else
    	begin
    		if alfa < value then
      	begin
        	if depth = maxDepth then
       	 	begin
        		setLength(bestJumpQueu, 0);
      			bestMove := move;
       	 		bestMover := current;
        	end;
      			bestValue := value;
      			alfa := value;
    				if alfa >=beta then
      			begin
      				Result:=beta;
        			exit;
      			end;
        end;
    	end;
  	end;
	end;
end;
Result:=bestValue;
end;


// koniec

// funkcje i procedury potrzebne do obliczania ruchow

function getNextLeft(mover :Int64):Int64;
begin
    Result:= (LEFT AND mover) shl Int64(7);
end;

function getNextRight(mover :Int64):Int64;
begin
    Result:= (RIGHT AND mover) shl Int64(9);
end;

function getBackLeft(mover :Int64):Int64;
begin
    Result:= (LEFT AND mover) shr Int64(9);
end;

function getBackRight(mover :Int64):Int64;
begin
    Result:= (RIGHT AND mover) shr Int64(7);
end;

function getPossibleNextJumps(mover : Int64; enemy : Int64; requiredFiled : Int64):Int64;
var
temp, jumps: Int64;
begin
		temp:= getNextLeft(mover) AND enemy;
    jumps:= getNextLeft(temp) AND requiredFiled;
    temp:= getNextRight(mover) AND enemy;
    jumps:= jumps OR (getNextRight(temp) AND requiredFiled);
		Result:= jumps;
end;

function getPossibleBackJumps(mover : Int64; enemy : Int64; requiredFiled : Int64):Int64;
var
temp, jumps : Int64;
begin
		temp:= getBackLeft(mover) AND enemy;
    jumps:= getBackLeft(temp) AND requiredFiled;
    temp:= getBackRight(mover) AND enemy;
    jumps:= jumps OR (getBackRight(temp) AND requiredFiled);
		Result:= jumps;
end;

function getPossibleNextMoves(mover : Int64; enemy : Int64; requiredField : Int64):Int64;
begin
		Result:= (getNextLeft(mover) OR getNextRight(mover)) AND requiredField;
end;

function getPossibleBackMoves(mover : Int64; enemy : Int64; requiredField : Int64):Int64;
begin
		Result:= (getBackLeft(mover) OR getBackRight(mover)) AND requiredField;
end;

// zwraca wolne miejsca az do napotkania przeszkody oraz zwraca przeszkode jesli jest przeciwnikiem

function getSlideMoves(direction : integer; mover :Int64; dst : Int64; var nEnemy : Int64):Int64;
var
moves, temp, taken : Int64;
begin
	taken := (playerWhite.pieces OR playerBlack.pieces);
  moves := 0;
	temp := mover;
  nEnemy := 0;
  	repeat
  		temp := getMoveInRD(direction, temp);
      if(temp AND dst <>0) then
      	nEnemy:= nEnemy or (dst AND temp);
      temp:=temp AND NOT taken;
      moves := moves OR temp;
  	until temp = 0;
Result:=moves;
end;

function getKingsMovers(player:TPlayer):Int64;
var
temp, movers, empty:Int64;
direction:integer;
begin
temp:=0;
movers:=0;
empty := NOT (player.pieces OR player.enemy.pieces);
for direction :=1 to 4 do
begin
	temp:= getMoveInRD(direction, empty);
  temp := temp AND K AND player.pieces;
  if temp<> 0 then
  	movers:=movers OR temp;
end;
Result:=movers;
end;

function getKingsJumpers(player: TPlayer):Int64;
var
nEnemy : array [1..4] of Int64;
tempK, jumpers : Int64;
direction : integer;
begin
jumpers:=0;
for direction :=1 to 4 do
begin
tempK :=0;
	getSlideMoves(direction, NOT (playerWhite.pieces OR playerBlack.pieces) AND CH_BOARD,  player.enemy.pieces, nEnemy[direction]);
  if(nEnemy[direction]<>0) then
  getSlideMoves(direction, nEnemy[direction],  player.pieces AND K, tempK);
  jumpers := jumpers OR tempK;
end;
Result := Jumpers;
end;
function getKingsJumpers2(enemy:Int64; toCheck :Int64):Int64;
var
nEnemy : array [1..4] of Int64;
tempK, jumpers : Int64;
direction : integer;
begin
jumpers:=0;
for direction :=1 to 4 do
begin
tempK :=0;
	getSlideMoves(direction, NOT (playerWhite.pieces OR playerBlack.pieces) AND CH_BOARD,  enemy, nEnemy[direction]);
  if(nEnemy[direction]<>0) then
  getSlideMoves(direction, nEnemy[direction],  toCheck, tempK);
  jumpers := jumpers OR tempK;
end;
Result := Jumpers;
end;

procedure getKingPossibleMovesAndJumps(mover : Int64; enemy : Int64;var moves : Int64; var jumps : Int64);
var
nEnemy : array [1..4] of Int64;
temp :Int64;
direction : integer;
begin
	moves:= 0;
  jumps:=0;
  temp :=0;
  for direction :=1 to 4 do
  	begin
    	moves := moves OR getSlideMoves(direction, mover,  enemy,nEnemy[direction]);
      if(nEnemy[direction]<>0) then
      jumps := jumps OR getSlideMoves(direction, nEnemy[direction],  enemy,nEnemy[direction]);
   	end;
    temp := getKingsJumpers2(enemy, jumps);
    if temp <> 0  then
    	jumps := temp;
end;

// wybiera odpowiednia funkcje dla kierunku ruchu

function getMoveInRD(direction : integer; mover : Int64):Int64;
begin
	Result:=0;
	case direction of
  N_LEFT : Result := getNextLeft(mover);
  N_RIGHT : Result := getNextRight(mover);
  B_RIGHT : Result := getBackRight(mover);
  B_LEFT : Result := getBackLeft(mover);
	end;
end;

function getPieceToKill(src: Int64; dst : Int64; enemy : Int64):Int64;
var
nEnemy: array [1..4] of Int64;
temp : Int64;
direction : integer;
begin
	Result :=0;
  for direction := 1 to 4 do
  	begin
    	getSlideMoves(direction, dst, enemy, nEnemy[direction]);
      if(nEnemy[direction]<>0) then
      begin
      	getSlideMoves(direction, nEnemy[direction], src, temp);
        if(temp<>0) then
        	Result:=nEnemy[direction];
      end;
   	end;
end;
//koniec
//  funckje oceniajace

function getBitcount(bitboard: Int64):integer;
var
	count : integer;
begin
	count := 0;
  while(bitboard<>0) do
  begin
  	bitboard := bitboard AND (bitboard-1);
    Inc(count);
  end;
  Result:=count;
end;

procedure getPiecesValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
begin
pValue:=0;
  eValue:=0;
	pValue := getBitcount(player.pieces AND NOT K)*P_VALUE + getBitcount(player.pieces AND K)*K_VALUE;
  eValue := getBitcount(enemy.pieces AND NOT K)*P_VALUE + getBitcount(enemy.pieces AND K)*K_VALUE;
end;

procedure getZoneValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
begin
pValue:=0;
  eValue:=0;
	pValue := getBitcount(player.pieces AND II_ZONE)*II_ZONE_VALUE + getBitcount(player.pieces AND III_ZONE)*III_ZONE_VALUE;
  eValue := getBitcount(enemy.pieces AND II_ZONE)*II_ZONE_VALUE + getBitcount(enemy.pieces AND III_ZONE)*III_ZONE_VALUE;
end;

procedure getLevelValue(player, enemy: TPlayer;var pValue : integer;var eValue:integer);
begin
  if(player.color = WHITE) then
  begin
  pValue:=0;
  eValue:=0;
	pValue := getBitcount(player.pieces AND LEVELS[4])*BEST_LEVEL_VALUE
  			 + getBitcount(player.pieces AND LEVELS[3])*MEDIUM_LEVEL_VALUE
         + getBitcount(player.pieces AND LEVELS[2])*WORST_LEVEL_VALUE;
  eValue := getBitcount(enemy.pieces AND LEVELS[1])*BEST_LEVEL_VALUE
  			 + getBitcount(enemy.pieces AND LEVELS[2])*MEDIUM_LEVEL_VALUE
         + getBitcount(enemy.pieces AND LEVELS[3])*WORST_LEVEL_VALUE;
  end
  else
  begin
  	pValue := getBitcount(player.pieces AND LEVELS[1])*BEST_LEVEL_VALUE
  			 + getBitcount(player.pieces AND LEVELS[2])*MEDIUM_LEVEL_VALUE
         + getBitcount(player.pieces AND LEVELS[3])*WORST_LEVEL_VALUE;
  	eValue := getBitcount(enemy.pieces AND LEVELS[4])*BEST_LEVEL_VALUE
  			 + getBitcount(enemy.pieces AND LEVELS[3])*MEDIUM_LEVEL_VALUE
         + getBitcount(enemy.pieces AND LEVELS[2])*WORST_LEVEL_VALUE;
  end;
end;

procedure getProtectValue(player, enemy:TPlayer; var pValue: integer; var eValue :integer);
var
temp : Int64;
begin
  pValue:=0;
  eValue:=0;
	if player.color = WHITE then
  begin
  	temp := getPossibleBackJumps(enemy.pieces,player.pieces,player.pieces);
    pValue := getBitcount(temp)*PROTECT_VALUE;
  end
  else
  begin
  	temp := getPossibleNextJumps(player.pieces,enemy.pieces,enemy.pieces);
    eValue := getBitcount(temp)*PROTECT_VALUE;
  end;
end;

function evaluate(player, enemy: TPlayer):integer;
var
temp,pValue, eValue:integer;
begin
  temp:=0;
	getLevelValue(player, enemy,pValue, eValue);
  temp:=temp + pValue-eValue;
  getZoneValue(player, enemy,pValue, eValue);
  temp:=temp + pValue-eValue;
  getPiecesValue(player, enemy,pValue, eValue);
  temp:=temp + pValue-eValue;
  getProtectValue(player, enemy,pValue, eValue);
  temp:=temp + pValue-eValue;
  Result := temp;
end;
//koniec
// funckje watku odpowiedzialne za sterownie komputerem
procedure TComputerThread.UpdateGraphicss;
begin
	updateGraphics();
end;
Constructor TComputerThread.Create();
begin
	inherited Create(true);
end;
procedure TComputerThread.Execute;
var
mover, move:Int64;
jumpQueu : TJumpArray;
i : integer;
begin
		isProcessing :=true;
    FreeOnTerminate :=true;
    sleep(sleepTime);
  	mover:= 0;
  	move:=0;
  	player.Alfabeta(maxDepth,player,-10000,10000,mover,move,jumpQueu);
  	if High(jumpQueu)>-1  then
  	begin
  		for i:=Low(jumpQueu) to High(jumpQueu) do
    	begin
    		player.doJump(mover,jumpQueu[i]);
      	mover:=jumpQueu[i];
    	end;
 	 	end
  	else
  	player.doMove(mover,move);
    Synchronize(updateGraphicss);
    player := player.enemy;
    isProcessing := false;
    handleGame(0);
end;
//koniec
// funkcje i procedury do sterowania graczem

procedure handleGame(clickedTile : Int64);
begin
	if(playerWhite.pieces = 0) OR (playerBlack.pieces = 0) then
  begin
  	gameState := GAMEOVER;
  	Form1.Board2.Canvas.draw(0,0,b_gameOver);
    exit;
  end
  else if (playerWhite.getAllMovers = 0) OR (playerBlack.getAllMovers = 0)then
  begin
    exit;
  end;
	ComputerThread := TComputerThread.Create;
	if(NOT isProcessing) then
	case gameType of
  	1: if player.color = BLACK then ComputerThread.Resume else handleTouch(clickedTile);
    2: ComputerThread.Resume;
    3: handleTouch(clickedTile);
    end;
end;

procedure handlePossibles(piece : Int64);
var
jumpers: Int64;
begin
	jumpers :=0;
	if piece AND player.pieces <> 0 then
	begin
    jumpers := player.getPossibleJumps(player.pieces);
    player.getKingMovesAndJumps(K AND player.pieces, possibleMoves, possibleJumps);
    jumpers := jumpers OR possibleJumps;
    possibleMoves := 0;
    possibleJumps := 0;
    	if K AND piece <> 0 then
      begin
      	player.getKingMovesAndJumps(piece, possibleMoves, possibleJumps);
        if jumpers<>0 then
        	possibleMoves := 0;
      end
      else
      begin
    		if(jumpers=0) then
					possibleMoves := player.getPossibleMoves(piece);
				possibleJumps := player.getPossibleJumps(piece);
      end;
  end;
end;

procedure handleMove(dst : Int64);
begin
  player.doMove(oldClick, dst);
  player := player.enemy;
	clearAfterMove();
end;

procedure handleJump(dst : Int64);
begin
	if oldClick AND player.pieces <> 0 then
  	if(player.doJump(oldClick, dst)=false) then player:=player.enemy;
  clearAfterMove();
end;

procedure handleTouch(clickedTile : Int64);
begin
 if (clickedTile AND (playerWhite.pieces OR playerBlack.pieces) <> 0) AND (clickedTile AND player.pieces <>0)then
  begin
  	handlePossibles(clickedTile);
    updateGraphics();
    oldClick:=clickedTile;
	end
  else if possibleMoves AND clickedTile <>0 then
  begin
  	handleMove(clickedTile);
    updateGraphics();
    handleGame(0);
  end
  else if possibleJumps AND clickedTile <>0 then
  begin
    handleJump(clickedTile);
    updateGraphics();
    handleGame(0);
  end;

end;
//koniec
// funckje i procedury do zmieniania grafiki
// uaktualnia szachownice
procedure initGraphics();
var
i, j : word;
begin
	
	chessBoard:=TBitmap.Create;
  chessboard.LoadFromFile('pascal\chessboard.bmp') ;
  blackpawn:=TBitmap.Create;
  blackpawn.LoadFromFile('pascal\blackpawn.bmp');
  blackking:=TBitmap.Create;
  blackking.LoadFromFile('pascal\blackking.bmp');
  whitepawn:=TBitmap.Create;
  whitepawn.LoadFromFile('pascal\whiteChecker.bmp');
  whiteking:=TBitmap.Create;
  whiteking.LoadFromFile('pascal\whiteKing.bmp');
  b_gameOver:=TBitmap.Create;
  b_gameOver.LoadFromFile('pascal\gameover.bmp');
  for i :=7 downto 0 do
  begin
  	for j :=0 to 7 do
    begin
  			rects[j + (7-i)*8].x :=50*j;
  			rects[j + (7-i)*8].y :=50*i;
 		end;
  end;
end;

procedure updateGraphics();
var
i : integer;
temp : Int64;
begin

	Form1.Board.Canvas.draw(0,0,chessboard);
  for i:=63 downto 0 do
  begin
  	temp := (Int64(1)shl Int64(i));
  	if (playerBlack.pieces AND temp )<>0 then
    Form1.Board.Canvas.draw(rects[i].x,rects[i].y,blackpawn);
    if (playerWhite.pieces AND temp)<>0 then
    Form1.Board.Canvas.draw(rects[i].x,rects[i].y,whitepawn);
    if (K AND temp AND playerBlack.pieces)<>0 then
    begin
    Form1.Board.Canvas.draw(rects[i].x,rects[i].y,blackking);
    end;
    if (K AND temp AND playerWhite.pieces)<>0 then
    begin
    Form1.Board.Canvas.draw(rects[i].x,rects[i].y,whiteking);
    end;
    if (possibleMoves AND temp)<>0 then
    begin
    Form1.Board.Canvas.Pen.Color := clRed;
  	Form1.Board.Canvas.Rectangle(rects[i].x, rects[i].y,rects[i].x+50, rects[i].y + 50);
    end;
    if (possibleJumps AND temp)<>0 then
    begin
    Form1.Board.Canvas.Pen.Color := clRed;
  	Form1.Board.Canvas.Rectangle(rects[i].x, rects[i].y,rects[i].x+50, rects[i].y + 50);
    end;
  end;
end;
// koniec

// funkcje sprzatajace
procedure resetBoard();
begin
  if(Assigned(ComputerThread)) then
  begin
  	TerminateThread(ComputerThread.Handle,0);
    isProcessing := false;
  end;
  maxDepth := strtointdef(Form1.Edit1.Text,10);
  sleepTime := strtointdef(Form1.Edit2.Text,100);
  gameType:=0;
	WP := $55AA55;
  BP := $AA55AA0000000000;
  K :=0;
  playerWhite := TWhitePlayer.Create(WP, TOP, nil, WHITE);
  playerBlack := TBlackPlayer.Create(BP, BOTTOM, playerWhite, BLACK);
  playerWhite.enemy := playerBlack;
  player:=playerWhite;
  possibleMoves := 0;
  possibleJumps := 0;
  gameState := 0;
  Form1.Board2.Canvas.Draw(0,0,b_normal);
end;

procedure clearAfterMove();
begin
	oldClick :=0;
  possibleMoves := 0;
  possibleJumps :=0;
end;
// koniec
procedure TForm1.Button1Click(Sender: TObject);
begin
resetBoard();
initGraphics();
updateGraphics();
gameType :=  3;
end;

procedure TForm1.BoardClick(Sender: TObject);
var
 p : TPoint;
 x, y, i : integer;
begin
getcursorpos(p);
p:=form1.ScreenToClient(p);
x := p.X div 50;
y := p.Y div 50;
i := (x + (7-y)*8);
if(gameType=3) OR (gameType = 1) then
handleGame(Int64(1) shl Int64(i));
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
playerWhite.Free;
playerBlack.Free;
if(Assigned(ComputerThread)) then
	TerminateThread(ComputerThread.Handle,0);

end;
procedure TForm1.Button2Click(Sender: TObject);
begin
	resetBoard();
	initGraphics();
	updateGraphics();
  ComputerThread := TComputerThread.Create;
  gameType := 1;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
	resetBoard();
	initGraphics();
	updateGraphics();
  ComputerThread := TComputerThread.Create;
  gameType :=  2;
  handleGame(0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
	b_normal:=TBitmap.Create;
  b_normal.LoadFromFile('pascal\normal.bmp');
end;

end.




