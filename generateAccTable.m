clear
load trainAccModel.mat


dd = 0.6; %downsample ratio
%acc(s, m, t)

for t = 8: 8
    for m = 1 : 7
        for s = 1:15
            features = zeros(fdim,fdim,fdim);
            k = zeros(4, 1);
            k(4) = floor(s/8);
            k(3) = floor((s - k(4)*8)/4);
            k(2) = floor((s - k(4)*8 - k(3)*4)/2);
            k(1) = s- k(4)*8 - k(3)*4 - k(2)*2;
            for n = 1 : 4
               features = features + k(n)*car(n,t).obj(m).feature;
            end
            inputs(1:fdim+1,1:fdim+1,1:fdim+1,1,1) = 0;
            inputs(1:fdim,1:fdim,1:fdim,1,1) = floor(features*dd);
            inputs(fdim+1,1,1,1,1) = objs(m).size(1); 
            inputs(1,fdim+1,1,1,1) = objs(m).size(2); 
            inputs(1,1,fdim+1,1,1) = objs(m).size(3);             
            table(t).acc(m,s) = predict(accnet,inputs);

       end

        for n = 1 : 4
            table(t).z(m,n) = floor(car(n,t).obj(m).ptcloud.Count*dd);
        end
    end
    for n = 1 : 4
            table(t).pos(n,:) = car(n,t).cuboid.Center;
    end
end
al = table(t).acc
save('generateAccTable','table');