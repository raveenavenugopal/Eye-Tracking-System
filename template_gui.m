function [ty,tx] =template_gui()


scale=1;
kernelsize=8;
sigma=5;
minrad=4;
maxrad=30;
thresh=0.4;

% Read the image
I=imread('BioID_0418.pgm');
user=I;
iptsetpref('useIPPL',false);
I=imresize(I,scale,'lanczos3');

% If the image is rgb then convert it into grayscale
if(size(I,3)==3)
I=rgb2gray(I);
end
figure,imagesc(I),title('Original Image'),impixelinfo,colormap('gray');
hold on;

% Detect face
ConvertHaarcasadeXMLOpenCV('HaarCascades/haarcascade_frontalface_alt.xml');
Objects=ObjectDetection(I,'HaarCascades/haarcascade_frontalface_alt.mat');
[x1,x2,y1,y2]=ShowDetectionResult(I,Objects);

I1 = imcrop(I,[x1 y1 x2-x1 y2-y1]);
%hold off
figure, imagesc(I1),title('Face detected Image'),impixelinfo,colormap('gray');
J = imcrop(user,[x1 y1+(y2-y1)./4 x2-x1 (y2-y1)./4]);

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

% Convert the data txpe of the image to double. Divide the cropped
% image into two parts. One for each eye. Store it in variable cel
cel{1}=J(1:1:size(J,1),1:1:round(0.50*size(J,2)));
cel{2}=J(1:1:size(J,1),round(0.50*size(J,2)):1:size(J,2));
ty=zeros(2);
tx=zeros(2);

%for each eye apply the algorithm based on the method specified.
for row=1:1:2
    cel{row}=im2double(cel{row});
    
    % Smooth the image.
    cel{row}=imfilter(cel{row},h,'replicate','conv');
    
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
    
    % Create the weight array.Make 1 as the voting scheme 
    weight=zeros(size(cel{row},1),size(cel{row},2));
    for y=1:1:size(cel{row},1)
        for x=1:1:size(cel{row},2)
             weight(y,x)=1;
        end
    end
    
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
                            mapped(y+D_vector(y,x,2),x+D_vector(y,x,1))=mapped(y+D_vector(y,x,2),x+D_vector(y,x,1)) + weight(y,x);
                        end
                    end
                end
            end
        end
    end
    
     
    % smooth the accumulator
    mapped=imfilter(mapped,h,'replicate','conv');

    % Find the maximum isocenter
    [ty(row),tx(row)]=find(mapped==max(mapped(:)));
    mapped(mapped<max(mapped(:)))=0;
    
  end

end