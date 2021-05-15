classdef Numerlogy
    %Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    %   This class will perform all steps to create signal vector and
    %   frames
    
    properties
        BandWidth;          %Used transmission bandwidth
        ModulationOrder;    %Used for QAM 
        CodeRate;           %Used code rate *not implemented*
        FrameCount;         %How many frames will be uses *not implemented*
        ResourceElementCount;
        SeedPRBS;
    end
    methods(Static)
        % Method to create a pseudo random bit sequence depending on how many 
        % recource elements are used
        function BitStream = bit_stream(SeedPRBS, ResourceElementCount)
            BitPerSymbol = log2(ModulationOrder);
            BitStreamLength = BitPerSymbol*ResourceElementCount;
            BitStream = nrPRBS(SeedPRBS, BitStreamLength)';
        end
    end
    methods(Static)
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbols = symbol_mapper(ModulationOrder)     
            BitPerSymbol = log2(ModulationOrder);
            SymbolsInBitStream = length(Numerlogy.bit_stream/BitPerSymbol;
            DecStream = zeros(SymbolsInBitStream, 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream(1:BitPerSymbol)));
                BitStream(1:BitPerSymbol) = [];
            end
            ComplexSymbols = qammod(DecStream', ModulationOrder ,'gray');
        end
    end
    methods(Static)
        Frame = frame_creator(SymbolsPerFrame, ZeroPedding)
    end
end

