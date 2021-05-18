%--- Testscript for channel_model
%__________________________________________________________________________
%-- Settings
velocity = 10;
carrier_frequency = 900e6;
sampling_rate = 2000;
Number_of_samples =100000;

%-- Creation of a channel_model object
test_class_channel_model = channel_model(velocity,carrier_frequency,Number_of_samples,sampling_rate);



%__________________________________________________________________________
%-- Test of the methods
%- Calculation of the maximal doppler frequency
doppler_frequency_max =  test_class_channel_model.calculate_max_doppler_frequency;

%- Calculation of the jakes spectrum
jakes_spec = test_class_channel_model.jakes_spectrum(doppler_frequency_max *(Number_of_samples/ sampling_rate));

%- Calculation of the rayleighfading
rayleigh_time_signal = test_class_channel_model.rayleigh_fading_generator();



%__________________________________________________________________________
%-- Plots

rayleigh_time_signal_rms = rms(rayleigh_time_signal);
rayleigh_time_signal_db_relativ_rms = 10*log10(abs(rayleigh_time_signal./rayleigh_time_signal_rms));

t = (0:1:Number_of_samples-1)*1/sampling_rate;
f = -sampling_rate/2:sampling_rate/Number_of_samples:sampling_rate/2-sampling_rate/Number_of_samples;

figure(1)
plot(f,fftshift(jakes_spec))
title('Doppler spectrum')
grid on

figure(2)
plot(f,fftshift(jakes_spec))
title('Doppler spectrum zoomed')
xlim([-doppler_frequency_max-20,doppler_frequency_max+20])
grid on

figure(3)
plot(t,abs(rayleigh_time_signal))
title('Rayleigh fading')
grid on

figure(4)
plot(rayleigh_time_signal_db_relativ_rms)
title('Rayleigh fading in db relativ to RMS')
grid on

figure(5)
histogram(abs(rayleigh_time_signal))
title('Histogram of the amplitude')
grid on

