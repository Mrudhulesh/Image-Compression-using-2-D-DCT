% THE COEFFICIENTS ARE TAKEN IN DIFFERENT WAY BUT THE CODE PERFORMS IN THE
% SAME WAY 

clc; clear; close all;

% Define 8x8 DCT matrix
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

% Load image
fid = fopen('lena.raw');
a = fread(fid,[512,512],'uchar');
fclose(fid);
a = a';
% Compute DFT and magnitude spectrum of original image
A = fft2(double(a));
S = abs(A);

% Display magnitude spectrum    
figure('Name', 'DFT Magnitude Spectrum (Original Image)');
imshow(log(1+S), []);
title('DFT Magnitude Spectrum (Original Image)');

% Display original image
figure('Name', 'Original Image');
imshow(a, []);
title('Original Image');

% Perform DCT on the image
B = mydct2(a);
    
% Set percentage of coefficients to zero
percentages = [0.05 0.1 0.25 0.5];

% Define new quantization matrix
Q = [10 20 30 40 50 60 70 80;      20 30 40 50 60 70 80 90;      30 40 50 60 70 80 90 100;      40 50 60 70 80 90 100 110;      50 60 70 80 90 100 110 120;      60 70 80 90 100 110 120 130;      70 80 90 100 110 120 130 140;      80 90 100 110 120 130 140 150];



for k = 1:length(percentages)
    % Compute threshold for given percentage
    non_zero_values = sort(abs(B(:)), 'descend');
    non_zero_values = non_zero_values(non_zero_values > 0);
    threshold = non_zero_values(round(percentages(k) * numel(non_zero_values)));

    % Soft threshold the remaining coefficients and zero high frequencies
    B1 = sign(B) .* max(abs(B) - threshold, 0) .* (abs(B) >= threshold);


    % Quantize remaining coefficients using the JPEG standard quantization matrix
    B2 = zeros(size(B1));
    step_size = 0.1; % Define step size here
    for i = 1:size(B1,1)/8
        for j = 1:size(B1,2)/8
            block = B1((i-1)*8+1:i*8, (j-1)*8+1:j*8);
            B2((i-1)*8+1:i*8, (j-1)*8+1:j*8) = round(block ./ (step_size * Q)).* (abs(block) >= threshold);
        end
    end



    % Compute reconstructed image
    I_rec = myidct2(B2);

    % Compute DFT and magnitude spectrum of reconstructed image
    A_rec = fft2(double(I_rec));
    S_rec = abs(A_rec);

    % Display reconstructed image and magnitude spectrum
    figure('Name', sprintf('Reconstructed Image (%d%% Coefficients)',100 * percentages(k)));
    imshow(I_rec, []);
    title(sprintf('Reconstructed Image (%d%% Coefficients)', 100 * percentages(k)));

    figure('Name', sprintf('DFT Magnitude Spectrum (Reconstructed Image, %d%% Coefficients)',100 * percentages(k)));
    imshow(log(1+S_rec), []);
    title(sprintf('DFT Magnitude Spectrum (Reconstructed Image, %d%% Coefficients)', 100 * percentages(k)));

    % Scale images to 0-255 range
    a_scaled = uint8((a - min(a(:))) * (255 / (max(a(:)) - min(a(:)))));
    a_rec_scaled = uint8((I_rec - min(I_rec(:))) * (255 / (max(I_rec(:)) - min(I_rec(:)))));

    % Compute PSNR
    mse = mean(mean((double(a_scaled) - double(a_rec_scaled)).^2));
    psnr_val = 10 * log10(255^2 / mse);
    fprintf('PSNR for %d%% coefficients: %f\n', 100 * percentages(k), psnr_val);

    % Write reconstructed image to file in raw format
    fileID = fopen(sprintf('lena_reconstructed_%d.raw', round(100 * percentages(k))), 'w');
    fwrite(fileID, I_rec', 'uint8');
    fclose(fileID);
end
