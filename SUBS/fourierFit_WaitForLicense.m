%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 01-Dec-2014 11:53:50
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wait for license
function Yout = fourierFit_WaitForLicense(varargin)
    success = false;
    timeStamp = now;
  
%     while ~success
%         try
            Yout = fit(varargin{:});
%         catch err
%             sleep(10);
%             thusFar = now - timeStamp;
%             disp(err.message);
%             fprintf('been trying to get fit license for %s\n',datestr(thusFar,'hh:mm:ss'))
%             continue
%         end
%         success = true;
%     end
end