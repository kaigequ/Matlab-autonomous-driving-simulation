clear 
load evaluateResolutionK.mat

dNum_F = 1000;
%merge1.ptcloud = pcmerge(car(1,1).obj(1).ptcloudout, car(2,1).obj(1).ptcloudout,0.001);

for d = 1 : dNum_F
    m = 1;
            if m == 1 | m == 4
                cateId = 1;
            end
            if m == 2 | m == 3
                cateId = 2;
            end
            if m == 5 | m == 7  
                cateId = 3;
            end
            if m == 6
                cateId = 4;
            end
            %car: car(2,1).obj(2).ptcloud
            %truck: car(4,1).obj(4).ptcloud
            %ped: merge(1).obj(5).ptcloud
            %bi: merge(1).obj(6).ptcloud

            ptCloudout = pcdownsample(car(2,1).obj(1).ptcloud,'random',d/dNum_F);
            grid = pcbin(ptCloudout,[gs gs gs]);
            occupancyGrid = zeros(size(grid),'single');
            for ii = 1:numel(grid)
                occupancyGrid(ii) = ~isempty(grid{ii});
            end
            ptArray_F(d) = ptCloudout;
            occArray_F(:,:,:,1,d) =  occupancyGrid;
            cateidArray_F(d,1) = cateId;
            ptnumArray_F(d,1) =  ptCloudout.Count;
            

end

            
 for l = 1 : length(ptnumArray_F)
    if ptnumArray_F(l,1) > 0
        [outputLabel, outputScore]  = classify(voxnet,occArray_F(:,:,:,1,l));
        accArray_F(l,1) = outputScore(cateidArray_F(l,1));
    else
        accArray_F(l,1)  = 0;
    end
 end
% figure
% plot(ptnumArray_F,accArray_F,'co')
 
figure
plot(ptnumArray_F,accArray_F,'bo')
figure
pcshow(ptArray_F(50),'BackgroundColor',[1 1 1])
ptnumArray_F(50)
figure
pcshow(ptArray_F(250),'BackgroundColor',[1 1 1])
ptnumArray_F(250)
figure
pcshow(ptArray_F(500),'BackgroundColor',[1 1 1])
ptnumArray_F(500)