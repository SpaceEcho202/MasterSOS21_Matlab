classdef channel_model < matlab.mixin.SetGet
   properties (Constant,GetAccess=private)
       speed_of_light = 3e8;
   end
   
   properties 
       velocity;
       carrier_frequency;
       number_of_samples
       sampling_frequency
   end
   
   
   methods
       function obj = channel_model(velocity,carrier_frequency,number_of_samples, sampling_frequency)
           if nargin == 4
               set(obj,'velocity',velocity);
               set(obj,'carrier_frequency',carrier_frequency);
               set(obj,'number_of_samples',number_of_samples);
               set(obj,'sampling_frequency',sampling_frequency);
           end
       end
       
       function max_doppler_frequency = calculate_max_doppler_frequency(obj)
           if nargin <= 1
               max_doppler_frequency = obj.velocity/obj.speed_of_light * obj.carrier_frequency * 1/3.6;
           end
       end
       
       function rayleigh_signal = rayleigh_fading_generator(obj)
           if nargin <=1
               
               max_doppler_frequency = obj.calculate_max_doppler_frequency();
               normalized_doppler =  max_doppler_frequency *(obj.number_of_samples / obj.sampling_frequency);
               Fm = obj.jakes_spectrum(normalized_doppler);

               gaussian_x = randn(1,obj.number_of_samples);
               gaussian_y = randn(1,obj.number_of_samples);
               
               signal_x = gaussian_x .* Fm;
               signal_y = gaussian_y .* Fm;
               
               signal_z = ifft(signal_x-1i*signal_y);
               
               rayleigh_signal = signal_z;
               
           end
       end
       
       function frequency_response_jakes_spectrum = jakes_spectrum(obj,normalized_doppler)          
           km = floor(normalized_doppler);
           k = 0:obj.number_of_samples-1;
           Fm = zeros(1,obj.number_of_samples);
           Fm(2:km) = sqrt(1./(2*sqrt(1-(k(2:km)/(normalized_doppler))).^2));
           Fm(km+1) = sqrt(km/2*(pi/2-atan((km-1)/sqrt(2*km-1))));
           Fm(km+2:obj.number_of_samples -km) = 0;
           Fm(obj.number_of_samples  - km+1) = sqrt(km/2*(pi/2-atan((km-1)/sqrt(2*km-1))));
           Fm(obj.number_of_samples  - km+2:obj.number_of_samples ) = sqrt(1./(2*sqrt(1-((obj.number_of_samples -k(obj.number_of_samples  - km+2:obj.number_of_samples))/(normalized_doppler))).^2));
           frequency_response_jakes_spectrum = Fm;
       end
       
   end
end