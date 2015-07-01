% Nikolaus Koopmann 11/2011
%calc mean and std from new value and old mean/std
%function [mean_new, std_new]=mean_std_fromold(mean_old, std_old, value_N, N)
function [mean_new, std_new]=mean_std_fromold(mean_old, std_old, value_N, N)	
	mean_new=nansum([(N-1)./(N).*mean_old, (1./N).*value_N],2);
	
	if N>1
		std_new=sqrt(std_old.^2+1./(N-1).*(value_N-mean_old).^2);
	else
		std_new=value_N;
	end
	
end