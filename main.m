%% This is our main.m whicht will be used to execute the simulation!

clc
clear all


Simulation = Numerlogy;

Simulation.ModulationOrder      = 256;
Simulation.ResourceElementCount = 12;
Simulation.SeedPRBS             = 1;
Simulation.Bandwidth            = 1.4e6;

FreqAxis = linspace(-(15e3*64),(15e3*64),128);

TimeAxis = linspace(0,(1/15e3)*6,7);

OfdmTimeSignal = Simulation.ofdm_time_signal();
OfdmSpectrum = fft(OfdmTimeSignal,[],2)';

OfdmTimeSignal = reshape(OfdmTimeSignal,1,[]);

spectrogram(OfdmTimeSignal)

[Time, Freq] = meshgrid(TimeAxis, FreqAxis);

normFreq = Freq/1e6;
normTime = Time/1e-6;

surf(normTime,normFreq,(abs(OfdmSpectrum))),ylabel('Freq [MHz]'), 

xlabel('Time [\mus]'), xticks(0:1/15e-3:1/15e-3*7)



