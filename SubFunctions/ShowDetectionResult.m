function [x1,x2,y1,y2]= ShowDetectionResult(Picture,Objects)
%  ShowDetectionResult(Picture,Objects)
%
%
iptsetpref('useIPPL',false);
xmin=0;
xmax=1000;
ymin=0;
ymax=1000;
%I=imresize(I,scale,'lanczos3');

% Show the picture
%figure,imagesc(Picture),title('Face detected Image'),impixelinfo, hold on;
figure,imshow(Picture), hold on;

% Show the detected objects
if(~isempty(Objects));
    for n=1:size(Objects,1)
        x1=Objects(n,1); y1=Objects(n,2);
        x2=x1+Objects(n,3); y2=y1+Objects(n,4);
        plot([x1 x1 x2 x2 x1],[y1 y2 y2 y1 y1]);
        if (xmin<x1);
            xmin=x1;
        end
        if (xmax>x2);
            xmax=x2;
        end
        if (ymin<y1);
            ymin=y1;
        end
        if (ymax>y2);
            ymax=y2;
        end
    end
    clear x1 x2 y1 y2;
    %x1=Objects(size(Objects,1),1); y1=Objects(size(Objects,1),2);
    %x2=x1+Objects(size(Objects,1),3); y2=y1+Objects(size(Objects,1),4);
    %plot([x1 x1 x2 x2 x1],[y1 y2 y2 y1 y1]);
    x1=xmin;
    x2=xmax;
    y1=ymin;
    y2=ymax;
end
