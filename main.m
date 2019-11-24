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
%title("Image purifée(sans bruit)");

%detecter la region MSR
%Ici MSR permet de detecter très bien les régions contenant du texte
%Il est important de noter que l'algorithme MSR detecter les textes aussi
%bien que les régions stables de l'image qui ne sont pas forcément des
%textes
%On utilise detectMSERFeatures pour trouver les regions concernées et
%surtout les tracer.
[mserRegions, mserConnComp] = detectMSERFeatures(I2, ... 
    'RegionAreaRange',[50 8000],'ThresholdDelta',4);

%Utiliser regionprops pour mesurer quelques propriétés permettant de
%distinguer les régions textes et aussi non-textes(en faire mesurer les
%propriétés MSER).
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
    'Solidity', 'Extent', 'Euler', 'Image');

%{
figure(4);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('Régions MSER')
hold off
%}
 
%Calculer l'aspect ratio en utilisant des données boundingbox
bbox = vertcat(mserStats.BoundingBox);
w = bbox(:,3);
h = bbox(:,4);
aspectRatio = w./h;

%Seuil des données permettant de determiner quelles régions on doit
%supprimer. Ces seuils peuvent être adaptés pour d'autres images. 
filterIdx = aspectRatio' > 3; 
filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
filterIdx = filterIdx | [mserStats.Solidity] < .3;
filterIdx = filterIdx | [mserStats.Extent] < 0.2 | [mserStats.Extent] > 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] < -4;

%retirer les régions
mserStats(filterIdx) = [];
mserRegions(filterIdx) = [];

%Montrer les régions restantes(soient elles sans regions non-textuelles)

%{
figure(5);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('Régions MSER sans régions non-textes ou autres propriétes geométriques')
hold off
%}

%Maintenant on va supprimer les régions qui ne sont pas textuelles et
%surtout basées sur la variations des largeurs des traits.
regionImage = mserStats(6).Image;
regionImage = padarray(regionImage, [1 1]);

% Calculer la lageur des traits de l'image
distanceImage = bwdist(~regionImage); 
skeletonImage = bwmorph(regionImage, 'thin', inf);

strokeWidthImage = distanceImage;
strokeWidthImage(~skeletonImage) = 0;

% Afficher l'image à côté de l'image de la largeur des traits
%{
figure(6);
subplot(1,2,1);
imagesc(regionImage);
title('Region Image'),

subplot(1,2,2);
imagesc(strokeWidthImage);
title('Image de la largeur des traits');
%}

% Calcule la métrique de variation de largeur de trait 
strokeWidthValues = distanceImage(skeletonImage);   
strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);

%Ici, le seuil peut être appliquer pour retirer les régions non-textes
%Calcul du seuil du metrique de la variation de la largeur des traits
strokeWidthThreshold = 0.4;
strokeWidthFilterIdx = strokeWidthMetric > strokeWidthThreshold;

%Traiter les lrégions restantes
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

%Retirer les régions baseés sur la variation de la largeur du trait
mserRegions(strokeWidthFilterIdx) = [];
mserStats(strokeWidthFilterIdx) = [];

%Montrer les régions restantes
%{
figure(7);
imshow(I2);
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('Après avoir retirer les régions non-textes basées sur la variation de la largeur des traits')
hold off
%}

% Avoir des boites contenant du textes
bboxes = vertcat(mserStats.BoundingBox);

% on peut toujjours convertir du cadre de sélection [x y width height] au
% format [xmin ymin % xmax ymax pour plus de commodité
xmin = bboxes(:,1);
ymin = bboxes(:,2);
xmax = xmin + bboxes(:,3) - 1;
ymax = ymin + bboxes(:,4) - 1;

% Coupez les boîtes englobantes dans les limites de l'image
expansionAmount = 0.02;
xmin = (1-expansionAmount) * xmin;
ymin = (1-expansionAmount) * ymin;
xmax = (1+expansionAmount) * xmax;
ymax = (1+expansionAmount) * ymax;

% Afficher les zones de contour développées
xmin = max(xmin, 1);
ymin = max(ymin, 1);
xmax = min(xmax, size(I,2));
ymax = min(ymax, size(I,1));

% Show the expanded bounding boxes
expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
IExpandedBBoxes = insertShape(I1,'Rectangle',expandedBBoxes,'LineWidth',3);

figure(8);
imshow(IExpandedBBoxes);
title('Texte élargi des cadres de sélection');

% Calcule le taux de recouvrement 
overlapRatio = bboxOverlapRatio(expandedBBoxes, expandedBBoxes);

% Définissez le rapport de recouvrement entre un cadre de sélection et lui-même sur zéro pour % simplifier la représentation du graphique. 
n = size(overlapRatio,1); 
overlapRatio(1:n+1:n^2) = 0;

% Créez le graphique 
g = graph(overlapRatio);

% Trouver les régions de texte connectées dans le graphique 
componentIndices = conncomp(g);

% Fusionnez les cases en fonction des dimensions minimale et maximale. 
xmin = accumarray(componentIndices', xmin, [], @min);
ymin = accumarray(componentIndices', ymin, [], @min);
xmax = accumarray(componentIndices', xmax, [], @max);
ymax = accumarray(componentIndices', ymax, [], @max);

% Composez les boîtes englobantes fusionnées en utilisant le format [xy width height]. 
textBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];

% Supprime les cadres de sélection ne contenant qu'une région de texte
numRegionsInGroup = histcounts(componentIndices);
textBBoxes(numRegionsInGroup == 1, :) = [];

%Montrer le résultat final
ITextRegion = insertShape(I1, 'Rectangle', textBBoxes,'LineWidth',3);

figure(9);
imshow(ITextRegion);
title('Texte détecté');

