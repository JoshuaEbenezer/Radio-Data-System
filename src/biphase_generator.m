function [ biphase ] = biphase_generator( impulses)
%BIPHASE_GENERATOR generates biphase symbols of RDS bitstream
%   INPUT arguments:        stream of differntially encoded RDS data
%
%   OUTPUT arguments:       biphase symbols
%
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 6th, 2017    
%


% interpolate impulses so that values at multiples of td/2 can be accessed
% (for shifting)
impulses_interpl = upsample(impulses,200);

% initialize the shifted version of the signal
impulses_shift = zeros(1,length(impulses_interpl));

% delay index is the number of samples corresponding to td/2 
delay_index = 100;

% delay the stream by td/2
impulses_shift(delay_index+1:end) = impulses_interpl(1:end-delay_index);

% biphase
biphase = (impulses_interpl - impulses_shift);



end

