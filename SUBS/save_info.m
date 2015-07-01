function save_info(DD)	
%% refresh
DD.path=getfield(get_input,'path');
%% save
save([DD.path.root, 'DD.mat'],'-struct',	'DD')
end