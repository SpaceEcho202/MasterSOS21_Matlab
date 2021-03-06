%--- Testscript for channel_model
close all
clear all
%__________________________________________________________________________
%-- Settings
velocity = 30;
carrier_frequency = 900e6;
sampling_rate = 15.36e6*2;
precision = 0.01;
number_of_samples = 10000*2048;
time_interval = number_of_samples/(sampling_rate);
oversampling_factor = 1229;


%-- Creation of a channel_model object
test_class_channel_model = channel_model(velocity,carrier_frequency,oversampling_factor,time_interval,precision,sampling_rate);

%__________________________________________________________________________
%-- Test of the methods
%- Calculation of the maximal doppler frequency
max_doppler_frequency =  test_class_channel_model.calculate_max_doppler_frequency;

%-Calculation of doppler samples
%number_of_samples_doppler = test_class_channel_model.calculation_of_doppler_samples(max_doppler_frequency,precision,time_interval);

%- Calculation of the jakes spectrum
%jakes_spec = test_class_channel_model.jakes_spectrum(max_doppler_frequency *(Number_of_samples/ sampling_rate),number_of_samples_doppler);

%- Calculation of the rayleighfading
tic
rayleigh_time_signal = test_class_channel_model.rayleigh_fading_generator();
toc

%__________________________________________________________________________
%-- Plots

rayleigh_time_signal_rms = rms(rayleigh_time_signal);
rayleigh_time_signal_db_relativ_rms = 10*log10(abs(rayleigh_time_signal./rayleigh_time_signal_rms));

f = -sampling_rate/2 : sampling_rate/(4*length(rayleigh_time_signal)) : sampling_rate/2 - sampling_rate/(4*length(rayleigh_time_signal));

% figure(1)
% plot(fftshift(jakes_spec))
% title('Doppler spectrum')
% grid on
figure(2)
plot(abs(rayleigh_time_signal))
title('Rayleigh fading')
grid on

figure(3)
plot(f,(abs(fftshift(fft(rayleigh_time_signal,4*length(rayleigh_time_signal))))))
title('Spectrum')
grid on
xlim([-max_doppler_frequency*2 max_doppler_frequency*2]);

figure(4)
plot(rayleigh_time_signal_db_relativ_rms)
title('Rayleigh fading in db relativ to RMS')
grid on

figure(5)
histogram(abs(rayleigh_time_signal))
title('Histogram of the amplitude')
grid on
