%% ===========================  main_rds.n ============================= %%
% Purpose of script:                 Simulation of Modulation and Demodulation of an FM RDS broadcast
% User-defined Functions called:     
%                                    generate_msgs       
%                                    biphase_generator
%                                    pulse_shape
%                                    fmrds_modulate
%                                    fmrds_demod
%                                    synchronize
%                                    data decode
%                                    message_display
%
% Author:                            Joshua Peter Ebenezer
% Date of creation:                  1st December, 2017
%

%% ------------------------- Sequence of flow -------------------------- %%

% Script - main_rds.m
%   main function
%   Audio is generated
%   call function generate_msgs.m
%                   Messages are generated (random information with proper checkwords and
%                   offsets)
%   Differential encoding
%   call function biphase_generator.m
%                    Converts NRZ to bipolar impulses
%   call function pulse_shape.m
%                    Shape the data using raised cosine filter
%   call function fmrds_modulate.m
%                    Modulate data with carriers and add audio and RDS
%   Frequency modulation & demodulation/ Noise
%   call function fmrds_demod.m
%                   Carrier recovery, demodulate data
%   Differential decoding of RDS data
%   call function synchronize.m
%                   Initial acquisition of synchronisation (start bit)
%   call function data_decode.m
%                   CRC decoding and error finding, information extraction
%   call message_display.m
%                   Display the information in a user-friendly format

%% ----------------------------------------------------------------------%%

clc;
clear;
close all;
%%
% pilot frequency is at 19kHz
pilot_freq = 19000;
% number of sampling instances
L = 9.5e5;
% frequency of sampling
Fs = 2.375e5;
% time step
Ts = 1/Fs;
% last sampling instance
tmax = (L/2)*Ts;
% sampling time array
t = (-L/2:L/2-1)*Ts;
% frequency
f = Fs*(0:(L/2))/L;
%% -------------------- Generation of audio signal ------------------- %%
% message signal - single tone

left = sin(2*pi*1000*t);
right = cos(2*pi*1000*t);

%% --------------  Generation of RDS data (data-link layer) --------------%
% clk freq of rds data is 3 times carrier frequency divided by 48 (1187.5
% bits/second)
rds_stream_length = round(2*tmax*pilot_freq*3/48);

% number of messages (that can be received/sent)
% bitstream size may not be equal to a multiple of the number of messages
no_msgs = floor(rds_stream_length/104);

% set option to 1 if reading from file
read_from_file = 0;

% group version - keeping it constant as version A
version = 'A';

[rds_bitstream,information] = generate_msgs(no_msgs,read_from_file,rds_stream_length, version);

%% ----------------- Differential encoding of the bitstream ------------ %%
encode = comm.DifferentialEncoder;
tx_code = encode(rds_bitstream.');
tx_code = tx_code.';

%% ------------------ Data-channel spectrum shaping -------------------- %%
% convert NRZ to polar impulses
impulses = 2*tx_code-1;

% generate biphase symbols
biphase = biphase_generator(impulses);

% send the biphase symbols through the pulse shaper
rds = pulse_shape(biphase,L,Fs);

%% -------------------- Generate signal for transmission --------------- %%
fm_rds_signal = fmrds_modulate(left,right, rds, pilot_freq,L,Fs);

%% --------------------- Find and display fft of broadcast ------------- %%
fm_rds_Y = fft(fm_rds_signal);
% double sided spectrum
P2 = abs(fm_rds_Y/L);
% single sided spectrum
FM_RDS_FT = P2(1:L/2+1);

% recover exact amplitudes
FM_RDS_FT(2:end-1) = 2*FM_RDS_FT(2:end-1);

figure;
plot(f,FM_RDS_FT)
title('Single-Sided Amplitude Spectrum of message to be broadcast');
xlabel('f (Hz)');
ylabel('|FT(f)|');

%% ------------------------- Frequency modulation ---------------------- %%
% considering Fc as 100 MHz
fm_centre_freq = 100e6;
% sampling frequency is 4 times Fc
fm_sampling_freq = 400e6;
% frequency deviation
freqdev = 50;

% modulating signal to generate broadcast
% fm_broadcast = fmmod(fm_rds_signal,fm_centre_freq,fm_sampling_freq,freqdev);

%% ------------------------------- Noise ------------------------------- %%

% to hold bit indices at which errors occur for 100 SNR values
sig_error = zeros(1,100,4750);
% to hold number of errors for 100 SNR values
num_err = zeros(1,100);
% to hold average absolute error for 100 SNR values
avg_err = zeros(1,100);
% to hold the start locations for 100 SNR values
start = ones(1,100);

% SNR is fixed here as 50 dB. A for loop can be written here to observe
% outputs for 100 diff. SNR values (from 1 to 100)
snr = 50;

% add AWGN
fm_noisy_channel = awgn(fm_rds_signal,snr, 'measured');

%% ------------------------ Frequency demodulation --------------------- %%
% fm_received = fmdemod(fm_noisy_channel, fm_centre_freq, fm_sampling_freq, freqdev);

%% ------- View spectrum of received signal after FM mod&demod or noise --------- %%
fm_demod_fft = fft(fm_noisy_channel);
% double sided spectrum
P2 = abs(fm_demod_fft/L);
% single sided spectrum
FM_DEMOD_FT = P2(1:L/2+1);

% recover exact amplitudes
FM_DEMOD_FT(2:end-1) = 2*FM_DEMOD_FT(2:end-1);

figure;
plot(f,FM_DEMOD_FT)
title('Single-Sided Amplitude Spectrum of message after frequency demodulation/noise');
xlabel('f (Hz)');
ylabel('|FT(f)|');


%% ----------------------- Demodulate received signal ------------------ %%
[left_rec, right_rec, pilot, rx_encoded] = fmrds_demod(fm_noisy_channel,Fs,L);

%% ---------------------- Error in Audio ------------------------------- %%
% find the error in the signal
aud_error = left-left_rec;

% average error
avg_aud_err = sum(abs(aud_error(:)))/length(aud_error);
% fprintf('Average error = %f for audio \n',avg_aud_err);

%% ---------------- Plot the received and transmitted signals ---------- %%
figure;
subplot(2,1,1);
stairs(rx_encoded(1:100))
title('Differentially encoded received data');
xlabel('Bit number');
ylabel('Received data');

subplot(2,1,2);
stairs(tx_code(1:100))
title('Differentially encoded transmitted data');
xlabel('Bit number');
ylabel('Transmitted data');

%% -------- Find the error in the encoded digitised received data ------ %%
code_error = rx_encoded - tx_code;
figure;
stairs(code_error);
title('Error in encoded received data');
xlabel('Bit number');
ylabel('Error in received signal');

%% ------------------------ Decode RDS data ---------------------------- %%
% perform differential decoding
decode = comm.DifferentialDecoder;
rx_bitstream = decode(rx_encoded.');
rx_bitstream = rx_bitstream.';

%% -------------------- Acquisition of synchronisation ----------------- %%
start_location = synchronize(rx_bitstream);

%% ----------------------- Data-link layer decoding -------------------- %%
[rx_information, info_error] = data_decode(rx_bitstream, start_location);

%% ------------------ Find and display error in information ------------ %%
figure;
stairs(info_error);
title('Error in received messages');
xlabel('Word number');
ylabel('Error in received messages');

%% Display the time-domain differentially encoded RDS and the RDS signals
figure;
subplot(2,1,1);
stairs(rx_encoded(1:100))
title('Encoded RDS signal (time domain) at receiver end');
xlabel('Bit number');
ylabel('Diff Enco RDS');

subplot(2,1,2);
stairs(rx_bitstream(1:100))
title('Extracted RDS signal (time domain) at receiver end');
xlabel('Bit number');
ylabel('RDS');

%% Find the error in the received data wrt transmitted data
% find the error in the signal
sig_error(1,100-snr+1,1:4750) = rx_bitstream-rds_bitstream;
% find number of errors
num_err(1,100-snr+1) = length(find(sig_error(1,100-snr+1,1:4750)~=0));
% average error
avg_err(100-snr+1) = sum(abs(sig_error(1,100-snr+1,1:4750)))/4750;
fprintf('Average error = %f and number of errors = %d \n',avg_err(100-snr+1), num_err(100-snr+1));
start(100-snr+1) = start_location;


%% ------------------------ Message presentation layer ----------------- %%
message_display(rx_information);