%  DCT
function B = mydct2(a)
T = zeros(8, 8);
for i = 0:7
    for j = 0:7
        if i == 0
            ai = sqrt(1/8);
        else
            ai = sqrt(2/8);
        end
        if j == 0
            aj = sqrt(1/8);
        else
            aj = sqrt(2/8);
        end
        T(i+1,j+1) = ai * aj * cos(pi*(2*i+1)*j/16);    
    end
end
B = zeros(size(a));
for i = 1:size(a,1)/8
    for j = 1:size(a,2)/8
        block = a((i-1)*8+1:i*8, (j-1)*8+1:j*8);
        B((i-1)*8+1:i*8, (j-1)*8+1:j*8) = T * block * T';
    end
end
end