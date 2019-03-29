program SpaceInvader;

uses sdl,sdl_image, SDL_MIXER,sdl_ttf,sysutils,KeyBoard,crt;

const
	SURFACEWIDTH=1250; {largeur en pixels de la surface de jeu}
	SURFACEHEIGHT=750; {hauteur en pixels de la surface de jeu}
	IMAGEWIDTH=50; {largeur en pixels de l'image}
	IMAGEHEIGHT=50; {hauteur en pixels de l'image}
	SPRITESIZE=50; {taille des sprites}

	AUDIO_FREQUENCY:INTEGER=22050;
	AUDIO_FORMAT:WORD=AUDIO_S16;
	AUDIO_CHANNELS:INTEGER=2;
	AUDIO_CHUNKSIZE:INTEGER=4096;

    {TSpriteSheet est une feuille de textures qui contient toutes les textures du jeu}
    Type TSpriteSheet=record {Definition du type enregistrement}
        earth,down,badguy,MissileAlien,MissileAllie,Protection,Soucoupe,Alien1:PSDL_Surface;
    end;
    Type PSpriteSheet=^TSpriteSheet; {Definition du type pointeur}

	type direction=(gauche,droite);

	Type coord=record
		x,y:Integer;
	end;
		 Element=record
			Score:Longint;
			Grille:Array[1..19,1..50] of Integer;
			CompteurSoucoupe,nbrMissileAllie, nbrMissileAlien, nbrAlien1,nbrAlien2,NbrProtection:Integer;
			MissileAllie, MissileAlien,Protection:Array[1..20]of Coord;
			PresenceSoucoupe:Boolean;		
			Soucoupe,Vaisseau:Coord;
			Alien:Array[1..15,1..2] of Coord;
		end;
	
	Scores=record
		Score:LongInt;
		Pseudo:String;
	end;
	
	TabScore=record
		Tab:Array[1..5]of Scores;
		NbrScore:Integer;
	end;
	
	


{Procedure d'initialisation des elements de l'affichage: 
* la fenetre et l'image}
procedure initialise(var window, Logo : PSDL_SURFACE);
begin
	{charger la bibliotheque}
	SDL_Init(SDL_INIT_VIDEO);
  	SDL_Init(SDL_INIT_AUDIO);

	{initialiser la surface de la fenetre: largeur, hauteur,
	*  profondeur des couleurs, type de fenetre}
	window :=SDL_SetVideoMode(SURFACEWIDTH+100, SURFACEHEIGHT, 32,SDL_SWSURFACE); 
										
	{chargement de l'image}									
	Logo := IMG_Load('ressources/Logo.png');

end;

{Procedure pour quitter proprement la SDL}
procedure termine(var window, logo: PSDL_SURFACE; var sound : pMIX_MUSIC);
begin
	{vider la memoire correspondant a l'image et a la fenetre}
	SDL_FreeSurface(logo);	
	SDL_FreeSurface(window);
	MIX_FREEMUSIC(sound);
	Mix_CloseAudio();
	{decharger la bibliotheque}
	SDL_Quit();
end;

function initSprites():PSpriteSheet;
{On charge les textures en mémoire}
var newSpriteSheet : PSpriteSheet;
begin
    new(newSpriteSheet);
    newSpriteSheet^.earth:=IMG_Load('ressources/fond.png');
    newSpriteSheet^.down:=IMG_Load('ressources/vaisseau.png');
    newSpriteSheet^.badguy:=IMG_Load('ressources/Alien.png');
    newSpriteSheet^.MissileAllie:=IMG_Load('ressources/MissileAllie.png');
    newSpriteSheet^.MissileAlien:=IMG_Load('ressources/MissileAlien.png');
    newSpriteSheet^.Protection:=IMG_Load('ressources/Protection.png');
    newSpriteSheet^.Soucoupe:=IMG_Load('ressources/Soucoupe.png');
    newSpriteSheet^.Alien1:=IMG_Load('ressources/Alien1.png');      
    initSprites:=newSpriteSheet;
end;


procedure disposeSprite(p_sprite_sheet: PSpriteSheet);
{On décharge les textures de la mémoire}
begin
    SDL_FreeSurface(p_sprite_sheet^.earth);
    SDL_FreeSurface(p_sprite_sheet^.down);
    SDL_FreeSurface(p_sprite_sheet^.MissileAllie);
    SDL_FreeSurface(p_sprite_sheet^.MissileAlien);
    SDL_FreeSurface(p_sprite_sheet^.badguy);
    dispose(p_sprite_sheet);
end;


{Procedure de mise en musique}
procedure son(var sound : pMIX_MUSIC);
begin
    if MIX_OpenAudio(AUDIO_FREQUENCY, AUDIO_FORMAT,AUDIO_CHANNELS, 
		AUDIO_CHUNKSIZE)<>0 then HALT;
	sound := MIX_LOADMUS('ressources/Son.mp3');

    MIX_VolumeMusic(MIX_MAX_VOLUME);
    MIX_PlayMusic(sound, -1);
end;


{Procedure d'affichage}
procedure affiche(var window, logo: PSDL_SURFACE);
	var destination_rect : TSDL_RECT;
begin
	{Choix de la position et taille de l'element a afficher}
	destination_rect.x:=(SURFACEWIDTH - IMAGEWIDTH) div 2-100;
	destination_rect.y:=(SURFACEHEIGHT - IMAGEHEIGHT) div 2-50;
	destination_rect.w:=IMAGEWIDTH;
	destination_rect.h:=IMAGEHEIGHT;
	
	{Coller l'element logo dans la fenetre window avec les 
	* caracteristiques destination_rect}
	SDL_BlitSurface(logo,NIL,window,@destination_rect);

	{Afficher la nouvelle image}
	SDL_Flip( window )
end;



procedure ecrire(screen:PSDL_Surface; txt:String;x,y,taille:Integer);
var
	position:TSDL_Rect;
	police:pTTF_Font;
	couleur:PSDL_Color;
	texte:PSDL_Surface;
	ptxt:pChar;
	black:LongWord;
 Begin
	black:=-1;
	SDL_FillRect(screen, NIL, black);

	IF TTF_INIT=-1 THEN HALT;

	police:=TTF_OPENFONT('ressources/Arial.ttf',25);
	new(couleur);
	couleur^.r:=128; couleur^.g:=0;    couleur^.b:=0; 

	TTF_CloseFont(police);

	police:=TTF_OPENFONT('ressources/Arial.ttf',taille);
	
	ptxt:=StrAlloc(length(txt)+1); 
	StrPCopy(ptxt,txt);
    texte:=TTF_RENDERTEXT_BLENDED(police, ptxt,couleur^);
    position.x:=x; position.y:=y;	
	strDispose(ptxt);
	
    SDL_BlitSurface(texte, NIL, screen,@position);
	
	DISPOSE(couleur);
	TTF_CloseFont(police);
    TTF_Quit();
    SDL_FreeSurface(texte);
End;

procedure drawScene(screen:PSDL_Surface; p_sprite_sheet: PSpriteSheet; ElementJeu:Element);
{On affiche la scène de jeu à l'écran}
var i,j:Integer;
    destination_rect:TSDL_RECT;
    player_sprite:PSDL_Surface;
begin
       {Les dessins sont faits en arrière plan sur une surface invisible à l'écran }
       {On remplit la surface de gazon}
       for i:=0 to ((SURFACEWIDTH div SPRITESIZE) -1) do
        for j:=0 to ((SURFACEHEIGHT div SPRITESIZE )-1) do
        begin
            {Rectangle de la surface où viendra se placer le sprite du gazon}
            {Attention, les coordonées (0,0) sont en haut à gauche}
            destination_rect.x:=i*SPRITESIZE;
            destination_rect.y:=j*SPRITESIZE;
            destination_rect.w:=SPRITESIZE;
            destination_rect.h:=SPRITESIZE;
            {On affiche sur la surface un bout de gazon}
            SDL_BlitSurface(p_sprite_sheet^.earth,NIL,screen,@destination_rect)
        end;
		for i:=1 to ElementJeu.NbrProtection do
			begin
				{Rectangle de la surface où viendra se placer le sprite de la protection}
				destination_rect.x:=ElementJeu.Protection[i].x*SPRITESIZE;
				destination_rect.y:=ElementJeu.Protection[i].y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.Protection,NIL,screen,@destination_rect);
			end;
		for i:=1 to ElementJeu.NbrMissileAllie do
			begin
				{Rectangle de la surface où viendra se placer le sprite des missiles Allie et Alien}
				destination_rect.x:=ElementJeu.MissileAllie[i].x*SPRITESIZE;
				destination_rect.y:=ElementJeu.MissileAllie[i].y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.MissileAllie,NIL,screen,@destination_rect);
			end;
		for i:=1 to ElementJeu.NbrMissileAlien do
			begin
				destination_rect.x:=ElementJeu.MissileAlien[i].x*SPRITESIZE;
				destination_rect.y:=ElementJeu.MissileAlien[i].y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.MissileAlien,NIL,screen,@destination_rect);
			end;
       {Rectangle de la surface où viendra se placer le sprite du heros}
       destination_rect.x:=ElementJeu.Vaisseau.x*SPRITESIZE;
       destination_rect.y:=ElementJeu.Vaisseau.y*SPRITESIZE;
       destination_rect.w:=SPRITESIZE;
       destination_rect.h:=SPRITESIZE;      
       {On affiche sur la surface le chat}
       SDL_BlitSurface(p_sprite_sheet^.down,NIL,screen,@destination_rect);			
		for i:=1 to ElementJeu.NbrAlien1 do
			begin
				{Rectangle de la surface où viendra se placer le sprite du méchant}
				destination_rect.x:=ElementJeu.Alien[i][1].x*SPRITESIZE;
				destination_rect.y:=ElementJeu.Alien[i][1].y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.badguy,NIL,screen,@destination_rect);
			end;
		for i:=1 to ElementJeu.NbrAlien2 do
			begin
				{Rectangle de la surface où viendra se placer le sprite du méchant}
				destination_rect.x:=ElementJeu.Alien[i][2].x*SPRITESIZE;
				destination_rect.y:=ElementJeu.Alien[i][2].y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.Alien1,NIL,screen,@destination_rect);
			end;
 		if ElementJeu.PresenceSoucoupe = true then
			begin
				{Rectangle de la surface où viendra se placer le sprite de la soucoupe}
				destination_rect.x:=ElementJeu.Soucoupe.x*SPRITESIZE;
				destination_rect.y:=ElementJeu.Soucoupe.y*SPRITESIZE;
				destination_rect.w:=SPRITESIZE;
				destination_rect.h:=SPRITESIZE;
				SDL_BlitSurface(p_sprite_sheet^.Soucoupe,NIL,screen,@destination_rect);
			end;      
       {On a finit le calcul on bascule la surface à l'écran}
       SDL_Flip(screen );
       ecrire(screen,'score:' + IntToStr(ElementJeu.score), SURFACEWIDTH + 5,SURFACEHEIGHT -30,18);
end;

procedure processKey(key:TSDL_KeyboardEvent;var ElementJeu:Element);
begin
    {Suivant la touche appuyée on change la direction du chat et on le déplace}
    {Attention, les coordonées (0,0) sont en haut à gauche}
    case key.keysym.sym of
        SDLK_LEFT:   if ElementJeu.Vaisseau.x>0 then
                            ElementJeu.Vaisseau.x:=ElementJeu.Vaisseau.x-1;
        SDLK_RIGHT: if ElementJeu.Vaisseau.x< (SURFACEWIDTH div SPRITESIZE) -1 then
                            ElementJeu.Vaisseau.x:=ElementJeu.Vaisseau.x+1;
        SDLK_UP: if (ElementJeu.MissileAllie[ElementJeu.NbrMissileAllie].y<>ElementJeu.Vaisseau.y-1) {and(ElementJeu.MissileAllie[ElementJeu.NbrMissileAllie].y<>ElementJeu.Vaisseau.y-2)} then
							begin	
								ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie+1;
								ElementJeu.MissileAllie[ElementJeu.NbrMissileAllie].x:=ElementJeu.Vaisseau.x;
								ElementJeu.MissileAllie[ElementJeu.NbrMissileAllie].y:=ElementJeu.Vaisseau.y;
							end;
    end;
end;


Procedure TirE(i,j:Integer; var ElementJeu:Element);
var k:Integer;
	begin
		k:=random(100)+1;
		if (k>99)and(ElementJeu.NbrMissileAlien<5) then
			begin
				ElementJeu.NbrMissileAlien:=ElementJeu.nbrMissileAlien+1;
				ElementJeu.MissileAlien[ElementJeu.NbrMissileAlien].x:=ElementJeu.Alien[i][j].x;
				ElementJeu.MissileAlien[ElementJeu.NbrMissileAlien].y:=ElementJeu.Alien[i][j].y;
			end;
	end;	
	
	
procedure MvtAlien(var ElementJeu:Element);
var i:Integer;
begin
	    {Attention, les coordonnees (0,0) sont en haut a gauche}
    if (((ElementJeu.Alien[1][1].y mod 2=0)and(ElementJeu.NbrAlien1<>0))or((ElementJeu.Alien[1][2].y mod 2<>0)and(ElementJeu.NbrAlien2<>0)))and(ElementJeu.Alien[ElementJeu.NbrAlien1][1].x<>(SURFACEWIDTH div SPRITESIZE)-1)and(ElementJeu.Alien[ElementJeu.NbrAlien2][2].x<>(SURFACEWIDTH div SPRITESIZE)-1)then
			begin
				for i:=1 to ElementJeu.NbrAlien1 do
					ElementJeu.Alien[i][1].x:=ElementJeu.Alien[i][1].x+1;
				for i:=1 to ElementJeu.NbrAlien2 do
					ElementJeu.Alien[i][2].x:=ElementJeu.Alien[i][2].x+1;
			end
	else
		if (((ElementJeu.Alien[1][1].y mod 2<>0)and(ElementJeu.NbrAlien1<>0))or((ElementJeu.Alien[1][2].y mod 2=0)and(ElementJeu.NbrAlien2<>0)))and (ElementJeu.Alien[1][1].x<>0)and(ElementJeu.Alien[1][2].x<>0)then
			begin
				for i:=1 to ElementJeu.NbrAlien1 do
					ElementJeu.Alien[i][1].x:=ElementJeu.Alien[i][1].x-1;
				for i:=1 to ElementJeu.NbrAlien2 do
					ElementJeu.Alien[i][2].x:=ElementJeu.Alien[i][2].x-1;
			end
		else
			if (ElementJeu.Alien[15][1].x=(SURFACEWIDTH div SPRITESIZE)-1)or(ElementJeu.Alien[15][2].x=(SURFACEWIDTH div SPRITESIZE)-1)then
				begin
				for i:=1 to ElementJeu.NbrAlien1 do
					ElementJeu.Alien[i][1].y:=ElementJeu.Alien[i][1].y+1;
				for i:=1 to ElementJeu.NbrAlien2 do
					ElementJeu.Alien[i][2].y:=ElementJeu.Alien[i][2].y+1;
			end
			else
				if (ElementJeu.Alien[15][1].x=0)or(ElementJeu.Alien[15][2].x=0)then
					begin
						for i:=1 to ElementJeu.NbrAlien1 do
							ElementJeu.Alien[i][1].y:=ElementJeu.Alien[i][1].y+1;
						for i:=1 to ElementJeu.NbrAlien2 do
							ElementJeu.Alien[i][2].y:=ElementJeu.Alien[i][2].y+1;
					end;
	randomize;
	for i:=1 to ElementJeu.NbrAlien1 do
		TirE(i,1,ElementJeu);
	for i:=1 to ElementJeu.NbrAlien1 do
		TirE(i,1,ElementJeu);		
end;

procedure MvtMissile(var ElementJeu:Element);
var i,j,k:Integer;
begin
		{Deplacer les missiles alliés de une case vers le haut}
	for i:=1 to ElementJeu.NbrMissileAllie do
		ElementJeu.MissileAllie[i].y:=ElementJeu.MissileAllie[i].y-1;
		{Supprimer missile Allie si sort du cadre}
	for i:=1 to ElementJeu.NbrMissileAllie do
		if (ElementJeu.MissileAllie[i].y=-1)  then
			begin
				for j:=i to ElementJeu.NbrMissileAllie-1 do
					ElementJeu.MissileAllie[j]:=ElementJeu.MissileAllie[j+1];
				ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
			end;
		{Test Colision Missile 1}
	for i:=1 to ElementJeu.NbrMissileAllie do
		for j:=1 to ElementJeu.NbrMissileAlien do
			if (ElementJeu.MissileAllie[i].y=ElementJeu.MissileAlien[j].y) and (ElementJeu.MissileAllie[i].x = ElementJeu.MissileAlien[j].x) then
				begin
					for k:=i to ElementJeu.NbrMissileAllie-1 do 
							ElementJeu.MissileAllie[k]:=ElementJeu.MissileAllie[k+1];
					ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
					for k:=j to ElementJeu.NbrMissileAlien-1 do
								ElementJeu.MissileAlien[k]:=ElementJeu.MissileAlien[k+1];
					ElementJeu.NbrMissileAlien:=ElementJeu.NbrMissileAlien-1;
				end;
		{Deplacer les missiles aliens de une case vers le bas}
	for i:=1 to ElementJeu.NbrMissileAlien do
			ElementJeu.MissileAlien[i].y:=ElementJeu.MissileAlien[i].y+1;
		{Supprimer missile Alien si sort du cadre}
	Repeat	
		for i:=1 to ElementJeu.NbrMissileAlien do
			if (ElementJeu.MissileAlien[i].y=(SURFACEHEIGHT div Spritesize))then
				begin
					for j:=i to ElementJeu.NbrMissileAlien-1 do
						ElementJeu.MissileAlien[j]:=ElementJeu.MissileAlien[j+1];
					ElementJeu.NbrMissileAlien:=ElementJeu.NbrMissileAlien-1;
				end;
		until (ElementJeu.NbrMissileAlien=0) or	(ElementJeu.MissileAlien[1].y<>(SURFACEHEIGHT div Spritesize));	
		{Si le missile est sur une protection, supprimer protection et missile}
	for i:=1 to ElementJeu.NbrMissileAllie do
		for j:=1 to ElementJeu.NbrProtection do
			If	(ElementJeu.MissileAllie[i].y=ElementJeu.Protection[j].y) and (ElementJeu.MissileAllie[i].x = ElementJeu.Protection[j].x) then
				begin
					for k:=j to ElementJeu.NbrProtection-1 do
						ElementJeu.Protection[k]:=ElementJeu.Protection[k+1];
					ElementJeu.NbrProtection:=ElementJeu.NbrProtection-1;
					for k:=i to ElementJeu.NbrMissileAllie-1 do
						ElementJeu.MissileAllie[k]:=ElementJeu.MissileAllie[k+1];
					ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
				end;
	for i:=1 to ElementJeu.NbrMissileAlien do
		for j:=1 to ElementJeu.NbrProtection do
			If	(ElementJeu.MissileAlien[i].y=ElementJeu.Protection[j].y) and (ElementJeu.MissileAlien[i].x = ElementJeu.Protection[j].x) then
				begin
					for k:=j to ElementJeu.NbrProtection-1 do
						ElementJeu.Protection[k]:=ElementJeu.Protection[k+1];
					ElementJeu.NbrProtection:=ElementJeu.NbrProtection-1;
					for k:=i to ElementJeu.NbrMissileAlien-1 do
						ElementJeu.MissileAlien[k]:=ElementJeu.MissileAlien[k+1];
					ElementJeu.NbrMissileAlien:=ElementJeu.NbrMissileAlien-1;
				end;					
		{Test colision missile 2 }
	for i:=1 to ElementJeu.NbrMissileAllie do
		for j:=1 to ElementJeu.NbrMissileAlien do
			if (ElementJeu.MissileAllie[i].y=ElementJeu.MissileAlien[j].y) and (ElementJeu.MissileAllie[i].x = ElementJeu.MissileAlien[j].x) then
				begin
					for k:=i to ElementJeu.NbrMissileAllie-1 do 
						ElementJeu.MissileAllie[k]:=ElementJeu.MissileAllie[k+1];
					ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
					for k:=j to ElementJeu.NbrMissileAlien-1 do
						ElementJeu.MissileAlien[k]:=ElementJeu.MissileAlien[k+1];
					ElementJeu.NbrMissileAlien:=ElementJeu.NbrMissileAlien-1;
				end;
			{Detruire l'alien si touché}
	for j:=1 to ElementJeu.NbrMissileAllie do
		begin
			for i:=1 to ElementJeu.NbrAlien1 do
				If (ElementJeu.MissileAllie[j].y=ElementJeu.Alien[i][1].y)and(ElementJeu.MissileAllie[j].x=ElementJeu.Alien[i][1].x) then
					begin
						for k:=j to ElementJeu.NbrMissileAllie-1 do
							ElementJeu.MissileAllie[k]:=ElementJeu.MissileAllie[k+1];
						ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
						for k:=i to ElementJeu.NbrAlien1-1 do
							ElementJeu.Alien[k][1]:=ElementJeu.Alien[k+1][1];
						ElementJeu.NbrAlien1:=ElementJeu.NbrAlien1-1;
						ElementJeu.Score:=ElementJeu.Score+100;			
					end;
			for i:=1 to ElementJeu.NbrAlien2 do
				If (ElementJeu.MissileAllie[j].y=ElementJeu.Alien[i][2].y)and(ElementJeu.MissileAllie[j].x=ElementJeu.Alien[i][2].x) then
					begin
						for k:=j to ElementJeu.NbrMissileAllie-1 do
							ElementJeu.MissileAllie[k]:=ElementJeu.MissileAllie[k+1];
						ElementJeu.NbrMissileAllie:=ElementJeu.NbrMissileAllie-1;
						for k:=i to ElementJeu.NbrAlien2-1 do
							ElementJeu.Alien[k][2]:=ElementJeu.Alien[k+1][2];
						ElementJeu.NbrAlien2:=ElementJeu.NbrAlien2-1;
						ElementJeu.Score:=ElementJeu.Score+100;			
					end;
			end;
		for k:=1 to ElementJeu.NbrMissileAllie do
			if  (ElementJeu.PresenceSoucoupe=True)and(ElementJeu.MissileAllie[k].Y=ElementJeu.Soucoupe.Y)and(ElementJeu.MissileAllie[k].X=ElementJeu.Soucoupe.X) then
				begin
					ElementJeu.PresenceSoucoupe:=False;
					ElementJeu.Score:=ElementJeu.Score+1000;
				end;
end;

Procedure MvtSoucoupe(var ElementJeu:Element);
	begin
		ElementJeu.CompteurSoucoupe:=ElementJeu.CompteurSoucoupe+1;
		if (ElementJeu.CompteurSoucoupe mod 50 = 0) then 
			begin
				ElementJeu.PresenceSoucoupe:=True;
				ElementJeu.Soucoupe.x:= (SURFACEWIDTH div SPRITESIZE)-1;
				ElementJeu.Soucoupe.y:=0;
			end;
		if ElementJeu.PresenceSoucoupe=True then
			ElementJeu.Soucoupe.x:=ElementJeu.Soucoupe.x-1;
		if ((ElementJeu.PresenceSoucoupe=True)and(ElementJeu.Soucoupe.x=1))or(ElementJeu.Alien[1][1].y=0) then
			ElementJeu.PresenceSoucoupe:=False;
	end;
	
procedure move(var ElementJeu:Element);
begin
	MvtAlien(ElementJeu);
	MvtSoucoupe(ElementJeu);
	MvtMissile(ElementJeu);
end;


Procedure Initialisation(var ElementJeu:Element);
var x,y,i:Integer;
	begin
		for y:=1 to 14 do
			for x:=1 to 50 do
				ElementJeu.Grille[y][x]:=0;
		ElementJeu.Vaisseau.x:=12;
		ElementJeu.Vaisseau.y:=14;
		for y:=0 to 1 do
			for i:=1 to 8 do
				begin
					ElementJeu.Alien[i][y+1].x:=i*2;
					ElementJeu.Alien[i][y+1].y:=y;
				end;
		y:=(SURFACEHEIGHT div Spritesize)-3;
		i:=(SURFACEWIDTH div Spritesize);
		for x:=1 to 6 do
						ElementJeu.Protection[x].y:=y;
		for x:=7 to 12 do 
						ElementJeu.Protection[x].y:=y-1;
		for x:=0 to 1 do 
			begin
				ElementJeu.Protection[x+1].x:=(i div 4)+x;
				ElementJeu.Protection[6+x+1].x:=(i div 4)+x;
			end;			
		for x:=0 to 1 do
			begin
				ElementJeu.Protection[3+x].x:=2*(i div 4)+x;
				ElementJeu.Protection[9+x].x:=2*(i div 4)+x;
			end;			
		for x:=0 to 1 do 
			begin
				ElementJeu.Protection[5+x].x:=3*(i div 4)+x;
				ElementJeu.Protection[11+x].x:=3*(i div 4)+x;
			end;
		ElementJeu.NbrAlien1:=8;
		ElementJeu.NbrAlien2:=8;		
		ElementJeu.NbrMissileAlien:=0;	
		ElementJeu.NbrMissileAllie:=0;
		ElementJeu.CompteurSoucoupe:=0;
		ElementJeu.NbrProtection:=12;
		ElementJeu.PresenceSoucoupe:=False;
	end;	
	
 procedure jeu(fenetre:PSDL_SURFACE; var ElementJeu:Element);
 var
	event: TSDL_Event; {Un événement}
	q,i:Integer;
    fin: boolean;
    sprites:PSpriteSheet;
 begin
	Fin:=False;
	q:=0;
	sprites:=initSprites();
	ElementJeu.Score:=0;
	repeat
		Initialisation(ElementJeu);
		drawScene(fenetre,sprites,ElementJeu);
		repeat
			while not(SDL_PollEvent(@event)=1)and(ElementJeu.Alien[1][1].y<>((SURFACEHEIGHT div Spritesize)-1))and((ElementJeu.NbrAlien1>=1)or(ElementJeu.NbrAlien2>=1))and(ElementJeu.Alien[1][2].y<>((SURFACEHEIGHT div Spritesize)-1)) do
				begin		
					SDL_Delay(350-q);
					{On affiche la scene}
					move(ElementJeu);
					drawScene(fenetre,sprites,ElementJeu);
								for i:=1 to ElementJeu.NbrMissileAlien do
				if (ElementJeu.MissileAlien[i].y=ElementJeu.Vaisseau.y)and(ElementJeu.Vaisseau.x=ElementJeu.MissileAlien[i].x) then
					Fin:=True;
				end;
			if event.type_=SDL_KEYDOWN then
				processKey(event.key,ElementJeu);        	
			for i:=1 to ElementJeu.NbrMissileAlien do
				if (ElementJeu.MissileAlien[i].y=((SURFACEHEIGHT div Spritesize)-1))and(ElementJeu.Vaisseau.x=ElementJeu.MissileAlien[i].x) then
					Fin:=True;
			drawScene(fenetre,sprites,ElementJeu);
		Until (ElementJeu.Alien[1][1].y=(((SURFACEHEIGHT div Spritesize)-1))) or  (ElementJeu.Alien[1][2].y=((SURFACEHEIGHT div Spritesize)-1)) or((ElementJeu.NbrAlien1=0)and(ElementJeu.NbrAlien2=0)) or (Fin=True);
		q:=q+20;
	Until (ElementJeu.Alien[1][1].y=(SURFACEHEIGHT div Spritesize)-1)or(ElementJeu.Alien[1][2].y=((SURFACEHEIGHT div Spritesize)-1)) or (Fin=True);
	ecrire(fenetre,'Game-Over, Score :' + IntToStr(ElementJeu.score),25,(SURFACEHEIGHT div 2) -30,30);
	sdl_flip(fenetre);
	SDL_Delay(5000);
 end;


Procedure GestionScore(ElementJeu:Element);
	var a:TabScore;
		Pseudo:String;
		f:file of TabScore;
		i,j:Integer;
	begin
		
		If FileExists('Score') then
			begin
				assign(f, 'Score');
				reset(f);
				read(f,a);
				close(f);
				j:=0;
				Repeat
					j:=j+1;
				until ((a.Tab[j].Score)<(ElementJeu.Score))or (j=a.NbrScore+1);
				if (j<>a.NbrScore+1) or (j<6) then
					begin
						writeln('entrez votre pseudo :');
						readln(Pseudo);
						if a.NbrScore<>5 then
							begin
								a.NbrScore:=a.NbrScore+1;
								for i:=a.NbrScore downto j do
									a.Tab[i]:=a.Tab[i-1];
							end
						else
							for i:=a.NbrScore downto j do
								a.Tab[i]:=a.Tab[i-1];
							a.tab[j].Score:=ElementJeu.Score;
							a.tab[j].Pseudo:=Pseudo;
							if a.NbrScore<>5 then
							a.NbrScore:=a.NbrScore+1;
					end;
			end
		else
			begin
				Writeln('Quel est votre pseudo ?');
				Readln(Pseudo);
				a.Tab[1].Score:=ElementJeu.Score;
				a.Tab[1].Pseudo:=Pseudo;
				a.NbrScore:=1;
				for i:=2 to 5 do
					begin
						a.Tab[i].Score:=0;
						a.Tab[i].Pseudo:='Unknown';
						a.NbrScore:=5;
					end;
			end;
			assign(f, 'Score');
			rewrite(f);
			write(f,a);
			close(f);
	end;
 
 Procedure TableauDeScore();
var a:TabScore;
	f:file of TabScore;
	i:Integer;
	begin
		assign(f, 'Score');
		If FileExists('Score') then
			begin
				reset(f);
				read(f,a);
				close(f);
				clrscr;
				GotoXY(18,1);
				writeln('Space Invaders');
				GoToXY(10,3);
				Writeln('Top Score:');
				for i:=1 to a.NbrScore  do
					begin
						GoToXY(10,3+i);
						Writeln( i,'. ',a.Tab[i].Pseudo,' ',a.Tab[i].Score);
					end;
			end;	
	end;
 
Procedure Acceuil();
	begin
			clrscr;
			TextColor(Brown);
			GotoXY(18,1);
			writeln('Space Invaders');
			TableauDeScore();
			GotoXY(19,10);	
	end;

function Choix():Integer;
var Reponse:Integer;
begin
	Writeln('(1 to play 2 to leave)');
	readln(Reponse);
	Choix:=Reponse;
end;
		
var fenetre, Logo: PSDL_SURFACE;
	event: TSDL_Event; {Un événement}
	suite:Boolean;
    ElementJeu:Element;
    Reponse:Integer;
    music: pMIX_MUSIC=NIL;
begin
	InitKeyboard();
	repeat
		Acceuil();
		Reponse:=Choix;
		if Reponse=1 then
			begin
				initialise(fenetre,Logo);
				affiche(fenetre,Logo);
				son(music);
				SDL_EnableKeyRepeat(0,500);

				suite:=False;
  
				while not suite do
					begin
						{On se limite a 100 fps.}
						SDL_Delay(100);
						{On affiche la scene}
						affiche(fenetre,Logo);
						{On lit un evenement et on agit en consequence}
						SDL_PollEvent(@event);
   
						if event.type_=SDL_KEYDOWN then
						suite:=True;	
					end;	
				jeu(fenetre,ElementJeu);
				termine(fenetre,Logo, music);
				GestionScore(ElementJeu);
			end;
	until (Reponse=2);
end.
