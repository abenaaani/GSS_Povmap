clear

*Does any member of the household own mobile phone?
g mobileown = 2 - s5cq5
label var mobileown "1 = Any member of the household owns a mobile phone, 0 otherwise"

*Does any member of the household use internet?
g internetuse = 1 if s5cq8a==1 | s5cq8b==1 | s5cq8c==1 | s5cq8d2==1
replace internetuse = 0 if internetuse==.
label var internetuse "1 = Any member of the household uses internet, 0 otherwise"

*Does the household own fixed telephone line at home?
g fixedphone = 2 - s7eq1a
label var fixedphone "1 = Household owns a fixed telephone line, 0 otherwise"

*Does any member of the household own desktop or laptop computers?
g pc = 1 if s5cq1b==1
replace pc=0 if pc==.
label var pc "1 = Any member of the household owns desktop or laptop computers, 0 otherwise"


*Type of dwelling
recode s7aq1 (1 2 3 4 5 6 9 = 1) (7 8 10 11 = 0), gen(conventional)
label var conventional "1 = Conventional dwelling, 0 otherwise"

*Outer wall
recode s7fq1 (1 7 = 1) (2 3 8 9 = 2) (4 5 6 10 = 3), gen(wall)
label var wall "Main construction material of outer wall"
label define wall 1 "Mud bricks/earth, Landcrete" 2 "Wood, Metal sheet/slate/asbestos, Bamboo, Palm leaves/thatch(grass/ruffian)" 3 "Stone, Burnt bricks, Cement blocks/concrete, Other"
label val wall wall
tab wall, gen(wall)

*Floor
recode s7fq2 (1 = 1) (2 3 4 = 2)(5 6 7 8 9 = 3), gen(floor)
label var floor "Main construction material of floor"
label define floor 1 "Earth/mud" 2 "Cement/concrete, stone, burnt bricks" 3 "Wood, vinyl tiles, ceramic/porcelain/granite/marble tiles,terrazo/terrazo tiles, other"
label val floor floor
tab floor, gen(floor)

*Roof
recode s7fq3 (1 7 8 = 1)(2 4 6 = 2)(3 = 3)(5 9 = 4) , gen(roof)
label var roof "Main construction material of roof"
label define roof 1 "Mud/mud bricks/earth, bamboo, palm leaves/thatch(grass/ruffian)" 2 "Wood, slate/asbestos, roofing tile" 3 "Metal sheet" 4 "Concrete/Other"
label val roof roof
tab roof, gen(roof)

*Tenure
recode s7bq1 (1 = 1) (2 = 2) (3/5 = 3), gen(tenure)
label var tenure "Tenancy arrangement"
label define tenure 1 "Owning" 2 "Renting" 3 "Rent free, perching, squatting"
label val tenure tenure
tab tenure, gen(tenure)

*Number of rooms
g rooms = s7aq2
label var rooms "Number of rooms"

*Number of bedrooms
g bedrooms = s7aq3
label var bedrooms "Number of bedrooms"

*Main source of lighting
recode s7dq11a (1 2 5 = 1) (3 4 = 2) (7 = 3) (6 8 9 10 = 4), gen(lighting)
label var lighting "Main source of lighting"
label define lighting 1 "Electricity(mains), electricity(private generator),solar energy" 2 "Kerosene or gas lamp" 3 "Flashlight/torch" 4 "Candle, firewood, crop residue, other"
label val lighting lighting
tab lighting, gen(lighting)

*Source of drinking water
recode s7dq1a1 (1 2 3 4 = 1) (5 6 8 = 2) (9 10 = 3) (7 11/16 = 4), gen(water_drinking)
label var water_drinking "Main source of drinking water"
label define water1 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring" 3 "Bottled or satchet water" 4 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_drinking water1
tab water_drinking, gen(water_drinking)

*Water for general use
recode s7dq1a2 (1 2 3 4 = 1) (5 6 8 9 10 = 2) (7 11/16 = 3), gen(water_general)
label var water_general "Main source of water for general use"
label define water2 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring, satchet water" 3 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_general water2
tab water_general, gen(water_general)

*Main source of cooking fuel
recode s7dq19 (2 = 1) (3 = 2) (4 = 3) (1 5/10 = 4), gen(fuel)
label var fuel "Main source of cooking fuel"
label define fuel 1 "Wood" 2 "Charcoal" 3 "Gas" 4 "Electricity, kerosense , crop residue, sawdust, animal waste, other"
label val fuel fuel
tab fuel, gen(fuel)

*Type of toilet
recode s7dq26a (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5/7 = 5), gen(toilet)
label var toilet "Type of toilet"
label define toilet 1 "No facility" 2 "WC" 3 "Pit latrine" 4 "KVIP" 5 "Bucket/pan, public toilet, other"
label val toilet toilet
tab toilet, gen(toilet)

*Solid waste disposal
rename s7dq24a solidwaste
tab solidwaste, gen(solidwaste)


  