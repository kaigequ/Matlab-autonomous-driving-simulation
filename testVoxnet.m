clear
load generateSensorDataWithDifferentSampleRatio.mat


for l = 1 : length(ptnumArray_D)
    if ptnumArray_D(l,1) > 0
        [outputLabel, outputScore]  = classify(voxnet,occArray_D(:,:,:,1,l));
        accArray_D(l,1) = outputScore(cateidArray_D(l,1));
    else
        accArray_D(l,1)  = 0;
    end
end

truckIndex= find(cateidArray_D == 1);
carIndex = find(cateidArray_D == 2);
pedIndex = find(cateidArray_D == 3);
bycIndex = find(cateidArray_D == 4);


figure
plot3(ptnumArray_D,varArray_D,accArray_D,'bo')
hold on
plot3(ptnumArray_D(carIndex),varArray_D(carIndex),accArray_D(carIndex),'go')
hold on
plot3(ptnumArray_D(truckIndex),varArray_D(truckIndex),accArray_D(truckIndex),'mo')
hold on
plot3(ptnumArray_D(pedIndex),varArray_D(pedIndex),accArray_D(pedIndex),'yo')
hold on
plot3(ptnumArray_D(bycIndex),varArray_D(bycIndex),accArray_D(bycIndex),'co')
xlim([0 10000])


% figure
% plot3(ptnumArray_D(truckIndex),varArray_D(truckIndex),accArray_D(truckIndex),'bo')
% figure
% plot3(ptnumArray_D(carIndex),varArray_D(carIndex),accArray_D(carIndex),'bo')
% figure
% plot3(ptnumArray_D(pedIndex),varArray_D(pedIndex),accArray_D(pedIndex),'bo')
% figure
% plot3(ptnumArray_D(bycIndex),varArray_D(bycIndex),accArray_D(bycIndex),'bo')

save testVoxnet.mat