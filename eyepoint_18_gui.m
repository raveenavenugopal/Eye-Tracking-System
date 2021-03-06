function [ro,c] = eyepoint_18_gui(input,sigma)
import java.awt.Robot;
import java.awt.event.*;

% -------------------------------------------------------------------------
% !!!!!!!! Input Arguments !!!!!!!!!!!
% input = Either Grayscale or RGB image.
% sigma = Standard deviation of gaussian filter.

% !!!!!!!! Output Arguments !!!!!!!!!!
% r = y-coordinates of estimated center.
% c = x-coordinates of estimated center.
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mouse = Robot;
screenSize = get(0,'screensize');
size_x=screenSize(3);
size_y=screenSize(4);

% variables used
% kernelsize = size of Gaussian kernel used for smoothing and filtering the image.
% minrad = minimum value of magnitude of displacement vector estimated using 
% the method that should be used for voting. Values below it are not used for voting.
% maxrad = maximum value of magnitude of displacement vector estimated
% using  the method that should be used for voting. Values above it are not
% used for center voting.
% thresh = threshhold value as required for Canny operator in  Edge method. 

kernelsize=8;
minrad=4;
maxrad=30;
thresh=0.4;
scale=1;

% find Center position using template image
[ty,tx]=template_gui();

% Read the image
I=imread(input);
user=I;
%I=input;
iptsetpref('useIPPL',false);
I=imresize(I,scale,'lanczos3');

% If the image is rgb then convert it into grayscale
if(size(I,3)==3)
I=rgb2gray(I);
end
figure,imagesc(I),title('Original Image'),impixelinfo,colormap('gray');
hold on;

% Finding face region
ConvertHaarcasadeXMLOpenCV('HaarCascades/haarcascade_frontalface_alt.xml');
Objects=ObjectDetection(I,'HaarCascades/haarcascade_frontalface_alt.mat');
[x1,x2,y1,y2]=ShowDetectionResult(I,Objects);

I1 = imcrop(I,[x1 y1 x2-x1 y2-y1]);
facex=x2-x1;
facey=y2-y1;
hold off;

rect = [x1 y1+(y2-y1)./4 x2-x1 (y2-y1)./4];
J = imcrop(user,[x1 y1+(y2-y1)./4 x2-x1 (y2-y1)./4]);
m=[rect(1) rect(1)+rect(3)];
n=[rect(2) rect(2)+rect(4)];

% Display the cropped image
hold off
figure,imagesc(J,'XData',m,'YData',n),title('Cropped Image'),impixelinfo,colormap('gray');

% Blink detection
b=im2bw(J);
figure,imshow(b,2);
rowSumZeros = sum(~b,1);
rowSumOnes = sum(b,1);
oneSum=sum(rowSumOnes);
zeroSum=sum(rowSumZeros);
fprintf('\nBlack spots: %d\n', zeroSum);
fprintf('White spots : %d\n', oneSum);
tsum=oneSum+zeroSum;
fprintf('Total sum : %d\n',tsum);
per=(zeroSum./tsum)*100;
wper=(oneSum./tsum)*100;
fprintf('Percentage : %f\n',per);
fprintf('Percentage white dots : %f\n',wper);

if wper < 50
    uiwait(warndlg('BLINK : Closed Eyes'));
    mouse.mousePress(InputEvent.BUTTON1_MASK);
    pause(0.1);
    mouse.mouseRelease(InputEvent.BUTTON1_MASK);
    pause(1.0);
    mouse.mousePress(InputEvent.BUTTON1_MASK);
    pause(0.1);
    mouse.mouseRelease(InputEvent.BUTTON1_MASK);
    pause(0.1);
    mouse.mousePress(InputEvent.BUTTON1_MASK);
    pause(0.1);
    mouse.mouseRelease(InputEvent.BUTTON1_MASK);
else
    uiwait(warndlg('Opened Eyes'));

   % Obtain the kernel for smoothing the image using the given arguments 
    sz=2*kernelsize-1;
    h=zeros(2*sz-1,2*sz-1);
    for y=-(sz-1):1:(sz-1)
        for x=-(sz-1):1:(sz-1)
            a=x+sz;
            b=y+sz;
            h(b,a)=exp(-((x*x) + (y*y))/(2*sigma*sigma))/(2*pi*sigma*sigma);
        end
    end

    % smooth the image using imfilter function and kernel obtained above
    % Apply the canny operator on the image
    J=imfilter(J,h,'replicate','conv');
    J=edge(J,'canny',thresh,sigma);


    % Convert the data type of the image to double. Divide the cropped
    % image into two parts. One for each eye. Store it in variable cel
    cel{1}=J(1:1:size(J,1),1:1:round(0.50*size(J,2)));
    cel{2}=J(1:1:size(J,1),round(0.50*size(J,2)):1:size(J,2));
    ro=zeros(2);
    c=zeros(2);

    %for each eye apply the algorithm.
    for row=1:1:2
    cel{row}=im2double(cel{row});
    % Smooth the image.
    cel{row}=imfilter(cel{row},h,'replicate','conv');
    
    % Calculate the gradient using the compute using gradient method of MATLAB.
    [FX,FY]=gradient(cel{row});
    [FXX,FXY]=gradient(FX);
    [FYX,FYY]=gradient(FY);

    % Calculate the curvedness
    curved=sqrt(im2double(FXX.^2 + 2*FXY.^2 + FYY.^2));
   
    % Calculate the displacement vectors
    G1=FX.^2 + FY.^2;
    G2=((FY.^2).*FXX) - (2*(FX.*FXY).*FY) + ((FX.^2).*FYY);
    G2=round(G1./G2);
    G2=-1*G2;
    
    % Clear the redundant variables to free some space
    clear FXX;
    clear FXY;
    clear FYY;
    G4=G2.*FX;
    G5=G2.*FY;
    G1=G1.^(1.5);
    G8=round(G2./G1);
    G8=-1*G8;
    clear FX;
    clear FY;
    
    D_vector=zeros(size(cel{row},1),size(cel{row},2),2);
    for y=1:1:size(cel{row},1)
        for x=1:1:size(cel{row},2)
            D_vector(y,x,1)=G4(y,x);
            D_vector(y,x,2)=G5(y,x);
        end
    end
    D_vector=round(D_vector);
    Mag_D_vector=sqrt(D_vector(:,:,1).^2 + D_vector(:,:,1).^2);
    
       
    % Create the accumulator that will store the result
    mapped=zeros(size(cel{row},1),size(cel{row},2));
    Used_D_Vector=zeros(size(cel{row},1),size(cel{row},2),2);
    for y=1:1:size(cel{row},1)
        for x=1:1:size(cel{row},2)
            if((D_vector(y,x,1)~=0) || (D_vector(y,x,2)~=0))
                if((x+D_vector(y,x,1)>0) &&  (y+D_vector(y,x,2)>0))
                    if((x+D_vector(y,x,1)<=size(cel{row},2)) &&  (y+D_vector(y,x,2)<=size(cel{row},1)) && (G8(y,x)<0))
                        if((Mag_D_vector(y,x)>=minrad)&&(Mag_D_vector(y,x)<=maxrad))
                        
                            % use only those displacement vectors which are within the specified range
                            
                            Used_D_Vector(y,x,1)=D_vector(y,x,1);
                            Used_D_Vector(y,x,2)=D_vector(y,x,2);  
                            mapped(y+D_vector(y,x,2),x+D_vector(y,x,1))=mapped(y+D_vector(y,x,2),x+D_vector(y,x,1))+1;
                        end
                    end
                end
            end
        end
    end
    
    % smooth the accumulator
    mapped=imfilter(mapped,h,'replicate','conv');

    % Find the maximum isocenter
    [ro(row),c(row)]=find(mapped==max(mapped(:)));
  
    end

    cx=c;
    cy=ro;

    c(1)=c(1)+m(1);
    ro(1)=ro(1)+n(1);
    c(2)=c(2)+m(1)+0.50*size(J,2);
    ro(2)=ro(2)+n(1);
    
    % Display the resulting image.
    figure;imshow(I,[],'initialMagnification','fit');impixelinfo;hold on;
    plot(c(1),ro(1),'r*');
    plot(c(2),ro(2),'r*');
    c(1),ro(1)
    c(2),ro(2)
    hold off;
    %clear all
    
    %$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    
    pause(1.0)
    change_x=tx(1)-cx(1);
    change_y=ty(1)-cy(1);
    curent = get(0,'PointerLocation');
    curent(2)=size_y-curent(2);
    centerx=size_x/2;
    centery=size_y/2;
    change_x=change_x*(size_x/facex);
    change_y=change_y*(size_y/facey);
    mov_x=curent(1)+change_x;
    mov_y=curent(2)+change_y;
   
%----------------------------------------
ddaline(curent(1),curent(2),mov_x,mov_y);
      
end
