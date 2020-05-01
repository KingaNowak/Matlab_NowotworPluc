A=im2double(dicomread('C:\Users\kinga\Desktop\pom_program\to\LCTSC\LCTSC-Test-S3-102\11-08-2004-LEFT LUNG-11520\1.000000-95635\1-105.dcm'));
Amax=max(A(:));
Amin=min(A(:));
B=imadjust(A,[Amin Amax],[0 1]);
figure()
imshow(B);
[w,k]=size(A);
for i=1:w
    for j=1:k
        A(i,j)=A(i,j)/Amax;
    end
end
figure()
imshow(A);
%%
I=imread('C:\Users\kinga\Desktop\pazigi_projekt\Lab\00.JPG');
figure()
imshow(I);
II=imresize(imrotate(I,-20),1.2);
figure();
imshow(II);
%%
I1 = rgb2gray(imread('viprectification_deskLeft.png'));
I2 = rgb2gray(imread('viprectification_deskRight.png'));
figure()
imshow(I1)
figure()
imshow(I2)