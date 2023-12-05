clear
load trainAccModel.mat

dNum = 10;
for fdim = 1 : 4
    for d = 1 : dNum
        for m = 1 : objNum
             for t = 1 : timeNum
                odx = obj(m,t).cuboid.Dimensions(1)/fdim;
                ody = obj(m,t).cuboid.Dimensions(2)/fdim;
                odz = obj(m,t).cuboid.Dimensions(3)/fdim;
                ocx = obj(m,t).cuboid.Center(1);
                ocy = obj(m,t).cuboid.Center(2);
                ocz = obj(m,t).cuboid.Center(3);
                for i = 1 : fdim
                    for j = 1 : fdim
                        for k = 1 : fdim
                            px = ocx + (-(fdim-1)/(2*fdim)+1/fdim*(i-1))*odx*fdim;
                            py = ocy + (-(fdim-1)/(2*fdim)+1/fdim*(j-1))*ody*fdim;
                            pz = ocz + (-(fdim-1)/(2*fdim)+1/fdim*(k-1))*odz*fdim;
                            quality(fdim).partition(i,j,k).cuboid = cuboidModel([px,py,pz, odx, ody, odz, obj(m,t).cuboid.Orientation]);
                            quality(fdim).featureArray_Train_D(i,j,k,1,(d-1)*objNum*timeNum+(m-1)*timeNum+t)  = numel(findPointsInsideCuboid(quality(fdim).partition(i,j,k).cuboid,  ptTrain((d-1)*objNum*timeNum+(m-1)*timeNum+t).ptcloud));
                              for n = 1 : carNum
                                  quality(fdim).featureArray_Test_D(i,j,k,1,(d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n)  = numel(findPointsInsideCuboid(quality(fdim).partition(i,j,k).cuboid, ptTest((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n).ptcloud));
                              end
                        
                        end
                    end
                end%i
    
               
                 
               
        
            end%t
        end
    end
    quality(fdim).featureArray_D =  cat(5, quality(fdim).featureArray_Test_D, quality(fdim).featureArray_Train_D);

end

for fdim = 1: 4
    for i = 1 : size(quality(fdim).featureArray_D, 5)
          quality(fdim).inputArray_D(1:fdim+1,1:fdim+1,1:fdim+1,1,i) = 0;
          quality(fdim).inputArray_D(1:fdim,1:fdim,1:fdim,1,i) = quality(fdim).featureArray_D(:,:,:,1,i);
          quality(fdim).inputArray_D(fdim+1,1,1,1,i) = shapeArray_D(i,1); 
          quality(fdim).inputArray_D(1,fdim+1,1,1,i) = shapeArray_D(i,2); 
          quality(fdim).inputArray_D(1,1,fdim+1,1,i) = shapeArray_D(i,3); 
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

    accnet = trainNetwork(quality(fdim).inputArray_D, accArray_D, accnet, options);
    quality(fdim).accPredict_D = predict(accnet,quality(fdim).inputArray_D);
    figure
    plot3(ptnumArray_D,varArray_D,accArray_D,'bo')
    hold on 
    plot3(ptnumArray_D,varArray_D,quality(fdim).accPredict_D,'r*')
    quality(fdim).loss = norm(quality(fdim).accPredict_D -accArray_D)^2;
end 
bar([quality(1).loss quality(2).loss quality(3).loss quality(4).loss ]/5600)
x=[1,2,3,4]
y=[quality(1).loss quality(2).loss quality(3).loss quality(4).loss ]/5600
bar(x,y)
xlabel('Data quality parameter K')
ylabel('MSE')
save evaluateResolutionK.mat