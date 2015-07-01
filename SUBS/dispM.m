function dispM(string,MasterOnly)
	if nargin<2,MasterOnly=false;end
	if labindex==1
		disp(['Master Thread: ']);
		disp([string]);
	else
		if ~MasterOnly
			fprintf('thread %d :\n %s \n',labindex,string);
		end
	end
end








%
% function dispM(string,MasterOnly)
%  	if nargin<2,MasterOnly=false;end
%     if labindex==1
%         disp(['Master Thread: ']);
%         disp([string]);
%     else
%         if ~MasterOnly
%             commFile=sprintf('./.comm%03d.mat',labindex);
%             comm=matfile(commFile,'writable',true);
%             comm.printstack(end+1,1)={string};
%         end
%     end
% end
