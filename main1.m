I = imread('img.jpg');
figure(1);
imshow(I);
title('Image originale');
impixelinfo;

%imcrop(x, y, width, heigth)
%Segmentation et extraction de l'image contenant du bruit
I2= imcrop(I, [299, 704, 1988-299, 1175-704]);
figure(2);
imshow(I2);
title('Image scindée contenant du bruit');

%%Convertir en echelle de gris
if size(I2, 3) == 3 %Cela signifie que c'est une image RGB
    I2=rgb2gray(I2);
end

%%Convertir l'image en binaire
seuil = graythresh(I2);
I2 = ~im2bw(I2, seuil);

%%Rejeter tous les objects contenant moins de 30pixels
I2 = bwareaopen(I2, 40);

%%Montrer l'image binaire
figure(3);
imshow(~I2);
title("Image purifée(sans bruit)");
