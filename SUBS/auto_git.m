function auto_git
	system('git add *.m')
	system('git add SUBS')
	system('git commit -a -m "MATLAB generated commit"')	
end