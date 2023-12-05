clear
load dataQualityVectorExtraction.mat
gs = 32;

for m = 1 : objNum
    if m == 1 | m == 4
        cate = categorical(cellstr('truck'));
        shape = trucksize;
        cateId = 1;
    end
    if m == 2 | m == 3
        cate = categorical(cellstr('car'));
        shape = carsize;
        cateId = 2;
    end
    if m == 5 | m == 7  
        cate = categorical(cellstr('pedestrian'));
        shape = pedsize;
        cateId = 3;
    end
    if m == 6
        cate = categorical(cellstr('bicycle'));
        shape = bycsize;
        cateId = 4;
    end
    for t = 1 : timeNum
        ptCloudout = merge(t).obj(m).ptcloud;
        grid = pcbin(ptCloudout,[gs gs gs]);
        occupancyGrid = zeros(size(grid),'single');
        for ii = 1:numel(grid)
            occupancyGrid(ii) = ~isempty(grid{ii});
        end
        occArray_Train(:,:,:,1,(m-1)*timeNum+t) =  occupancyGrid;
        cateArray_Train((m-1)*timeNum+t,1) = cate; % category
        cateidArray_Train((m-1)*timeNum+t,1) = cateId; % category Id
        ptnumArray_Train((m-1)*timeNum+t,1) =  ptCloudout.Count;
        varArray_Train((m-1)*timeNum+t,1) =  max(var(ptCloudout.Location));
        featureArray_Train(:,:,:,1,(m-1)*timeNum+t) = merge(t).obj(m).feature;
        shapeArray_Train((m-1)*timeNum+t,:) = shape;

        for n = 1 : carNum
            ptCloudout = car(n,t).obj(m).ptcloud;
            cateArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,1) = cate;
            cateidArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,1) = cateId;
            ptnumArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,1) =  ptCloudout.Count;
            featureArray_Test(:,:,:,1,(m-1)*timeNum*carNum+(t-1)*carNum+n) = car(n,t).obj(m).feature;
            shapeArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,:)=shape;
            if ptCloudout.Count > 0
                grid = pcbin(ptCloudout,[gs gs gs]);
                occupancyGrid = zeros(size(grid),'single');
                for ii = 1:numel(grid)
                    occupancyGrid(ii) = ~isempty(grid{ii});
                end
                occArray_Test(:,:,:,1,(m-1)*timeNum*carNum+(t-1)*carNum+n) =  occupancyGrid;
                varArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,1) = max(var(ptCloudout.Location));
            else
                occArray_Test(:,:,:,1,(m-1)*timeNum*carNum+(t-1)*carNum+n) =  zeros(gs,gs,gs);
                varArray_Test((m-1)*timeNum*carNum+(t-1)*carNum+n,1) = 0;
            end
        end

    end
end

ptnumArray = [ptnumArray_Test; ptnumArray_Train];
varArray = [varArray_Test; varArray_Train];
shapeArray = [shapeArray_Test; shapeArray_Train];
featureArray = cat(5,featureArray_Test,featureArray_Train);
occArray = cat(5,occArray_Test,occArray_Train);
cateArray = [cateArray_Test; cateArray_Train];
cateidArray = [cateidArray_Test; cateidArray_Train];

layers = [image3dInputLayer([gs gs gs],'Name','inputLayer','Normalization','none'),...
    convolution3dLayer(5,gs,'Stride',2,'Name','Conv1'),...
    leakyReluLayer(0.1,'Name','leakyRelu1'),...
    convolution3dLayer(3,gs,'Stride',1,'Name','Conv2'),...
    leakyReluLayer(0.1,'Name','leakyRulu2'),...
    maxPooling3dLayer(2,'Stride',2,'Name','maxPool'),...
    fullyConnectedLayer(128,'Name','fc1'),...
    reluLayer('Name','relu'),...
    dropoutLayer(0.5,'Name','dropout1'),...
    fullyConnectedLayer(4,'Name','fc2'),...
    softmaxLayer('Name',['softmax']),...
    classificationLayer('Name','crossEntropyLoss')];

voxnet = layerGraph(layers);

options = trainingOptions('sgdm', 'Plots', 'training-progress');
% options = trainingOptions('sgdm','InitialLearnRate',0.01,'MiniBatchSize',32,...
%     'LearnRateSchedule','Piecewise',...
%     'MaxEpochs',60,...
%     'Plots', 'training-progress',...
%     'DispatchInBackground',false,...
%     'Shuffle','never');
voxnet = trainNetwork(occArray_Train, cateArray_Train, voxnet, options);

save trainVoxnet.mat