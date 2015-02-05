function[result] = ratel_log(msg, groups)
//logging allowing control of output

  result = %F;
  log_groups_var = 'ratel_log_groups';

  //type checking
  if strcmp(typeof(msg), 'string') ~= 0 then
    mprintf('[ratel_log, error] msg must be a string');
    return;
  end
  [r,c] = size(msg);
  if r ~= 1 then
    mprintf('[ratel_log, error] msg string must be a single string');
    return;
  end 

  if strcmp(typeof(groups), 'string') ~= 0 then
    mprintf('[ratel_log, error] log groups must be a string');
    return;
  end

  //flatten groups
  [rg, cg] = size(groups);
  groups = matrix(groups, 1, rg*cg);

  //if no groups wanted return silently
  if ~isdef(log_groups_var) then
    result = %T;
    return;
  end;

  //disp the msg along with groups it belongs to if 
  //1. at least one of the groups is in log_groups_var OR
  //2. log_groups_var contains 'all'
  included = strcmp(groups, eval(log_groups_var))
  all_enabled = strcmp(eval(log_groups_var), 'all')
  if or([~isempty(find(included == 0)), ~isempty(find(all_enabled == 0))]) then
    mprintf('[');
    for i = 1:cg,
      if (i ~= 1) then mprintf(', '); end
      mprintf('%s', groups(i));
    end //for
    mprintf('] ');
    mprintf(msg);
  end //if
 
  result = %T; 
endfunction //ratel_log
