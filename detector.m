function detector( database, record )
    % Matlab file for this record already exists
    
    % Detect the fiducial points
    t=cputime();
    idx = chen(database, record);
    fprintf('Running time for record %s: %f\n', record, cputime() - t);
    
    % Write the fiducial points to a .asc file
    ascName = sprintf('%s/%s.asc', database, record);
    fid = fopen(ascName, 'wt');
    for i=1:size(idx,2)
      fprintf(fid,'0:00:00.00 %d N 0 0 0\r\n', idx(1,i) );
    end
    fclose("all"); % in case we CTRL+C for some reason, and the file remains open
end
