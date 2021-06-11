% DATA
secondReserveTable = readtable('SecondReserve.xlsx');
lambda_secondReserve = table2array(secondReserveTable(:, 7));

sureSdreTable = readtable('SURE_SDRE.xlsx');
lambda_sure = table2array(sureSdreTable(:, 7));
lambda_sdre = table2array(sureSdreTable(:, 8));

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
g = ones(t) * 5464000; % [5464000, 5464000, ..., 5464000], data from 2013, assume g(t) = g(min) = g(max)

%  LI-ION BATTERY parameters
% B = linspace(1, 6, 6); % batteries = [1, 2, ..., 6]
DELTA_REP = 0.6;
d_max = 500; % battery's max charge/discharge rate, kWh
e_max = 1000; % battery's capacity, kWh
C_CAP = 1250 * e_max; % capital cost of each battery
cyc_max = 6000; % battery's cycle life
soc_0 = 0.5; % soc_0 NEEDS TO BE RESET AFTER EVERY 24H
soc_min = 0.3;
soc_max = 0.9;
gamaRTE = 0.8;
deltat = 1;
deltat_SR = 0.25;

% OPTIMIZATION VARIABLES
% g = optimvar('g', t, 'LowerBound', g, 'UpperBound', g); 
m = optimvar('m', t, 'LowerBound', 0);
id = optimvar('id', t, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
d = optimvar('d', t, 'LowerBound', 0, 'UpperBound', d_max); % define d_max_id
c = optimvar('c', t, 'LowerBound', 0, 'UpperBound', d_max); % define d_max_one_minus_id
soc = optimvar('soc', t, 'LowerBound', soc_min, 'UpperBound', soc_max);
eu = optimvar('eu', t, 'UpperBound', e_max);
ed = optimvar('ed', t, 'UpperBound', e_max);
ru = optimvar('ru', t, 'LowerBound', 0);  
rd = optimvar('rd', t, 'LowerBound', 0); 
 
% CONSTRAINTS

cons4 = d <= d_max * id;
cons5 = c <= d_max * (1 - id);
cons7 = soc == soc(t-1) + 1 * (c - d/gamaRTE)/e_max + (edb - eub/gamaRTE);
cons10 = ru <= d_max - d + c;
cons11 = rd <= d_max + d - c;

% kud da smjestim soc0 i kako da organiziram soc? 
% trebam ga koristiti paralelno kao polje, da nemam 744 constrainta, zapravo 1488

% cons14 = optimconstr(744);
% cons15 = optimconstr(744);
% cons14(1) = soc_0 + deltat * (c(1) - d(1)/gamaRTE)/e_max - deltat_SR * (ru(i)/(gamaRTE*e_max)) >= soc_min;
% for i = 2:744
%     cons14(i) = soc(i - 1) + deltat * (c(i) - d(i)/gamaRTE)/e_max - deltat_SR * (ru(i)/(gamaRTE*e_max)) >= soc_min;
%     cons15(i) = soc(i - 1) + deltat * (c(i) - d(i)/gamaRTE)/e_max - deltat_SR * (ru(i)/(gamaRTE*e_max)) >= soc_max;
% end


% cons14 = soc(t-1) + deltat * (c - d/gamaRTE)/e_max - deltat_SR * (ru/(gamaRTE*e_max)) >= soc_min;
cons15 = soc(t-1) + deltat * (c - d/gamaRTE)/e_max + deltat_SR * (rd/e_max) <= soc_max;
cons16 = sum(ru) == alpha_SR * sum(rd); % sum by batteries and not t
cons17 = ed(t) == deltat_SR * betad * rd ;
cons18 = eu(t) == deltat_SR * betau * ru;

% OBJECTIVE FUNCTION
ObjectiveFunctionEPVPP = - sum(lambdaDAM.*m) - sum(lambdaSRB.*(ru+rd)) - 0 - (DELTA_REP * C_CAP * sum((t * sum(c) + sum(edb)) / (e_max * cyc_max)));

% OPTIMIZATION PROBLEM
batteryProblem = optimproblem;
batteryProblem.Objective = ObjectiveFunctionEPVPP;
batteryProblem.Constraints.soc = cons7;
batteryProblem.Constraints.socmin = cons14;
batteryProblem.Constraints.socmax = cons15;
batteryProblem.Constraints.ru = cons16;
batteryProblem.Constraints.ed = cons17;
batteryProblem.Constraints.eu = cons18;
[sol, fval] = solve(batteryProblem)