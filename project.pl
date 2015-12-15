:- use_module(library(clpfd)).
:- use_module(library(lists)).

% Plan/6 for a month
plan(Goal, MealsPerDay, Weight, FatPerc, ActivityVariable, Schedule):-
	MealsPerDay > 2,
	MealsPerDay < 6,
	LBM is Weight*(100 - FatPerc) / 100,
	BMR is 370 + 21.6 * LBM,
	TEE is ActivityVariable * BMR,
	calories(Goal, TEE, CAL),
	protein(LBM, Protein),
	fat(LBM, Fat),
	carbs(CAL, Protein, Fat, Carbs),
	MinProtein is integer(Protein * 1000),
	MinFat is integer(Fat * 1000),
	MinCarbs is integer(Carbs * 1000),
	MaxProtein is integer(Protein * 1050),
	MaxFat is integer(Fat * 1050),
	MaxCarbs is integer(Carbs * 1050),
	plan( % Plan/10 for 4 weeks
	    MinProtein, MinFat, MinCarbs,
	    MaxProtein, MaxFat, MaxCarbs,
	    CAL, MealsPerDay, Schedule,
	    4, 7, [], []).

calories(bulk, TEE, CAL):-
	CAL is TEE * 1.2.
calories(cut, TEE, CAL):-
	CAL is TEE * 0.8.
protein(LBM, P):-
	mass(LBM, LB),
	P is 1.5 * LB.
fat(LBM, F):-
	mass(LBM, LB),
	F is 0.4 * LB.
carbs(CAL, P, F, C):-
	caloriesFat(F, FC),
	caloriesProt(P, PC),
	C is (CAL - FC - PC) / 4.

caloriesFat(F, C):-
	C is 9*F.
%caloriesCarb(Carb, Cal):-
%	Cal is 4*Carb.
caloriesProt(P, C) :-
	C is 4*P.

mass(KG, LB):-
	LB is 0.453592 * KG.

% Plan/10 for a new week
plan(
    MinProtein, MinFat, MinCarbs,
    MaxProtein, MaxFat, MaxCarbs,
    CAL, MPD, Schedule,
    Weeks, 0, WACC, SACC):-
	Weeks > 0,
	RemWeeks is Weeks-1,
	%%%%%%%%%%%%%%%%%%%noWeeksRep(WACC, SACC),
	plan( % Plan/10 for this week
	    MinProtein, MinFat, MinCarbs,
	    MaxProtein, MaxFat, MaxCarbs,
	    CAL, MPD, Schedule,
	    RemWeeks, 7, [], [WACC|SACC]).

% Plan/10 complete. Dump Accumulators
plan(
    _, _, _,
    _, _, _,
    _, _, Schedule,
    0, 0, _, Schedule).

% Plan/10 for this week
plan(
    MinProtein, MinFat, MinCarbs,
    MaxProtein, MaxFat, MaxCarbs,
    CAL, MPD, Schedule,
    Weeks, Days, WACC, SACC):-
	Days > 0,
	Weeks > 0,
	% Plan for today
	today(
	    0, 0, 0, 0,
	    MinProtein, MinFat, MinCarbs,
	    MaxProtein, MaxFat, MaxCarbs,
	    CAL, MPD, Today),
	%%%%%%%%%%%%%%%%%%%%%thirdMealRule(Today, WACC),
	RD is Days - 1,
	% Continue Week
	plan( %Plan/10
	    MinProtein, MinFat, MinCarbs,
	    MaxProtein, MaxFat, MaxCarbs,
	    CAL, MPD, Schedule,
	    Weeks, RD, [Today|WACC], SACC).

% Today/10 plan complete. Check if it satisfies needs.
today(
    Protein, Fat, Carbs, Cals,
    MinProtein, MinFat, MinCarbs,
    MaxProtein, MaxFat, MaxCarbs,
    CAL, 0, []):-
	Protein >= MinProtein,
	Protein =< MaxProtein,
	Fat >= MinFat,
	Fat =< MaxFat,
	Carbs >= MinCarbs,
	Carbs =< MaxCarbs,
	Cals =< CAL * 1.05.

% Today/10 plan
today(
    Protein, Fat, Carbs, Cals,
    MinProtein, MinFat, MinCarbs,
    MaxProtein, MaxFat, MaxCarbs,
    CAL, Meals, [Components|T]):-
	Meals > 0,
	RP is MaxProtein - Protein,
	RF is MaxFat - Fat,
	RC is MaxCarbs - Carbs,
	RJ is CAL - Cals,
	meal(TP, TF, TC, TJ, RP, RF, RC, RJ, M, Components),
	NP is Protein + TP,
	NF is Fat + TF,
	NC is Carbs + TC,
	NJ is Cals + TJ,
	NM is M-1,
	plan(
	    NP, NF, NC, NJ,
	    MinProtein, MinFat, MinCarbs,
	    MaxProtein, MaxFat, MaxCarbs,
	    CAL, NM, T).

% Meal/10 for right now
meal(P, F, C, J, MP, MF, MC, MJ, M, Components):-
	component(E1, P1, C1, F1, J1, _, H1, S1, B1),
	%\+member(M, H1),
	component(E2, P2, C2, F2, J2, _, H2, S2, B2),
	%\+member(M, H2),
	%E2 \= E1,
	component(E3, P3, C3, F3, J3, _, H3, S3, B3),
	%\+member(M, H3),
	%E3 \= E1, E3 \= E2,
	component(E4, P4, C4, F4, J4, _, H4, S4, B4),
	%\+member(M, H4),
	%E4 \= E1, E4 \= E2, E4 \= E3,
	M1 in S1..B1, M2 in S2..B2, M3 in S3..B3, M4 in S4..B4,
	P #= M1*P1 + M2*P2 + M3*P3 + M4*P4,
	C #= M1*C1 + M2*C2 + M3*C3 + M4*C4,
	F #= M1*F1 + M2*F2 + M3*F3 + M4*F4,
	J is M1*J1 + M2*J2 + M3*J3 + M4*J4,
	P #=< MP, F #=< MF, C #=< MC, J #=< MJ,
	label([M1, M2, M3, M4]),
	Components = [eat(E1, M1), eat(E2, M2), eat(E3, M3), eat(E4, M4)].

% Component(Name, Protein, Carbs, Fats, Calories, Pref in, Hate in, Min
% units, max units)

component(empty, 0, 0, 0, 0, [], [], 1, 1).
component(banana, 1.1, 0.3, 23, 89, [], [], 1, 2).

noWeeksRep(A, B):-
	\+member(A, B).

thirdMealRule([_|[_|[ThirdMeal|_]]], Meals):-
	thirdMealRule(ThirdMeal, Meals, N),
	N < 3.
thirdMealRule(_, [], 0).
thirdMealRule(M, [H|T], N):-
	sameMeal(M, H),
	N1 is N+1,
	thirdMealRule(M, T, N1).
thirdMealRule(M, [H|T], N):-
	\+sameMeal(M, H),
	thirdMealRule(M, T, N).

sameMeal(meal(X, A), meal(X, B)):-
	true.
%Write Meal Comparator
%Change GRAMS to Milligrams and use CLPFD









