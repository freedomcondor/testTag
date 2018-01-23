function solveQuad(a1,b1,c1,d1,e1,f1,
				   a2,b2,c2,d2,e2,f2,
				   standard,x0,y0,
				   count)
	-- solve equations:
	-- a1x^2 + b1y^2 + c1xy + d1x + e1y + f1 = 0
	-- a2x^2 + b2y^2 + c2xy + d2x + e2y + f2 = 0
	-- try starts from x0,y0,(0,0) default, until err < standard
	-- if count > XXXX (specified in line 50), considered no solution

	local count = count or 1

	local x = x0 or 0
	local y = y0 or 0

	local F1 = a1*x^2 + b1*y^2 + c1*x*y + d1*x + e1*y + f1
	local F2 = a2*x^2 + b2*y^2 + c2*x*y + d2*x + e2*y + f2

	if (F1 >= -standard) and (F1 <= standard) and
	   (F2 >= -standard) and (F2 <= standard) then
	   	return x,y
	end

	local F1_x = 2*a1*x+c1*y+d1
	local F1_y = 2*b1*y+c1*x+e1

	local F2_x = 2*a2*x+c2*y+d2
	local F2_y = 2*b2*y+c2*x+e2

	-- climb up direction of F1 should be (F1_x,F1_y)
	-- climb up direction of F2 should be (F2_x,F2_y)

	local F1_L = math.sqrt(F1_x^2 + F1_y^2)
	local F2_L = math.sqrt(F2_x^2 + F2_y^2)

	local F1_x_nor = F1_x / F1_L
	local F1_y_nor = F1_y / F1_L
	local F1_del = F1_x_nor * F1_x + F1_y_nor * F1_y

	local F2_x_nor = F2_x / F2_L
	local F2_y_nor = F2_y / F2_L
	local F2_del = F2_x_nor * F2_x + F2_y_nor * F2_y

	-- for F1, (x0,y0 go (x_nor,y_nor) * err_F1)
	-- for F2, (x0,y0 go (x_nor,y_nor) * err_F2)

	x = x + (0-F1)/F1_del * F1_x_nor + (0-F2)/F2_del * F2_x_nor
	y = y + (0-F1)/F1_del * F1_y_nor + (0-F2)/F2_del * F2_y_nor

	--if (count > 1000000) then return nil,nil end
	if (count > 100000) then return x,y end

	return solveQuad(	a1,b1,c1,d1,e1,f1,
				   		a2,b2,c2,d2,e2,f2,
				   		standard,x,y,count + 1)
end
