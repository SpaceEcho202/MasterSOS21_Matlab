%% This is our main.m whicht will be used to execute the simulation!

clc
clear all


Simulation = Numerlogy;

Simulation.ModulationOrder      = 256;
Simulation.ResourceElementCount = 12;
Simulation.SeedPRBS             = 1;
Simulation.Bandwidth            = 1.4e6;

FreqAxis = linspace(-(15e3*128),(15e3*128),128);
TimeAxis = linspace(0,(1/15e3)*7,7);
OfdmSpectrum = fft(Simulation.ofdm_time_signal(),[],2);
[Time, Freq] = meshgrid(TimeAxis, FreqAxis);
surf(Time',Freq',20*log10(abs(OfdmSpectrum)))

