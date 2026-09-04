function mpc = case_IEEE9BusSystem
%CASE_IEEE9BUSSYSTEM

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	3	0	0	0	0	1	1	0	16.5	1	1.1	0.9;
	2	2	0	0	0	0	1	1	0	18	1	1.1	0.9;
	3	2	0	0	0	0	1	1	0	13.8	1	1.1	0.9;
	4	1	0	0	0	0	1	1	0	230	1	1.1	0.9;
	5	1	125	50	0	0	1	1	0	230	1	1.1	0.9;
	6	1	90	30	0	0	1	1	0	230	1	1.1	0.9;
	7	1	0	0	0	0	1	1	0	230	1	1.1	0.9;
	8	1	100	35	0	0	1	1	0	230	1	1.1	0.9;
	9	1	0	0	0	0	1	1	0	230	1	1.1	0.9;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	1	0	0	300	-300	1	100	1	300	0	0	0	0	0	0	0	0	0	0	0	0;
	2	163	0	300	-300	1.025	100	1	626	0	0	0	0	0	0	0	0	0	0	0	0;
	3	85	0	300	-300	1.025	100	1	470	0	0	0	0	0	0	0	0	0	0	0	0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	4	5	0.0188405482	0.105678663	0.0329056698	0	0	0	0	0	1	-360	360;
	4	6	0.0235072779	0.110342949	0.0269028779	0	0	0	0	0	1	-360	360;
	5	7	0.0456805293	0.205356825	0.0504753031	0	0	0	0	0	1	-360	360;
	6	9	0.0503478261	0.211357327	0.0678056226	0	0	0	0	0	1	-360	360;
	7	8	0.0178402647	0.0970128562	0.0272319346	0	0	0	0	0	1	-360	360;
	8	9	0.0322816635	0.165220455	0.0181419926	0	0	0	0	0	1	-360	360;
	4	1	0.0002	0.0576	0	0	0	0	1	0	1	-360	360;
	7	2	0.0002	0.0625	0	0	0	0	1	0	1	-360	360;
	9	3	0.0002	0.0586	0	0	0	0	1	0	1	-360	360;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0	1	0;
	2	0	0	3	0	1	0;
	2	0	0	3	0	1	0;
];

%% switchable disturbance loads (behind a breaker)
%	bus	Pd	Qd	status (1=in base case, 0=out)
mpc.switched_load = [
	6	50	30	0;
];
