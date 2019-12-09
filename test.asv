%Image original
I = imread('img.jpg');
%{
figure(1);
imshow(I);
title('Image originale');
impixelinfo;
%}

%Image Scindée principal
%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
I= imcrop(I, [65 539 2546-65 1226-539]);
%I= imcrop(I, [59 172 579-59 336-172]);

figure(2);
imshow(I);
title('Image scindée contenant du bruit');


%Convertir une image en couleur en gris
Igris = rgb2gray(I);

results = ocr(Igris);

BW = imbinarize(Igris);

%figure(3); 
%imshowpair(I,BW,'montage');

Icorrected = imtophat(I,strel('disk',15));

BW1 = imbinarize(Icorrected);

%figure(4); 
%imshowpair(Icorrected,BW1,'montage');

marker = imerode(Icorrected, strel('line',10,0));
Iclean = imreconstruct(marker, Icorrected);

BW2 = imbinarize(Iclean);

%figure(5); 
%imshowpair(Iclean,BW2,'montage');

results = ocr(BW2,'TextLayout','Block');

toutesLesLignes = strsplit(results.Text, "\n");
premiereLigne = strsplit(char(toutesLesLignes(3)), " ");

premiereLettre = char(premiereLigne(2));


indexArobase = strfind(char(toutesLesLignes(2)), '@');
indexHum = strfind(char(toutesLesLignes(2)), '§');

%debut2Ligne =cellstr(reshape(char(toutesLesLignes(2)), 12, [])')
if( contains(toutesLesLignes(3), 'A') || contains(toutesLesLignes(5), 'Q') || contains (toutesLesLignes(6)
    element = "bonjour"
end    
