function velocity = moveWithBall1 (vr)
    velocity = [0 0 0 0];
    dql = vr.m.left.dequeAll;
    dqr = vr.m.right.dequeAll;

    if numel(dql) ~= 2
        dql = [0 0];
    end
    if numel(dqr) ~= 2
        dqr = [0 0];
    end
    
    if (dql(1)-dqr(1)) > 0
        velocity(4) = -.1;
    end
    
    if (dql(1)-dqr(1)) < 0
        velocity(4) = .1;
    end
    
    if mean([dql(2),dqr(2)]) > 0
        velocity(1) = 2*sin(-vr.position(4));
    end
    
    if mean([dql(2),dqr(2)]) < 0
        velocity(1) = -2*sin(-vr.position(4));
    end
    
    if mean([dql(1),dqr(1)]) > 0
        velocity(2) = 2*cos(-vr.position(4));
    end
    
    if mean([dql(1),dqr(1)]) < 0
        velocity(2) = -2*cos(-vr.position(4));
    end
    disp(velocity)