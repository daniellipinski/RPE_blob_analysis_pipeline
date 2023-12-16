        clearvars
        close all
        clc
%% SECTION 1: IMAGE MASKING
	% SECTION 1.1: Raw Image Referencing
	    stem = input('What is the image filename? e.g. if file saved as Group1Well##, enter Group1Well:	', 's');
	    loops = input('How many images need masked?');
	    first = input('What is the number of the first image?');
            % Note: code will only loop for sequentially named files
            
for n = first:(first+loops-1)
	% SECTION 1.2 Raw Image Uploading
    	number = num2str(first+n-1);
    	filename = strcat(stem,number,'.tif'); %if needed, change file type here (.bmp, .jpg, .tif...)
    	raw = imread(filename);
    	raw_double = double(raw); 
 
	% SECTION 1.3 ROI Selection
    	disp('Draw a rectangle, right click, and copy/paste XY');
    	imshow(raw);
    	figure(1)
    	h = imrect;
    	XY = input('Paste coordinates here: ');
    	roundXY = [round(XY(1)),round(XY(2)),round(XY(3)),round(XY(4))] 
    	radius = round(0.5*(sqrt(roundXY(3)^2 + roundXY(4)^2)));
    	center = [round(roundXY(1)+0.5*(roundXY(3))),round(roundXY(2)+0.5*(roundXY(4)))]
 
	% SECTION 1.4: Image Masking
    	mask = CircleMask(raw,center,radius);
    	raw_double = double(raw);
    	masked = raw_double.*mask;
    	masked = uint8(masked);
 
	% SECTION 1.5: Masked Image Cropping
        left = center(1)-radius; right = center(1)+radius;
        top = center(2)-radius; bottom = center(2)+radius;
        cropped = masked(top:bottom, left:right, :);
 
	% SECTION 1.6: Masked/Cropped Image Saving
        figure(2)
        imshow(cropped)
        saveas(gcf,strcat(stem,number," masked.tif"))
 
	% SECTION 1.7: Store data, reset variables
	    Store_Raw{n} = cropped
	    close all
	    clear number filename raw raw_double h XY roundXY radius center mask masked left right top bottom cropped
end
save Workplace1.mat
clear n

%% SECTION 2: IMAGE ADJUSTMENTS
for n = first:(first+loops-1)
    number = num2str(first+n-1);
 
    % SECTION 2.1: Image Processing
    Retrieve = Store_Raw{n};
    AVG = zeros(size(Retrieve)); SD = AVG;
        %Note: Local neighborhood (here, 11) needs to be odd
    SD(:,:) = stdfilt(Retrieve(:,:),true(11)); % assess local st.dev.
    weight = ones(11,11)./121;
    AVG(:,:) = imfilter(SD(:,:),weight);  
                
    % SECTION 2.2: Conversion to Binary Thresholded @ Background
    BG = mean2(Retrieve);
    AVG = round(AVG);
 
    for j = 1:size(AVG,2)
        for i = 1:size(AVG,1)
            if AVG(i,j) <= BG
            binary(i,j) = 0;
            else binary(i,j) = 1;
            end
        end
    end
 
    Store_Processed{n} = binary;
    figure
    imshow(binary)
    saveas(gcf,strcat(stem,number," processed.tif"))

end
save Workplace2.mat
sound(sin(1:3000));
close all 

%% SECTION 3: Blob Analysis 
% SECTION 3.1: Setting Up Algorithm, hblob
    % Note: All size/area numbers handled by BlobAnalysis refer to sq.pixels!
        % ... For absolute measurements, calculate pixel size and adjust output
        % Our pixel size = 0.665 um
    hblob = vision.BlobAnalysis(...
                'MinimumBlobArea', 400, ... % Min = 15um diameter
                'MaximumBlobArea', 160000, ... % Max = 300um diameter
                'MaximumCount', 5000);
    % Note: This turns on parts of BlobAnalysis beyond only count and area
            hblob.BoundingBoxOutputPort = true; %Essential, leave as true!
            hblob.EccentricityOutputPort = true; %Optional
            hblob.EquivalentDiameterSquaredOutputPort = true; %Optional
            hblob.LabelMatrixOutputPort = true; %Essential, leave as true!
            hblob.ExcludeBorderBlobs = true; %Optional
            Store_Count = zeros(loops,1); 
% SECTION 3.2: Running Blob Analysis
for n = first:(first+loops-1)number = num2str(first+n-1);
        Retrieve = Store_Processed{n};
        Blobs = logical(Retrieve);
        [AREA, CENTROID, BBOX, ECCENTRICITY, EQDIASQ, LABEL] = step(hblob,Blobs);
    
        figure
        imshow(LABEL)
        colormap(gca,parula)
        caxis([0,1])
        saveas(gcf,strcat(stem,number," pre-EAT.tif")) % EAT = Ellipse Area Threshold, see below
        close all
        
    % SECTION 3.2.1:Ellipse Area Calcuation and Thresholding
        % Note: This section recalculates area assuming drusen are solid and ellipsoid
        % Purpose: to correct for "donut-ing" artifact
        CANDIDATES = length(AREA)   
    for i = 1:CANDIDATES
        ELLIPSE(i,1) = ceil(pi*0.5*BBOX(i,3)*0.5*BBOX(i,4));
    end    
        EAT = 1590; % change if final size threshold is different than 30um diameter (1590 sq.px. area)
        Index = ones(CANDIDATES,1);

    for j = 1:CANDIDATES
        if ELLIPSE(j) <= EAT
            Index(j) = 0;
            LABEL(LABEL == j) = 0;
        end
    end

    % SECTION 3.2.2: Manual Exclusions
        edit = 1; %Turn to 0 to turn off or 1 to turn on
        sound(sin(1:3000));
        
    while edit == 1
        figure(1)
        imshow(LABEL)
        colormap(gca,parula)
        caxis([0,1])
        
        query = input('Manually exclude a blob? "NO" = 0; "YES" = "Index#"')
        if query ~= 0
            LABEL(LABEL == query) = 0;
            Index(query) = 0;
        elseif query == 0
            saveas(gcf,strcat(stem,number," post-EAT.tif"))
            edit = 0;
        end
    end
        close all
    
    % SECTION 3.2.3: Store Data   
        Store_Blobs{n} = (LABEL ~= 0);
        Store_Label{n} = LABEL;
        
        Store_Count(n) = length(ELLIPSE(Index~=0));
        Store_Area{n} = AREA(Index ~= 0);;
        Store_Ellipse{n} = ELLIPSE(Index ~= 0);; % Note: this is ellipse area calculated from BBOX to correct donuting
        Store_BBox{n} = BBOX(Index ~= 0);;
        Store_Centroid{n} = CENTROID(Index ~= 0);; 
        Store_Eccentricity{n} = ECCENTRICITY(Index ~= 0);;
        Store_EqDiaSq{n} = EQDIASQ(Index ~= 0);; 
        
    % SECTION 3.2.4: Saving Raw+Blobs Montage  
        fuse = imfuse(Store_Raw{n},Store_Blobs{n});
        montage = imfuse(Store_Raw{n},fuse,'montage');
        figure
        imshow(montage)
        saveas(gcf,strcat(stem,number," montage.tif"))
        close all
        
    % SECTION 3.2.5: Resetting Loop
        clear i j k Retrieve Blobs AREA CENTROID ECCENTRICITY EQDIASQ LABEL fuse montage query clear
end

%% Section 4: Data Summary
clear n i j;

for n = 1:size(Store_Blobs,2);
    Summary(1,n) = (first+n-1);
    Summary(2,n) = Store_Count(n);
    Summary(3,n) = mean(Store_Ellipse{n});
    Summary(4,n) = std(double(Store_Ellipse{n}));
end 
save Workplace3.mat