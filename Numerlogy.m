classdef Numerlogy
    % Numerlogy Class is used to assigne subcarrier to dedicated bandwidth
    % This class will perform all steps to create signal vector and
    % frames
    
    properties
        Bandwidth;              %Used transmission bandwidth
        ModulationOrder;        %Used for QAM
        Coderate;               %Used code rate *not implemented*
        FrameCount;             %How many frames will be uses *not implemented*
        ResourceElementCount;
        SeedPRBS;
        ComplexSymbols;
        SubcarrierSpacing;
        CyclicPrefix;
    end
    methods
        % Is used as constructor to predifine class variables
        function obj                    = Numerlogy()
            obj.Bandwidth               = 1.4e6;
            obj.ModulationOrder         = 4;
            obj.Coderate                = [];
            obj.FrameCount              = 1;
            obj.ResourceElementCount    = 1;
            obj.SeedPRBS                = 401;
            obj.SubcarrierSpacing       = 15e3;
            obj.CyclicPrefix            = 1/4;
        end
    end
    methods
        function [ResourceBlockCount, FFTSize] = resource_blocks(obj)
            switch obj.Bandwidth
                case 1.4e6
                    ResourceBlockCount = 6;
                    FFTSize = 128;
                case 3e6
                    ResourceBlockCount = 15;
                    FFTSize = 256;
                case 5e6
                    ResourceBlockCount = 25;
                    FFTSize = 521;
                case 10e6
                    ResourceBlockCount = 50;
                    FFTSize = 1024;
                otherwise
                    ResourceBlockCount = empty; 
                    FFTSize = empty; 
            end
        end
    end
    methods
        % Method to create a pseudo random bit sequence depending on how many
        % recource elements are used
        function BitStream = bit_stream(obj)
            BitPerSymbol = log2(obj.ModulationOrder);
            BitStreamLength = BitPerSymbol*obj.ResourceElementCount*resource_blocks(obj);
            BitStream = nrPRBS(obj.SeedPRBS, BitStreamLength)';
        end
    end
    methods
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbols = symbol_mapper(obj)
            BitPerSymbol = log2(obj.ModulationOrder);
            SymbolsInBitStream = length(bit_stream(obj))/BitPerSymbol;
            BitStream = bit_stream(obj);
            DecStream = zeros(SymbolsInBitStream , 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream(1:BitPerSymbol)));
                BitStream(1:BitPerSymbol) = [];
            end
            ComplexSymbols = qammod(DecStream', obj.ModulationOrder ,'gray');
        end
    end  
    methods
        % Methods which transforms a zero padded vector in a time time
        % vector
        function IFFT = ifft_signal(obj)
            [ResourceBlocks, Size] = resource_blocks(obj); 
            VirtualSubcarrierCount = Size-ResourceBlocks*obj.ResourceElementCount;
            IFFTFrame = [zeros(1, VirtualSubcarrierCount/2), symbol_mapper(obj),...
                zeros(1, VirtualSubcarrierCount/2)];
            IFFT = ifft(IFFTFrame);
        end
    end
end

