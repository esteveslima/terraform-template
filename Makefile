#	Utility commands

# clear temp files
clean:
	find . -type d -name .terraform -prune -exec rm -rf {} \;