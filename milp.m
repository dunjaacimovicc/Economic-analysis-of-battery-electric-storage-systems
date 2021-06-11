% potrosnja hotela 
% potrosnja = readtable('Hotel_consumption.xlsx',...
%               'Sheet', 'Load', ...
%               'Range','A1:M745',...
%               'ReadVariableNames',true);
% pv_proizvodnja = readtable('Hotel_consumption.xlsx',...
%               'Sheet', 'solar2', ...
%               'Range','A1:M745',...
%               'ReadVariableNames',true);
% c = readtable('Hotel_consumption.xlsx',...
%               'Sheet', 'tou', ...
%               'Range','A1:B745',...
%               'ReadVariableNames',true); 
% pp_cijena = 6
% n = 200000
% eta_punj = 0.9
% eta_praz = 0.88
% E2P = 1
% cijena_bat = 1430
% SoCmin = 0.25
% cijena_PV = 9040
% max_broj_modula = 150
% P_jednog_modula = 0.290
% inv_max = 3300000
% max_bat = inv_max/cijena_bat

% ensmax = 

% potrosnja_1 = potrosnja;
% potrosnja_2 = potrosnja;
% potrosnja_join = join(potrosnja_1, potrosnja_2, 'Keys', 'Var1');
% potrosnja_join.m1_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m2_potrosnja_1 = potrosnja_join.m2_potrosnja_1 + potrosnja_join.m2_potrosnja_1
% potrosnja_join.m3_potrosnja_1 = potrosnja_join.m3_potrosnja_1 + potrosnja_join.m3_potrosnja_1
% potrosnja_join.m4_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m5_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m6_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m7_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m8_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m9_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m10_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m11_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2
% potrosnja_join.m12_potrosnja_1 = potrosnja_join.m1_potrosnja_1 + potrosnja_join.m1_potrosnja_2

% % Write the objective function vector and vector of integer variables.
% f = [-3;-2;-1];
% intcon = 3;
% 
% % Write the linear inequality constraints.
% A = [1,1,1];
% b = 7;
% 
% % Write the linear equality constraints.
% Aeq = [4,2,1];
% beq = 12;
% 
% % Write the bound constraints.
% lb = zeros(3,1);
% ub = [Inf;Inf;1]; % Enforces x(3) is binary
% 
% % Call intlinprog.
% [x,fval,exitflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub)

% T = readtable('marginalpdbc_20210610.1')
% files = dir('*.1')
% % for f=1:length(files)
% %     T = readtable(files(f))
% % end
% files = dir('*.txt');
% c = containers.Map;
% 
% for i=1:length(files)
%     filename = files(i).name;
%     disp(string(extractBetween(filename, "_", ".")))
% %     c(date) = readtable(filename)
% end

% string_keys = strings(length(keys), 1)
% for i=1:length(keys)
%   string_keys(i) = string(keys(i))
% end

% --- 
% Mixed-Integer Linear Programming Basics: Problem-Based
% ---

steelprob = optimproblem;

ingots = optimvar('ingots',4,'Type','integer','LowerBound',0,'UpperBound',1);
alloys = optimvar('alloys',3,'LowerBound',0);
scrap = optimvar('scrap','LowerBound',0);

weightIngots = [5,3,4,6];
costIngots = weightIngots.*[350,330,310,280];
costAlloys = [500,450,400];
costScrap = 100;
cost = costIngots*ingots + costAlloys*alloys + costScrap*scrap;

steelprob.Objective = cost;
totalWeight = weightIngots*ingots + sum(alloys) + scrap;

carbonIngots = [5,4,5,3]/100;
carbonAlloys = [8,7,6]/100;
carbonScrap = 3/100;
totalCarbon = (weightIngots.*carbonIngots)*ingots + carbonAlloys*alloys + carbonScrap*scrap;

molybIngots = [3,3,4,4]/100;
molybAlloys = [6,7,8]/100;
molybScrap = 9/100;
totalMolyb = (weightIngots.*molybIngots)*ingots + molybAlloys*alloys + molybScrap*scrap;

% jfd = alloys * 100
alloysCons = optimconstr(3);
for i = 2:3
    alloysCons(i) = alloys(i) <= alloys(i-1);
end

steelprob.Constraints.alloysCons = alloysCons
steelprob.Constraints.conswt = totalWeight == 25;
steelprob.Constraints.conscarb = totalCarbon == 1.25;
steelprob.Constraints.consmolyb = totalMolyb == 1.25;

[sol,fval] = solve(steelprob)
sol.alloys