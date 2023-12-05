clear
load testVoxnet.mat

for i = 1 : size(featureArray_D, 5)
      inputArray_D(1:fdim+1,1:fdim+1,1:fdim+1,1,i) = 0;
      inputArray_D(1:fdim,1:fdim,1:fdim,1,i) = featureArray_D(:,:,:,1,i);
      inputArray_D(fdim+1,1,1,1,i) = shapeArray_D(i,1); 
      inputArray_D(1,fdim+1,1,1,i) = shapeArray_D(i,2); 
      inputArray_D(1,1,fdim+1,1,i) = shapeArray_D(i,3); 
end


acclayers = [image3dInputLayer([fdim+1 fdim+1 fdim+1],'Name','inputLayer','Normalization','none'),...
    convolution3dLayer(fdim+1,fdim+1,'Stride',1,'Name','Conv1'),...
    leakyReluLayer(0.1,'Name','leakyRulu1'),...
    convolution3dLayer(1,fdim+1,'Stride',1,'Name','Conv2'),...
    leakyReluLayer(0.1,'Name','leakyRulu2'),...
    maxPooling3dLayer(1,'Stride',1,'Name','maxPool1'),...
    fullyConnectedLayer(10,'Name','fc1'),...
    fullyConnectedLayer(1,'Name','fc2'),...
    sigmoidLayer('Name','Sigmoid'),...
    regressionLayer('Name','Regression')];

accnet = layerGraph(acclayers);
options = trainingOptions('sgdm', 'Plots', 'training-progress');
accnet = trainNetwork(inputArray_D, accArray_D, accnet, options);
accPredict_D = predict(accnet,inputArray_D);

figure
plot3(ptnumArray_D,varArray_D,accArray_D,'bo')
hold on 
plot3(ptnumArray_D,varArray_D,accPredict_D,'r*')


figure
plot3(ptnumArray_D(carIndex),varArray_D(carIndex),accArray_D(carIndex),'bo')
hold on 
plot3(ptnumArray_D(carIndex),varArray_D(carIndex),accPredict_D(carIndex),'g*')


figure
plot3(ptnumArray_D(truckIndex),varArray_D(truckIndex),accArray_D(truckIndex),'bo')
hold on 
plot3(ptnumArray_D(truckIndex),varArray_D(truckIndex),accPredict_D(truckIndex),'m*')


figure
plot3(ptnumArray_D(pedIndex),varArray_D(pedIndex),accArray_D(pedIndex),'bo')
hold on 
plot3(ptnumArray_D(pedIndex),varArray_D(pedIndex),accPredict_D(pedIndex),'y*')

figure
plot3(ptnumArray_D(bycIndex),varArray_D(bycIndex),accArray_D(bycIndex),'bo')
hold on 
plot3(ptnumArray_D(bycIndex),varArray_D(bycIndex),accPredict_D(bycIndex),'c*')


% figure
% plot3(ptnumArray_D,varArray_D,accArray_D,'bo')
% hold on 
% plot3(ptnumArray_D(carIndex),varArray_D(carIndex),accPredict_D(carIndex),'g*')
% hold on 
% plot3(ptnumArray_D(truckIndex),varArray_D(truckIndex),accPredict_D(truckIndex),'m*')
% hold on 
% plot3(ptnumArray_D(pedIndex),varArray_D(pedIndex),accPredict_D(pedIndex),'y*')
% hold on 
% plot3(ptnumArray_D(bycIndex),varArray_D(bycIndex),accPredict_D(bycIndex),'c*')

% testIndex = [1:448];
% trainIndex = [449:560];
% figure
% plot3(ptnumArray(trainIndex),varArray(trainIndex),accArray(trainIndex),'bo')
% hold on 
% plot3(ptnumArray(trainIndex),varArray(trainIndex),accPredict(trainIndex),'r*')
% xlim([0 4000])
% 
% figure
% plot3(ptnumArray(testIndex),varArray(testIndex),accArray(testIndex),'bo')
% hold on 
% plot3(ptnumArray(testIndex),varArray(testIndex),accPredict(testIndex),'r*')
% xlim([0 4000])
save trainAccModel.mat