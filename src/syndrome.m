function [ offset, version ] = syndrome( block )
%SYNDROME Finds offset corresponding to the input block
%   INPUT argument:     block of length 26 bits
%
%   OUTPUT argument:    offset word index corresponding to block
% version default - null
version = [];
% create an identity matrix
id_ten = eye(10);
% generate the lower part of the parity check matrix
lower = [1 0 1 1 0 1 1 1 0 0;
    0 1 0 1 1 0 1 1 1 0;
    0 0 1 0 1 1 0 1 1 1;
    1 0 1 0 0 0 0 1 1 1;
    1 1 1 0 0 1 1 1 1 1;
    1 1 0 0 0 1 0 0 1 1;
    1 1 0 1 0 1 0 1 0 1;
    1 1 0 1 1 1 0 1 1 0;
    0 1 1 0 1 1 1 0 1 1;
    1 0 0 0 0 0 0 0 0 1;
    1 1 1 1 0 1 1 1 0 0;
    0 1 1 1 1 0 1 1 1 0;
    0 0 1 1 1 1 0 1 1 1;
    1 0 1 0 1 0 0 1 1 1;
    1 1 1 0 0 0 1 1 1 1;
    1 1 0 0 0 1 1 0 1 1];
% generate the parity check matrix by concatenating the two
H = cat(1, id_ten,lower);
% generate syndrome
syndrome_calc = block * H;
% convert to modulo-2 form
syndrome = mod(syndrome_calc,2);
    % check if syndrome matches any of the offsets
    if (isequal(syndrome,[1 1 1 1 0 1 1 0 0 0]))
        offset = 1; % offset A [0 0 1 1 1 1 1 1 0 0]
    elseif (isequal(syndrome,[1 1 1 1 0 1 0 1 0 0]))
        offset = 2; % offset B [0 1 1 0 0 1 1 0 0 0]  
        
    elseif (isequal(syndrome,[1 0 0 1 0 1 1 1 0 0]))
        offset = 3; % offset C [0 1 0 1 1 0 1 0 0 0];
        version = 'A';        
    elseif (isequal(syndrome,[1 1 1 1 0 0 1 1 0 0]))
        offset = 3; % offset C'[1 1 0 1 0 1 0 0 0 0]
        version = 'B';
    
    elseif (isequal(syndrome,[1 0 0 1 0 1 1 0 0 0]))
        offset = 4; % offset D [0 1 1 0 1 1 0 1 0 0]
    else
        offset= 10;
    end
end

