I = imread('img.jpg');
figure(1);
imshow(I);
title('Image originale');
impixelinfo;

%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
I2= imcrop(I, [65 539 2546-65 1226-539]);
figure(2);
imshow(I2);
title('Image scindée contenant du bruit');

%%Convertir en echelle de gris
if size(I2, 3) == 3 %Cela signifie que c'est une image RGB
    I2=rgb2gray(I2);
end

%%Convertir l'image en binaire
%seuil = graythresh(I2);
%I2 = ~im2bw(I2, seuil);

%%Rejeter tous les objects contenant moins de 30pixels
%I2 = bwareaopen(I2, 40);

%%Montrer l'image binaire
%figure(3);
%imshow(~I2);
%title("Image purifée(sans bruit)");

%detecter la region MSR
[mserRegions, mserConnComp] = detectMSERFeatures(I2, ... 
    'RegionAreaRange',[50 8000],'ThresholdDelta',4);

% Utiliser regionprops pour mesurer les propriétés MSER 
mserStats = regionprops (mserConnComp, 'BoundingBox' , 'Eccentricity' , ... 
    'Solidity' , 'Extent' , 'Euler' , 'Image' );

% Calculez le rapport de format à l'aide des données du cadre de sélection.
bbox = vertcat (mserStats.BoundingBox);
w = bbox (:, 3);
h = bbox (:, 4);
aspectRatio = w./h;

% Seuil des données pour déterminer les régions à supprimer. Il peut être nécessaire d’ajuster ces seuils % pour d’autres images.
filterIdx = aspectRatio' > 3; 
filterIdx = filterIdx | [mserStats.Eccentricity]> .995;
filterIdx = filterIdx | [mserStats.Solidity] <.3;
filterIdx = filterIdx | [mserStats.Extent] <0.2 | [mserStats.Extent]> 0.9;
filterIdx = filterIdx | [mserStats.EulerNumber] <-4;

% Supprimer des régions
mserStats (filterIdx) = [];
mserRegions (filterIdx) = [];

% Afficher les régions restantes
figure(4)
imshow(I2)
hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('après le retrait de la Région non-Texte basée sur les propriétés géométriques')
hold off

regionImage = mserStats(6).Image;
regionImage = padarray(regionImage, [1 1]);

% Compute the stroke width image.
distanceImage = bwdist(~regionImage); 
skeletonImage = bwmorph(regionImage, 'thin', inf);

strokeWidthImage = distanceImage;
strokeWidthImage(~skeletonImage) = 0;

% Show the region image alongside the stroke width image. 
figure
subplot(1,2,1)
imagesc(regionImage)
title('Region Image')

subplot(1,2,2)
imagesc(strokeWidthImage)
title('Stroke Width Image')

strokeWidthValues = distanceImage(skeletonImage);   
strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);

strokeWidthThreshold = 0.4;
strokeWidthFilterIdx = strokeWidthMetric > strokeWidthThreshold;

for j = 1:numel(mserStats)
    
    regionImage = mserStats(j).Image;
    regionImage = padarray(regionImage, [1 1], 0);
    
    distanceImage = bwdist(~regionImage);
    skeletonImage = bwmorph(regionImage, 'thin', inf);
    
    strokeWidthValues = distanceImage(skeletonImage);
    
    strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
    
    strokeWidthFilterIdx(j) = strokeWidthMetric > strokeWidthThreshold;
    
end

% Remove regions based on the stroke width variation
mserRegions(strokeWidthFilterIdx) = [];
mserStats(strokeWidthFilterIdx) = [];

% Show remaining regions
figure
imshow(I)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
title('After Removing Non-Text Regions Based On Stroke Width Variation')
hold off

% Get bounding boxes for all the regions
bboxes = vertcat(mserStats.BoundingBox);

% Convert from the [x y width height] bounding box format to the [xmin ymin
% xmax ymax] format for convenience.
xmin = bboxes(:,1);
ymin = bboxes(:,2);
xmax = xmin + bboxes(:,3) - 1;
ymax = ymin + bboxes(:,4) - 1;

% Expand the bounding boxes by a small amount.
expansionAmount = 0.02;
xmin = (1-expansionAmount) * xmin;
ymin = (1-expansionAmount) * ymin;
xmax = (1+expansionAmount) * xmax;
ymax = (1+expansionAmount) * ymax;

% Clip the bounding boxes to be within the image bounds
xmin = max(xmin, 1);
ymin = max(ymin, 1);
xmax = min(xmax, size(I,2));
ymax = min(ymax, size(I,1));

% Show the expanded bounding boxes
expandedBBoxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
IExpandedBBoxes = insertShape(I2,'Rectangle',expandedBBoxes,'LineWidth',3);

figure
imshow(IExpandedBBoxes)
title('Expanded Bounding Boxes Text')

