%% This is our main.m whicht will be used to execute the simulation!

clc
clear all

SequenceLength = 1024;
SeedPRBS = 1;

Simulation = Numerlogy;

Simulation.ModulationOrder = 4;

ComplexSymbols = Simulation.symbol_mapper(Simulation.ModulationOrder);

fprintf("gray-coded-complex-symbolstream: \n");
fprintf('%f%+fj\n', real(ComplexSymbols),imag(ComplexSymbols));
