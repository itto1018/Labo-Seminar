//変数名の変更
	rename 台数 sale
	rename 型式 id
	rename 新車価格 price
	rename 新車価格_CPI price_cpi
	rename 排気量 exhaust
	rename トランスミッション mission
	rename 乗車定員 people
	rename ハイブリッド d_hv
	rename 最高出力_kW kw
	rename 燃費WLTC fuel_wltc
	rename 燃費JC08 fuel_jc08
	rename 燃費1015 fuel_1015
	rename 全長 lenght
	rename 全幅 width
	rename 全高 height
	rename サイズ size
	rename 車両重量 weight
	rename メーカー標準ボディカラー color_std
	rename メーカーオプションボディカラー color_opt
	rename 過給機 d_turbo
	rename 駆動 drive
	rename 燃料 fuel
	rename 自動ブレーキシステム d_aeb
	rename 充電走行距離 ev_dist
	rename 車種 type
	rename 備考 memo

	rename 企業株価 stock
	rename ガソリン価格 petrol
	rename ガソリン価格_CPI petrol_cpi
	rename 半導体素子価格 diode
	rename 半導体素子価格_CPI diode_cpi
	rename 半導体素子価格_CGPI diode_cgpi
	rename 世帯数_年 house
	rename 貨物_保有数 owned_cargo
	rename 乗用_保有数 owned_norm
	rename 特許数 patent


//外れ値など
	drop if 通称名=="Ｃ＋ＰＯＤ"
//レギュラー車のみなのでfuelを消す
	drop fuel
	//加工0921_スポーツカーと電気自動車
drop if 通称名=="アイ・ミーブ" 

//destring(文字データから数字データへ変換)
	destring kw,replace
	destring fuel_wltc,replace
	destring fuel_jc08,replace
	destring fuel_1015,replace
	destring owned_cargo,replace
	destring owned_norm,replace

//encode(文字データから数字データへ変換し、新たな変数として作成)
	encode メーカー, gen (maker)
	encode 通称名, gen (model)
	encode drive,gen (c_drive)

//時間データ化
	format date %td
	label variable date 年月


//エコカー補助金を1とするダミー変数(0か1をとる変数)の作成
	//第一次エコカー補助金(2009/4/10~2010/9/7)対象車のダミー変数
		gen f_target=0
		replace f_target=1 if date>=mdy(4,10,2009) & date<=mdy(9,7,2010)

		//2005年排ガス規制75%かつ2010年燃費基準+15%達成
		gen f_exhaust_H17=0
		replace f_exhaust_H17=1 if substr(id,1,1)=="D"

		gen f_weight_2010=.
		replace f_weight_2010=8 if weight<=1265
		replace f_weight_2010=4 if weight<=1015
		replace f_weight_2010=2 if weight<=827
		replace f_weight_2010=1 if weight<=702

		gen f_fuel_2010=0
		replace f_fuel_2010=1 if fuel_1015>=18.4
		replace f_fuel_2010=2 if fuel_1015>=20.6
		replace f_fuel_2010=4 if fuel_1015>=21.6
		replace f_fuel_2010=8 if fuel_1015>=24.4

		gen f_subsidy=0
		replace f_subsidy=1 if f_target*f_exhaust_H17*f_weight_2010*f_fuel_2010>=8
		label variable f_subsidy 第一次エコカー補助金ダミー

	drop f_target f_fuel_2010 f_exhaust_H17

	//第二次エコカー補助金(2011/12/20~2012/9/21)対象車のダミー変数
		gen s_target=0
		replace s_target=1 if date>=mdy(12,20,2011) & date<=mdy(9,21,2012)
		
		//2010年燃費基準+25%達成車
		gen s_fuel_2010=0
		replace s_fuel_2010=1 if fuel_1015>=20.0
		replace s_fuel_2010=2 if fuel_1015>=22.4
		replace s_fuel_2010=4 if fuel_1015>=23.5
		replace s_fuel_2010=8 if fuel_1015>=26.5
		
		gen s_subsidy=0
		replace s_subsidy=1 if s_target*f_weight_2010*s_fuel_2010>=8
		
		//2015年燃費基準達成車
		//JC08
		gen s_weight_2015=.
		replace s_weight_2015=32 if weight<=1195
		replace s_weight_2015=16 if weight<=1080
		replace s_weight_2015=8 if weight<=970
		replace s_weight_2015=4 if weight<=855
		replace s_weight_2015=2 if weight<=740	
		replace s_weight_2015=1 if weight<=600
		
		gen s_fuel_2015=0
		replace s_fuel_2015=1 if fuel_jc08>=18.7 | fuel_wltc>=18.7
		replace s_fuel_2015=2 if fuel_jc08>=20.5 | fuel_wltc>=20.5
		replace s_fuel_2015=4 if fuel_jc08>=20.8 | fuel_wltc>=20.8
		replace s_fuel_2015=8 if fuel_jc08>=21.0 | fuel_wltc>=21.0
		replace s_fuel_2015=16 if fuel_jc08>=21.8 | fuel_wltc>=21.8
		replace s_fuel_2015=32 if fuel_jc08>=22.5 | fuel_wltc>=22.5
		
		replace s_subsidy=1 if s_target*s_weight_2015*s_fuel_2015>=32

	label variable s_subsidy 第二次エコカー補助金ダミー
	drop s_target s_fuel_2010

	gen subsidy=0
	replace subsidy=1 if f_subsidy==1 | s_subsidy==1
	label variable subsidy 補助金ダミー


//エコカー減税ダミー(取得税・重量税)
gen cl_exhaust=0
replace cl_exhaust=1 if substr(id,1,1)=="D" | substr(id,1,1)=="5" | substr(id,1,1)=="6"

	//2009~2012's
		gen target_1=0
		replace target_1=1 if date>=mdy(4,1,2009) & date<=mdy(3,31,2012)

		gen fuel_2010=0 //減税ダミーのため、軽減率は分けていない
		replace fuel_2010=1 if fuel_1015>=18.4
		replace fuel_2010=2 if fuel_1015>=20.6
		replace fuel_2010=4 if fuel_1015>=21.6
		replace fuel_2010=8 if fuel_1015>=24.4
		
		gen eco_tax1=0
		replace eco_tax1=1 if target_1*cl_exhaust*f_weight_2010*fuel_2010>=8
		
		drop target_1  f_weight_2010 fuel_2010
		
	//2013~2014's
		gen target_2=0
		replace target_2=1 if date>=mdy(4,1,2012) & date<=mdy(3,31,2015)
		
		gen eco_tax2=0
		replace eco_tax2=1 if target_2*cl_exhaust*s_weight_2015*s_fuel_2015>=32
		
		drop s_fuel_2015 target_2
	
	//2015~2016's
		//2020年基準
		gen target_3=0
		replace target_3=1 if date>=mdy(4,1,2015) & date<=mdy(3,31,2017)
		
		gen weight_H32=.
		replace weight_H32=16 if weight<1196
		replace weight_H32=8 if weight<1081
		replace weight_H32=4 if weight<971
		replace weight_H32=2 if weight<856
		replace weight_H32=1 if weight<741
		
		gen fuel_H32=0
		replace fuel_H32=1 if fuel_jc08>=21.8 | fuel_wltc>=21.8
		replace fuel_H32=2 if fuel_jc08>=23.4 | fuel_wltc>=23.4
		replace fuel_H32=4 if fuel_jc08>=23.7 | fuel_wltc>=23.7
		replace fuel_H32=8 if fuel_jc08>=24.5 | fuel_wltc>=24.5
		replace fuel_H32=16 if fuel_jc08>=24.6 | fuel_wltc>=24.6
		
		//2015年基準
		gen fuel_2015=0
		replace fuel_2015=1 if fuel_jc08>=19.6 | fuel_wltc>=19.6
		replace fuel_2015=2 if fuel_jc08>=21.6 | fuel_wltc>=21.6
		replace fuel_2015=4 if fuel_jc08>=21.8 | fuel_wltc>=21.8
		replace fuel_2015=8 if fuel_jc08>=22.1 | fuel_wltc>=22.1
		replace fuel_2015=16 if fuel_jc08>=22.9 | fuel_wltc>=22.9
		replace fuel_2015=32 if fuel_jc08>=23.6 | fuel_wltc>=23.6
		
		gen eco_tax3=0
		replace eco_tax3=1 if target_3*cl_exhaust*weight_H32*fuel_H32>=16
		replace eco_tax3=1 if target_3*cl_exhaust*s_weight_2015*fuel_2015>=32

		drop target_3 fuel_2015
		
	//2017's
		gen target_4=0
		replace target_4=1 if date>=mdy(4,1,2017) & date<=mdy(3,31,2018)
		
		//2015年基準+10%
		gen fuel_2015_2=0
		replace fuel_2015_2=1 if fuel_jc08>=19.6 | fuel_wltc>=20.6
		replace fuel_2015_2=2 if fuel_jc08>=21.6 | fuel_wltc>=22.6
		replace fuel_2015_2=4 if fuel_jc08>=21.8 | fuel_wltc>=22.9
		replace fuel_2015_2=8 if fuel_jc08>=22.1 | fuel_wltc>=23.1
		replace fuel_2015_2=16 if fuel_jc08>=22.9 | fuel_wltc>=24.0
		replace fuel_2015_2=32 if fuel_jc08>=23.6 | fuel_wltc>=24.8
		
		gen eco_tax4=0
		replace eco_tax4=1 if target_4*cl_exhaust*weight_H32*fuel_H32>=16
		replace eco_tax4=1 if target_4*cl_exhaust*s_weight_2015*fuel_2015_2>=32
		
		drop target_4 fuel_2015_2 s_weight_2015
		
	//2018~2019's
		gen target_5=0
		replace target_5=1 if date>=mdy(4,1,2018) & date<=mdy(10,1,2019)
		
		gen eco_tax5=0
		replace eco_tax5=1 if target_5*cl_exhaust*weight_H32*fuel_H32>=16
		
		drop target_5 weight_H32 fuel_H32

gen eco_tax=0
replace eco_tax=1 if eco_tax1==1 | eco_tax2==1 | eco_tax3==1 | eco_tax4==1 | eco_tax5==1
label variable eco_tax エコカー減税ダミー

//ダイハツ・トヨタ子会社ダミー等
	//ダイハツ子会社化(2016/8)ダミー
	gen ToyoHatsu_date=0
	replace ToyoHatsu_date=1 if date>=mdy(8,1,2016)
	label variable ToyoHatsu_date ダイハツ子会社ダミー

	//TOYOTA&DAIHATSUダミー
	gen ToyoHatsu_maker=0
	replace ToyoHatsu_maker=1 if メーカー=="TOYOTA"
	replace ToyoHatsu_maker=1 if メーカー=="DAIHATSU"
	label variable ToyoHatsu_maker トヨタダイハツ車ダミー

	//交差項
	gen toyohatsu=ToyoHatsu_date*ToyoHatsu_maker
	label variable toyohatsu ToyoHatsu_dateかつToyoHatsu_maker


//三菱不正車ダミー等
	//ekデイズ発売(2013/6)ダミー
	gen ekdays_date=0
	replace ekdays_date=1 if date>=mdy(6,1,2013)
	label variable ekdays_date ek・days発売ダミー

	//eKデイズダミー
	gen ekdays_model=0 
	replace ekdays_model=1 if 通称名=="eKワゴン"　& date>=mdy(6,1,2013)
	replace ekdays_model=1 if 通称名=="eKスペース"　& date>=mdy(6,1,2013)
	replace ekdays_model=1 if 通称名=="デイズ"　& date>=mdy(6,1,2013)
	label variable ekdays_model ek・daysダミー

	//交差項
	gen ekdays=ekdays_date*ekdays_model
	label variable ekdays ekdays_dateかつekdays_model


	//不正発覚後ダミー
	gen after=1 if date>=mdy(4,1,2016)
	replace after=0 if after==.
	label variable after 燃費不正発覚ダミー

	//交差項
	gen kouka=ekdays*after
	label variable kouka ekdaysかつafter

//不正した期間のみ不正車＝1とするダミー変数
	gen ekdays_model2=ekdays_model 
	replace ekdays_model2=0 if ekdays_model2==.

	gen kouka3=ekdays_model2*after
	
	
	
//燃費
	gen fuel=fuel_jc08 if fuel_jc08!=.

	reg fuel_jc08 fuel_1015
	replace fuel=fuel_1015*0.8932002+0.6794758 if fuel_wltc==. & fuel_jc08==.

	reg fuel_jc08 fuel_wltc
	replace fuel=fuel_wltc*1.301491 if fuel_jc08==. & fuel_1015==.

	
//対数をとる
	gen lnsale=log(sale)
	gen lnprice=log(price_cpi)
	gen lndiode=log(diode)
	gen lnfuel=log(fuel)
	gen lnstock=log(stock)
	gen lnsize=log(size)
	gen lnsale2=log(sale2)
		drop if lnsale2==.
	
//不要な変数の削除
	drop memo eco_tax1 eco_tax2 eco_tax3 eco_tax4 eco_tax5 f_subsidy s_subsidy cl_exhaust d_mt
	drop color_std color_opt lenght width height mission type drive ev_dist people exhaust


//固定効果
gen yearlinear=1 if date == td(01jan2007)
forvalues a=2/180{
	foreach j=td(01feb2007)/td(0){
			replace yearlinear=`a' if date==td(`j')
		}
}


gen maker_R=1 if maker==1
forvalues r=2/8{
	replace maker_R=`r' if maker==`r'
}

	replace maker_R=2 if maker==2
	replace maker_R=3 if maker==3 
	replace maker_R=4 if maker==4
	replace maker_R=5 if maker==5 
	replace maker_R=6 if maker==6
	replace maker_R=7 if maker==7 
	replace maker_R=8 if maker==8

gen makerYearliner=maker_R*yearlinear


//その他	
	gen color=color_std+color_opt
	
	gen d_4wd=0
	replace d_4wd=1 if drive=="4WD"
	
	gen d_at=0
	replace d_at=1 if mission=="3AT" | mission=="4AT" | mission=="5AT" | mission=="CVT"
	
	gen d_normal=0
	replace d_normal=1 if type=="乗用"

	gen sale2=sale
	replace sale2=0.001 if sale==0 & model==5
	

	
//分析	

	tsset model date

	preserve

		keep if date<=mdy(9,1,2016)
		drop if model==46
		drop if model==5 & date==mdy(5,1,2016) & date==mdy(6,1,2016)
		
		su sale2 fuel price_cpi petrol_cpi size weight d_at d_aeb d_hv eco_tax i.c_drive iv_BLP_own_kw iv_BLP_own_Fuel iv_BLP_own_size iv_BLP_other_kw iv_BLP_other_Fuel iv_BLP_other_size

			reg lnsale2 fuel ekdays_model2 after kouka3 petrol_cpi lnprice lnsize d_hv d_aeb eco_tax i.c_drive i.maker makerYearliner,robust 
			*outreg2 using myreg1.xls, replace

			ivregress 2sls lnsale2 (lnprice=Fuel_sum_own size_sum_own kw_sum_own Fuel_sum_mkt size_sum_mkt kw_sum_mkt iv_BLP_own_kw iv_BLP_own_Fuel iv_BLP_own_size iv_BLP_other_kw iv_BLP_other_Fuel iv_BLP_other_size) fuel ekdays_model2 after kouka3 petrol_cpi lnsize d_hv d_aeb eco_tax i.c_drive, first robust 
			*outreg2 using myreg1.xls, append 
			
			ivregress 2sls lnsale2 (lnprice=Fuel_sum_own size_sum_own kw_sum_own Fuel_sum_mkt size_sum_mkt kw_sum_mkt iv_BLP_own_kw iv_BLP_own_Fuel iv_BLP_own_size iv_BLP_other_kw iv_BLP_other_Fuel iv_BLP_other_size) fuel ekdays_model2 after kouka3 petrol_cpi lnsize d_hv d_aeb eco_tax i.c_drive i.maker, first robust 
			*outreg2 using myreg1.xls, append addtext(Maker FE, YES)
		
			ivregress 2sls lnsale2 (lnprice=Fuel_sum_own size_sum_own kw_sum_own Fuel_sum_mkt size_sum_mkt kw_sum_mkt iv_BLP_own_kw iv_BLP_own_Fuel iv_BLP_own_size iv_BLP_other_kw iv_BLP_other_Fuel iv_BLP_other_size) fuel ekdays_model2 after kouka3 petrol_cpi lnsize d_hv d_aeb eco_tax i.c_drive i.maker makerYearliner, first robust 
			*outreg2 using myreg1.xls, append addtext(Maker FE, YES, Year FE, Yes)

	restore

