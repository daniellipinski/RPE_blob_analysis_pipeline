test = round(50*rand(50));
bg = mean2(test)
test2 = test;

for i = 1:(2+round(5*rand(1)))
diameter = 3+round(3*rand(1))
blob = round(bg + (1+(5*rand(1)))*(25*rand(diameter)))
x = 9+round(32*rand(1));
y = 9+round(32*rand(1));
test2(x:(x+diameter-1),y:(y+diameter-1)) = blob;
end

sd = stdfilt(test2);
weight = ones(3,3)./9;
adjusted(:,:) = imfilter(sd,weight);  

    for j = 1:size(adjusted,2)
        for i = 1:size(adjusted,1)
            if adjusted(i,j) <= bg
                binary(i,j) = 0;
            else binary(i,j) = 1;
            end
        end
    end

figure
subplot(1,5,1)
imshow(test)
colormap(gca,parula)
caxis([0,100])

subplot(1,5,2)
imshow(test2)
colormap(gca,parula)
caxis([0,100])

subplot(1,5,3)
imshow(sd)
colormap(gca,parula)
caxis([0,50])

subplot(1,5,4)
imshow(adjusted)
colormap(gca,parula)
caxis([0,50])

subplot(1,5,5)
imshow(binary)