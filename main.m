I = imread('img.jpg');
figure(1);
imshow(I);
title('Image originale');
impixelinfo;

%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
%I1= imcrop(I, [65 539 2546-65 1226-539]);
I1 = imcrop(I, [299, 704, 1988-299, 1175-704]);
figure(2);
imshow(I1);
title('Image scind�e contenant du bruit');

%%Convertir en echelle de gris
if size(I1, 3) == 3 %Cela signifie que c'est une image RGB
    I2=rgb2gray(I1);
end

%enlever les variations du background du clavier et am�liorer la
%segmentation du texte
I2 = imtophat(I1,strel('disk',15));
%Conversion en binaire pour ameliorer le traitement de l'image
BIN = imbinarize(I2);
figure(3);
%Pour visualiser I2 et BIN
imshowpair(I2, BIN, 'montage');
title("Image purif�e(sans bruit)");

%%Rejeter tous les objects contenant moins de 30pixels
%I2 = bwareaopen(I2, 30);

%Correction de l'image
marker = imerode(I2, strel('line', 10, 0));
Ipropre = imreconstruct(marker, I2);

binAmeliore = imbinarize(Ipropre);
figure(4);
imshowpair(Ipropre, binAmeliore, 'montage');
title("Image avec encore moins de bruits");

%Le MSER permet de detecter la region contenant le texte.
[mserRegions, mserConnComp] = detectMSERFeatures(binAmeliore, ...
    'RegionAreaRange', [200 8000], 'ThresholdDelta',4);
