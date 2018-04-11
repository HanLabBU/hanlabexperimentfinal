function velocity = moveWithBall (vr)
try
    t = toc;
    tic
catch me
    tic
    t=0;
end

    dql = vr.l.dq;
    dqr = vr.r.dq;
    rscale = -1/10; % ballpark 1/100 is good
    xscale = 10;
    yscale = 10;
%     fprintf('dql(x,y) = %d %d and dqr(x,y) = %d %d \t t=%d\n',dql,dqr,t)
    
    if numel(dql) ~= 2
        dql = [0 0];
    end
    
    if numel(dqr) ~= 2
        dqr = [0 0];
    end
    velocity = zeros(1,4);
    %     newv1 = (dql(2) - dqr(2))*xscale;
    %     newv2 = (dql(2) + dqr(2))*yscale;
    vx = dqr(1)*xscale;
    vy = dql(1)*yscale;
%     newv1 = -mean([dql(2),dqr(2)])*sin(-vr.position(4))*xscale;
%     newv2 = -mean([dql(1),dqr(1)])*cos(-vr.position(4))*yscale;

%     dx = vx*cos(-vr.position(4)*2*pi) + vy*sin(-vr.position(4)*2*pi);
%     dy = vx*sin(-vr.position(4)*2*pi) + vy*cos(-vr.position(4)*2*pi);
    dx = vx;
    dy = vy;
    newv4 = (dql(2)+ dqr(2))*rscale;
    newvelocity = [dx dy 0 newv4];
    vr.velocitybuffer = vertcat(newvelocity,vr.velocitybuffer(1:(size(vr.velocitybuffer,1)-1),:));
    %     disp(vr.velocitybuffer)
    for i = 1:size(vr.velocitybuffer,2)
        velocity(1,i) = mean(vr.velocitybuffer(:,i),1);
    end
%     disp('The velocities are:')
%     disp(velocity)
    %     end

    
    
    
%     velocity(4) =  (dql(1)+ dqr(1))*rscale;
%     velocity(1) = (dql(2) - dqr(2))*xscale;
%     velocity(2) = (dql(2) + dqr(2))*yscale;    

%     velocity(1) = -mean([dql(2),dqr(2)])*sin(-vr.position(4));
%     velocity(2) = -mean([dql(1),dqr(1)])*cos(-vr.position(4));
   