function write_fields(dd,ff,fld,grids) %#ok<INUSD>
	file=[dd.path.(fld).name, dd.path.(fld).files(ff).name];
	save(file,'grids','-append')
