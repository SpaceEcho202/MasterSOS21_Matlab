%% This is our main.m whicht will be used to execute the simulation!

clc
clear all

SequenceLength = 1024;
SeedPRBS = 1;

Simulation = Numerlogy;

Simulation.ModulationOrder = 64;
Simulation.BitStream = nrPRBS(SeedPRBS, SequenceLength)';

ComplexSymbols = Simulation.symbol_mapper;

fprintf("gray-coded-complex-symbolstream: \n");
fprintf('%f%+fj\n', real(ComplexSymbols),imag(ComplexSymbols));
