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
        SymbolsPerFrame;
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
            obj.SymbolsPerFrame         = 7;
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
                    FFTSize = 512;
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
            BitStreamLength = BitPerSymbol*obj.ResourceElementCount...
                *resource_blocks(obj)*obj.SymbolsPerFrame;
            BitStream = nrPRBS(obj.SeedPRBS, BitStreamLength)';
        end
    end
    methods
        % Method to encode a parsed logical bitstream into graycoded symbols
        % depending on parsed modulation order
        function ComplexSymbolFrame = symbol_mapper(obj)
            BitPerSymbol = log2(obj.ModulationOrder);
            SymbolsInBitStream = length(bit_stream(obj))/BitPerSymbol;
            BitStream = bit_stream(obj);
            DecStream = zeros(SymbolsInBitStream , 1);
            for Index = 1:SymbolsInBitStream
                DecStream(Index,:) = bin2dec(num2str(BitStream(1:BitPerSymbol)));
                BitStream(1:BitPerSymbol) = [];
            end
            OfdmSymbolsPerFrame = obj.ResourceElementCount*resource_blocks(obj);
            obj.ComplexSymbols = qammod(DecStream', obj.ModulationOrder ,'gray');
            ComplexSymbolFrame = zeros(obj.SymbolsPerFrame, OfdmSymbolsPerFrame);
            for Index = 1:obj.SymbolsPerFrame
                ComplexSymbolFrame(Index,:) = obj.ComplexSymbols(1:OfdmSymbolsPerFrame);
                obj.ComplexSymbols(1:OfdmSymbolsPerFrame) = [];
            end
        end
    end
    %     methods
    %         function CyclicPrefix = cyclic_extension(obj)
    %             for Index = 0:
    %                 OfdmSymbol = ofdm_symbol(obj);
    %         end
    %     end
    methods
        % Methods which transforms a zero padded vector in a time time
        % vector
        function TimeSignal = ofdm_time_signal(obj)
            [ResourceBlocks, Size] = resource_blocks(obj);
            VirtualSubcarrierCount = Size-ResourceBlocks*obj.ResourceElementCount;
            ComplexSymbolFrame = symbol_mapper(obj);
            IFFTFrame = zeros(ResourceBlocks, Size);
            for Index = 1:ResourceBlocks
                IFFTFrame(Index,:) = [zeros(1, VirtualSubcarrierCount/2), ComplexSymbolFrame(Index,:),...
                    zeros(1, VirtualSubcarrierCount/2)];
                TimeSignal = ifftshift(ifft(IFFTFrame));
            end
        end
    end
end

