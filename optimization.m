% DATA
secondReserveTable = readtable('SecondReserve.xlsx');
lambda_secondReserve = table2array(secondReserveTable(:, 7));

sureSdreTable = readtable('SURE_SDRE.xlsx');
lambda_sure = table2array(sureSdreTable(:, 3));
lambda_sdre = table2array(sureSdreTable(:, 4));

damFiles = struct2table(dir('*.txt')); % convert the struct array to a table
damFilesSize = size(damFiles);
damFilesSorted = sortrows(damFiles, 'name'); % change it back to struct array if necessary
lambdaDAM = zeros(24*damFilesSize(:, 1), 1);
for i=1:damFilesSize(:,1)
    filename = table2array(damFilesSorted(i, 1));
    table = readtable(string(filename));
    array = table2array(table(1:24, 6));
    for j=1:24
        lambdaDAM(j+(i-1)*24) = array(j);
    end
end 

% CONSTANTS
t = 744;
B = linspace(1, 6, 6); % batteries = [1, 2, ..., 6]
% g = ones(t, 1) * 5464; % [5464000, 5464000, ..., 5464000], data from 2013, assume g(t) = g(min) = g(max)
d_max = 500; % battery's max charge/discharge rate, kWh
e_max = 1000; % battery's capacity, kWh
C_CAP = 1250 * e_max; % capital cost of each battery
cyc_max = 6000; % battery's cycle life
soc_0 = 0.5;
soc_min = 0.3;
soc_max = 0.9;
gamaRTE = 0.8;
DELTA_REP = 0.6;
deltat = 1;
deltat_SR = 0.25;
alpha_SR = 1.5;

betau = rand(744, 1);
betad = rand(744, 1);

% OPTIMIZATION VARIABLES
g = optimvar('g', t, 'LowerBound', 5464, 'UpperBound', 5464); 
m = optimvar('m', t, 'LowerBound', 0);
% L = optimvar('L', t, 'LowerBound', 0);
id = optimvar('id', t, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
d = optimvar('d', t, 'LowerBound', 0, 'UpperBound', d_max); 
c = optimvar('c', t, 'LowerBound', 0, 'UpperBound', d_max); 
soc = optimvar('soc', t+1, 'LowerBound', soc_min, 'UpperBound', soc_max);
e = optimvar('e', t, 'LowerBound', 0, 'UpperBound', e_max);
eu = optimvar('eu', t, 'LowerBound', 0, 'UpperBound', e_max);
ed = optimvar('ed', t, 'LowerBound', 0, 'UpperBound', e_max);
ru = optimvar('ru', t, 'LowerBound', 0);  
rd = optimvar('rd', t, 'LowerBound', 0); 
 
% CONSTRAINTS
cons1 = m == deltat * g + deltat * sum(d - c);
cons4 = d <= d_max * id;
cons5 = c <= d_max * (1 - id);
cons7_9 = optimconstr(744);
for i=1:745
   if mod(i, 24) == 1
       cons7_9(i) = soc(i) == soc_0;
   else
       cons7_9(i) = soc(i) == soc(i - 1); % + deltat * (c(i - 1) - d(i - 1)/gamaRTE)/e_max + (ed(i - 1) - eu/gamaRTE);
   end
end
cons10 = ru <= d_max - d + c;
cons11 = rd <= d_max + d - c;
cons12 = e == soc(1:744) * e_max + deltat * (c - d/gamaRTE) 
cons13 = e == soc(1:744) * e_max + deltat * (c - d/gamaRTE) - deltat_SR * ru/gamaRTE;
cons14 = soc(1:744) + deltat * (c - d/gamaRTE)/e_max - deltat_SR * (ru/(gamaRTE*e_max)) >= soc_min;
cons15 = soc(1:744) + deltat * (c - d/gamaRTE)/e_max + deltat_SR * (rd/e_max) <= soc_max;
cons16 = ru == alpha_SR * rd; % sum by batteries and not t
cons17 = ed == deltat_SR * rd .* betad; % trebam betad i betau
cons18 = eu == deltat_SR * ru .* betau;

% OBJECTIVE FUNCTION
ObjectiveFunctionEPVPP = - sum(lambdaDAM(1:744).*m) - sum(lambda_secondReserve(1:744).*(ru+rd)) - 0 - (DELTA_REP * C_CAP * sum((t * sum(c) + sum(ed)) / (e_max * cyc_max)));

% OPTIMIZATION PROBLEM
batteryProblem = optimproblem;
batteryProblem.Objective = ObjectiveFunctionEPVPP;
batteryProblem.Constraints.m = cons1;
batteryProblem.Constraints.d = cons4;
batteryProblem.Constraints.c = cons5;
batteryProblem.Constraints.soc = cons7_9;
batteryProblem.Constraints.ru = cons10;
batteryProblem.Constraints.rd = cons11;
batteryProblem.Constraints.cons12 = cons12;
batteryProblem.Constraints.cons13 = cons13;
batteryProblem.Constraints.socmin = cons14;
batteryProblem.Constraints.socmax = cons15;
batteryProblem.Constraints.ru = cons16;
batteryProblem.Constraints.ed = cons17;
batteryProblem.Constraints.eu = cons18;
[sol, fval] = solve(batteryProblem);