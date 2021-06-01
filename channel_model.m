classdef channel_model < matlab.mixin.SetGet
    properties (Constant,GetAccess=private)
        speed_of_light = 3e8;
    end
    
    properties
        velocity;
        carrier_frequency;
        oversampling_factor;
        bandwidth_signal;
        simulation_time;
        precision;
        sampling_rate_system;
    end
    
    
    methods
        function obj = channel_model(velocity,carrier_frequency, oversampling_factor,simulation_time,precision,sampling_rate_system)
            
            set(obj,'velocity',velocity);
            set(obj,'carrier_frequency',carrier_frequency);
            set(obj,'oversampling_factor',oversampling_factor);
            set(obj,'simulation_time',simulation_time);
            set(obj,'precision',precision);
            set(obj,'sampling_rate_system',sampling_rate_system);
            
        end
        
        
        function max_doppler_frequency = calculate_max_doppler_frequency(obj)
            if nargin <= 1
                max_doppler_frequency = obj.velocity/obj.speed_of_light * obj.carrier_frequency * 1/3.6;
            end
        end
        
        function [resampled_signal] = resampler(obj, signal, sampling_rate_sys, sampling_rate_gen)
            upsampling_factor = sampling_rate_sys / sampling_rate_gen;
            resample_nominators =[];
            
            if upsampling_factor > 1000
                ten_potency = ceil(log10(upsampling_factor));
                ten_potency_divide = (ceil(ten_potency)-3);
                upsampling_factor = upsampling_factor/10^ten_potency_divide;
                
                if ten_potency_divide > 3
                    number_of_resampler_with_factor_1000 = floor(ten_potency_divide/3);
                    resample_values = 1000 * ones(1,number_of_resampler_with_factor_1000);
                    rest_resampler = 10^mod(ten_potency_divide,3);
                    resample_nominators = [resample_values rest_resampler];
                else
                    rest_resampler = 10^(ten_potency_divide);
                    resample_nominators = rest_resampler;
                end
            end
            
            nummerator = floor(upsampling_factor);
            denominators = abs(floor(upsampling_factor)-upsampling_factor);
            
            if denominators == 0
                denominators = 1;
            else
                denominators = denominators^-1;
            end
            
            resample_nominators = [resample_nominators nummerator];
            resample_denominators = [ones(1,length(resample_nominators)-1) denominators];
            
            resampled_signal = signal;
            for i = 1:length(resample_denominators)
                resampled_signal =  resample(resampled_signal,resample_nominators(i),resample_denominators(i));
            end
            
            
            
            
            %            ten_potency = floor(log10(upsampling_factor));
            %            oversamplingfactor = upsampling_factor/10^(ceil(ten_potency/2));
            %            resample_factor = 10^(ceil(ten_potency/2));
            
            %oversamplingfactor = 10^(ceil(ten_potency/2));
            %resample_factor = upsampling_factor/10^(ceil(ten_potency/2));
            
        end
        
        function [normalized_doppler_frequency, max_doppler_position_oversampled,number_of_samples_jakes_spec_oversampled, number_of_samples_oversampled,number_of_needed_samples,sampling_rate_gen] = calculation_of_doppler_samples(obj,max_doppler_frequency,precision,time_intervall)
            
            % Calculation frequency resolution
            frequency_resolution = 2*sqrt(precision) / (pi * time_intervall);
            
            % Claculation sampling rate
            sampling_rate_gen_half = 2^(ceil(log2(10*max_doppler_frequency)));
            sampling_rate_gen = 2 * sampling_rate_gen_half;
            
            % Calculation of needed samples
            max_doppler_position = floor(max_doppler_frequency / frequency_resolution);
            number_of_samples_jakes_spec = 2 * floor(max_doppler_frequency / frequency_resolution ) + 1;
            number_of_samples = 2 * floor(sampling_rate_gen_half / frequency_resolution ) + 1;
            
            % Calculation of oversamplingfactor
            oversamplingfactor = 2^(ceil(log2(number_of_samples*100)))/(number_of_samples );
            
            % Increase number of samples by oversamplingfactor
            max_doppler_position_oversampled = floor(max_doppler_position * oversamplingfactor);
            number_of_samples_jakes_spec_oversampled = floor(number_of_samples_jakes_spec * oversamplingfactor);
            number_of_samples_oversampled = round(number_of_samples * oversamplingfactor);
            
            %frequency_resolution_oversampled = max_doppler_frequency*oversampling_factor/number_of_samples;
            frequency_resolution_oversampled = frequency_resolution/oversamplingfactor;
            normalized_doppler_frequency = max_doppler_frequency / frequency_resolution_oversampled;
            
            number_of_needed_samples = round( sampling_rate_gen  * time_intervall );
        end
        
        %        function [normalized_doppler_frequency, max_doppler_position, number_of_samples] = calculation_of_doppler_samples(obj,max_doppler_frequency,precision,time_intervall,oversampling_factor)
        %            frequency_resolution = 2*sqrt(precision) / (pi * time_intervall);
        %            max_doppler_position = floor(max_doppler_frequency / frequency_resolution )*oversampling_factor;
        %            number_of_samples = 2 * max_doppler_position+oversampling_factor;
        %
        %            %frequency_resolution_oversampled = max_doppler_frequency*oversampling_factor/number_of_samples;
        %            frequency_resolution_oversampled = frequency_resolution/oversampling_factor;
        %            normalized_doppler_frequency = max_doppler_frequency / frequency_resolution_oversampled;
        %
        %         end
        
        function frequency_response_jakes_spectrum = jakes_spectrum(obj,normalized_doppler,max_doppler_position, number_of_samples)
            km = max_doppler_position;
            k = 0:number_of_samples-1;
            Fm = zeros(1,number_of_samples);
            Fm(2:km) = sqrt(1./(2*sqrt(1-(k(2:km)/normalized_doppler)).^2));
            Fm(km+1) = sqrt(km/2*(pi/2-atan((km-1)/sqrt(2*km-1))));
            Fm(km+2:number_of_samples -km) = 0;
            Fm(number_of_samples  - km+1) = sqrt(km/2*(pi/2-atan((km-1)/sqrt(2*km-1))));
            Fm(number_of_samples  - km+2:number_of_samples ) = sqrt(1./(2*sqrt(1-((number_of_samples -k(number_of_samples  - km+2:number_of_samples))/(normalized_doppler))).^2));
            frequency_response_jakes_spectrum = Fm;
            
        end
        
        function rayleigh_signal = rayleigh_fading_generator(obj)
            
            max_doppler_frequency = obj.calculate_max_doppler_frequency();
            [normalized_doppler,max_doppler_position, number_of_samples_jakes_spec_oversampled,number_of_samples_doppler,number_of_needed_samples,sampling_rate_gen] = obj.calculation_of_doppler_samples(max_doppler_frequency,obj.precision,obj.simulation_time);
            %[resample_factor1,resample_factor2] = obj.oversamplingfactor_calc(obj.sampling_rate_system, sampling_rate_gen);
            
            
            Fm = obj.jakes_spectrum(normalized_doppler,max_doppler_position,number_of_samples_jakes_spec_oversampled);
            
            %          figure();
            %          plot(Fm)
            Fm_padded = [Fm(1:floor(length(Fm)/2)) zeros(1,number_of_samples_doppler - number_of_samples_jakes_spec_oversampled) Fm(floor(length(Fm)/2)+1:length(Fm))];
            %Fm_padded = [Fm(1:floor(length(Fm)/2)) zeros(1,number_of_samples_doppler) Fm(floor(length(Fm)/2)+1:length(Fm))];
            Fm_padded_normalized = Fm_padded / (sqrt(mean(abs(Fm_padded).^2)));
            
            figure();
            plot(Fm_padded)
            
            % Creation of gaussian random samples
            gaussian_x =  1/sqrt(2) * randn(1,number_of_samples_doppler);
            gaussian_y =  1/sqrt(2) * randn(1,number_of_samples_doppler);
            
            % Multiplication of gauss samples with the doppler spectrum
            signal_x = gaussian_x .* Fm_padded_normalized;
            signal_y = gaussian_y .* Fm_padded_normalized;
            
            
            %number_of_needed_samples = round( obj.oversampling_factor * sampling_rate_gen  * obj.simulation_time );
            rayleigh_signal_low_sampling_rate = ifft(signal_x-1i*signal_y);
            rayleigh_signal = obj.resampler(rayleigh_signal_low_sampling_rate(1:number_of_needed_samples), obj.sampling_rate_system, sampling_rate_gen);
            %rayleigh_signal = obj.resampler([rayleigh_signal_low_sampling_rate(1:number_of_needed_samples/2) rayleigh_signal_low_sampling_rate(length(rayleigh_signal_low_sampling_rate)-number_of_needed_samples/2:length(rayleigh_signal_low_sampling_rate)) ], obj.sampling_rate_system, sampling_rate_gen);
            
            %            %rayleigh_signal = resample([rayleigh_signal_low_sampling_rate(1:number_of_needed_samples/2) rayleigh_signal_low_sampling_rate(length(rayleigh_signal_low_sampling_rate)-number_of_needed_samples/2:length(rayleigh_signal_low_sampling_rate)) ],resample_factor,1);
            %               rayleigh_signal_fs1 = resample(rayleigh_signal_low_sampling_rate(1:number_of_needed_samples),resample_factor1,1);
            %               rayleigh_signal_fs_sys = resample( rayleigh_signal_fs1,resample_factor2,1);
            %               %rayleigh_signal = resample(rayleigh_signal_low_sampling_rate,resample_factor,1);
            %               rayleigh_signal = rayleigh_signal_fs_sys;
            
            
        end
        
    end
    
end