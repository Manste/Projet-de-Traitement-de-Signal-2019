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
title('Image scind�e contenant du bruit');

%%Convertir en echelle de gris
if size(I1, 3) == 3 %Cela signifie que c'est une image RGB
    I2=rgb2gray(I1);
end

%%Convertir l'image en binaire
seuil = graythresh(I2);
I2 = ~im2bw(I2, seuil);

%%Rejeter tous les objects contenant moins de 0pixels
I2 = bwareaopen(I2, 0);

%%Montrer l'image binaire
%figure(3);
%imshow(~I2);
%title("Image purif�e(sans bruit)");

%detecter la region MSR
%Ici MSR permet de detecter tr�s bien les r�gions contenant du texte
%Il est important de noter que l'algorithme MSR detecter les textes aussi
%bien que les r�gions stables de l'image qui ne sont pas forc�ment des
%textes
%On utilise detectMSERFeatures pour trouver les regions concern�es et
%surtout les tracer.
[mserRegions, mserConnComp] = detectMSERFeatures(I2, ... 
    'RegionAreaRange',[50 8000],'ThresholdDelta',4);

%Utiliser regionprops pour mesurer quelques propri�t�s permettant de
%distinguer les r�gions textes et aussi non-textes(en faire mesurer les
%propri�t�s MSER).
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');

%{
figure(4);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('R�gions MSER')
hold off
%}
 
%Calculer l'aspect ratio en utilisant des donn�es boundingbox
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;

%Seuil des donn�es permettant de determiner quelles r�gions on doit
%supprimer. Ces seuils peuvent �tre adapt�s pour d'autres images. 
filterIdx = aspectRatio' > 3; 
filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
filterIdx = filterIdx | [mserStats.Solidity] < .3;
filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] < -4;

%retirer les r�gions
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];

%Montrer les r�gions restantes(soient elles sans regions non-textuelles)

%{
figure(5);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('R�gions MSER sans r�gions non-textes ou autres propri�tes geom�triques')
hold off
%}

%Maintenant on va supprimer les r�gions qui ne sont pas textuelles et
%surtout bas�es sur la variations des largeurs des traits.
regionImage = mserStats(6).Image;
regionImage = padarray(regionImage, [1 1]);

% Calculer la lageur des traits de l'image
distanceImage = bwdist(~regionImage); 
skeletonImage = bwmorph(regionImage, 'thin', inf);

strokeWidthImage = distanceImage;
strokeWidthImage(~skeletonImage) = 0;

% Afficher l'image � c�t� de l'image de la largeur des traits
%{
figure(6);
subplot(1,2,1);
imagesc(regionImage);
title('Region Image'),

subplot(1,2,2);
imagesc(strokeWidthImage);
title('Image de la largeur des traits');
%}

% Calcule la m�trique de variation de largeur de trait 
strokeWidthValues = distanceImage(skeletonImage);   
strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);

%Ici, le seuil peut �tre appliquer pour retirer les r�gions non-textes
%Calcul du seuil du metrique de la variation de la largeur des traits
strokeWidthThreshold = 0.4;
strokeWidthFilterIdx = strokeWidthMetric > strokeWidthThreshold;

%Traiter les lr�gions restantes
for j = 1:numel(mserStats)
    
    regionImage = mserStats(j).Image;
    regionImage = padarray(regionImage, [1 1], 0);
    
    distanceImage = bwdist(~regionImage);
    skeletonImage = bwmorph(regionImage, 'thin', inf);
    
    %Calculer la metrique de la variation de la largeur des traits
    strokeWidthValues = distanceImage(skeletonImage);
    
    strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
    
    strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;
    
end

%Retirer les r�gions base�s sur la variation de la largeur du trait
mserRegions(strokeWidthFilterIdx) = [];
mserStats(strokeWidthFilterIdx) = [];

%Montrer les r�gions restantes
%{
figure(7);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('Apr�s avoir retirer les r�gions non-textes bas�es sur la variation de la largeur des traits')
hold off
%}

% Avoir des boites contenant du textes
bboxes = vertcat(mserStats.BoundingBox);

% on peut toujjours convertir du cadre de s�lection [x y width height] au
% format [xmin ymin % xmax ymax pour plus de commodit�
xmin = bboxes(:,1);
ymin = bboxes(:,2);
xmax = xmin + bboxes(:,3) - 1;
ymax = ymin + bboxes(:,4) - 1;

% Coupez les bo�tes englobantes dans les limites de l'image
expansionAmount = 0.02;
xmin = (1-expansionAmount) * xmin;
ymin = (1-expansionAmount) * ymin;
xmax = (1+expansionAmount) * xmax;
ymax = (1+expansionAmount) * ymax;

% Afficher les zones de contour d�velopp�es
xmin = max(xmin, 1);
ymin = max(ymin, 1);
xmax = min(xmax, size(I,2));
ymax = min(ymax, size(I,1));

% Show the expanded bounding boxes
expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
IExpandedBBoxes = insertShape(I1,'Rectangle',expandedBBoxes,'LineWidth',3);

figure(8);
imshow(IExpandedBBoxes);
title('Texte �largi des cadres de s�lection');

% Calcule le taux de recouvrement 
overlapRatio = bboxOverlapRatio(expandedBBoxes, expandedBBoxes);

% D�finissez le rapport de recouvrement entre un cadre de s�lection et lui-m�me sur z�ro pour simplifier la repr�sentation du graphique. 
n = size(overlapRatio,1); 
overlapRatio(1:n+1:n^2) = 0;

% Cr�ez le graphique 
g = graph(overlapRatio);

% Trouver les r�gions de texte connect�es dans le graphique 
componentIndices = conncomp(g);

% Fusionnez les cases en fonction des dimensions minimale et maximale. 
xmin = accumarray(componentIndices', xmin, [], @min);
ymin = accumarray(componentIndices', ymin, [], @min);
xmax = accumarray(componentIndices', xmax, [], @max);
ymax = accumarray(componentIndices', ymax, [], @max);

% Composez les bo�tes englobantes fusionn�es en utilisant le format [xy width height]. 
textBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];

% Supprime les cadres de s�lection ne contenant qu'une r�gion de texte
numRegionsInGroup = histcounts(componentIndices);
textBBoxes(numRegionsInGroup == 1, :) = [];

%Montrer le r�sultat final
ITextRegion = insertShape(I1, 'Rectangle', textBBoxes,'LineWidth',3);

figure(9);
imshow(ITextRegion);
title('Texte d�tect�');

ocrtxt = ocr(I, textBBoxes);
[ocrtxt.Text]
