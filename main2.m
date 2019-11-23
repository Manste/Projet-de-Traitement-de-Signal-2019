%Image original
I = imread('img.jpg');
figure(1);
imshow(I);
title('Image originale');
impixelinfo;

%Image Scindée principal
%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
I= imcrop(I, [65 539 2546-65 1226-539]);
%I= imcrop(I, [59 172 579-59 336-172]);
figure(2);
imshow(I);
title('Image scindée contenant du bruit');

%%Convertir en echelle de gris
if size(I, 3) == 3 %Cela signifie que c'est une image RGB
    I=rgb2gray(I);
end

%enlever les variations du background du clavier et améliorer la
%segmentation du texte
I2 = imtophat(I,strel('disk',15));
%Conversion en binaire pour ameliorer le traitement de l'image
BIN = imbinarize(I2);
figure(3);
%Pour visualiser I2 et BIN
imshowpair(I2, BIN, 'montage');

%Correction de l'image
marker = imerode(I2, strel('line', 10, 0));
Ipropre = imreconstruct(marker, I2);

bin = imbinarize(Ipropre);
figure(4);
imshowpair(Ipropre, bin, 'montage');

