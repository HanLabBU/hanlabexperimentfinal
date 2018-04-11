function velocity = moveWithKeyboard(vr)

velocity = [0 0 0 0];
switch vr.keyPressed
    case '4'
        velocity(4) = 2;
    case '6'
        velocity(4) = -2;
    case '8'
        velocity(1) = 15*sin(-vr.position(4));
        velocity(2) = 15*cos(-vr.position(4));
    case '2'
        velocity(1) = -15*sin(-vr.position(4));
        velocity(2) = -15*cos(-vr.position(4));
    case '`'
        scr = get(0,'screensize');
        ptr = get(0,'pointerlocation')-scr(3:4)/2;
        velocity(1) = ptr(2)/2*sin(-vr.position(4));
        velocity(2) = ptr(2)/2*cos(-vr.position(4));
        velocity(4) = ptr(1)/100;
        
        velocity = velocity / 5;
end