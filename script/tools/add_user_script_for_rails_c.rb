%w(Test21_Tester21 Test22_Tester22 Test23_Tester23 Test24_Tester24 Test25_Tester25 Test26_Tester26 Test27_Tester27 Test28_Tester28 Test29_Tester29 Test30_Tester30 Test31_Tester31 Test32_Tester32 Test33_Tester33 Test34_Tester34 Test35_Tester35 Test36_Tester36 Test37_Tester37 Test38_Tester38 Test39_Tester39 Test40_Tester40 Test41_Tester41 Test42_Tester42 Test43_Tester43 Test44_Tester44 Test45_Tester45 Test46_Tester46 Test47_Tester47 Test48_Tester48 Test49_Tester49 Test50_Tester50 Test51_Tester51 Test52_Tester52 Test53_Tester53 Test54_Tester54 Test55_Tester55 Test56_Tester56 Test57_Tester57 Test58_Tester58 Test59_Tester59 Test60_Tester60 ).each{|per| u = User.new({:firstname => per.split("_").first, :lastname => per.split("_").last, :mail => "#{per.split("_").last}@spambog.com", :confirm => true});u.password = "p4ssw0rD!"; u.login = "#{per.split("_").last}@spambog.com"; u.save!; }
