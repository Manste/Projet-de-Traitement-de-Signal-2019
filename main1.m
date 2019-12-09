I = imread('img.jpg');
figure(1);
imshow(I);
title('Image originale');
impixelinfo;

%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
I1= imcrop(I, [65 539 2546-65 1226-539]);
figure(2);
imshow(I1);
title('Image scindée contenant du bruit');

%%Convertir en echelle de gris
I2=rgb2gray(I1);

%Les regions MSER sont des regions qui ont des intensités constantes
%On extrait les regions et calculons leurs valeurs pixels
mserRegions = detectMSERFeatures(I2, 'RegionAreaRange', [80, 2000]);
mserRegionsPixels = vertcat(cell2mat(mserRegions.PixelList));%pour extraire les regions.

figure(3);
imshow(I1);
hold on;
    plot(mserRegions, 'showPixelList', true, 'showEllipses', false);
    title('la regions MSR');
hold off;

%Convertir la liste des pixels MSER en masque binaire
mserMask = false(size(I2));
ind = sub2ind(size(mserMask), mserRegionsPixels(:,2), mserRegionsPixels(:,1));
mserMask(ind) = true;

%On demarre le detecteur des frontières
edgeMask = edge(I2, 'Canny');

%On fait une intersection entre les frontières et les régions MSR
adgeAndMSERIntersections = edgeMask & mserMask;
figure(4);
imshowpair(edgeMask, adgeAndMSERIntersections, 'montage');
title("limites Canny et l'intersection des limites Canny avec les régions MSER");

%pour trouver le gradient
[~, gDir] = imgradient(I2);
%On doit spécifier si le texte est clair sur un font noir ou vice versa
gradientGrownEdgesMask = helperGrowEdges(adgeAndMSERIntersections, gDir, 'LightTextOnDark');

figurer(5);
imshow(gradientGrownEdgesMask);
title("croissance de limites cote à cote de la dircetion des gradients");

