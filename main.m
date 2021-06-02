%% This is our main.m whicht will be used to execute the simulation!

%{
=======

>>>>>>> 968f164dfcd421d4c20a6744280abac7bdac3979
Simulation = Numerlogy;

Simulation.ModulationOrder              = 4;
Simulation.SubcarrierPerRescourceBlock  = 12;
Simulation.SeedPRBS                     = 1;
Simulation.Bandwidth                    = 10e6;

[GoldSequence, x1, x2, MPN, Pream] = Simulation.gold_sequencer();
figure(1)
subplot(3,2,3)
stem(x1)
subplot(3,2,2)
stem(x2)
subplot(3,2,1)
stem(GoldSequence)
subplot(3,2,2)
% stem(abs(1/(2*length(GoldSequence))*xcorr(GoldSequence)));
% subplot(3,3,3)
% stem(abs(1/(2*length(Pream))*xcorr(Pream)));


%{
FreqAxis = linspace(-(15e3*64),(15e3*64),128);
TimeAxis = linspace(0,(1/15e3)*7,8);

OfdmTimeSignal = Simulation.ofdm_time_signal();
CyclicPrefix = Simulation.cycle_prefixer();
OfdmSpectrum = fft(OfdmTimeSignal,[],2)';
OfdmSpectrum = horzcat(OfdmSpectrum, OfdmSpectrum(:,7));

OfdmTimeSignal = reshape(Simulation.cycle_prefixer(),[],1);

t = linspace(0,(1/15e3)*length(OfdmTimeSignal),length(OfdmTimeSignal));
figure(1)
plot(t, abs(OfdmTimeSignal))

[Time, Freq] = meshgrid(TimeAxis, FreqAxis);

normFreq = Freq/1e6;
normTime = Time/1e-6;
figure(2)
surf(normTime,normFreq,(abs(OfdmSpectrum))),ylabel('Freq [MHz]'), 
xlabel('Time [\mus]'), xticks(0:1/15e-3:1/15e-3*7)
%}


