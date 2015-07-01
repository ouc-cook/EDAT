function [matrix3d]=vertstack(matrix2d,Zreps)
		matrix3d=repmat(permute(matrix2d,[3,1,2]),[Zreps,1,1]);	
end