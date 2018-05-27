function sleep(s)
	local t0 = os.clock()
	while os.clock() - t0 <= s do end
end
