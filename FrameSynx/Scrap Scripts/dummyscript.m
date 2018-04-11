f = figure;
        textH = text(.5, .5, 'Hello');
        set(textH,'Editing','on');
        disp('This prints immediately');
        waitfor(textH,'Editing','off');
        disp('This prints after text editing is complete');
        close(f);