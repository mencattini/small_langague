% on va définir les éléments qui vont nous servirent pour l'interpréteur
% afin de gérer les variables globals et les variables locales, je vais ajouter
% la notion de degré
%il y a un nom, une valeur et un degre
% memoireGlobal(Nom,Valeur,Degr)
% degr = 1 est le niveau global, degre = 2 est un bloc...
:- dynamic (memoire/3).

% on définit les instructions qui seront disponibles dans le programme,
% on retrouve ceux du projet partie un, et les nouveaux:
:- dynamic (declare/1).
:- dynamic (declare/2).
:- dynamic (jump/3).
:- dynamic (copy/2).
:- dynamic (incr/1).
:- dynamic (up/1).
:- dynamic (down/1).
:- dynamic (if/3).
:- dynamic (procThen/3).
:- dynamic (procElse/3).

% on fera attention a ce que les deux éléments suivants soient uniques
% on considère que le programme est toujours une liste parsée:
:- dynamic (programme/1).

% que le pointeur est toujours un entier
:- dynamic (index/1).

% on a également besoin de connaître notre degré actuel dans le bloc
:- dynamic (degre/1).


%% on va définir une fonction qui permet de rechercher et de trouver un registre
%% et le cas échéant de le créer dans le plus haut degré i.e."1"
%%  s'il n'existe pas.
rechercheR(Nom,Valeur,Degre):-  memoire(Nom,Valeur,Degre).
rechercheR(Nom,Valeur,Degre):-  not(memoire(Nom,Valeur,Degre)),
                                asserta(memoire(Nom,0,1)).

%% on va définir le declare, d'abord la version avec juste un nom
%% on va poser comme condition, qu'il ne doit pas exister de registre du même
%% niveau, si on veut en déclarer un nouveau.
%% on insère les nouveaux registres à la fin de la mémoire.
%% la fonction marche comme ça: on récupère le degré actuel, on vérifie qu'il n'
%% existe aucun registre dans ce degré, et on le crée.
declare(Nom):-  degre(D), not(memoire(Nom,_Valeur,D)),
                asserta(memoire(Nom,0,D)), index(I), I2 is I + 1,
                retract(index(_)),assert(index(I2)).


%% même principe pour un declare a deux paramètres
declare(Nom,Valeur):- degre(D), not(memoire(Nom,_Valeur,D)),
                      asserta(memoire(Nom,Valeur,D)),index(I), I2 is I + 1,
                      retract(index(_)),assert(index(I2)).

%% on déclare la fonction copy, qui prend deux registres. On utilise
%% la fonction rechercheR, pour voir si le registre et le crée le cas
%% échéant. ensuite on copie la valeur du premier dans le deuxième
copy(R1,R2):- rechercheR(R1,V1,_D1),rechercheR(R2,_V2,D2),
              retractall(memoire(R2,_V,D2)),asserta(memoire(R2,V1,D2)),
              index(I), I2 is I + 1,
              retract(index(_)),assert(index(I2)).

%% on définit la fonction incr, qui prend un registre et qui augmente sa valeur,
%% on utilise la fonction rechercheR pour obtenir ou créer r1, et on l'augmente
incr(R1):-  rechercheR(R1,V1,_),memoire(R1,V1,D), V2 is V1 + 1,
            retractall(memoire(R1,_V1,D)),asserta(memoire(R1,V2,D)),
            index(I), I2 is I + 1,
            retract(index(_)),assert(index(I2)).

%% on va définir la fonction jump, elle prend deux registres. comme pour copy,
%% on va récupérer les valeurs des registres, les comparer et ensuite
%% modifier le pointeur. On regarde aussi les cas ou R1 != R2. La on augmente
%% juste le pointeur. Il faut aussi faire attention a ce que R3 soit un registre
%% ou un nombre, d'où le teste atom(R3) => R3 est un registre, number(R3) =>
%% R3 est un nombre.
jump(R1,R2,R3):-  rechercheR(R1,V1,_D1), rechercheR(R2,V2,_D2), V1 = V2,
                  index(I),number(R3), choice(R3,I),
                  retractall(index(_)), assert(index(R3)).
jump(R1,R2,R3):-  rechercheR(R1,V1,_D1), rechercheR(R2,V2,_D2),atom(R3),
                  rechercheR(R3,V3,_D), V1 = V2,
                  index(I),choice(V3,I),
                  retractall(index(_)),
                  assert(index(V3)).
jump(R1,R2,_):-  rechercheR(R1,V1,_D1), rechercheR(R2,V2,_D2), not(V1 = V2),
                  index(I),I2 is I + 1,
                  retractall(index(_)), assert(index(I2)).

%% on définit le add, qui prend 2 registres et qui retourne la valeur dans le
%% troisième. même principe qu'ailleur , on trouve les valeurs et on assert
%% la nouvelle valeur dans le dernier registre
add(R1,R2,R3):- rechercheR(R1,V1,D1),rechercheR(R2,V2,D2),
                memoire(R1,V1,D1),memoire(R2,V2,D2),
                V4 is V1 + V2, rechercheR(R3,_,D3),memoire(R3,_,D3),
                retractall(memoire(R3,_,D3)),
                asserta(memoire(R3,V4,D3)),index(I), I2 is I + 1,
                retract(index(_)),assert(index(I2)).

%% même principe pour le sub, sauf qu'on soustrait
sub(R1,R2,R3):- rechercheR(R1,V1,D1),rechercheR(R2,V2,D2),
                memoire(R1,V1,D1),memoire(R2,V2,D2),
                V4 is V1 - V2,rechercheR(R3,_,D3),memoire(R3,_,D3),
                retractall(memoire(R3,_,D3)),
                asserta(memoire(R3,V4,D3)),index(I), I2 is I + 1,
                retract(index(_)),assert(index(I2)).

%% on va utiliser le beginbloc comme début de bloc.on augmente le degré
%% ensuite on va continuer
%% tant qu'on ne trouve pas l'instruction de fin (endbloc). à ce moment
%% on supprime tout les variables locacles de degré D, et on diminue le degré
%% ------> on suppose que les lignes begin et end bloc sont numérotées comme
%% les autres.
beginbloc:- degre(D), D2 is D + 1, retract(degre(_I)), assert(degre(D2)),
            index(I), I2 is I + 1, retract(index(_)),assert(index(I2)).
endbloc:- degre(D), D2 is D-1, retractall(memoire(_R,_V,D)),
          retract(degre(_I)),assert(degre(D2)),index(I), I2 is I + 1,
          retract(index(_)),assert(index(I2)).

%% on créer une fonction qui nous informe si le jump "remonte" le programme, ou
%% bien le "descend", i.e., la ligne de destination est plus petite ou grande
%% que la ligne de l'instruction jump, on va ensuite récupérer la sous-liste
%% comprise entre ces deux nombres, et on va l'exécuter en descendant (down) ou
%% en montant (up)
choice(LigneDestination,LigneInstruction):- LigneDestination > LigneInstruction,
                                            listeEntreAB(LigneInstruction,LigneDestination,L),
                                            down(L).

choice(LigneDestination,LigneInstruction):- LigneInstruction > LigneDestination,
                                            listeEntreAB(LigneDestination,LigneInstruction,L),
                                            up(L).


% on a besoin d'une fonction qui retourne le nième élément d'une liste
% car le programme est représenté sous forme de liste pour cet intrepréteur
niemeElement([],_N,_Element):- false.
niemeElement([Element|_L],1,Element).
niemeElement([_X|Liste],Nombre,Element):-   Nombre2 is Nombre - 1,
                                            niemeElement(Liste,Nombre2,Element).

%% on définit la fonction listeEntreAB, qui donne la sous-liste du programme
%% entre la borne A et la borne B,i.e. listeEntreAB(A,B,ListeRetour), ou A < B.
listeEntreAB(A,A,[]).
listeEntreAB(A,B,L):- A2 is A + 1,programme(P),niemeElement(P,A,E),
                      append([E],L2,L),listeEntreAB(A2,B,L2).

%% on va définir l'instruction if(R1,==,R2), qui prend une relation, et qui va
%% exécuter jusqu'au endif qui délimite la fin. Il s'agit d'un gros bloc d'instruction
%% a la fin on sort du bloc d'où la décrémentation du degré.
%% on suppose que le parsing est bien fait.
if([X,==,Z]):-  rechercheR(X,V1,_),rechercheR(Z,V2,_),V1 = V2,
                index(I), I2 is I+ 1,writef('\t%d==%d\n',[X,Z]),
                retractall(index(_)),assert(index(I2)),degre(D), D2 is D+1,
                retractall(degre(_)),assert(degre(D2)),
                programme(P),procIf(P,I2,true),
                retractall(degre(_)),assert(degre(D)),
                retractall(memoire(_R,_V,D2)).
if([X,==,Z]):-  rechercheR(X,V1,_),rechercheR(Z,V2,_),not(V1 = V2),
                index(I), I2 is I+ 1, writef('\t%d!= %d\n',[X,Z]),
                retractall(index(_)),assert(index(I2)),degre(D), D2 is D+1,
                retractall(degre(_)),assert(degre(D2)),
                programme(P),procIf(P,I2,false),
                retractall(degre(_)),assert(degre(D)),
                retractall(memoire(_R,_V,D2)).

%% on définit le else et le then, ainsi que le endif qui me servent
%% qu'a incrémenter le pointeur
else:- index(I), I2 is I+ 1,retractall(index(_)),assert(index(I2)).
then:- index(I), I2 is I+ 1,retractall(index(_)),assert(index(I2)).
endif :- index(I), I2 is I+ 1,retractall(index(_)),assert(index(I2)).

%% nous avons plusieurs cas.
%% si procIf a la valeur B = true, alors tant qu'on ne rencontre pas un else,
%% on exécute ce qu'on trouve comme instruction
%% si procIf a la valeur B = flase, alors tant qu'on ne rencontre pas un else,
%% on ne fait rien
%% si procIf a la valeur B =true ou false, et qu'on
%% rencontre else, on change la valeur
%% et ensuite si procIf a la valeur true, on exécute tant qu'on ne rencontre pas
%% endif ( on n'exécute pas si on a la valeur false)
%% quand on rencontre endif, c'est la fin.
procIf(P,I,B):-   B,niemeElement(P,I,Instr), Instr = else, B2 = not(B),
                  index(I), I2 is I+ 1,retractall(index(_)),
                  assert(index(I2)),procIf(P,I2,B2).
procIf(P,I,B):-   not(B),niemeElement(P,I,Instr), Instr = else, Instr,
                  index(I2),B2 = not(B), procIf(P,I2,B2).
procIf(P,I,_B):-  niemeElement(P,I,Instr), Instr = endif,Instr,
                  writef('\t%d\n',[Instr]),!.
procIf(P,I,B):-   not(B),niemeElement(P,I,Instr), Instr \= endif,index(I),
                  I2 is I+ 1,retractall(index(_)),
                  assert(index(I2)),procIf(P,I2,B).
procIf(P,I,B):-   B,niemeElement(P,I,Instr), Instr \= else, Instr,
                  writef('\t%d\n',[Instr]),index(I2),procIf(P,I2,B).

%% on définit le up, qui en prennnant une liste en entrée, va inverser les begin
%% et les ends bloc. afin de bien gérer l'état de la mémoire lors de saut en
%% dehors du bloc.on a quatres cas: 1) si L = [], c'est notre fin de récursion
%% 2) I = beginbloc, alors on doit faire endbloc pour garder une cohérence dans
%% les degrés, et ensuite faire la récursion. 3) pareil mais pour endbloc qui
%% est inversé. 4) si aucune des deux instructions, on fait simplement la
%% recursion.
up([]).
up([I|L]):- I = beginbloc, endbloc, up(L).
up([I|L]):- I = endbloc, beginbloc, up(L).
up([I|L]):- I = if(_),endbloc,up(L).
up([I|L]):- I = endif, beginbloc,up(L).
up([_|L]):- up(L).

%% même chose pour down, mais sauf qu'on inverse pas les instructions.
down([]).
down([I|L]):- I = beginbloc, beginbloc, down(L).
down([I|L]):- I = endbloc, endbloc, down(L).
down([I|L]):- I = if(_),beginbloc,down(L).
down([I|L]):- I = endif, endbloc, down(L).
down([_|L]):- down(L).


%% fonction pour évaluer un programme en entrée. On suppose que la mémoire est
%% vide, et que le pointeur vaut 1. On enlève tout ce qui est dans la mémoire,
%% dans l'index, le degre et le programme.
%% on rentre l'index a 1, on rentre le programme comme une liste, et ensuite on
   %% exécute avec eval. pour afficher ensuite le résultat avec du formatage.
   evaluation(Programme):-   retractall(memoire(_X,_Y,_Z)),
                          retractall(index(_)),retractall(degre(_)),
                          retractall(programme(_)),
                          assert(index(1)),assert(degre(1)),
                          assert(programme(Programme)),
                          writef('\nProgramme:\n'),
                          evalProgramme(Programme,1),
                          writef('\nÉtat de la mémoire:\n'),
                          findall([X,Y],memoire(X,Y,_),Liste),
                          writef('\t%w\n',[Liste]),
                          index(Pointeur2),
                          writef('Valeur du pointeur :\n\t%d\n',[Pointeur2]).

% le code ci-dessous évalue le programme.
% le premier bloc est notre condition d'arret: si on dépasse
% la liste d'instruction, on s'arrête
%  le deuxième bloc concerne l'évaluation à proprement parlé.
% elle prend l'élément désigné par le pointeur, l'exécute et l'affiche, et on
% lance la récursion.
evalProgramme(Programme,Pointeur):- length(Programme,N),N < Pointeur,!,true.
evalProgramme(Programme,Pointeur):- niemeElement(Programme,Pointeur,Instruction),
                                    writef('\t%w\n',[Instruction]),
                                    Instruction,
                                    index(Pointeur2),
                                    evalProgramme(Programme,Pointeur2).

%% exemple programme, je suppose que le parsing a bien été fait:
:- evaluation([declare(x,3),declare(a,1),if([x,==,a]),then,incr(xx),else,incr(aa),endif, beginbloc,declare(x,0),declare(b,2),add(x,a,x),incr(x),beginbloc,incr(c),incr(c),jump(x,c,13),endbloc,endbloc]).
