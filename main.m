%% This is our main.m whicht will be used to execute the simulation!
clc
clear all
Simulation = NumerlogyRefactoring;
Simulation.Bandwidth = 10e6;
Simulation.show_goldsequence();
tic;
TxFrameCP = Simulation.cycle_prefixer();
toc;
