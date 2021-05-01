classdef Numerlogy
    %Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    %   This class will perform all steps to create signal vector and
    %   frames
    
    properties
        bandwidth
        modulation_order
        code_rate
        frame_count
        bit_stream
    end
    
    methods(Static)
        %Method to encode a parsed logical bitstream into graycoded symbols
        %depending on parsed modulation order
        function ComplexSymbols = symbol_mapper(BitStream, ModulationOrder)
            M = log2(ModulationOrder);     
            SymbolsInBitStream = length(BitStream)/M;
            DecStream = zeros(SymbolsInBitStream, 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream(1:M)));
                BitStream(1:M) = [];
            end
            ComplexSymbols = qammod(DecStream', ModulationOrder ,'gray');
        end
    end
end

