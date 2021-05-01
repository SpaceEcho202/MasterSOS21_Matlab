classdef Numerlogy
    %Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    %   This class will perform all steps to create signal vector and
    %   frames 
    
    properties
        bandwidth
        modulation_order
        code_rate
        frame_count
    end

    methods(Static)
        function [symbols, mapping] = symbol_mapper(modulation_order,bit_stream)
            [symbols, mapping] = bin2gray(bit_stream, 'qam', modulation_order);
        end      
    end
end

