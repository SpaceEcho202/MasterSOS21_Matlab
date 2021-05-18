%% This is our main.m whicht will be used to execute the simulation!

clc
clear all


Simulation = Numerlogy;

Simulation.ModulationOrder      = 256;
Simulation.ResourceElementCount = 12;
Simulation.SeedPRBS             = 1;
Simulation.Bandwidth            = 1.4e6;

complexSymbols = Simulation.symbol_mapper();
ifft = Simulation.ifft_signal();
fft = (fft(ifft));
f = linspace(-length(ifft)/2, length(ifft)/2, length(ifft));
figure(1)
subplot(2,1,1)
plot(linspace(0,length(ifft), length(ifft)),ifft), xlim([1 length(ifft)])
subplot(2,1,2)
plot(f, 20*log10(abs(fft))), xlim([-length(ifft)/2 length(ifft)/2])
