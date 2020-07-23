function [BER, numBits] = BERTool_QPSK_RicianChannel(EbNo, maxNumErrs, maxNumBits)

    persistent FullOperatingTime

    % Display Line on the Start of Imitation Modeling
    disp('======================================');
    % Start Time
    tStart = clock;
    % Total Duration of Imitation Modeling
    % Saving for each trials. To restart need 'clear all' command.
    if isempty(FullOperatingTime)
        FullOperatingTime = 0;
    end
    
    
    %%%%% Initial Information Source %%%%%
    
    % Symbol Rate
    Rs = 100e3;
    % Symbol Duration
    Ts = 1/Rs;
    
    % Number of Symbols per Frame
    numFrameSymbols = 1e4;
    
    
    %%%%% QPSK Modulation %%%%%
   
    % Number of Bits in QPSK Symbol by definition
    k = 2;
    
    % QPSK Modulator Object
    QPSKModulator = comm.QPSKModulator( ...
        'PhaseOffset', pi/4, ...
        'BitInput', true, ...    
        'SymbolMapping', 'Gray' ...
    );

    % QPSK Demodulator Object
    QPSKDemodulator = comm.QPSKDemodulator( ...    
        'PhaseOffset', QPSKModulator.PhaseOffset, ...
        'BitOutput', QPSKModulator.BitInput, ...
        'SymbolMapping', QPSKModulator.SymbolMapping, ...
        'DecisionMethod', 'Hard decision' ...
    );


    %%%%% Transionospheric Communication Channel %%%%%
    
    % Discrete Paths Relative Delays
    PathDelays = [0 Ts/5];
    % Discrete Paths Average Gains
    PathAvGains = [0 -10];
    % Discrete Paths K Factors
    K = [3 3];
    % Max Doppler Frequency Shift
    fD = 25;
    
    % Rician Channel Object
    RicianChannel = comm.RicianChannel( ...
        'SampleRate', Rs, ...
        'PathDelays', PathDelays, ...
        'AveragePathGains', PathAvGains, ...
        'NormalizePathGains', true, ...
        'KFactor', K, ...
        'MaximumDopplerShift', fD, ...
        'DirectPathDopplerShift', zeros(size(K)), ...
        'DirectPathInitialPhase', zeros(size(K)), ...        
        'DopplerSpectrum', doppler('Jakes'), ...
        'PathGainsOutputPort', true ...
    );

    % Delay in Rician Channel Object
    ChanDelay = info(RicianChannel).ChannelFilterDelay;

    % AWGN Channel Object
    AWGNChannel = comm.AWGNChannel( ...
        'NoiseMethod', 'Signal to noise ratio (SNR)', ...
        'SNR', EbNo + 10*log10(k) ...
    );


    %%%%% Imitation Modeling %%%%%
    
    % Import Java class for BERTool
    import com.mathworks.toolbox.comm.BERTool;    
    
    % BER Calculator Object
    BERCalculater = comm.ErrorRate;
    % BER Intermediate Variable
    BERIm = zeros(3,1);
    
    
    % Imitation Modeling Loop
    tLoop1 = clock;
    while BERIm(2) < maxNumErrs && BERIm(3) < maxNumBits
        
        % Check of User push Stop
        if BERTool.getSimulationStop
            break;
        end
        
        
        % >>> Transmitter >>>   
        
        % Generation of Data Bits
        BitsTx = randi([0 1], k*numFrameSymbols, 1);   
        
        % QPSK Modulation
        SignalTx = QPSKModulator(BitsTx);        
        % Power of Transmitted Signal
        SignalTxPower = var(SignalTx);
        
        
        % >>> Transionospheric Communication Channel >>>
        
        % Adding zero samples to the end of Transmitted Signal
        % to not lose shifted samples caused by delay after Rician Channel
        SignalTx = [SignalTx; zeros(ChanDelay, 1)];
        % Rician Channel
        [SignalChan1, PathGain] = RicianChannel(SignalTx);
        % Removing first ChanDelay samples and
        % selection of Channel's Signal related to Transmitted Signal
        SignalChan1 = SignalChan1(ChanDelay + 1 : end);
        
        % AWGN Channel
        AWGNChannel.SignalPower = SignalTxPower;
        SignalChan2 = AWGNChannel(SignalChan1);
        
        
        % >>> Receiver >>>
        
        % Least Squares Solution to remove Fading effects
        % on the first Discrete Path
        SignalRx = SignalChan2 ./ PathGain(ChanDelay + 1 : end, 1);
        % QPSK Demodulation
        BitsRx = QPSKDemodulator(SignalRx);
        
        % BER Calculation
        BERIm = BERCalculater(BitsTx, BitsRx);
        
    end
    tLoop2 = clock;
    
    % BER Results
    BER = BERIm(1);
    numBits = BERIm(3);
    disp(['BER = ', num2str(BERIm(1), '%.5g'), ' at Eb/No = ', num2str(EbNo), ' dB']);
    disp(['Number of bits = ', num2str(BERIm(3))]);
    disp(['Number of errors = ', num2str(BERIm(2))]);
    
    
    % Performance of Imitation Modeling
    Perfomance = BERIm(3) / etime(tLoop2, tLoop1);
    disp(['Perfomance = ', num2str(Perfomance), ' bit/sec']);
    
    % Duration of this Imitation Modeling
    duration = etime(clock, tStart);
    disp(['Operating time = ', num2str(duration), ' sec']);
    
    % Total Duration of Imitation Modeling
    FullOperatingTime = FullOperatingTime + duration;
    assignin('base', 'FullOperatingTime', FullOperatingTime);

end