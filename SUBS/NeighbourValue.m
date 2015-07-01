% input:
% grid=NeighbourValue(idx,grid)
function grid=NeighbourValue(idx,grid,step)
	if isempty(idx),return;end
	if ~exist('step','var'),step=1;end
	neighbouredMeanedGrid=getMean(grid);
	grid(idx)=neighbouredMeanedGrid(idx);
if mod(step,100)==0, 	disp(['blending in nans. Recursion level: ' num2str(step)]); end
	%% recursive
	idx=find(isnan(grid));
	grid=NeighbourValue(idx,grid,step+1);
	%%
	function out=getMean(grid)
		[y,x]=size(grid);
		toMean=nan(y,x,4);
		toMean(:,:,1)=[nan(y,1)     ,   grid(:,1:end-1)]; %west
		toMean(:,:,2)=[grid(:,2:end),   nan(y,1)];%east
		toMean(:,:,3)=[grid(2:end,:);   nan(1,x)];%north
		toMean(:,:,4)=[nan(1,x)     ;   grid(1:end-1,:)];%south
		out=nanmean(toMean,3);
	end
end